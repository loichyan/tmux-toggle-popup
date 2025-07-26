#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"
# shellcheck source=../src/helpers.sh
source "$CURRENT_DIR/../src/helpers.sh"

test_parse_commands() {
	parse_cmds "$1"
	shift

	if [[ $# -ne ${#cmds[@]} ]]; then
		failf "expected $# tokens to be parsed, got ${#cmds[@]}:%s" "$(printf "\n\t%s" "${cmds[@]}")"
	fi

	local -i i=0
	while [[ $# -gt 0 ]]; do
		if [[ $1 != "${cmds[$i]}" ]]; then
			git diff <(echo "$1") <(echo "${cmds[i]}")
			failf "unexpected token at $((i + 1))"
		fi
		shift
		i+=1
	done
}

echo "test: delimited_by_semis"
test_parse_commands \
	'set status off ; set exit-empty off' \
	'set' 'status' 'off' ';' \
	'set' 'exit-empty' 'off'
echo "test: delimited_by_line_breaks"
test_parse_commands \
	'set status off
	 set exit-empty off' \
	'set' 'status' 'off' \
	'set' 'exit-empty' 'off'
echo "test: escaped_multiple_commands"
test_parse_commands \
	'bind -n M-1 display random\ text \\; display and\ more' \
	'bind' '-n' 'M-1' \
	'display' 'random text' '\;' \
	'display' 'and more'
echo "test: quoted_multiple_commands"
test_parse_commands \
	"bind -n M-2 \"display 'random text' ; display 'and more'\"" \
	'bind' '-n' 'M-2' \
	"display 'random text' ; display 'and more'"
