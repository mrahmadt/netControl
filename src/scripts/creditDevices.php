<?php
// Description: Track the credit consumption/reset

require_once dirname(__FILE__) . '/include/config.php';
$timeNow = (int)date('Gi');


//--------------------------------------------------------------------------------
// UPDATE EVERY MINUTE IF USER IS LOGGED IN
//--------------------------------------------------------------------------------
$sql = "UPDATE devices SET availableCredit=availableCredit-1 WHERE Is_loggedIn=1";
$dblink->exec($sql);


//--------------------------------------------------------------------------------
// Action Logout when credit consumed
//--------------------------------------------------------------------------------
$sql = "SELECT id,modeWhenCreditconsumed,macaddr,bandwidth FROM devices WHERE Is_loggedIn=1 AND availableCredit<=0";
$sth = $dblink->prepare($sql);
$sth->execute();
$devices = $sth->fetchAll(PDO::FETCH_ASSOC);
if($devices) $bandwidths = getBandwidths();
foreach($devices as $device){
    $doLogin = 0;
    if($device['modeWhenCreditconsumed']==3) $doLogin = 1;
    setDevices($device['id'], $device['modeWhenCreditconsumed'], $device['macaddr'], $device['bandwidth'], null, 0, $doLogin, $bandwidths);
}

// ------------------------------------------------------------
// Update credit in midnight
// ------------------------------------------------------------
if($timeNow==0){
    $dayName = date('D');
    $sql = "UPDATE devices SET availableCredit=".$dayName."Credit";
    $dblink->exec($sql);
}
