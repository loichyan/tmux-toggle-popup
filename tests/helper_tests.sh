#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=../src/helpers.sh
source "$CURRENT_DIR/../src/helpers.sh"

test_fail() {
	echo "${BASH_SOURCE[1]}:${BASH_LINENO[1]}" "$@"
	exit 1
}

test_interpolate() {
	local result
	result=$(interpolate "${@}" "$format")

	if [[ $result != "$expected" ]]; then
		test_fail "$result != $expected"
	fi
}

format="{session}/{project}/{popup_name}"
expected="working/{project}/default"
test_interpolate session="working" popup_name="default"

format="{var1}/{var2}/{var2}/{var1}"
expected="value1/value2/value2/value1"
test_interpolate var1="value1" var2="value2"

format="{var1}/{var2}/{var2}/{var1}"
expected="var1=value1/var2=value2/var2=value2/var1=value1"
test_interpolate var1="var1=value1" var2="var2=value2"
