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
		set-option -g @popup-toggle "$CURRENT_DIR/src/toggle.sh" \; \
		set-option -g @popup-focus "$CURRENT_DIR/src/focus.sh" \; \
		set-option -g @popup-proxy "$CURRENT_DIR/bin/proxy" \; \
		set-option -g @popup-sync-buffer "$CURRENT_DIR/src/sync-buffer.sh" \; \
		set-option -goq @popup-autostart 'off' \; \
		set-option -goq @popup-id-format "$DEFAULT_ID_FORMAT" \; \
		set-option -goq @popup-on-init "$DEFAULT_ON_INIT" \; \
		set-option -goq @popup-toggle-mode "$DEFAULT_TOGGLE_MODE" \; \
		set-option -goq @popup-socket-name "$DEFAULT_SOCKET_NAME" \;

	local autostart socket_name socket_path default_shell
	target='' batch_get_options \
		autostart='#{@popup-autostart}' \
		socket_name='#{@popup-socket-name}' \
		socket_path='#{@popup-socket-path}' \
		default_shell='#{default-shell}'

	# Do not start itself within a popup server
	if [[ $autostart == 'on' && -z $TMUX_POPUP_SERVER ]]; then
		(
			local args
			if [[ -n $socket_path ]]; then
				args=(-S "$socket_path")
			else
				args=(-L "$socket_name")
			fi
			# Set $TMUX_POPUP_SERVER to identify the popup server.
			export TMUX_POPUP_SERVER=$socket_name
			# Propagate user's default shell.
			export SHELL=${default_shell:-$SHELL}
			tmux "${args[@]}" set-option -g exit-empty off \; start-server
		) &
	fi
}
main "$@"
