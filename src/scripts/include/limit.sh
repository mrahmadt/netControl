#!/usr/bin/env bash
# Description: create limit for devices

Action=""
Rate="1mbit"

while getopts a:r:m:d: flag
do
    case "${flag}" in
        a) Action=${OPTARG};;
        r) Rate=${OPTARG};;
        m) MacAddr=${OPTARG};;
        d) DeviceID=${OPTARG};;
    esac
done

if [[ "$Action" != "add" && "$Action" != "del" ]]; then
    echo "Unknown action $Action";
    exit 1
fi

if [[ -z "$DeviceID" && -z "$MacAddr" ]]; then
    echo "./script -a [del|add] -r 1mbit -m MacAddress  or ./script -a [del|add] -r 1mbit -d DeviceID"
    exit 1

elif [[ -n "$DeviceID" && -n "$MacAddr" ]]; then
    echo -n ""
else
    if [[ -n "$DeviceID" ]]; then
        DB_macaddr=$(sqlite3 ${ETC_DIR}/home.sqlite3 "SELECT macaddr FROM devices WHERE id=${DeviceID}")
        if [[ -n "$DB_macaddr" ]]; then
            MacAddr="$DB_macaddr"
        else
            echo "Device id ${DeviceID} not found!"
            exit 1
        fi
    fi

    if [[ -n "$MacAddr" ]]; then
        DB_deviceID=$(sqlite3 ${ETC_DIR}/home.sqlite3 "SELECT id FROM devices WHERE macaddr LIKE '${MacAddr}'")
        if [[ -n "$DB_deviceID" ]]; then
            DeviceID="$DB_deviceID"
        else
            echo "Device with Mac Address ${MacAddr} not found!"
            exit 1
        fi
    fi
fi

echo "----------------------"
echo "Action: $Action";
echo "DeviceID: $DeviceID";
echo "MacAddr: $MacAddr";
echo "Rate: $Rate";
echo "----------------------"


#######################
### Traffic Control
#######################

if [[ -n "$DeviceID" && "$Action" = "del" ]]; then
    echo "del DeviceID=${DeviceID} (${MacAddr})"
fi

tc filter del dev ${LAN_INTERFACE} protocol ip handle 800::${DeviceID} parent 1:0 prio 1 u32 2>/dev/null
tc class del dev ${LAN_INTERFACE} parent 1: classid 1:${DeviceID} 2>/dev/null


if [[ "$Action" = "add" ]]; then
    echo "add DeviceID=${DeviceID} (${MacAddr}) Rate:${Rate}"
    M0M1M2M3=$(echo $MacAddr | awk -F: '{print $1$2$3$4}')
    M4M5=$(echo $MacAddr | awk -F: '{print $5$6}')
    M0M1=$(echo $MacAddr | awk -F: '{print $1$2}')
    M2M3M4M5=$(echo $MacAddr | awk -F: '{print $3$4$5$6}')
    tc class add dev $LAN_INTERFACE parent 1: classid 1:${DeviceID} htb rate ${Rate}
    tc filter add dev $LAN_INTERFACE protocol ip handle ::${DeviceID} parent 1:0 prio 1 u32 match u16 0x0800 0xFFFF at -2 match u32 0x$M2M3M4M5 0xFFFFFFFF at -12 match u16 0x$M0M1 0xFFFF at -14 flowid 1:${DeviceID}
fi
