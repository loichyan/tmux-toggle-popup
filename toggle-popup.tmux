#!/usr/bin/env bash

# Name:     tmux-toggle-popup
# Version:  0.4.4
# Authors:  Loi Chyan <loichyan@outlook.com>
# License:  MIT OR Apache-2.0

set -eo pipefail
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./src/helpers.sh
source "$CURRENT_DIR/src/helpers.sh"
# shellcheck source=./src/variables.sh
source "$CURRENT_DIR/src/variables.sh"

main() {
	# Set option defaults, and export public APIs.
	tmux \
		set -g @popup-toggle "$CURRENT_DIR/src/toggle.sh" \; \
		set -g @popup-focus "$CURRENT_DIR/src/focus.sh" \; \
		set -goq @popup-autostart "off" \; \
		set -goq @popup-id-format "$DEFAULT_ID_FORMAT" \; \
		set -goq @popup-on-init "$DEFAULT_ON_INIT" \; \
		set -goq @popup-toggle-mode "$DEFAULT_TOGGLE_MODE" \; \
		set -goq @popup-socket-name "$DEFAULT_SOCKET_NAME" \;

	local autostart socket_name default_shell
	target='' batch_get_options \
		autostart="#{@popup-autostart}" \
		socket_name="#{@popup-socket-name}" \
		default_shell="#{default-shell}"
	default_shell=${default_shell:-$SHELL}

	# Do not start itself within a popup server
	if [[ $autostart == "on" && -z $TMUX_POPUP_SERVER ]]; then
		# Set $TMUX_POPUP_SERVER to identify the popup server.
		# Propagate user's default shell.
		TMUX_POPUP_SERVER="$socket_name" SHELL="$default_shell" \
			tmux -L "$socket_name" set exit-empty off \; start &
	fi
}
main "$@"
