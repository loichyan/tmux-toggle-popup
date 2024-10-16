#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./scripts/helpers.sh
source "$CURRENT_DIR/scripts/helpers.sh"
# shellcheck source=./scripts/variables.sh
source "$CURRENT_DIR/scripts/variables.sh"

set_keybindings() {
	tmux \; \
		set -g "@popup-toggle" "$CURRENT_DIR/scripts/toggle.sh" \; \
		set -g "@popup-focus" "$CURRENT_DIR/scripts/focus.sh" \;
}

handle_autostart() {
	# shellcheck disable=2155
	if [[ -z $TMUX_POPUP_SERVER ]]; then
		# set $TMUX_POPUP_SERVER, used to identify the popup server
		local socket_name="$(get_socket_name)"
		TMUX_POPUP_SERVER="$socket_name" tmux -L "$socket_name" new -d &
	fi
}

main() {
	set_keybindings
	handle_autostart
}

main
