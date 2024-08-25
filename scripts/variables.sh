#!/usr/bin/env bash

# shellcheck disable=2034
DEFAULT_NAME='default'
DEFAULT_SOCKET_NAME='popup'
DEFAULT_ID_FORMAT='#{b:socket_path}/#{session_name}/#{b:pane_current_path}/#{@popup_name}'
DEFAULT_ON_INIT="set exit-empty off \; set status off"

get_socket_name() {
	showopt @popup-socket-name "$DEFAULT_SOCKET_NAME"
}
