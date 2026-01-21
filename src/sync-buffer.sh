#!/usr/bin/env bash
# shellcheck disable=SC2154
set -eo pipefail
IFS=':' read -r caller_socket _caller_pane <<<"$__tmux_popup_caller"
if [[ -n $caller_socket ]]; then
	tmux -S "$caller_socket" saveb - | tmux loadb -
fi
