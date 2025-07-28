#!/usr/bin/env bash

# Name:     tmux-toggle-popup
# Version:  0.4.1
# Authors:  Loi Chyan <loichyan@foxmail.com>
# License:  MIT OR Apache-2.0

set -e
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./src/helpers.sh
source "$CURRENT_DIR/src/helpers.sh"
# shellcheck source=./src/variables.sh
source "$CURRENT_DIR/src/variables.sh"

handle_exports() {
	tmux \
		set -g "@popup-toggle" "$CURRENT_DIR/src/toggle.sh" \; \
		set -g "@popup-focus" "$CURRENT_DIR/src/focus.sh" \;
}

handle_autostart() {
	# Do not start itself within a popup server
	if [[ $autostart == "on" && -z $TMUX_POPUP_SERVER ]]; then
		# Set $TMUX_POPUP_SERVER so as to identify the popup server,
		# and propagate user's default shell.
		env \
			TMUX_POPUP_SERVER="$socket_name" \
			SHELL="$default_shell" \
			tmux -L "$socket_name" set exit-empty off \; start &
	fi
}

declare autostart socket_name default_shell
main() {
	batch_get_options \
		autostart="#{@popup-autostart}" \
		socket_name="#{@popup-socket-name}" \
		default_shell="#{default-shell}"
	socket_name=${socket_name:-$DEFAULT_SOCKET_NAME}
	default_shell=${default_shell:-$SHELL}

	handle_exports
	handle_autostart
}
main
