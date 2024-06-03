#!/usr/bin/env bash

# Concats multiline Tmux commands into a single line.
joincmd() {
	sed 's/$/ \\;/' | tr '\n' ' '
}

# Escapes all given arguments.
escape() {
	if [ $# -gt 0 ]; then
		printf '%q ' "$@"
	fi
}

# Prints an error message and exits.
die() {
	echo "$*" >&2
	exit 1
}

# Reports illegal arguments.
badopt() {
	case "$OPT" in
	:) die "option requires a value: -$OPTARG <value>" ;;
	\?) die "illegal option: -$OPTARG" ;;
	*) die "illegal option: --$OPTARG" ;;
	esac
}

# Returns the value of the specified option or the second argument as the
# fallback value if the option is empty.
showopt() {
	local v
	v="$(tmux show -Aqv "$1")"
	echo "${v:-"$2"}"
}

# Expand the provided Tmux FORMAT string. The last argument is the format
# string, while the preceding ones represent variables available during the
# expansion.
format() {
	local set_v=() unset_v=()
	while [ $# -gt 1 ]; do
		set_v+=(set "$1" "$2" \;)
		unset_v+=(set -u "$1" \;)
		shift 2
	done
	tmux "${set_v[@]}" display -p "$*" \; "${unset_v[@]}"
}
