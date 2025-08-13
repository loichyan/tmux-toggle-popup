#!/usr/bin/env bash

set -euo pipefail
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=../src/helpers.sh
source "$CURRENT_DIR/../src/helpers.sh"

failf() {
	local source lineno
	source=$(basename "${BASH_SOURCE[1]}")
	lineno=${BASH_LINENO[1]}
	printf "%s:%s: $1" "$source" "$lineno" "${@:2}"
	exit 1
}

assert_eq() {
	if [[ $1 != "$2" ]]; then
		failf "assertion failed: left != right:\n\tleft: %s\n\tright: %s" "$1" "$2"
	fi
}

begin_test() {
	echo -e "[test] helpers_tests::$1"
}

#=== test:parse_cmds ===#

test_parse_commands() {
	parse_cmds "$1"
	shift

	if [[ $# -ne ${#cmds[@]} ]]; then
		failf "expected $# tokens to be parsed, got ${#cmds[@]}:%s" "$(printf "\n\t%s" "${cmds[@]}")"
	fi

	local i=0
	while [[ $# -gt 0 ]]; do
		if [[ $1 != "${cmds[$i]}" ]]; then
			git diff <(echo "$1") <(echo "${cmds[i]}")
			failf "unexpected token at $((i + 1))"
		fi
		shift
		((i++))
	done
}

begin_test "delimited_by_semis"
test_parse_commands \
	'set status off ; set exit-empty off' \
	'set' 'status' 'off' ';' \
	'set' 'exit-empty' 'off'

begin_test "delimited_by_line_breaks"
test_parse_commands \
	'set status off
	 set exit-empty off' \
	'set' 'status' 'off' \
	'set' 'exit-empty' 'off'

begin_test "escaped_multiple_commands"
test_parse_commands \
	'bind -n M-1 display random\ text \\; display and\ more' \
	'bind' '-n' 'M-1' \
	'display' 'random text' '\;' \
	'display' 'and more'

begin_test "quoted_multiple_commands"
test_parse_commands \
	"bind -n M-2 \"display 'random text' ; display 'and more'\"" \
	'bind' '-n' 'M-2' \
	"display 'random text' ; display 'and more'"

#=== test:interpolate ===#

declare expected output
test_interpolate() {
	output=$(interpolate "${@}" "$format")
	assert_eq "$expected" "$output"
}

begin_test "no_interpolate_of_unknown"
format="{session}/{project}/{popup_name}"
expected="working/{project}/default"
test_interpolate session="working" popup_name="default"

begin_test "interpolate_multi"
format="{var1}/{var2}/{var2}/{var1}"
expected="value1/value2/value2/value1"
test_interpolate var1="value1" var2="value2"

begin_test "interpolate_with_equals"
format="{var1}/{var2}/{var2}/{var1}"
expected="var1=value1/var2=value2/var2=value2/var1=value1"
test_interpolate var1="var1=value1" var2="var2=value2"

#=== test:batch_get_options ===#

# Simulates a tmux response.
declare input delimiter="EOF"
declare var1 var2 var3 var4
tmux() {
	printf "%s\nEOF\n" "${input[@]}"
}

begin_test "batch_get_options"
input=("value1" "value2" "value3")
batch_get_options var1= var2= var3=
assert_eq "$var1" "value1"
assert_eq "$var2" "value2"
assert_eq "$var3" "value3"

begin_test "batch_get_multiline_options"
input=(
	$'\nline1\n'
	$'line1\nline2'
	$'line1\n\nline2'
	$'\nline1\n\nline2\nline3\n\n'
)
batch_get_options var1= var2= var3= var4=
assert_eq "$var1" "line1"
assert_eq "$var2" "line1 line2"
assert_eq "$var3" "line1 line2"
assert_eq "$var4" "line1 line2 line3"
