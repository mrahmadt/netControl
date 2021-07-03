#!/usr/bin/env bash
# Description: Enable the system (control traffic)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/include/config.sh


source $SCRIPT_DIR/include/scratch.sh

#######################
### Firewall
#######################
# Redirect to web portal

iptables -t mangle -N internet
iptables -t mangle -A PREROUTING -p tcp --dport 80:50000 -j internet
iptables -t mangle -A internet -j MARK --set-mark 99
iptables -t nat -A PREROUTING -p tcp -m mark --mark 99 -j DNAT --to-destination ${PORTAL_IP}


iptables -A POSTROUTING -t nat -o ${WAN_INTERFACE} -j MASQUERADE 
iptables -A FORWARD -o ${WAN_INTERFACE} -p tcp --dport 53 -j REJECT
iptables -A FORWARD -o ${WAN_INTERFACE} -p udp --dport 53 -j REJECT


#######################
### Sync Devices with IPTABLES
#######################

php $SCRIPT_DIR/enableSyncDevices.php


###############################################################
#
# mode : 1 ---> Allow (MACADDR, DeviceID)
    ## ٌRemove Prev Allow
    ## Remove Slow
    ## Add Allow

#
# mode : 2 ---> Block (MACADDR, DeviceID)
    ## Remove Prev Allow
    ## Remove Slow

#
# mode : 3 ---> allow and slow  (MACADDR, DeviceID)
    ## ٌRemove Prev Allow
    ## Remove Slow
    ## Add Allow
    ## Add Slow


#
# mode : 4 ---> check schedule table [with login?]
    # Schedule:Allow -- NO LOGIN REQUIRED
        ## ٌRemove Prev Allow
        ## Remove Slow
        ## Add Allow

    #
    # Schedule:Block -- NO LOGIN REQUIRED
        ## Remove Prev Allow
        ## Remove Slow

    #
    # Schedule:allow and slow -- NO LOGIN REQUIRED
        ## ٌRemove Prev Allow
        ## Remove Slow
        ## Add Allow
        ## Add Slow


#TODO: What about break ? --> when logout ---> need to delete this? but be carful, (if user logout but he is not logged in!)

#TODO: When change mode to schedule from UI, check the schedule table (plus fix in temporaryMode)

#TODO: Add current status (sync with iptable)

#TODO: Install
#TODO: Uninstall
#TODO: Update

#TODO: No need to relay on PiHOLE?

#TODO: ### UI
#Index
#User management
#Device management
#Settings
#Portal Page
#Statistics from PiHole logs
#Assign Name to Device (DNS)
