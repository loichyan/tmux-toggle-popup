#!/usr/bin/env bash
# shellcheck disable=SC2154
# Use `tmux display` to ensure we see the latest environments.
IFS=':' read -r socket_name socket_path _ caller < <(tmux display-message -p '#{@popup-socket-name}:#{@popup-socket-path}:#{__tmux_popup_caller}')
socket_path=${socket_path:-"${TMUX_TMPDIR:-/tmp}/tmux-$UID/$socket_name"}
export TMUX=${caller:-$TMUX}
if [[ $1 == '--sync' ]]; then
	shift
	exec tee >(tmux "$@") >(tmux -S "$socket_path" "$@") >/dev/null
else
	exec tmux "$@"
fi
