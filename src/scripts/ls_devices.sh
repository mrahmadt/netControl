#!/usr/bin/env bash
# Description: Allow device to access internet
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${SCRIPT_DIR}/include/config.sh

sqlite3 ${ETC_DIR}/home.sqlite3 "SELECT id, macaddr, name, manufacturer, datetime(updated_at, 'unixepoch', 'localtime') FROM devices"
