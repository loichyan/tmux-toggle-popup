#!/usr/bin/env bash

# Prints an error message and exits.
die() {
	echo "$*" >&2
	exit 1
}

# Reports illegal arguments.
die_badopt() {
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
	v=$(tmux show -gqv "$1")
	echo "${v:-"${2-}"}"
}

# Fetches tmux options in batch. Each argument may be specified in the syntax
# `key=format`, where `format` is a tmux FORMAT to retrieve the intended option,
# and its value is assigned to a variable named `key`.
batch_get_options() {
	local vars=() formats=() key val
	while [[ $# -gt 0 ]]; do
		key=${1%%=*}
		val=${1#*=}
		vars+=("$key")
		formats+=("$val")
		shift
	done
	set -- "${vars[@]}"
	while IFS= read -r val; do
		printf -v "$1" "%s" "$val"
		shift
	done < <(tmux display -p "$(printf "%s\n" "${formats[@]}")")
}

# Escapes all given arguments.
escape() {
	if [[ $# -gt 0 ]]; then
		printf '%q ' "$@"
	fi
}

# Replace special chars with '_' in a session name.
# See: https://github.com/tmux/tmux/blob/ef68debc8d9e0e5567d328766f705bb1f42b7c51/session.c#L242
escape_session_name() {
	echo "${1//[.:]/_}"
}

# Parses tmux commands, assigning the tokens to an array named `cmds`.
declare cmds
parse_cmds() {
	# shellcheck disable=SC2034
	IFS=$'\n' read -d '' -ra cmds < <(echo "$*" | xargs printf "%s\n") || true
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
	local result key val
	result=${!#}
	while [[ $# -gt 1 ]]; do
		key=${1%%=*}
		val=${1#*=}
		result=${result//"{$key}"/$val}
		shift
	done
	echo "$result"
}
