#!/usr/bin/env bash

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./helpers.sh
source "$SRC_DIR/helpers.sh"

declare OPT OPTARG OPTIND=1 mode=I
while getopts :-: OPT; do
	if [[ $OPT == '-' ]]; then OPT="${OPTARG%%=*}"; fi
	case "$OPT" in
	enter) mode=I ;;
	leave) mode=O ;;
	help)
		cat <<-EOF
			Usage:

			  focus.sh [OPTION]... [PROGRAM]...

			Options:

			  --enter      Send focus enter event [Default mode]
			  --leave      Send focus leave event

			Examples:

			  focus.sh --enter nvim emacs
		EOF
		exit
		;;
	*) badopt ;;
	esac
done
progs=("${@:$OPTIND}")

# Checks whether the running program is in the given list.
check_program() {
	if [[ ${#progs} == 0 ]]; then
		return
	fi

	for prog in "${progs[@]}"; do
		if [[ $(format '#{pane_current_command}') == "$prog" ]]; then
			return
		fi
	done

	return 1
}

main() {
	if check_program; then
		tmux send Escape "[$mode"
	fi
}

main
