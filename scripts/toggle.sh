#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"
# shellcheck source=./variables.sh
source "$CURRENT_DIR/variables.sh"

declare name popup_args session_args cmd OPT OPTARG OPTIND=1

while getopts :-:BCEb:c:d:e:h:s:S:t:T:w:x:y: OPT; do
	if [[ $OPT == '-' ]]; then OPT="${OPTARG%%=*}"; fi
	case "$OPT" in
	[BCE]) popup_args+=("-$OPT") ;;
	[bcdhsStTwxy]) popup_args+=("-$OPT" "$OPTARG") ;;
	# forward environment overrides to popup sessions
	e) session_args+=("-e" "'$OPTARG'") ;;
	name | socket-name | id-format | on-init | before-open | after-close)
		OPTARG="${OPTARG:${#OPT}}"
		if [[ ${OPTARG::1} == '=' ]]; then
			# format: `--name=value`
			declare "${OPT/-/_}"="${OPTARG:1}"
		else
			# format: `--name value`
			declare "${OPT/-/_}"="${!OPTIND}"
			OPTIND=$((OPTIND + 1))
		fi
		;;
	toggle) declare "${OPT/-/_}"="1" ;;
	help)
		cat <<-EOF
			USAGE:

			  toggle.sh [OPTION]... [SHELL_COMMAND]...

			OPTION:

			  --name <name>               Popup name. [Default: "$DEFAULT_NAME"]
			  --socket-name <value>       Socket name. [Default: "$DEFAULT_SOCKET_NAME"]
			  --id-format <value>         Popup ID format. [Default: "$DEFAULT_ID_FORMAT"]
			  --on-init <hook>            Command to run on popup initialization. [Default: "$DEFAULT_ON_INIT"]
			  --before-open <hook>        Hook to run before opening the popup. [Default: ""]
			  --after-close <hook>        Hook to run after closing the popup. [Default: ""]
			  --toggle                    Always close the current popup instead of opening a new one.
			  -[BCE]                      Flags passed to display-popup.
			  -[bcdehsStTwxy] <value>     Options passed to display-popup.

			EXAMPLES:

			  toggle.sh -Ed'#{pane_current_path}' --name=bash bash
		EOF
		exit
		;;
	*) badopt ;;
	esac
done
cmd=("${@:$OPTIND}")

# If the specified name doesn't match the currently opened popup, we open a new
# popup within the current one (i.e. popup-in-popup).
opened_name="$(showvariable @__popup_opened)"
if [[ -n $opened_name && ($name == "$opened_name" || -n $toggle || -z $*) ]]; then
	# Clear the variables to prevent a manually attached session from being
	# detached by the keybinding.
	tmux set -u @__popup_opened \; detach
	exit 0
fi

name="${name:-$DEFAULT_NAME}"
socket_name="${socket_name:-$(get_socket_name)}"
id_format="${id_format:-$(showopt @popup-id-format "$DEFAULT_ID_FORMAT")}"
on_init="${on_init:-$(showhook @popup-on-init "$DEFAULT_ON_INIT")}"
before_open="${before_open:-$(showhook @popup-before-open)}"
after_close="${after_close:-$(showhook @popup-after-close)}"

popup_id="$(format @popup_name "$name" "$id_format")"

eval "tmux -C \; $before_open >/dev/null"
tmux popup "${popup_args[@]}" "
		TMUX_POPUP_SERVER='$socket_name' tmux -L '$socket_name' \
			new -As '$popup_id' ${session_args[*]} $(escape "${cmd[@]}") \; \
			set @__popup_opened '$name' \; \
			$on_init \; \
			>/dev/null"
eval "tmux -C \; $after_close >/dev/null"
