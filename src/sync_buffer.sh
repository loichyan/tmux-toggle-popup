#!/usr/bin/env bash
# shellcheck disable=SC2154
IFS=':' read -r _ caller <<<"$__tmux_popup_caller"
if [[ -n $caller ]]; then
	TMUX=$caller tmux save-buffer - | tmux load-buffer -
fi
