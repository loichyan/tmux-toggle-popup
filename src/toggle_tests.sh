#!/usr/bin/env bash

set -eo pipefail
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=../src/helpers.sh
source "$CURRENT_DIR/helpers.sh"

#=== test:tggles ===#

declare delimiter=">>>END" inputs f_call_id f_output
add_input() {
	inputs+=("$(printf "%s\n$delimiter\n" "$@")")
}
tmux() {
	# Bump call ID
	local call_id
	call_id=$(cat "$f_call_id")
	echo "$((call_id + 1))" >"$f_call_id"

	# Appends arguments to output
	{
		echo ">>>tmux:begin($call_id)"
		printf "%s\n" "$@"
		echo "<<<tmux:end($call_id)"
		echo
	} >>"$f_output"

	# Mock tmux response
	echo -n "${inputs[$call_id]}"
}

declare test_name mode opened_name
test_toggle() {
	inputs=()
	# batch_get_options
	add_input \
		"pane/path/{popup_name}" \
		"display 'hook:begin' ; display 'on-init' ; display 'hook:end'" \
		"display 'hook:begin' ; display 'before-open' ; display 'hook:end'" \
		"display 'hook:begin' ; display 'after-close' ; display 'hook:end'" \
		"$mode" \
		"popup1" \
		"socket/path/popup2" \
		"$opened_name" \
		"caller/id/format" \
		"caller/session/pane" \
		"caller/pane/path" \
		"session/path/{popup_name}" \
		"/usr/bin/fish" \
		"working/session/path" \
		"working/pane/path"

	f_call_id=$(alloctmp)
	f_output=$(alloctmp)
	echo 0 >"$f_call_id"
	source "$CURRENT_DIR/toggle.sh"

	local expected="$CURRENT_DIR/toggle_tests/$test_name.stdout"
	if [[ $TEST_OVERWRITE = 1 ]]; then
		mkdir -p "$(dirname "$expected")"
		cp "$f_output" "$expected"
	else
		git diff --exit-code "$f_output" "$expected"
	fi
}

test_name="open_popup"
mode="switch"
opened_name=""
begin_test "$test_name"
test_toggle --name="p_open"

test_name="close_popup"
mode="switch"
opened_name="p_close"
begin_test "$test_name"
test_toggle --name="p_close"

test_name="switch_popup"
mode="switch"
opened_name="p_switch_1"
begin_test "$test_name"
test_toggle --name="p_switch_2"

test_name="force_close_popup"
mode="force-close"
opened_name="p_force_close_1"
begin_test "$test_name"
test_toggle --name="p_force_close_2"

test_name="open_nested_popup"
mode="force-open"
opened_name="p_open_nested_1"
begin_test "$test_name"
test_toggle --name="p_open_nested_2"
