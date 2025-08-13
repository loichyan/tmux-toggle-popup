#!/usr/bin/env bash
# shellcheck disable=SC2034

set -eo pipefail
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=../src/helpers.sh
source "$CURRENT_DIR/helpers.sh"

#=== test:tggles ===#

prepare_batch_options() {
	fake_batch_options \
		t_id_format="pane/path/{popup_name}" \
		t_on_init="display 'on-init' ; run '#{@on_init}'" \
		t_before_open="display 'before-open' ; run '#{@before_open}'" \
		t_after_close="display 'after-close' ; run '#{@after_close}'" \
		t_toggle_mode="switch" \
		t_socket_name="popup_server1" \
		t_socket_path="socket/path/popup_server2" \
		t_opened_name="" \
		t_caller_id_format="caller/id/format" \
		t_caller_path="caller/session/pane" \
		t_caller_pane_path="caller/pane/path" \
		t_default_id_format="session/path/{popup_name}" \
		t_default_shell="/usr/bin/fish" \
		t_session_path="working/session/path" \
		t_pane_path="working/pane/path"
}

declare delimiter=">>>END" exit_codes f_call_id f_output
tmux() {
	# Bump call ID
	local call_id
	call_id=$(cat "$f_call_id")
	echo "$((call_id + 1))" >"$f_call_id"

	# The first call is always `batch_get_options`.
	# Discard its output since not particular useful.
	if [[ $call_id == 0 ]]; then
		prepare_batch_options
		return
	fi

	# Appends arguments to output
	{
		echo ">>>TMUX:BEGIN($call_id)"
		printf "%s\n" "$@"
		echo "<<<TMUX:END($call_id)"
		echo
	} >>"$f_output"

	# Fake tmux exit code
	# shellcheck disable=SC2086
	return ${exit_codes[$call_id]}
}

declare test_name
test_toggle() {
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
exit_codes=(0 0 0)
t_toggle_mode="switch"
t_opened_name=""
begin_test "$test_name"
test_toggle --name="p_open"

test_name="close_popup"
exit_codes=(0 0 0)
t_toggle_mode="switch"
t_opened_name="p_close"
begin_test "$test_name"
test_toggle --name="p_close"

test_name="switch_popup"
exit_codes=(0 0 0)
t_toggle_mode="switch"
t_opened_name="p_switch_1"
begin_test "$test_name"
test_toggle --name="p_switch_2"

test_name="switch_new_popup"
exit_codes=(0 1 0)
t_toggle_mode="switch"
t_opened_name="p_switch_1"
begin_test "$test_name"
test_toggle --name="p_switch_2"

test_name="force_close_popup"
exit_codes=(0 0 0)
t_toggle_mode="force-close"
t_opened_name="p_force_close_1"
begin_test "$test_name"
test_toggle --name="p_force_close_2"

test_name="open_nested_popup"
exit_codes=(0 0 0)
t_toggle_mode="force-open"
t_opened_name="p_open_nested_1"
begin_test "$test_name"
test_toggle --name="p_open_nested_2"
