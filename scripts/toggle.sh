#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"

DEFAULT_NAME='default'
DEFAULT_SOCKET_NAME='popup'
DEFAULT_ID_FORMAT='#{b:socket_path}/#{session_name}/#{b:pane_current_path}/#{@popup_name}'
DEFAULT_ON_OPEN="set exit-empty off ; set status off"
DEFAULT_ON_CLOSE=''

declare name cmd popup_args

while [[ $# -gt 0 ]]; do
	case $1 in
	--name)
		name="$2"
		shift
		shift
		;;
	--help)
		cat <<-EOF >&2
			USAGE:

			  toggle.sh [OPTION]... [COMMAND]...

			OPTION:

			  --name <name>  Popup name [Default: "default"]
			  -[BCE]         Flags passed to display-popup
			  -[bcdehsStTwxy] <value>
			                 Options passed to display-popup

			EXAMPLES:

			  toggle.sh --name bash -E -d '#{pane_current_path}' bash
		EOF
		exit
		;;
	-[BCE])
		popup_args+=("$1")
		shift
		;;
	-[bcdehsStTwxy])
		popup_args+=("$1" "$2")
		shift
		shift
		;;
	-*)
		echo "Unknown argument '$1'"
		exit 1
		;;
	*)
		cmd="'$(printf '%q ' "$@")'"
		break
		;;
	esac
done

opened="$(tmux show -qv @__popup_opened)"

if [[ -n "$opened" && ("$opened" = "$name" || -z "$*") ]]; then
	on_close=$(showopt @popup-on-close "$DEFAULT_ON_CLOSE")

	# Clear the flag to prevent a manually attached session from being detached by
	# the keybinding.
	eval "$(
		cat <<-EOF | makecmd
			tmux
			$on_close
			set -u @__popup_opened
			detach
		EOF
	)"
else
	: "${name:="$DEFAULT_NAME"}"
	socket_name="$(showopt @popup-socket-name "$DEFAULT_SOCKET_NAME")"
	on_open="$(showopt @popup-on-open "$DEFAULT_ON_OPEN")"
	id_format="$(showopt @popup-id-format "$DEFAULT_ID_FORMAT")"
	popup_id="$(tmux set @popup_name "$name" \; display -p "$id_format" \; set -u @popup_name)"

	tmux popup "${popup_args[@]}" "$(
		cat <<-EOF | makecmd
			tmux -L '$socket_name'
			new -As '$popup_id' $cmd
			set @__popup_opened '$name'
			$on_open
		EOF
	)"
fi
