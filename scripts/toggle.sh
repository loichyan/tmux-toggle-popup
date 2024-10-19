#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"
# shellcheck source=./variables.sh
source "$CURRENT_DIR/variables.sh"

declare popup_args session_args toggle_keys prog OPT OPTARG OPTIND=1

while getopts :-:BCEb:c:d:e:h:s:S:t:T:w:x:y: OPT; do
	if [[ $OPT == '-' ]]; then OPT="${OPTARG%%=*}"; fi
	case "$OPT" in
	[BCE]) popup_args+=("-$OPT") ;;
	[bcdhsStTwxy]) popup_args+=("-$OPT" "$OPTARG") ;;
	# forward environment overrides to popup sessions
	e) session_args+=("-e" "$OPTARG") ;;
	name | toggle-key | socket-name | id-format | on-init | before-open | after-close)
		OPTARG="${OPTARG:${#OPT}}"
		if [[ ${OPTARG::1} == '=' ]]; then
			# format: `--name=value`
			OPTARG="${OPTARG:1}"
		else
			# format: `--name value`
			OPTARG="${!OPTIND}"
			OPTIND=$((OPTIND + 1))
		fi
		if [[ $OPT == "toggle-key" ]]; then
			toggle_keys+=("$OPTARG")
		else
			declare "${OPT/-/_}"="$OPTARG"
		fi
		;;
	force) declare "${OPT/-/_}"="1" ;;
	help)
		cat <<-EOF
			USAGE:

			  toggle.sh [OPTION]... [SHELL_COMMAND]...

			OPTIONS:

			  --name <name>               Popup name. [Default: "$DEFAULT_NAME"]
			  --force                     Toggle the popup even if its name doesn't match.
			  --toggle-key <key>          Bind additional keys to close the opened popup.
			  -[BCE]                      Flags passed to display-popup.
			  -[bcdehsStTwxy] <value>     Options passed to display-popup.

			POPUP OPTIONS:

			  Override global popup options on the fly.

			  --socket-name <value>       Socket name. [Default: "$DEFAULT_SOCKET_NAME"]
			  --id-format <value>         Popup ID format. [Default: "$DEFAULT_ID_FORMAT"]
			  --on-init <hook>            Command to run on popup initialization. [Default: "$DEFAULT_ON_INIT"]
			  --before-open <hook>        Hook to run before opening the popup. [Default: ""]
			  --after-close <hook>        Hook to run after closing the popup. [Default: ""]

			EXAMPLES:

			  toggle.sh -Ed'#{pane_current_path}' --name=bash bash
		EOF
		exit
		;;
	*) badopt ;;
	esac
done
prog=("${@:$OPTIND}")

# If the specified name doesn't match the currently opened popup, we open a new
# popup within the current one (i.e., popup-in-popup).
opened_name="$(showvariable @__popup_opened)"
if [[ -n $opened_name && ($name == "$opened_name" || -n $force || -z $*) ]]; then
	# Clear the variables to prevent a manually attached session from being
	# detached by the keybinding.
	tmux set -u @__popup_opened \; detach
	exit 0
fi

name="${name:-$DEFAULT_NAME}"
socket_name="${socket_name:-$(get_socket_name)}"
id_format="${id_format:-$(showopt @popup-id-format "$DEFAULT_ID_FORMAT")}"
on_init="${on_init:-$(showopt @popup-on-init "$DEFAULT_ON_INIT")}"
before_open="${before_open:-$(showopt @popup-before-open)}"
after_close="${after_close:-$(showopt @popup-after-close)}"
popup_id="$(format @popup_name "$name" "$id_format")"

# bind toggle keys in the opened popup
unbind_keys=()
for k in "${toggle_keys[@]}"; do
	if [[ -n $force ]]; then
		on_init+=("; bind $k run \"#{@popup-toggle} --name='$name'\" --force")
	else
		on_init+=("; bind $k run \"#{@popup-toggle} --name='$name'\"")
	fi
	unbind_keys+=("; unbind $k")
done

# hook: before-open
if [[ -n $before_open ]]; then
	eval "tmux -C $(echo "$before_open" | makecmds) >/dev/null"
fi
# Temporarily change `default-shell` to `/bin/sh` to ensure our scripts are
# recognized correctly. Once in the popup, we must promptly revert to the user's
# default shell to prevent long-running processes from permanently altering it.
default_shell="$(get_default_shell)"
reattach_args="$(format "'#{socket_path}' \; attach -t '#{session_id}'")"
tmux \
	set default-shell '/bin/sh' \; \
	popup "${popup_args[@]}" "$(
		cat <<-EOF
			tmux -CS $reattach_args \; set default-shell '$default_shell' \;  detach \; >/dev/null &
			TMUX_POPUP_SERVER='$socket_name' SHELL='$default_shell' tmux -L '$socket_name' \
				new -As '$popup_id' $(escape "${session_args[@]}") $(escape "${prog[@]}") \; \
				set @__popup_opened '$name' \; \
			    $(echo "${on_init[*]}" | makecmds) \; >/dev/null
		EOF
	)"
if [[ ${#unbind_keys[@]} -gt 0 ]]; then
	# the tmux server may have stopped, ignore the returned error
	eval "tmux -NCL '$socket_name' $(echo "${unbind_keys[*]}" | makecmds) 2&>/dev/null" || true
fi
# hook: after-close
if [[ -n $after_close ]]; then
	eval "tmux -C $(echo "$after_close" | makecmds) >/dev/null"
fi
