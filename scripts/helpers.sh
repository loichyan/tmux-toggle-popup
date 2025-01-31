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
	v="$(tmux show -gqv "$1")"
	echo "${v:-"${2-}"}"
}

# Returns the value of the specified variable in the current pane.
showvariable() {
	tmux show -qv "$1"
}

# Parses the tmux script into sequences and escapes each one, ensuring they can
# be safely interpreted by Bash.
makecmds() {
	# Force to use bash's bulitin printf as macOS's printf does not support
	# "%q". The first argument to `bash -c` is the script name, so we need a
	# dummy name to prevent it from being "eaten" by Bash.
	echo "$*" | xargs bash -c 'printf "%q " "$@"' _
}

# Expands the provided tmux FORMAT string.
format() {
	tmux display -p "$*"
}

# Interpolates the provided FORMAT string. The last argument is the format
# string, while the preceding arguments represent the variables available during
# the expansion. All `{variable}` placeholders in the format string will be
# replaced with their corresponding values.
interpolate() {
	local result="${*: -1}"
	while [[ $# -gt 1 ]]; do
		result="${result//"{$1}"/$2}"
		shift 2
	done
	echo "$result"
}

# Replace special chars with '_' in a session name.
# See: https://github.com/tmux/tmux/blob/ef68debc8d9e0e5567d328766f705bb1f42b7c51/session.c#L242
check_popup_id() {
	sed 's/[.:]/_/g'
}
