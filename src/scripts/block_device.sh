#!/usr/bin/env bash
# Description: block device from accessing internet
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${SCRIPT_DIR}/include/config.sh
source ${SCRIPT_DIR}/include/macadd-deviceid-getopts.sh

#######################
### Block
#######################
iptables -D internet -t mangle -m mac --mac-source ${MacAddr} -j RETURN 2>/dev/null

if [[ -z "$RMTRACK" || "$RMTRACK" = "1" ]]; then
    ${SCRIPT_DIR}/include/rmtrack-mac.sh ${MacAddr}  2>/dev/null
fi

#######################
### Remove Limit
#######################
${SCRIPT_DIR}/include/limit.sh -a del -d ${DeviceID} -m ${MacAddr}
