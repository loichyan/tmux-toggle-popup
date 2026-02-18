#!/usr/bin/env bash
# shellcheck disable=SC2030
# shellcheck disable=SC2031
# shellcheck disable=SC2034

set -eo pipefail
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"

#-- test:interpolate -----------------------------------------------------------

declare expected input
test_interpolate() {
	input=$(interpolate "${@}" "$format")
	assert_eq "$expected" "$input"
}

(
	begin_test 'no_interpolate_of_unknown' || exit 0
	format='{session}/{project}/{popup_name}'
	expected='working/{project}/default'
	test_interpolate session='working' popup_name='default'
) || exit 1

(
	begin_test 'interpolate_multi' || exit 0
	format='{var1}/{var2}/{var2}/{var1}'
	expected='value1/value2/value2/value1'
	test_interpolate var1='value1' var2='value2'
) || exit 1

(
	begin_test 'interpolate_with_equals' || exit 0
	format='{var1}/{var2}/{var2}/{var1}'
	expected='var1=value1/var2=value2/var2=value2/var1=value1'
	test_interpolate var1='var1=value1' var2='var2=value2'
) || exit 1

#-- test:batch_get_options -----------------------------------------------------

# Simulates a tmux response.
declare delimiter='>>>END' input
declare var1 var2 var3 var4
tmux() {
	printf "%s\n$delimiter\n" "${input[@]}"
}

(
	begin_test 'batch_get_options' || exit 0
	input=('value1' 'value2' 'value3')
	batch_get_options var1= var2= var3=
	assert_eq "$var1" "value1"
	assert_eq "$var2" "value2"
	assert_eq "$var3" "value3"
) || exit 1

(
	begin_test "batch_get_multiline_options" || exit 0
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
) || exit 1

#-- test:contains_format -------------------------------------------------------

must_contain_format() {
	if ! contains_format "$1"; then
		failf "'%s' must contain format" "$1"
	fi
}

must_not_contain_format() {
	if contains_format "$1"; then
		failf "'%s' must not contain format" "$1"
	fi
}

(
	begin_test 'contains_format' || exit 0
	must_not_contain_format ""
	must_not_contain_format "#"
	must_not_contain_format "#{"
	must_not_contain_format "#}"
	must_contain_format "#{}"
	must_contain_format "#{abc}"
	must_contain_format "a#{b}c"
	must_contain_format "#{}abc"
	must_contain_format "abc#{}"
)
