#!/bin/sh

# Clear the temporary variable
open_script="${__tmux_popup_open:-}"
unset -v __tmux_popup_open
if [ -n "$open_script" ]; then
	# Execute the open script if exists,
	eval "$open_script"
else
	# or fallback to user's default shell.
	exec "$SHELL" "$@"
fi
