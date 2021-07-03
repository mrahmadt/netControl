export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
export ETC_DIR="$( cd "${SCRIPT_DIR}/../etc" &> /dev/null && pwd )"

export WAN_INTERFACE=$(sqlite3 ${ETC_DIR}/home.sqlite3 "SELECT value FROM config WHERE name LIKE 'wan.interface'")
export LAN_INTERFACE=$(sqlite3 ${ETC_DIR}/home.sqlite3 "SELECT value FROM config WHERE name LIKE 'lan.interface'")
export PORTAL_IP=$(sqlite3 ${ETC_DIR}/home.sqlite3 "SELECT value FROM config WHERE name LIKE 'system.portal.ip'")
