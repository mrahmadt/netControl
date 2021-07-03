#!/usr/bin/env bash
# Description: Run with every reboot
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/include/config.sh

db_system_status=$(sqlite3 ${ETC_DIR}/home.sqlite3 "SELECT value FROM config WHERE name LIKE 'system.status'")

if [[ "${db_system_status}" -eq 1 ]]; then
    echo "System:Enable"
    source $SCRIPT_DIR/enable.sh
else
    echo "System:Disable"
    source $SCRIPT_DIR/disable.sh
fi

exit 0;
