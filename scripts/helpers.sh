#!/usr/bin/env bash

# Escapes all given arguments.
escape() {
	if [[ $# -gt 0 ]]; then
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
	*) die "illegal option: --$OPT" ;;
	esac
}

# Returns the value of the specified option or the second argument as the
# fallback value if the option is empty.
showopt() {
	local v
	v="$(tmux show -gqv "$1")"
	echo "${v:-"$2"}"
}

# Returns the value of the specified variable in the current pane.
showvariable() {
	tmux show -qv "$1"
}

# Parses the tmux script into sequences and escapes each one, ensuring they can
# be safely interpreted by Bash.
makecmds() {
	# Force to use bash's bulitin printf as macOS's printf does not support "%q"
	xargs bash -c 'printf "%q " "$@"' {}
}

# Expand the provided tmux FORMAT string. The last argument is the format
# string, while the preceding ones represent variables available during the
# expansion.
format() {
	local set_v=() unset_v=()
	while [[ $# -gt 1 ]]; do
		set_v+=(set "$1" "$2" \;)
		unset_v+=(set -u "$1" \;)
		shift 2
	done
	tmux "${set_v[@]}" display -p "$*" \; "${unset_v[@]}"
}
