#!/usr/bin/env bash
# shellcheck disable=SC2030
# shellcheck disable=SC2031
# shellcheck disable=SC2034

set -eo pipefail
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"

declare delimiter='@@@@@@@@@@' exit_codes=(0 0 0 0) test_name should_fail
test_toggle() {
	local i workdir f_call_id f_args f_input f_output f_expected

	# Prepare inputs
	workdir=$(mktemp -d)
	# shellcheck disable=SC2064
	trap "rm -rf '$workdir'" EXIT

	f_call_id="$workdir/call_id"
	f_args="$workdir/args"
	f_input="$workdir/iutput"
	f_output="$workdir/output"

	i=0
	for code in "${exit_codes[@]}"; do
		echo "$code" >"${f_input}_${i}"
		i=$((i + 1))
	done

	# Fake argument expansions
	local i=1 fake_expanded_args=()
	while [[ $i -le $# ]]; do
		fake_expanded_args+=("t_argv_$i=${!i}")
		i=$((i + 1))
	done
	fake_batch_options "${fake_expanded_args[@]}" >"$f_args"

	# Do call popup-toggle
	export delimiter f_call_id f_args f_input f_output
	export TMUX=tmux-test
	if [[ -n $should_fail ]]; then
		! command "$CURRENT_DIR/toggle.sh" "$@" 4>&2 2>>"$f_output" || exit 1
		f_expected="$CURRENT_DIR/toggle_tests/$test_name.stderr"
	else
		command "$CURRENT_DIR/toggle.sh" "$@" 4>&2 || exit 1
		f_expected="$CURRENT_DIR/toggle_tests/$test_name.stdout"
	fi

	# Validate outputs
	if [[ $TEST_OVERWRITE = 1 ]]; then
		mkdir -p "$(dirname "$f_expected")"
		cp "$f_output" "$f_expected"
	else
		diff -u --color=auto "$f_expected" "$f_output"
	fi
}

# Ensure out fake executable tmux is picked at first.
export PATH="$CURRENT_DIR/toggle_tests:$PATH"
export SHELL='/system/shell'
unset TMUX TMUX_POPUP_SERVER __tmux_popup_caller __tmux_popup_name

# Force subshell to ensure modifications are temporary.
(
	test_name='open_popup'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_open'
) || exit 1

(
	test_name='close_popup'
	export __tmux_popup_name='p_close'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_close'
) || exit 1
(
	test_name='switch_popup'
	export __tmux_popup_name='p_switch_1'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_switch_2'
) || exit 1

(
	test_name='switch_new_popup'
	exit_codes=(0 1 0 0)
	export __tmux_popup_name='p_switch_1'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_switch_2'
) || exit 1

(
	test_name='force_close_popup'
	export t_toggle_mode='force-close'
	export __tmux_popup_name='p_force_close_1'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_force_close_2'
) || exit 1

(
	test_name='open_nested_popup'
	export t_toggle_mode='force-open'
	export __tmux_popup_name='p_open_nested_1'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_open_nested_2'
) || exit 1

(
	test_name='open_with_toggle_key'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_toggle_key' --toggle-key='-T root M-p' --toggle-key='-n M-o'
) || exit 1

# Open nested popups should not clean toggle keys.
(
	test_name='open_nested_with_toggle_key'
	export t_toggle_mode='force-open'
	export __tmux_popup_name='p_nested_toggle_key_1'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_nested_toggle_key_2' --toggle-key='-n M-o'
) || exit 1

(
	test_name='open_with_overrides'
	begin_test "$test_name" || exit 0
	test_toggle \
		--name 'p_open_with_overrides' \
		--id-format 'local_id_format/{popup_name}' \
		--on-init 'nop' \
		--before-open 'run "#{@popup-focus} --enter"' \
		--after-close 'run "#{@popup-focus} --leave"' \
		--toggle-mode 'force-close' \
		--socket-name 'local_socket_name' \
		--socket-path '/local/socket_path/popup_server'
) || exit 1

(
	test_name='open_with_id'
	begin_test "$test_name" || exit 0
	test_toggle --id='p_open_with_id'
) || exit 1

(
	test_name='open_with_socket_path'
	export t_socket_path='/path/to/socket_path_server'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_open_with_socket_path'
) || exit 1

(
	test_name='open_with_directory'
	should_fail=1
	begin_test "$test_name" || exit 0
	test_toggle --name='p_open_with_directory' -d'{popup_caller_pane_path}'
) || exit 1

(
	test_name='open_with_environment'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_open_with_environment' -e MY_POPUP=NICE
) || exit 1

(
	test_name='open_with_style'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_open_with_style' -xR -yP -w50% -h70%
) || exit 1

(
	test_name='escape_session_name'
	export t_id_format='pane/.dot/:colon/{popup_name}'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_escape_session_name'
) || exit 1

(
	test_name='switch_with_directory'
	should_fail=1
	exit_codes=(0 1 0 0)
	export __tmux_popup_name='p_switch_with_directory_1'
	begin_test "$test_name" || exit 0
	test_toggle --name='p_switch_with_directory_2' -d'{popup_caller_pane_path}'
) || exit 1

# ID is taken as the opened name when it is specified.
(
	test_name='open_nested_with_id'
	export __tmux_popup_name='default'
	begin_test "$test_name" || exit 0
	test_toggle --id='p_open_nested_with_id' --toggle-mode=force-open
) || exit 1
