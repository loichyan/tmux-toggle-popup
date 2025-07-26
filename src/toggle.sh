#!/usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"
# shellcheck source=./variables.sh
source "$CURRENT_DIR/variables.sh"

declare OPT OPTARG OPTIND=1 popup_args open_args toggle_keys program
usage() {
	cat <<-EOF
		Usage:

		  toggle.sh [OPTIONS] [POPUP_OPTIONS] [SHELL_COMMAND]...

		Options:

		  --name <name>               Popup name [Default: "$DEFAULT_NAME"]
		  --id <id>                   Popup ID, default to the expanded ID format
		  --toggle-mode <mode>        Action to handle nested calls [Default: "$DEFAULT_TOGGLE_MODE"]
		  --toggle-key <key>          Bind additional keys to close the opened popup
		  -[BCE]                      Flags passed to display-popup
		  -[bcdehsStTwxy] <value>     Options passed to display-popup

		Popup Options:

		  Override global popup options on the fly.

		  --socket-name <value>       Socket name [Default: "$DEFAULT_SOCKET_NAME"]
		  --id-format <value>         Popup ID format [Default: "$DEFAULT_ID_FORMAT"]
		  --on-init <hook>            Command to run on popup initialization [Default: "$DEFAULT_ON_INIT"]
		  --before-open <hook>        Hook to run before opening the popup [Default: ""]
		  --after-close <hook>        Hook to run after closing the popup [Default: ""]

		Examples:

		  toggle.sh -Ed'{popup_caller_pane_path}' --name=bash bash
	EOF
}

# Prepares the tmux commands to open a popup. After called,
#
# - `open_cmds` is used to create the popup session
# - `on_cleanup` is used to undo temporary changes on the popup server
# - `popup_id` is set to the expanded popup session name
declare open_cmds on_cleanup popup_id
prepare_open() {
	open_cmds=()

	popup_id=${id:-$(interpolate popup_name="$name" "$id_format")}
	popup_id=$(escape_session_name "$popup_id")
	if [[ -n $popup_dir ]]; then
		open_args+=(-c "$(interpolate popup_caller_path="$caller_path" \
			popup_caller_pane_path="$caller_pane_path" "$popup_dir")")
	fi

	if [[ $1 == "open" ]]; then
		open_cmds+=(new -As "$popup_id" "${open_args[@]}" "${program[@]}" \;)
	else
		if ! tmux has -t "$popup_id" 2>/dev/null; then
			open_cmds+=(new -ds "$popup_id" "${open_args[@]}" "${program[@]}" \;)
		fi
		open_cmds+=(switch -t "$popup_id" \;)
	fi

	open_cmds+=(set @__popup_opened "$name" \;)
	open_cmds+=(set @__popup_id_format "$id_format" \;)
	open_cmds+=(set @__popup_caller_path "$caller_path" \;)
	open_cmds+=(set @__popup_caller_pane_path "$caller_pane_path" \;)

	# Create temporary toggle keys in the opened popup
	# shellcheck disable=SC2206
	for k in "${toggle_keys[@]}"; do
		open_cmds+=(bind $k run "#{@popup-toggle} --name='$name' --toggle-mode='$toggle_mode'" \;)
		on_cleanup+=(unbind $k \;)
	done

	parse_cmds "$on_init"
	open_cmds+=("${cmds[@]}")
}

declare name socket_name toggle_mode on_init before_open after_close id_format
declare opened_name caller_id_format caller_path caller_pane_path
declare default_id_format default_shell session_path pane_path popup_dir
main() {
	batch_get_options \
		socket_name="#{@popup-socket-name}" \
		toggle_mode="#{@popup-toggle-mode}" \
		on_init="#{@popup-on-init}" \
		before_open="#{@popup-before-open}" \
		after_close="#{@popup-after-close}" \
		id_format="#{E:@popup-id-format}" \
		opened_name="#{@__popup_opened}" \
		caller_id_format="#{@__popup_id_format}" \
		caller_path="#{@__popup_caller_path}" \
		caller_pane_path="#{@__popup_caller_pane_path}" \
		default_id_format="$DEFAULT_ID_FORMAT" \
		default_shell="#{default-shell}" \
		session_path="#{session_path}" \
		pane_path="#{pane_current_path}"
	name=${name:-$DEFAULT_NAME}
	socket_name=${socket_name:-$DEFAULT_SOCKET_NAME}
	toggle_mode=${toggle_mode:-$DEFAULT_TOGGLE_MODE}
	on_init=${on_init:-$DEFAULT_ON_INIT}
	id_format="${id_format:-$default_id_format}"

	while getopts :-:BCEb:c:d:e:h:s:S:t:T:w:x:y: OPT; do
		if [[ $OPT == '-' ]]; then OPT=${OPTARG%%=*}; fi
		case "$OPT" in
		[BCE]) popup_args+=("-$OPT") ;;
		[bchsStTwxy]) popup_args+=("-$OPT" "$OPTARG") ;;
		# Forward working directory to popup sessions
		d) popup_dir=$OPTARG ;;
		# Forward environment overrides to popup sessions
		e) open_args+=("-e" "$OPTARG") ;;
		name | toggle-key | socket-name | id-format | id | \
			toggle-mode | on-init | before-open | after-close)
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
	program=("${@:$OPTIND}")

	if [[ -n $opened_name ]]; then
		if [[ $name == "$opened_name" || $OPTIND -eq 1 || $toggle_mode == "force-close" ]]; then
			exec tmux detach >/dev/null
		elif [[ $toggle_mode == "switch" ]]; then
			# Inherit the caller's ID format in switch mode
			id_format=${caller_id_format}
			prepare_open "switch"
			exec tmux "${open_cmds[@]}"
		elif [[ $toggle_mode != "force-open" ]]; then
			die "illegal toggle mode: $toggle_mode"
		fi
	fi

	# Run hook: before-open
	if [[ -n $before_open ]]; then
		parse_cmds "$before_open"
		tmux -C "${cmds[@]}" >/dev/null
	fi

	# This session is the caller, so use it's path
	caller_path=${session_path}
	caller_pane_path=${pane_path}
	prepare_open "open"

	open_script=""
	open_script+="tmux set default-shell '$default_shell' ; "
	open_script+="exec $(escape tmux -L "$socket_name" "${open_cmds[@]}") >/dev/null"

	# Starting from version 3.5, tmux uses the user's `default-shell` to execute
	# shell commands. However, our scripts are written in `sh`, which may not be
	# recognized by some shells that are incompatible with it. Here we change
	# the default shell to `/bin/sh` and then revert immediately.
	tmux set default-shell "/bin/sh" \; \
		popup "${popup_args[@]}" -e TMUX_POPUP_SERVER="$socket_name" "$open_script"

	# Undo temporary changes on the popup server
	if [[ ${#on_cleanup} -gt 0 ]]; then
		# Ignore error if the server has already stopped
		tmux -NCL "$socket_name" "${on_cleanup[@]}" &>/dev/null || true
	fi

	# Run hook: after-close
	if [[ -n $after_close ]]; then
		parse_cmds "$after_close"
		tmux -C "${cmds[@]}" >/dev/null
	fi
}

main "$@"
