#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

for test in "$CURRENT_DIR"/tests/*_tests.sh; do
	echo "test: $(basename "$test")"
	command "$test"
done
