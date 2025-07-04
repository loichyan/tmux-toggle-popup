#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../src//helpers.sh
source "$CURRENT_DIR/../src/helpers.sh"

test_fail() {
	echo "${BASH_SOURCE[1]}:${BASH_LINENO[1]}" "$@"
	exit 1
}

# Simulates Bash arguments interpretation.
reparse_commands() {
	# shellcheck disable=2046
	eval printf '%s\\n' $(cat)
}

test_parse_commands() {
	echo "test: $1"
	shift

	local commands=()
	while IFS= read -r command; do
		commands+=("$command")
	done < <(makecmds "$1" | reparse_commands)
	shift

	if [[ $# -ne ${#commands[@]} ]]; then
		test_fail "expected $# commands to be parsed, got \`$(printf "%s, " "${commands[@]}")\`"
	fi

	local -i i=0
	while [[ $# -gt 0 ]]; do
		if [[ $1 != "${commands[$i]}" ]]; then
			git diff <(echo "$1") <(echo "${commands[i]}")
			test_fail "unexpected command at $((i + 1))"
		fi
		shift
		i+=1
	done
}

test_parse_commands "delimited_by_commas" \
	'set status off ; set exit-empty off' \
	'set' 'status' 'off' ';' \
	'set' 'exit-empty' 'off'
test_parse_commands "delimited_by_line_breaks" \
	'set status off
	 set exit-empty off' \
	'set' 'status' 'off' \
	'set' 'exit-empty' 'off'
test_parse_commands "escaped_multiple_commands" \
	'bind -n M-1 display random\ text \\; display and\ more' \
	'bind' '-n' 'M-1' \
	'display' 'random text' '\;' \
	'display' 'and more'
test_parse_commands "quoted_multiple_commands" \
	"bind -n M-2 \"display 'random text' ; display 'and more'\"" \
	'bind' '-n' 'M-2' \
	"display 'random text' ; display 'and more'"
