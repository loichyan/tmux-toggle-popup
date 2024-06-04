#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set keybindings
for key in toggle focus; do
	tmux set -g "@popup-$key" "$CURRENT_DIR/scripts/$key.sh"
done
