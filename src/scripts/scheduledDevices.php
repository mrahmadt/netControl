<?php
// Description: take care of the scheduling and track the credit consumption/reset

require_once dirname(__FILE__) . '/include/config.php';


$weekday = date('N');
$timeNow = date('G');

//--------------------------------------------------------------------------------
//-- Check schedule for all devices in mode 4 (requireLogin = 0 and requireLogin = 1)
//--------------------------------------------------------------------------------
$sql = "SELECT schedule.mode as scheduleMode,devices.id,devices.mode,devices.availableCredit,devices.modeWhenCreditconsumed,devices.macaddr,devices.Is_loggedIn,devices.bandwidth,devices.requireLogin FROM devices LEFT JOIN schedule ON (schedule.device_id=devices.id AND schedule.weekday=$weekday AND schedule.hour=$timeNow) WHERE devices.mode=4";
$sth = $dblink->prepare($sql);
$sth->execute();
$devices = $sth->fetchAll(PDO::FETCH_ASSOC);
if($devices) $bandwidths = getBandwidths();
foreach($devices as $device){
    if($device['scheduleMode'] == 1 || $device['scheduleMode'] == 3){
        $mode = $device['mode'];
        if($device['availableCredit']<=0 && $device['requireLogin'] == 1){
            $mode = $device['modeWhenCreditconsumed'];
        }
        setDevices($device['id'], $mode, $device['macaddr'], $device['bandwidth'], $device['scheduleMode'], $device['requireLogin'], $device['Is_loggedIn'], $bandwidths);
    }else{//no schedule ==> block it
        setDevices($device['id'], 2, $device['macaddr']);
    }
    //TODO: Do We need to verifiy if previous hour mode same as current hour (will current code impact user experiance?)
}