#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"

DEFAULT_NAME='default'
DEFAULT_SOCKET_NAME='popup'
DEFAULT_ID_FORMAT='#{b:socket_path}/#{session_name}/#{b:pane_current_path}/#{@popup_name}'
DEFAULT_ON_OPEN="set exit-empty off \; set status off"
DEFAULT_ON_CLOSE=''

declare name popup_args cmd OPT OPTARG OPTIND=1

while getopts :-:BCEb:c:d:e:h:s:S:t:T:w:x:y: OPT; do
	if [ "$OPT" = "-" ]; then OPT="$OPTARG"; fi
	case "$OPT" in
	[BCE]) popup_args+=("-$OPT") ;;
	[bcdehsStTwxy]) popup_args+=("-$OPT" "$OPTARG") ;;
	name)
		name="${!OPTIND}"
		OPTIND=$((OPTIND + 1))
		;;
	name=*) name="${OPTARG#*=}" ;;
	help)
		cat <<-EOF
			USAGE:

			  toggle.sh [OPTION]... [COMMAND]...

			OPTION:

			  --name <name>     Popup name [Default: "default"]
			  -[BCE]            Flags passed to display-popup
			  -[bcdehsStTwxy] <value>
			                    Options passed to display-popup

			EXAMPLES:

			  toggle.sh -Ed'#{pane_current_path}' --name=bash bash
		EOF
		exit
		;;
	*) badopt ;;
	esac
done
cmd=("${@:$OPTIND}")

opened="$(showopt @__popup_opened)"

if [[ -n "$opened" && ("$opened" = "$name" || -z "$*") ]]; then
	# Clear the variables to prevent a manually attached session from being
	# detached by the keybinding.
	eval "$(
		cat <<-EOF | joincmd
			tmux
				$(showopt @popup-on-close "$DEFAULT_ON_CLOSE")
				set -u @__popup_opened
				detach
		EOF
	)"
else
	name="${name:-"$DEFAULT_NAME"}"
	socket_name="$(showopt @popup-socket-name "$DEFAULT_SOCKET_NAME")"
	id_format="$(showopt @popup-id-format "$DEFAULT_ID_FORMAT")"
	popup_id="$(format @popup_name "$name" "$id_format")"

	tmux popup "${popup_args[@]}" "$(
		cat <<-EOF | joincmd
			tmux -L '$socket_name'
				new -As '$popup_id' $(escape "${cmd[@]}")
				set @__popup_opened '$name'
				$(showopt @popup-on-open "$DEFAULT_ON_OPEN")
		EOF
	) >/dev/null"
fi
