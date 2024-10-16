#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"
# shellcheck source=./variables.sh
source "$CURRENT_DIR/variables.sh"

declare name popup_args session_args cmd OPT OPTARG OPTIND=1

while getopts :-:BCEb:c:d:e:h:s:S:t:T:w:x:y: OPT; do
	if [[ $OPT == '-' ]]; then OPT="${OPTARG%%=*}"; fi
	case "$OPT" in
	[BCE]) popup_args+=("-$OPT") ;;
	[bcdhsStTwxy]) popup_args+=("-$OPT" "$OPTARG") ;;
	# forward environment overrides to popup sessions
	e) session_args+=("-e" "$OPTARG") ;;
	name)
		OPTARG="${OPTARG:${#OPT}}"
		if [[ ${OPTARG::1} == '=' ]]; then
			declare "$OPT"="${OPTARG:1}"
		else
			declare "$OPT"="${!OPTIND}"
			OPTIND=$((OPTIND + 1))
		fi
		;;
	help)
		cat <<-EOF
			USAGE:

			  toggle.sh [OPTION]... [SHELL_COMMAND]...

			OPTION:

			  --name <name>     Popup name [Default: "default"]
			  -[BCE]            Flags passed to display-popup
			  -[bcdehsStTwxy] <value>
			                    Options passed to display-popup

			EXAMPLES:

			  toggle.sh -Ed'#{pane_current_path}' --name=bash bash
		EOF
		exit
		;;
	*) badopt ;;
	esac
done
cmd=("${@:$OPTIND}")

opened="$(showvariable @__popup_opened)"

if [[ -n "$opened" && ("$opened" = "$name" || -z "$*") ]]; then
	# Clear the variables to prevent a manually attached session from being
	# detached by the keybinding.
	tmux set -u @__popup_opened \; detach
else
	name="${name:-"$DEFAULT_NAME"}"
	socket_name="$(get_socket_name)"
	id_format="$(showopt @popup-id-format "$DEFAULT_ID_FORMAT")"
	popup_id="$(format @popup_name "$name" "$id_format")"

	eval "tmux -C \; $(showhook @popup-before-open) >/dev/null"
	tmux popup "${popup_args[@]}" "
		TMUX_POPUP_SERVER='$socket_name' tmux -L '$socket_name' \
			new -As '$popup_id' ${session_args[*]} $(escape "${cmd[@]}") \; \
			new -As '$popup_id' $(escape "${cmd[@]}") \; \
			set @__popup_opened '$name' \; \
			$(showhook @popup-on-init "$DEFAULT_ON_INIT") \; \
			>/dev/null"
	eval "tmux -C \; $(showhook @popup-after-close) >/dev/null"
fi
