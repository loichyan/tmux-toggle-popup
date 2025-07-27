#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2120

set -euo pipefail

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"
# shellcheck source=../src/helpers.sh
source "$CURRENT_DIR/../src/helpers.sh"

declare expected output
test_interpolate() {
	output=$(interpolate "${@}" "$format")
	assert_eq "$expected" "$output"
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
declare input=() delimiter="EOF"
tmux() {
	printf "%s\nEOF\n" "${input[@]}"
}

echo "test: batch_get_options"
input=("value1" "value2" "value3")
batch_get_options var1= var2= var3=
assert_eq "$var1" "value1"
assert_eq "$var2" "value2"
assert_eq "$var3" "value3"

echo "test: batch_get_multiline_options"
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
