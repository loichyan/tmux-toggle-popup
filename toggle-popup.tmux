#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set keybindings
tmux set -g @popup-toggle "$CURRENT_DIR/scripts/toggle.sh"
