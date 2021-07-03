#!/usr/bin/env bash
# Description: Disable the system (allow all traffic)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/include/config.sh


source $SCRIPT_DIR/include/scratch.sh

iptables -A POSTROUTING -t nat -o ${WAN_INTERFACE} -j MASQUERADE 
iptables -A FORWARD -i ${LAN_INTERFACE} -o ${WAN_INTERFACE} -j ACCEPT
iptables -A FORWARD -i ${WAN_INTERFACE} -o ${LAN_INTERFACE} -m state --state ESTABLISHED,RELATED -j ACCEPT
