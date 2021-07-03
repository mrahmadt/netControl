#!/usr/bin/env bash

MACADDR="$1"
# echo "rmtrack-mac ${MACADDR}";
IPADDR=$(arp -an | grep -v incomplete | grep -v 'arp:'|  grep ${MACADDR} | awk '{print $2}' | sed 's/[()]//g')

if [[ -n "$IPADDR" ]]; then
# echo "IP Address: $IPADDR"
/usr/sbin/conntrack -L \
  |grep $IPADDR \
  |grep ESTAB \
  |grep 'dport=80' \
  |awk \
      "{ system(\"conntrack -D --orig-src $IPADDR --orig-dst \" \
          substr(\$6,5) \" -p tcp --orig-port-src \" substr(\$7,7) \" \
          --orig-port-dst 80\"); }"
fi
