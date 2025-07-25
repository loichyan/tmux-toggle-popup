#!/usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"

declare OPT OPTARG OPTIND=1 mode=I programs
usage() {
	cat <<-EOF
		Usage:

		  focus.sh [OPTION]... [PROGRAM]...

		Options:

		  --enter      Send focus enter event [Default mode]
		  --leave      Send focus leave event

		Examples:

		  focus.sh --enter nvim emacs
	EOF
}

# Checks whether the running program is in the given list.
check_program() {
	if [[ ${#programs} == 0 ]]; then
		return
	fi

	for prog in "${programs[@]}"; do
		if [[ $(format '#{pane_current_command}') == "$prog" ]]; then
			return
		fi
	done

	return 1
}

main() {
	while getopts :-: OPT; do
		if [[ $OPT == '-' ]]; then OPT=${OPTARG%%=*}; fi
		case "$OPT" in
		enter) mode=I ;;
		leave) mode=O ;;
		help)
			usage
			exit
			;;
		*) die_badopt ;;
		esac
	done
	programs=("${@:$OPTIND}")

	if check_program; then
		tmux send Escape "[$mode"
	fi
}

main "$@"
