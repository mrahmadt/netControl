<?php
//TODO: we need to run all commands with sudo!!
$iptables_mangle_output = null;

function getStatusMode($device_id,$macaddr){
    global $iptables_mangle_output;
    if($iptables_mangle_output==null) $iptables_mangle_output = execCmd("iptables -L -t mangle");
    if (stripos($iptables_mangle_output, $macaddr) === false) {
        return 2;
    }else{
        $cmdOutput = execCmd("tc filter show dev enp0s8 | grep '800::$device_id '");
        if($cmdOutput==''){
            return 1;
        }else{
            return 3;
        }
    }
}

function execCmd($cmd){
    ob_start();
    passthru($cmd);
    $var = ob_get_contents();
    ob_end_clean(); //Use this instead of ob_flush()
    return trim($var);
}


function getBandwidths(){
    global $dblink;
    $sql = "SELECT * FROM bandwidths";
    $sth = $dblink->prepare($sql);
    $sth->execute();
    $bandwidths = $sth->fetchAll(PDO::FETCH_ASSOC);
    $bandwidths = array_column($bandwidths, null, "id");
    return $bandwidths;
}

function getDeviceTypes(){
    global $dblink;
    $sql = "SELECT * FROM deviceTypes";
    $sth = $dblink->prepare($sql);
    $sth->execute();
    $deviceTypes = $sth->fetchAll(PDO::FETCH_ASSOC);
    $deviceTypes = array_column($deviceTypes, null, "id");
    return $deviceTypes;
}
function getUsers(){
    global $dblink;
    $sql = "SELECT * FROM users";
    $sth = $dblink->prepare($sql);
    $sth->execute();
    $users = $sth->fetchAll(PDO::FETCH_ASSOC);
    $users = array_column($users, null, "id");
    return $users;
}

function setTemporaryMode($device_id, $minutes = 10){
    global $dblink;
    $sql = 'DELETE FROM temporaryMode WHERE device_id=:device_id';
    $sth = $dblink->prepare($sql);
    $sth->execute([':device_id' => $device_id]);

    $sql = 'INSERT INTO temporaryMode (device_id, minutes) VALUES(:device_id,:minutes)';
    $sth = $dblink->prepare($sql);
    $sth->execute([':device_id' => $device_id, ':minutes'=> $minutes]);
}

function setDevices($id, $mode, $macaddr = null, $bandwidth = null, $scheduleMode = null, $requireLogin = 0, $doLogin = 0, $bandwidths = null){
    global $dblink;
    $cmd = [];
    $scriptAllow = __SCRIPT_DIR__ . '/allow_device.sh';
    $scriptBlock = __SCRIPT_DIR__ . '/block_device.sh';
    $scriptLimit = __SCRIPT_DIR__ . '/limit_device.sh';

    
    if($mode==1) { // Allow
        $cmd = [
            $scriptAllow,
            '-d ' . $id,
            '-m ' . $macaddr
        ];
    }elseif($mode==3) { // limit
        $rate = '1mbit';
        if($bandwidth){
            if(!$bandwidths){
                $bandwidths = getBandwidths();
            }
            $rate = $bandwidths[$bandwidth]['tcrate'];
        }
        $cmd = [
            $scriptLimit,
            '-d ' . $id,
            '-m ' . $macaddr,
            '-r ' . $rate,
        ];
    }elseif($mode==4 && ($requireLogin == 0 || $doLogin == 1)) { // scheduled with/without login
        if($scheduleMode==1) { // Allow
            $cmd = [
                $scriptAllow,
                '-d ' . $id,
                '-m ' . $macaddr
            ];
        }elseif($scheduleMode==3) { // limit
            $rate = '1mbit';
            if($bandwidth){
                if(!$bandwidths){
                    $bandwidths = getBandwidths();
                }
                $rate = $bandwidths[$bandwidth]['tcrate'];
            }
            $cmd = [
                $scriptLimit,
                '-d ' . $id,
                '-m ' . $macaddr,
                '-r ' . $rate,
            ];
        }else{
            $cmd = [
                $scriptBlock,
                '-d ' . $id,
                '-m ' . $macaddr
            ];
        }
    }else{ // Block
        $cmd = [
            $scriptBlock,
            '-d ' . $id,
            '-m ' . $macaddr
        ];
    }
    $cmdline = implode(' ',$cmd);
    if($cmd) $output = execCmd($cmdline);
    if($doLogin == 1){
        $sql = 'UPDATE devices SET stage=1, Is_loggedIn=1 WHERE device_id=' . $id;
    }else{
        $sql = 'UPDATE devices SET stage=1, Is_loggedIn=0 WHERE device_id=' . $id;
    }
    $dblink->exec($sql);
}

function timeAgo($time_ago) {
    $time  = time() - $time_ago;
    switch($time):
    // seconds
    case $time <= 60;
    return 'less than minute';
    // minutes
    case $time >= 60 && $time < 3600;
    return (round($time/60) == 1) ? 'a minute' : round($time/60).' minutes ago';
    // hours
    case $time >= 3600 && $time < 86400;
    return (round($time/3600) == 1) ? 'a hour ago' : round($time/3600).' hours ago';
    // days
    case $time >= 86400 && $time < 604800;
    return (round($time/86400) == 1) ? 'a day ago' : round($time/86400).' days ago';
    // weeks
    case $time >= 604800 && $time < 2600640;
    return (round($time/604800) == 1) ? 'a week ago' : round($time/604800).' weeks ago';
    // months
    case $time >= 2600640 && $time < 31207680;
    return (round($time/2600640) == 1) ? 'a month ago' : round($time/2600640).' months ago';
    // years
    case $time >= 31207680;
    return (round($time/31207680) == 1) ? 'a year ago' : round($time/31207680).' years ago' ;

    endswitch;
}