<?php
require_once 'validLogin.php';

require_once '../../scripts/include/config.php';


$command = explode(':',$_GET['action']);

$action = $command[0];
$value = $command[1];
$id = $_GET['id'];

$sth = $dblink->prepare('SELECT id,mode,macaddr,bandwidth,requireLogin FROM devices WHERE id=:id');
$sth->execute(array(':id' => $id));
$device = $sth->fetch(\PDO::FETCH_ASSOC);

if(!$device) goMainPage();


if($value == '0'){
    $stmt = $dblink->prepare('UPDATE devices SET stage=1,mode=:mode WHERE id=:id');
    if($action == 'allow'){
        $stmt->execute(['id'=>$id,'mode'=>1]);
        setDevices($device['id'], 1, $device['macaddr']);
    }elseif($action == 'block'){
        $stmt->execute(['id'=>$id,'mode'=>2]);
        setDevices($device['id'], 2, $device['macaddr']);
    }elseif($action == 'limit'){
        $stmt->execute(['id'=>$id,'mode'=>3]);
        setDevices($device['id'], 3, $device['macaddr'], $device['bandwidth']);
    }elseif($action == 'schedule'){
        $stmt->execute(['id'=>$id,'mode'=>4]);
        setDevices($device['id'], 4, $device['macaddr'], null, null, $device['requireLogin']);
    }

}else{
    if($action == 'allow'){
        setDevices($device['id'], 1, $device['macaddr']);
        setTemporaryMode($id, $value);
    }elseif($action == 'block'){
        setDevices($device['id'], 2, $device['macaddr']);
        setTemporaryMode($id, $value);
    }
}

goMainPage();

function goMainPage(){
    header("Location: /netcontrol-admin/index.php");
    exit;
}