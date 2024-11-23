#!/usr/bin/env bash

# name:     tmux-toggle-popup
# version:  0.4.0
# authors:  Loi Chyan <loichyan@foxmail.com>
# license:  MIT OR Apache-2.0

SRC_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# shellcheck source=./scripts/helpers.sh
source "$SRC_DIR/scripts/helpers.sh"
# shellcheck source=./scripts/variables.sh
source "$SRC_DIR/scripts/variables.sh"

set_keybindings() {
	tmux \; \
		set -g "@popup-toggle" "$SRC_DIR/scripts/toggle.sh" \; \
		set -g "@popup-focus" "$SRC_DIR/scripts/focus.sh" \;
}

handle_autostart() {
	# do not start itself within a popup server
	if [[ $(showopt @popup-autostart) == "on" && -z ${TMUX_POPUP_SERVER-} ]]; then
		# set $TMUX_POPUP_SERVER, used to identify the popup server
		socket_name="$(get_socket_name)"
		# propagate user's default shell
		default_shell="$(get_default_shell)"
		TMUX_POPUP_SERVER="$socket_name" SHELL="$default_shell" \
			tmux -L "$socket_name" set exit-empty off \; start &
	fi
}

main() {
	set_keybindings
	handle_autostart
}

main
