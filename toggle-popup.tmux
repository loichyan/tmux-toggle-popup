#!/usr/bin/env bash

# Name:     tmux-toggle-popup
# Version:  0.4.1
# Authors:  Loi Chyan <loichyan@foxmail.com>
# License:  MIT OR Apache-2.0

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./src/helpers.sh
source "$CURRENT_DIR/src/helpers.sh"
# shellcheck source=./src/variables.sh
source "$CURRENT_DIR/src/variables.sh"

export_commands() {
	tmux \; \
		set -g "@popup-toggle" "$CURRENT_DIR/src/toggle.sh" \; \
		set -g "@popup-focus" "$CURRENT_DIR/src/focus.sh" \;
}

handle_autostart() {
	# Do not start itself within a popup server
	if [[ $(showopt @popup-autostart) == "on" && -z ${TMUX_POPUP_SERVER-} ]]; then
		# Set $TMUX_POPUP_SERVER, used to identify the popup server
		socket_name=$(get_socket_name)
		# Propagate user's default shell
		default_shell=$(get_default_shell)
		env \
			TMUX_POPUP_SERVER="$socket_name" \
			SHELL="$default_shell" \
			tmux -L "$socket_name" set exit-empty off \; start &
	fi
}

main() {
	export_commands
	handle_autostart
}
main
