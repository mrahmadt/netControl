#!/usr/bin/env bash

while getopts m:d:r: flag
do
    case "${flag}" in
        m) MacAddr=${OPTARG};;
        d) DeviceID=${OPTARG};;
        r) Rate=${OPTARG};;
    esac
done

if [[ -z "$DeviceID" && -z "$MacAddr" ]]; then
    echo "./script -m MacAddress  or ./script -d DeviceID"
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

# echo "MacAddr: $MacAddr";
# echo "DeviceID: $DeviceID";

