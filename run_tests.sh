#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

status=0
for test in "$CURRENT_DIR"/tests/*; do
	echo "test: $(basename "$test")"
	if ! command "$test"; then
		echo "test failed"
		status=1
	fi
done
exit $status
