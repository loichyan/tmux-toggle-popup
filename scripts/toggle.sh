#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/helpers.sh"

DEFAULT_ID_FORMAT='popup/#{session_name}/#{b:pane_current_path}/#{@popup_name}'
DEFAULT_ON_OPEN='set status off'
DEFAULT_ON_CLOSE=''

declare name="default" cmd popup_args

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

flag="@popup-$name-opened"

if [[ "$(tmux show -qv "$flag")" = 1 ]]; then
	on_close=$(showopt @popup-on-close "$DEFAULT_ON_CLOSE")

	# Clear the flag to prevent a manually attached session from being detached by
	# the keybinding.
	eval "$(
		cat <<-EOF | makecmd
			tmux
			$on_close
			set -u '$flag'
			detach
		EOF
	)"
else
	id_format="$(showopt @popup-id-format "$DEFAULT_ID_FORMAT")"
	on_open="$(showopt @popup-on-open "$DEFAULT_ON_OPEN")"
	popup_id="$(tmux set @popup_name "$name" \; display -p "$id_format" \; set -u @popup_name)"

	tmux popup "${popup_args[@]}" "$(
		cat <<-EOF | makecmd
			tmux
			new -ADs '$popup_id' $cmd
			set '$flag' 1
			$on_open
		EOF
	)"
fi
