#!/usr/bin/env bash

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./helpers.sh
source "$SRC_DIR/helpers.sh"
# shellcheck source=./variables.sh
source "$SRC_DIR/variables.sh"

declare OPT OPTARG OPTIND=1 popup_args open_args toggle_keys program
usage() {
	cat <<-EOF
		Usage:

		  toggle.sh [OPTIONS] [POPUP_OPTIONS] [SHELL_COMMAND]...

		Options:

		  --name <name>               Popup name [Default: "$DEFAULT_NAME"]
		  --id <id>                   Popup ID, default to the expanded ID format
		  --toggle-mode <mode>        Action to handle nested calls [Default: "$DEFAULT_TOGGLE_MODE"]
		  --toggle-key <key>          Bind additional keys to close the opened popup
		  -[BCE]                      Flags passed to display-popup
		  -[bcdehsStTwxy] <value>     Options passed to display-popup

		Popup Options:

		  Override global popup options on the fly.

		  --socket-name <value>       Socket name [Default: "$DEFAULT_SOCKET_NAME"]
		  --id-format <value>         Popup ID format [Default: "$DEFAULT_ID_FORMAT"]
		  --on-init <hook>            Command to run on popup initialization [Default: "$DEFAULT_ON_INIT"]
		  --before-open <hook>        Hook to run before opening the popup [Default: ""]
		  --after-close <hook>        Hook to run after closing the popup [Default: ""]

		Examples:

		  toggle.sh -Ed'#{pane_current_path}' --name=bash bash
	EOF
}

# Prepares the tmux commands to open a popup. When called,
#
# - `open_cmds` is used to create the popup session
# - `on_cleanup` is used to undo temporary changes
# - `popup_id` is set to the expanded popup session name
declare name toggle_mode open_cmds on_cleanup popup_id
prepare_open() {
	local on_init="${on_init:-$(showopt @popup-on-init "$DEFAULT_ON_INIT")}"

	# Create temporary toggle keys in the opened popup
	for k in "${toggle_keys[@]}"; do
		on_init+=" ; bind $k run \"#{@popup-toggle} --name='$name' --toggle-mode='$toggle_mode'\""
		on_cleanup+=" ; unbind $k"
	done

	popup_id="${id:-$(interpolate popup_name "$name" "$id_format")}"
	open_cmds+="$(
		escape \
			new "${open_args[@]}" -s "$popup_id" "${program[@]}" \; \
			set @__popup_opened "$name" \; \
			set @__popup_id_format "$id_format" \;
	)"
	open_cmds+="$(makecmds "$on_init")"
}

main() {
	while getopts :-:BCEb:c:d:e:h:s:S:t:T:w:x:y: OPT; do
		if [[ $OPT == '-' ]]; then OPT="${OPTARG%%=*}"; fi
		case "$OPT" in
		[BCE]) popup_args+=("-$OPT") ;;
		[bcdhsStTwxy]) popup_args+=("-$OPT" "$OPTARG") ;;
		# Forward environment overrides to popup sessions
		e) open_args+=("-e" "$OPTARG") ;;
		name | toggle-key | socket-name | id-format | id | \
			toggle-mode | on-init | before-open | after-close)
			OPTARG="${OPTARG:${#OPT}}"
			if [[ ${OPTARG::1} == '=' ]]; then
				# FORMAT: `--name=value`
				OPTARG="${OPTARG:1}"
			else
				# FORMAT: `--name value`
				OPTARG="${!OPTIND}"
				OPTIND=$((OPTIND + 1))
			fi
			if [[ $OPT == "toggle-key" ]]; then
				toggle_keys+=("$OPTARG")
			else
				declare "${OPT/-/_}"="$OPTARG"
			fi
			;;
		help)
			usage
			exit
			;;
		*) badopt ;;
		esac
	done
	program=("${@:$OPTIND}")
	name="${name:-$DEFAULT_NAME}"
	toggle_mode="${toggle_mode:-$(showopt @popup-toggle-mode "$DEFAULT_TOGGLE_MODE")}"

	opened_name="$(showvariable @__popup_opened)"
	if [[ -n $opened_name ]]; then
		if [[ $name == "$opened_name" || $OPTIND -eq 1 || $toggle_mode == "force-close" ]]; then
			exec tmux detach >/dev/null
		elif [[ $toggle_mode == "switch" ]]; then
			# Reuse the caller's ID format to ensure we open the intended popup
			id_format="$(showvariable @__popup_id_format)"
			open_args+=("-d") # Create the target session if not exists
			prepare_open
			eval tmux -C "$open_cmds" &>/dev/null || true # Ignore error if already created
			exec tmux switch -t "$popup_id" >/dev/null
		elif [[ $toggle_mode != "force-open" ]]; then
			die "illegal toggle mode: $toggle_mode"
		fi
	fi

	# HOOK: before-open
	before_open="${before_open:-$(showopt @popup-before-open)}"
	if [[ -n $before_open ]]; then
		eval "tmux -C $(makecmds "$before_open")" >/dev/null
	fi

	# Expand the configured ID format
	id_format="$(format "${id_format:-$(showopt @popup-id-format "$DEFAULT_ID_FORMAT")}")"
	open_args+=("-A") # Create the target session and attach to it
	prepare_open
	socket_name="${socket_name:-$(get_socket_name)}"
	open_script="exec tmux -L '$socket_name' $open_cmds >/dev/null"

	# Starting from version 3.5, tmux uses the user's `default-shell` to execute
	# Shell commands. However, our scripts are written in `sh`, which may not be
	# Recognized by some shells that are incompatible with it. To address this,
	# We put the entire script in a temporary env variable and call `./really_open.sh`
	# To run these commands. This approach only requires the user's default
	# Shell to support the `exec` command, which we believe most shells do.
	tmux popup "${popup_args[@]}" \
		-e TMUX_POPUP_SERVER="$socket_name" \
		-e __tmux_popup_open="$open_script" \
		"exec $SRC_DIR/really_open.sh"

	# Undo temporary changes
	if [[ -n ${on_cleanup-} ]]; then
		# Ignore error if the server has already stopped
		eval "tmux -NCL '$socket_name' $(makecmds "$on_cleanup")" &>/dev/null || true
	fi

	# HOOK: after-close
	after_close="${after_close:-$(showopt @popup-after-close)}"
	if [[ -n $after_close ]]; then
		eval "tmux -C $(makecmds "$after_close")" >/dev/null
	fi

	return
}

main "$@"
