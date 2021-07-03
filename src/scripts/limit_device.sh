#!/usr/bin/env bash
# Description: limit device internet speed
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${SCRIPT_DIR}/include/config.sh



Rate="1mbit"
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

#######################
### add Limit
#######################
${SCRIPT_DIR}/include/limit.sh -a add -d ${DeviceID} -m ${MacAddr} -r ${Rate}

