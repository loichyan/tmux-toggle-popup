#!/bin/sh
# execute the open script if exists
if [ -n "$__tmux_popup_open" ]; then
	eval exec "$__tmux_popup_open"
else
	exec "$SHELL" "$@"
fi
