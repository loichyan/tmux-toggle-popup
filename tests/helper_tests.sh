#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2120

set -euo pipefail

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=../src/helpers.sh
source "$CURRENT_DIR/../src/helpers.sh"

test_fail() {
	echo "${BASH_SOURCE[1]}:${BASH_LINENO[1]}" "$@"
	exit 1
}

declare output expected
assert_eq() {
	local left right
	left=${1:-"$output"}
	right=${2:-"$expected"}
	if [[ $left != "$right" ]]; then
		test_fail "$left != $right"
	fi
}

test_interpolate() {
	output=$(interpolate "${@}" "$format")
	assert_eq
}

echo "test: no_interpolate_of_unknown"
format="{session}/{project}/{popup_name}"
expected="working/{project}/default"
test_interpolate session="working" popup_name="default"

echo "test: interpolate_multi"
format="{var1}/{var2}/{var2}/{var1}"
expected="value1/value2/value2/value1"
test_interpolate var1="value1" var2="value2"

echo "test: interpolate_with_equals"
format="{var1}/{var2}/{var2}/{var1}"
expected="var1=value1/var2=value2/var2=value2/var1=value1"
test_interpolate var1="var1=value1" var2="var2=value2"

# Simulates a tmux response.
tmux() {
	echo "value1"
	echo "value2"
	echo "value3"
}

echo "test: batch_get_options"
expected=$(printf "%s\n" format1 format2 format3)
batch_get_options var1=format1 var2=format2 var3=format3
assert_eq "$var1" "value1"
assert_eq "$var2" "value2"
assert_eq "$var3" "value3"
