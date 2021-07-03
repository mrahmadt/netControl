#!/usr/bin/env bash
# Description: Allow device to access internet
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${SCRIPT_DIR}/include/config.sh
source ${SCRIPT_DIR}/include/macadd-deviceid-getopts.sh

#######################
### Block & Remove Limit
#######################

RMTRACK=0 ${SCRIPT_DIR}/block_device.sh -d ${DeviceID} -m ${MacAddr}

#######################
### Allow
#######################
iptables -I internet 1 -t mangle -m mac --mac-source ${MacAddr} -j RETURN 2>/dev/null
${SCRIPT_DIR}/include/rmtrack-mac.sh ${MacAddr}
