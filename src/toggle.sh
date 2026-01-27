#!/usr/bin/env bash
# shellcheck disable=SC2153
# shellcheck disable=SC2154
# shellcheck disable=SC2155

set -eo pipefail
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"
# shellcheck source=./variables.sh
source "$CURRENT_DIR/variables.sh"

usage() {
	cat <<-EOF
		Usage:

		  toggle.sh [OPTIONS] [POPUP_OPTIONS] [SHELL_COMMAND]...

		Options:

		  --name <name>               Popup name [Default: "$DEFAULT_NAME"]
		  --id <id>                   Popup ID, default to the expanded ID format
		  --toggle-key <key>          Bind additional keys to close the opened popup
		  -[BCE]                      Flags passed to display-popup
		  -[bcdehsStTwxy] <value>     Options passed to display-popup

		Global Options:

		  Override the global options on the fly.

		  --id-format <str>           Popup ID format [Default: "$DEFAULT_ID_FORMAT"]
		  --on-init <hook>            Command to run on popup initialization [Default: "$DEFAULT_ON_INIT"]
		  --before-open <hook>        Hook to run before opening the popup [Default: ""]
		  --after-close <hook>        Hook to run after closing the popup [Default: ""]
		  --toggle-mode <mode>        Action to handle nested calls [Default: "$DEFAULT_TOGGLE_MODE"]
		  --socket-name <name>        Socket name of the popup server [Default: "$DEFAULT_SOCKET_NAME"]
		  --socket-path <path>        Socket path of the popup server [Default: ""]

		Examples:

		  toggle.sh -Ed'##{pane_current_path}' --name=bash bash
	EOF
}

# Prepares the tmux commands to initialize a popup session. After called,
#
# - `init_cmds` is used to initialize the popup session
# - `on_cleanup` is used to undo temporary changes on the popup server
# - `popup_id` is set to the name of the target popup session
declare init_cmds=() on_cleanup=() popup_id
prepare_init() {
	popup_id=${id:-$(interpolate popup_name="$name" "$id_format")}
	popup_id=$(escape_session_name "$popup_id")

	init_cmds=()
	if [[ $1 == "open" ]]; then
		init_cmds+=(new -As "$popup_id" "${init_args[@]}" \;)
	else
		# Start target session before attaching to it
		if ! tmux has -t "=$popup_id" 2>/dev/null; then
			init_cmds+=(new -ds "$popup_id" "${init_args[@]}" \;)
		fi
		init_cmds+=(switchc -t "$popup_id" \;)
	fi

	init_cmds+=(
		# Keep the information about popup caller up-to-date
		setenv __tmux_popup_caller "${popup_caller:-"$current_pane_id:$TMUX"}" \;
	)

	# Create temporary toggle keys in the opened popup
	# shellcheck disable=SC2206
	for k in "${toggle_keys[@]}"; do
		init_cmds+=(bind $k run "#{@popup-toggle} $(escape "${args[@]}")" \;)
		on_cleanup+=(unbind $k \;)
	done

	# Handle hook: on-init
	if check_hook "$on_init"; then init_cmds+=(run -C "$on_init" \;); fi
}

declare name id id_format toggle_keys=() init_args=() display_args=()
declare on_init before_open after_close toggle_mode socket_name socket_path
declare default_shell popup_caller opened_name current_pane_id
main() {
	# Load internal variables
	popup_caller=${__tmux_popup_caller} # content: {pane_id}:$TMUX
	opened_name=${__tmux_popup_name}

	# Expand each argument as a tmux format string before actually parsing.
	local i=1 batch_expand_args=()
	while [[ $i -le $# ]]; do
		batch_expand_args+=("argv_$i=${!i}")
		i=$((i + 1))
	done

	# Expand format strings in the caller pane to ensure consistency.
	target=$popup_caller batch_get_options \
		id_format="#{E:@popup-id-format}" \
		on_init="#{@popup-on-init}" \
		before_open="#{@popup-before-open}" \
		after_close="#{@popup-after-close}" \
		toggle_mode="#{@popup-toggle-mode}" \
		socket_name="#{@popup-socket-name}" \
		socket_path="#{@popup-socket-path}" \
		default_shell="#{default-shell}" \
		current_pane_id="#{pane_id}" \
		"${batch_expand_args[@]}"

	local i=1 k expanded_args=()
	while [[ $i -le $# ]]; do
		k="argv_$i"
		expanded_args+=("${!k}")
		i=$((i + 1))
	done
	set -- "${expanded_args[@]}" # now all arguments are expanded

	declare OPT OPTARG OPTIND=1
	while getopts :-:BCEb:c:d:e:h:s:S:t:T:w:x:y: OPT; do
		if [[ $OPT == '-' ]]; then OPT=${OPTARG%%=*}; fi
		case "$OPT" in
		[BCE]) display_args+=("-$OPT") ;;
		[bchsStTwxy]) display_args+=("-$OPT" "$OPTARG") ;;
		# Forward working directory to popup sessions
		d)
			# Report deprecated placeholders
			if [[ $OPTARG =~ \{popup_caller(_pane)?_path\} ]]; then
				die "'{popup_caller_path}' and '{popup_caller_pane_path}' has been removed." \
					"Please use '##{session_path}' and '##{pane_current_path}' instead." \
					"For more information, see <https://github.com/loichyan/tmux-toggle-popup/pull/58>."
			fi
			init_args+=(-c "$OPTARG")
			;;
		# Forward environment overrides to popup sessions
		e) init_args+=(-e "$OPTARG") ;;
		name | id | id-format | toggle-key | \
			on-init | before-open | after-close | \
			toggle-mode | socket-name | socket-path)
			OPTARG=${OPTARG:${#OPT}}
			if [[ ${OPTARG::1} == '=' ]]; then
				# Handle syntax: `--name=value`
				OPTARG=${OPTARG#*=}
			else
				# Handle syntax: `--name value`
				OPTARG=${!OPTIND}
				OPTIND=$((OPTIND + 1))
			fi
			if [[ $OPT == "toggle-key" ]]; then
				toggle_keys+=("$OPTARG")
			else
				printf -v "${OPT//-/_}" "%s" "$OPTARG"
			fi
			;;
		help)
			usage
			exit
			;;
		*) die_badopt ;;
		esac
	done

	# If ID specified, use it as the popup name.
	if [[ -n $id ]]; then name=${id}; fi
	name=${name:-$DEFAULT_NAME}
	init_args+=(
		-e __tmux_popup_name="$name" # set variable to identify opened popups
		"${@:$OPTIND}"               # forward program to start popup session
	)

	# Determine which server to start popups.
	if [[ -n $socket_path ]]; then
		popup_socket=(-S "$socket_path")
		popup_server=${socket_path##*/}
	else
		popup_socket=(-L "$socket_name")
		popup_server=${socket_name}
	fi

	if [[ -z $opened_name ]]; then
		prepare_init "open"
	elif [[ $name == "$opened_name" || $OPTIND -eq 1 || $toggle_mode == "force-close" ]]; then
		tmux detach >/dev/null
		return
	elif [[ $toggle_mode == "switch" ]]; then
		prepare_init "switch"
		tmux "${init_cmds[@]}"
		return
	elif [[ $toggle_mode != "force-open" ]]; then
		die "illegal toggle mode: $toggle_mode"
	fi

	# Command sequence to open the popup window, including hooks.
	open_cmds=()
	# Script to initialize the popup session inside a popup window.
	open_script=""

	# Handle hook: before-open
	if check_hook "$before_open"; then open_cmds+=(run -C "$before_open" \;); fi

	# Starting from version 3.5, tmux uses the user's `default-shell` to execute
	# shell commands. However, our scripts require sh(1) and may not be parsed
	# correctly by some incompatible shells. In this case, we change the default
	# shell to `/bin/sh` and then revert it immediately.
	open_script+="tmux set default-shell '$default_shell';"
	open_cmds+=(set default-shell "/bin/sh" \;)

	# Set $TMUX_POPUP_SERVER to identify the popup server.
	open_script+="export TMUX_POPUP_SERVER='$popup_server' SHELL='$default_shell';"

	# Suppress stdout to hide the `[detached] ...` message
	open_script+="exec $(escape tmux "${popup_socket[@]}" "${init_cmds[@]}")>/dev/null;"
	open_cmds+=(display-popup "${display_args[@]}" "$open_script" \;)

	# Handle hook: after-close
	if check_hook "$after_close"; then open_cmds+=(run -C "$after_close" \;); fi

	# Do open the popup window
	# printf '%s\n'
	tmux "${open_cmds[@]}"

	# Undo temporary changes on the popup server
	if [[ -z $opened_name && ${#on_cleanup} -gt 0 ]]; then
		# Ignore error if the server has already stopped
		tmux -N "${popup_socket[@]}" "${on_cleanup[@]}" 2>/dev/null || true
	fi
}

args=("$@")
main "$@"
