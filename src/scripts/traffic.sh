#!/bin/bash

TRAFFICDBFILE="/var/log/netControl/traffic.db"

datetime=$(date +'%F %T')

traffic=$(iptables -vxL -t mangle | grep 'MAC ' | awk '{print $2" "$NF}')
(IFS='
'
for i in $(iptables -Z -vxL -t mangle | grep 'MAC ' | awk '{print $2" "$NF}'); do

    byte=$(echo $i |awk '{print $1}');
    macaddr=$(echo $i |awk '{print $2}');

    if [ "$byte" -gt "0" ]; then
        echo "macaddr $macaddr  byte:$byte"
        echo "INSERT INTO traffics (macaddr, bytes, dt) VALUES('${macaddr}',${byte},'${datetime}')" | sqlite3 ${TRAFFICDBFILE}
    fi
done)
