#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./helpers.sh
source "$CURRENT_DIR/helpers.sh"

declare mode=I progs OPT OPTARG OPTIND=1

while getopts :-: OPT; do
	if [ "$OPT" = '-' ]; then OPT="${OPTARG%%=*}"; fi
	case "$OPT" in
	enter) mode=I ;;
	leave) mode=O ;;
	help)
		cat <<-EOF
			USAGE:

			  focus.sh [OPTION]... [PROGRAM]...

			OPTION:

			  --enter           Send focus enter event [Default mode]
			  --leave           Send focus leave event

			EXAMPLES:

			  focus.sh --enter nvim emacs
		EOF
		exit
		;;
	*) badopt ;;
	esac
done
progs=("${@:$OPTIND}")

check() {
	if [ ${#progs} = 0 ]; then
		return
	fi

	for prog in "${progs[@]}"; do
		if [ "$(format '#{pane_current_command}')" = "$prog" ]; then
			return
		fi
	done

	return 1
}
if check; then
	tmux send Escape "[$mode"
fi
