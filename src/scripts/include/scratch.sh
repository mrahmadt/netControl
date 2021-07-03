#!/usr/bin/env bash
# Description: Start from scratch

#######################
### Start from scratch
#######################
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT


#######################
### Gateway setup
#######################
sysctl -w net.ipv4.ip_forward=1
echo "1" > /proc/sys/net/ipv4/ip_forward


echo "LAN ${LAN_INTERFACE}";
tc qdisc del dev ${LAN_INTERFACE} root
tc qdisc add dev ${LAN_INTERFACE} root handle 1: htb 
