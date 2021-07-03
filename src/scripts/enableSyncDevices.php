<?php
// Description: Execute when system boot, add rules for all devices

require_once dirname(__FILE__) . '/include/config.php';


$weekday = date('N');
$timeNow = date('G');


$bandwidths = getBandwidths();


$sql = 'DELETE FROM temporaryMode';
$dblink->exec($sql);


$sql = "SELECT schedule.mode as scheduleMode,devices.id,devices.mode,devices.availableCredit,devices.modeWhenCreditconsumed,devices.macaddr,devices.Is_loggedIn,devices.bandwidth,devices.requireLogin FROM devices LEFT JOIN schedule ON (schedule.device_id=devices.id AND schedule.weekday=$weekday AND schedule.hour=$timeNow)";

$sth = $dblink->prepare($sql);
$sth->execute();
$devices = $sth->fetchAll(PDO::FETCH_ASSOC);
foreach($devices as $device){
    if ($device['mode'] == 1 || $device['mode'] == 2 || $device['mode'] == 3) {
        setDevices($device['id'], $device['mode'], $device['macaddr'], $device['bandwidth'], $device['scheduleMode'], $device['requireLogin'], 0, $bandwidths);
    }else{//mode=4
        if ($device['scheduleMode'] == 1 || $device['scheduleMode'] == 3) {
            $mode = $device['mode'];
            if ($device['availableCredit']<=0 && $device['requireLogin'] == 1) {
                $mode = $device['modeWhenCreditconsumed'];
            }
            setDevices($device['id'], $mode, $device['macaddr'], $device['bandwidth'], $device['scheduleMode'], $device['requireLogin'], $device['Is_loggedIn'], $bandwidths);
        } else {//no schedule ==> block it
            setDevices($device['id'], 2, $device['macaddr']);
        }
    }
}

