#!/usr/bin/env bash

showopt() {
	local v
	v="$(tmux show -Aqv "$1")"
	echo "${v:-"$2"}"
}

escape() {
	if [ $# -gt 0 ]; then
		printf '%q ' "$@"
	fi
}

joincmd() {
	sed 's/$/ \\;/' | tr '\n' ' '
}

bindkey() {
	tmux bind "$@"
}

format() {
	local set_v=() unset_v=()
	while [ $# -gt 1 ]; do
		set_v+=(set "$1" "$2" \;)
		unset_v+=(set -u "$1" \;)
		shift 2
	done
	tmux "${set_v[@]}" display -p "$*" \; "${unset_v[@]}"
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
