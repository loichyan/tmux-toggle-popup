#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

while read -r test; do
	echo "test: $(basename "$test")"
	command "$test"
done < <(find "$CURRENT_DIR/src/" -name "*_tests.sh")
