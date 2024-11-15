#!/usr/bin/env bash

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../scripts//helpers.sh
source "$SRC_DIR/../scripts/helpers.sh"

test_fail() {
	echo "${BASH_SOURCE[1]}:${BASH_LINENO[1]}" "$@"
	exit 1
}

test_interpolate() {
	format="$1" expected="$2"
	result="$(interpolate "${@:3}" "$format")"

	if [[ $result != "$expected" ]]; then
		test_fail "$result != $expected"
	fi
}

test_interpolate \
	"{session}/{project}/{popup_name}" \
	"working/{project}/default" \
	"session" "working" \
	"popup_name" "default"
test_interpolate \
	"{var1}/{var2}/{var2}/{var1}" \
	"value1/value2/value2/value1" \
	"var1" "value1" \
	"var2" "value2"
