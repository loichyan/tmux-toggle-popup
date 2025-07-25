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

		  toggle.sh -Ed'#{pane_current_path}' --name=bash bash
	EOF
}

# Prepares the tmux commands to open a popup. After called,
#
# - `open_cmds` is used to create the popup session
# - `on_cleanup` is used to undo temporary changes on the popup server
# - `popup_id` is set to the expanded popup session name
declare open_cmds on_cleanup popup_id
prepare_open() {
	local init_cmds=()

	popup_id=${id:-$(interpolate popup_name="$name" "$id_format")}
	popup_id=$(escape_session_name "$popup_id")

	init_cmds+=(new "${open_args[@]}" -s "$popup_id" "${program[@]}" \;)
	init_cmds+=(set @__popup_opened "$name" \;)
	init_cmds+=(set @__popup_id_format "$id_format" \;)

	# Create temporary toggle keys in the opened popup
	# shellcheck disable=SC2206
	for k in "${toggle_keys[@]}"; do
		init_cmds+=(bind $k run "#{@popup-toggle} --name='$name' --toggle-mode='$toggle_mode'" \;)
		on_cleanup+=(unbind $k \;)
	done

	parse_cmds "$on_init"
	open_cmds=$(escape "${init_cmds[@]}" "${cmds[@]}" \;)
}

declare socket_name toggle_mode on_init before_open after_close id_format
declare default_id_format caller_id_format opened_name default_shell
main() {
	batch_get_options \
		socket_name="#{@popup-socket-name}" \
		toggle_mode="#{@popup-toggle-mode}" \
		on_init="#{@popup-on-init}" \
		before_open="#{@popup-before-open}" \
		after_close="#{@popup-after-close}" \
		id_format="#{E:@popup-id-format}" \
		default_id_format="$DEFAULT_ID_FORMAT" \
		caller_id_format="#{@__popup_id_format}" \
		opened_name="#{@__popup_opened}" \
		default_shell="#{default-shell}"
	name=${name:-$DEFAULT_NAME}
	toggle_mode=${toggle_mode:-"$DEFAULT_TOGGLE_MODE"}
	socket_name=${socket_name:-"$DEFAULT_SOCKET_NAME"}
	on_init=${on_init:-"$DEFAULT_ON_INIT"}
	id_format="${id_format:-"$default_id_format"}"

	while getopts :-:BCEb:c:d:e:h:s:S:t:T:w:x:y: OPT; do
		if [[ $OPT == '-' ]]; then OPT=${OPTARG%%=*}; fi
		case "$OPT" in
		[BCE]) popup_args+=("-$OPT") ;;
		[bchsStTwxy]) popup_args+=("-$OPT" "$OPTARG") ;;
		# Forward working directory to popup sessions
		d) open_args+=("-c" "$OPTARG") ;;
		# Forward environment overrides to popup sessions
		e) open_args+=("-e" "$OPTARG") ;;
		name | toggle-key | socket-name | id-format | id | \
			toggle-mode | on-init | before-open | after-close)
			OPTARG=${OPTARG:${#OPT}}
			if [[ ${OPTARG::1} == '=' ]]; then
				# FORMAT: `--name=value`
				OPTARG=${OPTARG#*=}
			else
				# FORMAT: `--name value`
				OPTARG=${!OPTIND}
				OPTIND=$((OPTIND + 1))
			fi
			if [[ $OPT == "toggle-key" ]]; then
				toggle_keys+=("$OPTARG")
			else
				declare "${OPT//-/_}"="$OPTARG"
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
			# Reuse the caller's ID format to ensure we open the intended popup
			id_format=${caller_id_format}
			open_args+=("-d") # Create the target session if not exists
			prepare_open
			eval tmux -C "$open_cmds" &>/dev/null || true # Ignore error if already created
			# Forward current ID format so that this popup can be switched back.
			exec tmux switch -t "$popup_id" \; set @__popup_id_format "$id_format" \; >/dev/null
		elif [[ $toggle_mode != "force-open" ]]; then
			die "illegal toggle mode: $toggle_mode"
		fi
	fi

	# HOOK: before-open
	if [[ -n $before_open ]]; then
		parse_cmds "$before_open"
		eval "tmux -C $(escape "${cmds[@]}")" >/dev/null
	fi

	open_args+=("-A") # Create the target session and attach to it
	prepare_open

	# Starting from version 3.5, tmux uses the user's `default-shell` to execute
	# shell commands. However, our scripts are written in `sh`, which may not be
	# recognized by some shells that are incompatible with it. Here we change
	# the default shell to `/bin/sh` and then revert immediately.
	tmux \
		set default-shell "/bin/sh" \; \
		popup "${popup_args[@]}" -e TMUX_POPUP_SERVER="$socket_name" "
		tmux set default-shell '$default_shell'
		exec tmux -L '$socket_name' $open_cmds >/dev/null
	"

	# Undo temporary changes
	if [[ ${#on_cleanup} -gt 0 ]]; then
		# Ignore error if the server has already stopped
		eval "tmux -NCL '$socket_name' $(escape "${on_cleanup[@]}")" &>/dev/null || true
	fi

	# HOOK: after-close
	if [[ -n $after_close ]]; then
		parse_cmds "$after_close"
		eval "tmux -C $(escape "${cmds[@]}")" >/dev/null
	fi
}

main "$@"
