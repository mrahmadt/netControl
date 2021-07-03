<?php
// Description: Detect and add new devices

require_once dirname(__FILE__) . '/include/config.php';
$output = execCmd("arp -a -i ".$config['lan.interface']." | grep -v incomplete | grep -v 'arp:'");
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

    $device = [
        'macaddr' => $macaddr,
        'ipaddr' => $ipaddr,
        'hostname' => $hostname,
        'name' => $hostname,
        'mode' => $mode,
        'bandwidth' => $bandwidth,
        'created_at' => time(),
        'updated_at' => time(),
    ];
    $sql = 'INSERT INTO devices (name, macaddr, ipaddr, hostname, mode, bandwidth, created_at, updated_at) VALUES(:name, :macaddr,:ipaddr, :hostname, :mode, :bandwidth, :created_at, :updated_at) ON CONFLICT(macaddr) DO UPDATE SET ipaddr=:ipaddr, hostname=:hostname, updated_at=:updated_at;';
    $stmt = $dblink->prepare($sql);
    $stmt->execute($device);
    $id = $dblink->lastInsertId();
    if($id){
        if(!$bandwidths) $bandwidths = getBandwidths();
        setDevices($id, $mode, $macaddr, $bandwidth, null, 0, 0, $bandwidths);
        $execoutput = execCmd('dig +short -x '.$ipaddr.' @'. $config['lan.dnsserver1']);
        $hostname = null;
        $manufacturer = null;
        if($execoutput){
            $hostname = $execoutput;
        }else{
            $execoutput = execCmd('avahi-resolve-address '.$ipaddr);
            if($execoutput){
                $hostname = $execoutput;
            }
        }
        $vendorMacPrefix = explode(':',$macaddr);
        $vendorMacPrefix = $vendorMacPrefix[0] . '-' . $vendorMacPrefix[1] . '-' . $vendorMacPrefix[2];
        $manufacturer = execCmd("grep -i '$vendorMacPrefix' ".__ETC_DIR__."/oui.txt | cut -f 3");

        if($hostname || $manufacturer){
            $sql = 'UPDATE devices SET manufacturer=:manufacturer, hostname=:hostname WHERE id=:id';
            $stmt = $dblink->prepare($sql);
            $stmt->execute(['id'=>$id, 'hostname'=>$hostname, 'manufacturer'=>$manufacturer]);
        }
        //TODO: Send push notification to admin about new device
    }
}

// Clearing cache
execCmd('ip -s -s neigh flush all dev '. $config['lan.interface']);
