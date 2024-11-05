#!/usr/bin/env bash
SRC_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

SRC_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

status=0
for test in "$SRC_DIR"/tests/*; do
	echo "test: $(basename "$test")"
	if ! command "$test"; then
		echo "test failed"
		status=1
	fi
done
exit $status
