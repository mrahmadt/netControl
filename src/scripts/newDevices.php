<?php
// Description: Detect and add new devices

require_once dirname(__FILE__) . '/include/config.php';
$output = execCmd("arp -a -i ".$config['lan.interface']." | grep -v incomplete | grep -v 'arp:'");

//TODO: NEED TO FIX our router to make sure it's always allowed internet
//$output .= "? (192.168.1.44) at 10:dd:b1:9e:39:24 [ether] on enp1s0f0\n";

preg_match_all("|(.*) \((.*)\) at (([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2}))|m",$output,$out, PREG_SET_ORDER);
if(!isset($out[0])) exit;

$bandwidths = [];



foreach($out as $line){
    //TODO: need to ignore any device not in our lan
    //TODO: need to ignore our main router
    //TODO: need to ignore our router

    $macaddr = $line[3];
    $ipaddr = $line[2];
    if($ipaddr == $config['lan.ipaddr']) continue;
    if (false === filter_var($ipaddr, FILTER_VALIDATE_IP)) continue;
    if (false === filter_var($macaddr, FILTER_VALIDATE_MAC)) continue;
    $bandwidth = ($config['device.new.bandwidth'] !='') ? $config['device.new.bandwidth'] : null;
    $mode = $config['device.new.mode'];
    $hostname = ($line[1] != '?') ? $line[1] : null;
    $name = ($hostname) ? $hostname : 'Unknown';
    
    $device = [
        'macaddr' => $macaddr,
        'ipaddr' => $ipaddr,
        'hostname' => $hostname,
        'name' => $name,
        'mode' => $mode,
        'bandwidth' => $bandwidth,
        ':created_at' => time(),
        ':updated_at' => time(),
    ];
    // $sqlite_version = false;
    // $stmt = $dblink->query('SELECT sqlite_version()');
    // $row = $stmt->fetch(\PDO::FETCH_ASSOC);
    // if($row){
    //     $sqlite_version = $row['sqlite_version()'];
    // }
    // if ($sqlite_version && version_compare($sqlite_version, '3.24') >= 0) {
    //     $sql = 'INSERT INTO devices (name, macaddr, ipaddr, hostname, mode, bandwidth, created_at, updated_at) VALUES(:name, :macaddr,:ipaddr, :hostname, :mode, :bandwidth, :created_at, :updated_at) ON CONFLICT(macaddr) DO UPDATE SET ipaddr=:ipaddr, hostname=:hostname, updated_at=:updated_at;';
    //     $stmt = $dblink->prepare($sql);
    //     $stmt->execute($device);
    //     $id = $dblink->lastInsertId();
    // }else{
        $isNewDevice = true;
        $stmt = $dblink->prepare('SELECT id FROM devices WHERE macaddr LIKE :macaddr');
        $stmt->execute(['macaddr'=>$macaddr]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);
        if ($row) {
            $id = $row['id'];
            $isNewDevice = false;
            $sql = 'UPDATE devices SET updated_at=:updated_at WHERE id=:id';
            $stmt = $dblink->prepare($sql);
            $stmt->execute(['id'=>$id, 'updated_at'=>time()]);

        }else{
            $sql = 'INSERT INTO devices (name, macaddr, ipaddr, hostname, mode, bandwidth, created_at, updated_at) VALUES(:name, :macaddr,:ipaddr, :hostname, :mode, :bandwidth, :created_at, :updated_at)';
            $stmt = $dblink->prepare($sql);
            $stmt->execute($device);
            $id = $dblink->lastInsertId();
            $isNewDevice = true;
        }
    // }


    if($isNewDevice && $config['system.status'] == '1'){
        if(!$bandwidths) $bandwidths = getBandwidths();
        setDevices($id, $mode, $macaddr, $bandwidth, null, 0, 0, $bandwidths);
        $execoutput = execCmd('dig +short -x '.$ipaddr.' @'. $config['lan.dnsserver1']);
        $hostname = null;
        $manufacturer = null;
        if($execoutput){
            $hostname = $execoutput;
        }else{
            $execoutput = execCmd('avahi-resolve-address '.$ipaddr . ' | cut -f 2');
            if($execoutput){
                $hostname = $execoutput;
            }
        }
        $vendorMacPrefix = explode(':',$macaddr);
        $vendorMacPrefix = $vendorMacPrefix[0] . '-' . $vendorMacPrefix[1] . '-' . $vendorMacPrefix[2];
        $manufacturer = execCmd("grep -i '$vendorMacPrefix' ".__ETC_DIR__."/oui.txt | cut -f 3");

        if($hostname || $manufacturer){
            $sql = 'UPDATE devices SET stage=1, manufacturer=:manufacturer, hostname=:hostname, name=:name WHERE id=:id';
            $stmt = $dblink->prepare($sql);
            $name = ($hostname) ? $hostname : 'Unknown';
            $stmt->execute(['id'=>$id, 'hostname'=>$hostname, 'manufacturer'=>$manufacturer, 'name'=>$name]);
        }
        //TODO: Send push notification to admin about new device
    }
}

// Clearing cache
execCmd('ip -s -s neigh flush all dev '. $config['lan.interface']);
