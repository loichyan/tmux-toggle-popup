#!/usr/bin/env bash

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
