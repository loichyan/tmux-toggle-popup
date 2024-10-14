#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"
# shellcheck source=./variables.sh
source "$CURRENT_DIR/variables.sh"

declare name socket_name id_format popup_args cmd OPT OPTARG OPTIND=1

while getopts :-:BCEb:c:d:e:h:s:S:t:T:w:x:y: OPT; do
	if [[ $OPT = '-' ]]; then OPT="${OPTARG%%=*}"; fi
	case "$OPT" in
	[BCE]) popup_args+=("-$OPT") ;;
	[bcdehsStTwxy]) popup_args+=("-$OPT" "$OPTARG") ;;
	name | socket-name | id-format | on-init)
		OPTARG="${OPTARG:${#OPT}}"
		if [[ ${OPTARG::1} = '=' ]]; then
			declare "${OPT/-/_}"="${OPTARG:1}"
		else
			declare "${OPT/-/_}"="${!OPTIND}"
			OPTIND=$((OPTIND + 1))
		fi
		;;
	help)
		cat <<-EOF
			USAGE:

			  toggle.sh [OPTION]... [SHELL_COMMAND]...

			OPTION:

			  --name <name>                   Popup name. [Default: "$DEFAULT_NAME"]
			  --socket-name <value>           Socket name. [Default: "$DEFAULT_SOCKET_NAME"]
			  --id-format <value>             Popup ID format. [Default: "$DEFAULT_ID_FORMAT"]
			  --on-init <hook>                Command to run on popup initialization. [Default: "$DEFAULT_ON_INIT"]
				--popup-before-open <hook>      Hook to run before opening the popup.
				--popup-after-close <hook>      Hook to run after closing the popup.
			  -[BCE]                          Flags passed to display-popup.
			  -[bcdehsStTwxy] <value>         Options passed to display-popup.

			EXAMPLES:

			  toggle.sh -Ed'#{pane_current_path}' --name=bash bash
		EOF
		exit
		;;
	*) badopt ;;
	esac
done
cmd=("${@:$OPTIND}")

opened="$(showvariable @__popup_opened)"

if [[ -n "$opened" ]]; then
	# Clear the variables to prevent a manually attached session from being
	# detached by the keybinding.
	tmux set -u @__popup_opened \; detach

	exit 0
fi

name="${name:-"$DEFAULT_NAME"}"
socket_name="${socket_name:-$(get_socket_name)}"
id_format="${id_format:-$(showopt @popup-id-format "$DEFAULT_ID_FORMAT")}"
on_init="${on_init:-$(showopt @popup-on-init "$DEFAULT_ON_INIT")}"
popup_before_open="${popup_before_open:-$(showopt @popup-before-open)}"
popup_after_close="${popup_after_close:-$(showopt @popup-after-close)}"

popup_id="$(format @popup_name "$name" "$id_format")"

eval "tmux -C \; $popup_before_open >/dev/null"
tmux popup "${popup_args[@]}" "
		tmux -L '$socket_name' \
			new -As '$popup_id' $(escape "${cmd[@]}") \; \
			set @__popup_opened '$name' \; \
			$on_init \; \
			>/dev/null"

eval "tmux -C \; $popup_after_close >/dev/null"
