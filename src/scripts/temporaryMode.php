<?php
require_once dirname(__FILE__) . '/include/config.php';


$sql = "UPDATE temporaryMode SET minutes=minutes-1";
$dblink->exec($sql);

$weekday = date('N');
$timeNow = date('G');

$bandwidths = getBandwidths();


$sql = "SELECT schedule.mode as scheduleMode,devices.id,devices.mode,devices.macaddr,devices.bandwidth,devices.requireLogin,temporaryMode.minutes FROM temporaryMode LEFT JOIN devices ON (temporaryMode.device_id=devices.id) LEFT JOIN schedule ON (schedule.device_id=devices.id AND schedule.weekday=$weekday AND schedule.hour=$timeNow) WHERE temporaryMode.minutes<=0";
$sth = $dblink->prepare($sql);
$sth->execute();
$devices = $sth->fetchAll(PDO::FETCH_ASSOC);

foreach($devices as $device){
    print_r($device);
    $cmd = [];

    setDevices($device['id'], $device['mode'], $device['macaddr'], $device['bandwidth'], $device['scheduleMode'], $device['requireLogin'], 0, $bandwidths);

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

    $sql = 'DELETE FROM temporaryMode WHERE device_id=' . $device['id'];
    $dblink->exec($sql);

}

