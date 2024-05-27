#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/scripts/helpers.sh"

for name in $(showopt @popup-bind | tr "," $"\n"); do
	cmd="$(showopt "@popup-bind-$name")"
	table="$(showopt "@popup-bind-$name-T" 'prefix')"
	key="$(showopt "@popup-bind-$name-key")"

	tmux bind \
		-T "$table" "$key" \
		run "$CURRENT_DIR/scripts/toggle.sh --name '$name' $cmd"
done
