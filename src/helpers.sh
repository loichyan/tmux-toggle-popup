#!/usr/bin/env bash
# shellcheck disable=SC2153
# shellcheck disable=SC2154

print() {
	printf '%s' "$*"
}

println() {
	printf '%s\n' "$*"
}

# Prints an error message and exits.
die() {
	if [[ -n $TMUX ]]; then
		tmux run-shell "printf '%s\n' $(escape "$*")"
	else
		println "$@" >&2
	fi
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

# Fetches tmux options in batch. Each argument may be specified in the syntax
# `key=format`, where `format` is a tmux FORMAT to retrieve the intended option,
# and its value is assigned to a variable named `key`.
#
# Additionally, `$target` may be used to specify the pane in which the format
# string will be expanded. It should be provided in the format
# `<target_pane_id>:<target_TMUX>`.
declare target
batch_get_options() {
	local keys=() formats=()
	while [[ $# -gt 0 ]]; do
		keys+=("${1%%=*}")
		formats+=("${1#*=}")
		shift
	done
	delimiter=${delimiter:-"@@@@@$RANDOM@@@@@"} # generate a random delimiter

	local target_pane target_tmux args
	IFS=':' read -r target_pane target_tmux <<<"$target"
	args=(display-message)
	if [[ -n $target_pane ]]; then args+=(-t "$target_pane"); fi
	args+=(-p "$(printf "%s\n$delimiter\n" "${formats[@]}")")

	local val=() line
	set -- "${keys[@]}"
	while IFS= read -r line; do
		if [[ -z $line ]]; then
			:
		elif [[ $line != "$delimiter" ]]; then
			val+=("$line")
		elif [[ $# -eq 0 ]]; then
			die 'corrupted batch options'
		else
			printf -v "$1" '%s' "${val[*]}" # replace line breaks with spaces
			val=()
			shift
		fi
	done < <(TMUX=${target_tmux:-$TMUX} tmux "${args[@]}")

	if [[ $# -ne 0 ]]; then die 'corrupted batch options'; fi
}

# Escapes all given arguments.
escape() {
	if [[ $# -gt 0 ]]; then
		printf '%q ' "$@"
	fi
}

# Replace special chars with '_' in a session name.
# See <https://github.com/tmux/tmux/blob/ef68debc8d9e0e5567d328766f705bb1f42b7c51/session.c#L242>
escape_session_name() {
	print "${1//[.:]/_}"
}

# Returns whether a hook is enabled.
check_hook() {
	if [[ -z $1 || $1 == 'nop' ]]; then
		return 1
	fi
}

# Expands the provided tmux FORMAT string.
format() {
	tmux display-message -p "$*"
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
	print "$result"
}

#-- Test utils -----------------------------------------------------------------

failf() {
	local source lineno
	source=$(basename "${BASH_SOURCE[1]}")
	lineno=${BASH_LINENO[1]}
	printf "%s:%s: $1" "$source" "$lineno" "${@:2}" >&2
	exit 1
}

assert_eq() {
	if [[ $1 != "$2" ]]; then
		failf 'assertion failed: left != right:\n\tleft: %s\n\tright: %s\n' "$1" "$2"
	fi
}

begin_test() {
	local source
	source=$(basename "${BASH_SOURCE[1]}")
	if [[ -z $TEST_FILTER || $1 =~ $TEST_FILTER ]]; then
		echo "[test] ${source%.*}::${1}"
	else
		return 1
	fi
}

# Simulates the response of `batch_get_options`. It accepts arguments in the
# same format as `batch_get_options`: each pair contains the variable name and
# its default value. If a variable is set in the execution context, then its
# value will be used.
fake_batch_options() {
	local key val
	while [[ $# -gt 0 ]]; do
		key=${1%%=*}
		val=${1#*=}
		if [[ -n ${!key} ]]; then
			val=${!key}
		fi
		printf "%s\n$delimiter\n" "$val"
		shift
	done
}
