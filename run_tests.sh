#!/usr/bin/env bash

set -euo pipefail
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Supported environments:
# - TEST_OVERWRITE: set to 1 to overwrite snapshots
# - TEST_VERBOSE: set to 1 enable verbose test output
# - TEST_FILTER: set to a regex to filter test cases

while read -r test; do
	echo "[test] $(basename "$test")"
	command "$test"
done < <(find "$CURRENT_DIR/src" -name '*_tests.sh')
