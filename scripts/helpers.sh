#!/usr/bin/env bash

showopt() {
	local v
	v="$(tmux show -Aqv "$1")"
	echo "${v:-"$2"}"
}

makecmd() {
	tr '\n' ';' | sed 's/;/ \\; /g'
}

bindkey() {
	tmux bind "$@"
}

die() {
	echo "$*" >&2
	exit 1
}

badopt() {
	case "$OPT" in
	:) die "option requires a value: -$OPTARG <value>" ;;
	\?) die "illegal option: -$OPTARG" ;;
	*) die "illegal option: --$OPTARG" ;;
	esac
}
