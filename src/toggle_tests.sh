#!/usr/bin/env bash
# shellcheck disable=SC2030
# shellcheck disable=SC2031
# shellcheck disable=SC2034

set -eo pipefail
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"

declare delimiter=">>>END" exit_codes=(0 0 0 0) test_name
test_toggle() {
	local i workdir f_call_id f_input f_output f_expected

	# Prepare inputs
	workdir=$(mktemp -d)
	# shellcheck disable=SC2064
	trap "rm -rf '$workdir'" EXIT

	f_call_id="$workdir/call_id"
	f_input="$workdir/iutput"
	f_output="$workdir/output"

	i=0
	for code in "${exit_codes[@]}"; do
		echo "$code" >"${f_input}_${i}"
		i=$((i + 1))
	done

	# Do call popup-toggle
	export delimiter f_call_id f_input f_output
	command "$CURRENT_DIR/toggle.sh" "$@"

	# Validate outputs
	f_expected="$CURRENT_DIR/toggle_tests/$test_name.stdout"
	if [[ $TEST_OVERWRITE = 1 ]]; then
		mkdir -p "$(dirname "$f_expected")"
		cp "$f_output" "$f_expected"
	else
		git diff --exit-code "$f_expected" "$f_output"
	fi
}

# Ensure out fake executable tmux is picked at first.
export PATH="$CURRENT_DIR/toggle_tests:$PATH"
export SHELL="/system/shell"
export TMUX_POPUP_SERVER=

# Force subshell to ensure modifications are temporary.
(
	test_name="open_popup"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_open"
) || exit 1

(
	test_name="close_popup"
	export t_opened_name="p_close"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_close"
) || exit 1
(
	test_name="switch_popup"
	export t_opened_name="p_switch_1"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_switch_2"
) || exit 1

(
	test_name="switch_new_popup"
	exit_codes=(0 1 0 0)
	export t_opened_name="p_switch_1"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_switch_2"
) || exit 1

(
	test_name="force_close_popup"
	export t_toggle_mode="force-close"
	export t_opened_name="p_force_close_1"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_force_close_2"
) || exit 1

(
	test_name="open_nested_popup"
	export t_toggle_mode="force-open"
	export t_opened_name="p_open_nested_1"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_open_nested_2"
) || exit 1

(
	test_name="open_with_toggle_key"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_toggle_key" --toggle-key="-T root M-p" --toggle-key="-n M-o"
) || exit 1

# Open nested popups should not clean toggle keys.
(
	test_name="open_nested_with_toggle_key"
	export t_toggle_mode="force-open"
	export t_opened_name="p_nested_toggle_key_1"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_nested_toggle_key_2" --toggle-key="-n M-o"
) || exit 1

(
	test_name="open_with_overrides"
	begin_test "$test_name" || exit 0
	test_toggle \
		--name "p_open_with_overrides" \
		--id-format "local_id_format/{popup_name}" \
		--on-init "nop" \
		--before-open "run '#{@popup-focus} --enter'" \
		--after-close "run '#{@popup-focus} --leave'" \
		--toggle-mode "force-close" \
		--socket-name "local_socket_name" \
		--socket-path "/local/socket_path/popup_server"
) || exit 1

(
	test_name="open_with_id"
	begin_test "$test_name" || exit 0
	test_toggle --id='p_open_with_id'
) || exit 1

(
	test_name="open_with_socket_path"
	export t_socket_path="/path/to/socket_path_server"
	begin_test "$test_name" || exit 0
	test_toggle --name='p_open_with_socket_path'
) || exit 1

(
	test_name="open_with_directory"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_open_with_directory" -d'{popup_caller_pane_path}'
) || exit 1

(
	test_name="open_with_environment"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_open_with_environment" -e MY_POPUP=NICE
) || exit 1

(
	test_name="open_with_style"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_open_with_style" -xR -yP -w50% -h70%
) || exit 1

(
	test_name="escape_session_name"
	export t_id_format="pane/.dot/:colon/{popup_name}"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_escape_session_name"
) || exit 1

(
	test_name="switch_with_directory"
	exit_codes=(0 1 0 0)
	export t_opened_name="p_switch_with_directory_1"
	begin_test "$test_name" || exit 0
	test_toggle --name="p_switch_with_directory_2" -d'{popup_caller_pane_path}'
) || exit 1
