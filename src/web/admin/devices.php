<?php
require_once 'validLogin.php';
require_once '../../scripts/include/config.php';
$bandwidths = getBandwidths();
$deviceTypes = getDeviceTypes();
$users = getUsers();
//1 (for Monday) through 7 (for Sunday)
$weekDays = ['Mon'=>1,'Tue'=>2,'Wed'=>3,'Thu'=>4,'Fri'=>5,'Sat'=>6,'Sun'=>7];
$weekDaysByID = array_flip($weekDays);
$id = 0;

if (isset($_GET['id'])){
  $id = $_GET['id'];
}elseif (isset($_POST['id'])) {
  $id = $_POST['id'];
  saveDeviceForm($_POST);

  $sth = $dblink->prepare('SELECT id,mode,macaddr,bandwidth,requireLogin FROM devices WHERE id=:id');
  $sth->execute([':id'=>$id]);
  $device = $sth->fetch(\PDO::FETCH_ASSOC);

  if($device['mode'] == 1){
    setDevices($device['id'], 1, $device['macaddr']);
  }elseif($device['mode'] == 2){
    setDevices($device['id'], 2, $device['macaddr']);
  }elseif($device['mode'] == 3){
    setDevices($device['id'], 3, $device['macaddr'], $device['bandwidth'], null, 0, 0, $bandwidths);
  }elseif($device['mode'] == 4){
    setDevices($device['id'], 4, $device['macaddr'], null, null, $device['requireLogin']);
  }
  $dblink->exec('UPDATE devices SET stage=2 WHERE id=' . $device['id']);

  // @header('Location: /netcontrol-admin/devices.php?id='.$id . '&t='.time());
  @header('Location: /netcontrol-admin/index.php?t='.time());

  exit;
}

if (!$id) {
    exit;
}

$sth = $dblink->prepare('SELECT * FROM devices WHERE id=:id');
$sth->execute([':id'=>$id]);
$device = $sth->fetch(\PDO::FETCH_ASSOC);

if (!$device) {
    exit;
}

$sth = $dblink->prepare('SELECT * FROM schedule WHERE device_id=:device_id');
$sth->execute([':device_id'=>$id]);
$schedules = $sth->fetchAll(\PDO::FETCH_ASSOC);
$schCell = null;
$schCellArray = null;

foreach($schedules as $schedule){
  $schCellArray[] = $weekDaysByID[$schedule['weekday']] . $schedule['hour'] . ':' . $schedule['mode'];
}

if (!$schCellArray) {
  $schCell = '{}';
}else{
  $schCell = '{'.implode(',',$schCellArray).'}';
}

define('PAGE_TITLE', 'Device - ' . $device['name']);
require_once 'html/header.php';
require_once 'html/menu.php';

?>
<section class="py-4 px-4">
  <div class="container px-0 mx-auto">
    <?php
$deviceSettings = [
  ['text'=>'Device Information', 'header'=>true],
  ['text'=>'Name', 'name'=> 'name'],
  ['text'=>'Vendor', 'name'=> 'manufacturer'],
  ['text'=>'Host', 'name'=> 'hostname'],
  ['text'=>'MAC Address', 'name'=> 'macaddr'],
  ['text'=>'IP', 'name'=> 'ipaddr'],
  ['text'=>'Type', 'name'=> 'deviceType_id'],
  ['text'=>'First Seen', 'name'=> 'created_at'],
  ['text'=>'Last Seen', 'name'=> 'updated_at'],
  ['text'=>'User', 'name'=> 'user_id'],
  ['text'=>'Internet Control', 'header'=>true],
  ['text'=>'Mode', 'name'=> 'mode'],
  ['text'=>'Require Login', 'name'=> 'requireLogin', 'xshow'=>'mode==4'],
  ['text'=>'Remaining credit for today', 'name'=> 'availableCredit', 'xshow'=>'mode==4 && requireLogin==1'],
  ['text'=>'Speed limit', 'name'=> 'bandwidth', 'xshow'=>'mode==4 || mode==3'],
  ['text'=>'Monday credit', 'name'=> 'MonCredit', 'xshow'=>'mode==4 && requireLogin==1'],
  ['text'=>'Tuesday credit', 'name'=> 'TueCredit', 'xshow'=>'mode==4 && requireLogin==1'],
  ['text'=>'Wednesday credit', 'name'=> 'WedCredit', 'xshow'=>'mode==4 && requireLogin==1'],
  ['text'=>'Thursday credit', 'name'=> 'ThuCredit', 'xshow'=>'mode==4 && requireLogin==1'],
  ['text'=>'Friday credit', 'name'=> 'FriCredit', 'xshow'=>'mode==4 && requireLogin==1'],
  ['text'=>'Saturday credit', 'name'=> 'SatCredit', 'xshow'=>'mode==4 && requireLogin==1'],
  ['text'=>'Sunday credit', 'name'=> 'SunCredit', 'xshow'=>'mode==4 && requireLogin==1'],
  ['text'=>'Switch to slow speed when daily credit consumed?', 'name'=> 'modeWhenCreditconsumed', 'xshow'=>'mode==4 && requireLogin==1'],
];
// $xdata = implode('_show:true,', array_column($deviceSettings, 'name')) . '_show:true';
// print_r($xdata);exit;

$xdata = [
  'mode:'.$device['mode'],
  'requireLogin:'.$device['requireLogin'],
  'schCell:'.$schCell
]
?>
    <div class="p-4 mb-6 bg-white shadow rounded "
      x-data="{ <?php echo implode(',', $xdata);?> }">
      <form action="/netcontrol-admin/devices.php" method="post">
        <input type="hidden" name="id"
          value="<?php echo $_GET['id'];?>">
        <table class="table-auto w-full text-sm">
          <tbody>
            <?php foreach ($deviceSettings as $row) { ?>
            <tr class="text-left" <?php if (isset($row['xshow'])) {?> x-transition x-show="<?php echo $row['xshow'];?>"<?php }?>>
              <?php if (isset($row['header']) && $row['header']) {?>
              <td colspan="2" class=""><div class="text-xl font-bold py-4"><?php echo $row['text'];?></div><hr class="pb-2"></td>
              <?php continue;}?>
              <td x-cloak class="p-4"><?php echo $row['text'];?></td>
              <td x-cloak class="p-2"><?php
                $value = $row['name'];
                if ($row['name'] == 'name') {
                    ?>
<input type="text" class="px-1 border border shadow" name="<?php echo $row['name']; ?>" value="<?php echo $device[$row['name']]; ?>"><?php
                } elseif ($row['name'] == 'modeWhenCreditconsumed') {
                    ?>
<div><input type="radio" class="shadow" <?php if ($device['modeWhenCreditconsumed'] == 3) {?> checked="checked" <?php } ?> id="status1" name="modeWhenCreditconsumed" value=3> <label for="status1">Yes</label></div>
<div><input type="radio" class="shadow" <?php if ($device['modeWhenCreditconsumed'] != 3) {?> checked="checked" <?php } ?> id="status0" name="modeWhenCreditconsumed" value=2> <label for="status0">No (Block internet)</label></div>
                <?php
                } elseif ($row['name'] == 'requireLogin') {
                    ?>
<div><input x-model="requireLogin" type="radio" class="shadow" <?php if ($device['requireLogin'] == 1) {?> checked="checked" <?php } ?> id="status1" name="requireLogin" value=1> <label for="status1">Yes</label></div>
<div><input x-model="requireLogin" type="radio" class="shadow" <?php if ($device['requireLogin'] == 0) {?> checked="checked" <?php } ?> id="status0" name="requireLogin" value=0> <label for="status0">No</label></div>
<?php
                } elseif (in_array($row['name'], ['MonCredit','TueCredit','WedCredit','ThuCredit','FriCredit','SatCredit','SunCredit'])) {
                    ?>
<select class="px-1 border border shadow" name="<?php echo $row['name']; ?>">
                  <?php foreach ([
                    ['text'=>'No credit', 'value'=>0],
                    ['text'=>'30 minutes', 'value'=>30],
                    ['text'=>'1 hour', 'value'=>60],
                    ['text'=>'2 hours', 'value'=>120],
                    ['text'=>'3 hours', 'value'=>180],
                    ['text'=>'4 hours', 'value'=>240],
                    ['text'=>'5 hours', 'value'=>300],
                    ['text'=>'6 hours', 'value'=>360],
                    ['text'=>'7 hours', 'value'=>420],
                    ['text'=>'8 hours', 'value'=>480],
                    ['text'=>'9 hours', 'value'=>540],
                    ['text'=>'10 hours', 'value'=>600],
                    ['text'=>'14 hours', 'value'=>840],
                    ['text'=>'15 hours', 'value'=>900],
                    ['text'=>'16 hours', 'value'=>960],
                  ] as $option) {?>
                  <option value="<?php echo $option['value'];?>" <?php if ($device[$row['name']] == $option['value']) {?>selected="selected"<?php } ?>><?php echo $option['text'];?></option>
                  <?php } ?>
                </select>
                <?php
                } elseif ($row['name'] == 'mode') {
                    ?>
<select x-model="mode" class="px-1 border border shadow" name="mode">
                  <option value="1" <?php if ($device['mode'] == 1) {?>selected="selected"<?php } ?>>Allow Internet</option>
                  <option value="2" <?php if ($device['mode'] == 2) {?>selected="selected"<?php } ?>>Block Internet</option>
                  <option value="3" <?php if ($device['mode'] == 3) {?>selected="selected"<?php } ?>>Slow Internet</option>
                  <option value="4" <?php if ($device['mode'] == 4) {?>selected="selected"<?php } ?>>Schedule Internet</option>
                </select>
                <?php
                } elseif ($row['name'] == 'deviceType_id' || $row['name'] == 'user_id' || $row['name'] == 'bandwidth') {
                    $value = 0;
                    $Optionsrows = [];
                    if ($row['name'] == 'deviceType_id') {
                        if ($device['deviceType_id']) {
                            $value = $deviceTypes[$device['deviceType_id']]['id'];
                        }
                        $Optionsrows = $deviceTypes;
                    } elseif ($row['name'] == 'user_id') {
                        if ($device['user_id']) {
                            $value = $users[$device['user_id']]['id'];
                        }
                        $Optionsrows = $users;
                    } elseif ($row['name'] == 'bandwidth') {
                        $value = $config['device.new.bandwidth'];
                        if ($device['bandwidth']) {
                            $value = $bandwidths[$device['bandwidth']]['id'];
                        }
                        $Optionsrows = $bandwidths;
                    } ?>
<select class="px-1 border border shadow" name="<?php echo $row['name']; ?>">
                  <option value="">-</option>
                  <?php
                  foreach ($Optionsrows as $Optionrow) {
                      ?>
                  <option <?php if ($value == $Optionrow['id']) {?>selected="selected" <?php } ?> value="<?php echo $Optionrow['id']; ?>"><?php echo $Optionrow['name']; ?></option>
                  <?php
                  } ?>
                </select>
                <?php
                } elseif ($row['name'] == 'created_at' || $row['name'] == 'updated_at') {
                    echo timeAgo($device[$row['name']]);
                } elseif ($row['name'] == 'availableCredit') {
                    if ($device['availableCredit']<60) {
                        echo $device['availableCredit'] . ' minutes';
                    } else {
                        echo $device['availableCredit']/60 . ' hour(s)';
                    }
                } else {
                    echo $device[$value];
                }
                ?>
</td>
            </tr>
            <?php } ?>
            <tr x-cloak class="text-left"  x-transition x-show="mode == 4">
              <td colspan="2">
                <div class="text-xl font-bold py-4">Schedule Internet</div>
                <hr class="pb-2">
              </td>
            </tr>
            <tr x-cloak class="text-left" x-transition x-show="mode == 4">
              <td colspan="2">
                <table class="table-auto w-full text-sm text-center">
                  <tr class="">
                    <td class="font-bold border border-black">Hour</td>
                    <?php foreach (['Mon','Tue','Wed','Thu','Fri','Sat','Sun'] as $weekname) {?>
                    <td @click="if(schCell['<?php echo $weekname;?>0']===undefined){schCell['<?php echo $weekname;?>0']=1}else if(schCell['<?php echo $weekname;?>0']==3){schCell['<?php echo $weekname;?>0']=1}else{schCell['<?php echo $weekname;?>0']++}for(let i = 1; i < 24; i++){schCell['<?php echo $weekname;?>'+i]=schCell['<?php echo $weekname;?>0'];}" class="select-none cursor-pointer font-bold border border-black"><?php echo $weekname;?></td>
                    <?php }?>
                  </tr>
                  <?php
                  for ($hour=0; $hour < 24; $hour++) {
                      $h12Format = $hour;
                      if ($h12Format == 0) {
                          $h12Format = '12AM';
                      } elseif ($h12Format <= 11) {
                          $h12Format .= 'AM';
                      } elseif ($h12Format ==12) {
                          $h12Format = '12PM';
                      } elseif ($h12Format >12) {
                          $h12Format = ($h12Format -12) . 'PM';
                      } ?>
                  <tr class="border border-black">
                    <td class="font-bold select-none cursor-pointer" @click="if(schCell['Mon<?php echo $hour;?>']===undefined){schCell['Mon<?php echo $hour;?>']=1}else if(schCell['Mon<?php echo $hour;?>']==3){schCell['Mon<?php echo $hour;?>']=1}else{schCell['Mon<?php echo $hour;?>']++} schCell['Tue<?php echo $hour;?>']=schCell['Mon<?php echo $hour;?>'];schCell['Wed<?php echo $hour;?>']=schCell['Mon<?php echo $hour;?>'];schCell['Thu<?php echo $hour;?>']=schCell['Mon<?php echo $hour;?>'];schCell['Fri<?php echo $hour;?>']=schCell['Mon<?php echo $hour;?>']; schCell['Sat<?php echo $hour;?>']=schCell['Mon<?php echo $hour;?>']; schCell['Sun<?php echo $hour;?>']=schCell['Mon<?php echo $hour;?>']"><?php echo $h12Format; ?></td>
                    <?php foreach (['Mon','Tue','Wed','Thu','Fri','Sat','Sun'] as $weekname) {
                      $schCell = $weekname.$hour;
                    ?>
                    <td class="select-none cursor-pointer border border-black" :class="{'bg-green-600': schCell['<?php echo $schCell;?>']==1,'bg-red-500': schCell['<?php echo $schCell;?>']==2, 'bg-yellow-300': schCell['<?php echo $schCell;?>']==3}" x-init="if(schCell['<?php echo $schCell;?>']===undefined){schCell['<?php echo $schCell;?>']=2}" @click="if(schCell['<?php echo $schCell;?>']==3){schCell['<?php echo $schCell;?>']=1}else{schCell['<?php echo $schCell;?>']++}">
                    <span x-html="if(schCell['<?php echo $schCell;?>']==1){return 'Allow';}else if(schCell['<?php echo $schCell;?>']==3){return 'Limit';}else{return 'Block';}"></span>
                    <input x-model="schCell['<?php echo $schCell;?>']" type="hidden" name="hour[<?php echo $weekname;?>][<?php echo $hour; ?>]">
                  </td>
                    <?php } ?>
                  </tr>
                  <?php
                  }?>
                </table>
              </td>
            </tr>
          </tbody>
        </table>
        <div x-cloak class="py-5 text-center"><input type="submit"
            class="px-5 py-2 mx-auto bg-blue-500 hover:bg-blue-600 cursor-pointer text-lg font-bold text-white shadow-md rounded-full"
            value="Save"></div>
      </form>
    </div>
  </div>

</section>
<?php
require_once 'html/footer.php';

function saveDeviceForm($data){
  global $dblink, $weekDays;

  $schedule = false;
  $sqlValues = [
    ':id'=>$data['id'],
    ':name'=>$data['name'],
    ':user_id'=>($data['user_id']) ? $data['user_id'] : null,
    ':deviceType_id'=>($data['deviceType_id']) ? $data['deviceType_id'] : null,
    ':mode'=>$data['mode'],
    ':stage'=>2,
  ];
  $sqlValuesExtra = [];
  $sql = 'UPDATE devices SET stage=:stage,name=:name,user_id=:user_id,deviceType_id=:deviceType_id,mode=:mode %extraSets% WHERE id=:id';

  if($data['mode']==1){ //Allow
  }elseif($data['mode']==2){ //Block
  }elseif($data['mode']==3){ //Slow
    $sqlValuesExtra['bandwidth'] = $data['bandwidth'];
  }elseif($data['mode']==4 && $data['requireLogin'] == 0){ //mode 4 && requireLogin=0
    $schedule = true;
    $sqlValuesExtra['bandwidth'] = $data['bandwidth'];
    $sqlValuesExtra['requireLogin'] = $data['requireLogin'];
  }elseif($data['mode']==4 && $data['requireLogin'] == 1){ //mode 4 && requireLogin=1
    $schedule = true;
    $sqlValuesExtra['bandwidth'] = $data['bandwidth'];
    $sqlValuesExtra['requireLogin'] = $data['requireLogin'];
    $sqlValuesExtra['MonCredit'] = $data['MonCredit'];
    $sqlValuesExtra['TueCredit'] = $data['TueCredit'];
    $sqlValuesExtra['WedCredit'] = $data['WedCredit'];
    $sqlValuesExtra['ThuCredit'] = $data['ThuCredit'];
    $sqlValuesExtra['FriCredit'] = $data['FriCredit'];
    $sqlValuesExtra['SatCredit'] = $data['SatCredit'];
    $sqlValuesExtra['SunCredit'] = $data['SunCredit'];
    $sqlValuesExtra['modeWhenCreditconsumed'] = $data['modeWhenCreditconsumed'];
  }
  $extraSets = null;
  if($sqlValuesExtra){
    foreach($sqlValuesExtra as $name=>$value){
      $extraSets .= ',' . $name . '=:' . $name;
      $sqlValues[':'.$name] = $value;
    }
  }
  $sql = str_replace('%extraSets%',$extraSets,$sql);
  $sth = $dblink->prepare($sql);
  $sth->execute($sqlValues);

  if($schedule){
    $sth = $dblink->prepare('DELETE FROM schedule WHERE device_id=:device_id');
    $sth->execute([':device_id' => $data['id']]);
    $sthInsert = $dblink->prepare('INSERT INTO schedule (device_id,hour,weekday,mode) VALUES(:device_id,:hour,:weekday,:mode)');

    foreach($data['hour'] as $weekdayName => $hours){
      $weekDay = $weekDays[$weekdayName];
      for($hour=0;$hour<24;$hour++){
        if($hours[$hour]==2) continue;
        $sthInsert->execute([':device_id' => $data['id'],':hour' => $hour,':weekday' => $weekDay,':mode' => $hours[$hour]]);
      }
    }
  }

  // print "<xmp>";
  // print_r($data);
  // print "</xmp>";
  // print $sql . "<br>";
  // exit;

}