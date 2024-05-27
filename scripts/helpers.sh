#!/usr/bin/env bash

showopt() {
	local v
	v="$(tmux show-option -gqv "$1")"
	echo "${v:-"$2"}"
}

makecmd() {
	tr '\n' ';' | sed 's/;/ \\; /g'
}

bindkey() {
	tmux bind-key "$@"
}
