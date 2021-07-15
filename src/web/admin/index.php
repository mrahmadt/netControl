<?php
  require_once 'validLogin.php';

  define('PAGE_TITLE','Devices');
  require_once 'html/header.php';
  require_once 'html/menu.php';
//TODO: option to hide some devices

$bandwidths = getBandwidths();
$sth = $dblink->prepare('SELECT devices.*,users.name as user_name,deviceTypes.name as TypeName FROM devices LEFT JOIN users ON (users.id=devices.user_id) LEFT JOIN deviceTypes ON (deviceTypes.id=devices.deviceType_id) ORDER BY updated_at DESC');
$sth->execute();
$devices = $sth->fetchAll(PDO::FETCH_ASSOC);
?>
      <section class="py-4 px-4">
        <div class="container px-0 mx-auto">
        <?php
if($config['system.status'] == '0'){
?>
<div class="bg-red-500 text-white text-center py-2 mb-4">netConnect is disabled!, go to settings to enable it,</div>
<?php } ?>

          <div class="p-4 mb-6 bg-white shadow rounded ">
            <table class="table-auto w-full">
              <thead>
                <tr class="text-sm text-gray-500 text-center">
                  <th class="pb-3 font-medium"></th>
                  <th class="pb-3 font-medium">Device</th>
                  <th class="pb-3 font-medium">User</th>
                  <th class="pb-3 font-medium hidden lg:inline-block">Type</th>
                  <th class="pb-3 font-medium">Mode</th>
                  <th class="pb-3 font-medium hidden md:inline-block">Last Seen</th>
                  <th class="pb-3 font-medium">Action</th>
                </tr>
              </thead>
              <tbody>
                <?php 
                $bgColor = null;
                foreach($devices as $device){
                  $bgColor = ($bgColor=='bg-gray-100') ? 'bg-white' : 'bg-gray-100';
                  $modeText = 0;
                  $modeTitle = null;
                  $onlineText = null;
                  $onlineClass = null;
                  if($device['mode'] == 1){
                    $modeText = 'Allow';
                  }elseif($device['mode'] == 2){
                    $modeText = 'Block';
                  }elseif($device['mode'] == 3){
                    $modeText = 'Limit';
                    $rate = '1mbit';
                    if($device['bandwidth']) $rate = $bandwidths[$device['bandwidth']]['tcrate'];
                    $modeTitle = "Speed: " . $rate;
                  }elseif($device['mode'] == 4){
                    $modeText = 'Schedule';
                    $availableCredit = null;
                    $modeTitle = "Require login: " . ($device['requireLogin'] ? 'Yes' : 'No') . "\n";
                    if($device['availableCredit']){
                      if($device['availableCredit']<60){
                        $availableCredit = $device['availableCredit'] . ' minutes';
                      }else{
                        $availableCredit = $device['availableCredit']/60 . ' hour(s)';
                      }   
                    }
                    if($device['requireLogin'] && $device['Is_loggedIn']) {
                      $onlineText =  $availableCredit; 
                      $onlineClass = 'text-xs rounded-full px-1 py-1 text-white bg-green-500';
                      $modeTitle .= "Online: Yes\nRemaining Credit: " . $onlineText;
                    }elseif($device['requireLogin'] && $device['Is_loggedIn']==0) {
                      $onlineClass = 'text-xs rounded-full px-1 py-1 text-white bg-gray-400';
                      $onlineText = $availableCredit;
                      $modeTitle .= "Online: No\nRemaining Credit: " . $onlineText;
                    }
                    
                  }
                  $statusBgColor='bg-gray-500';
                  $status = getStatusMode($device['id'],$device['macaddr']);
                  if ($status==2) {
                    $status = 'Blocked';
                    $statusBgColor='bg-red-500';
                  }elseif ($status==3) {
                    $status = 'Limited';
                    $statusBgColor='bg-yellow-500';
                  }else{
                    $status = 'Allowed';
                    $statusBgColor='bg-green-500';
                  }
                ?>
                  <tr class="text-sm <?php echo $bgColor; ?> text-center">
                    <td class="<?php echo $statusBgColor; ?> w-2" title="<?php echo $status; ?>"> </td>
                    <td class="py-5 font-medium" title="<?php echo 'Vendor: '.$device['manufacturer'] . "\n" . 'Host: '.$device['hostname']; ?>"><?php if($device['stage']<=1){ ?><span class="text-xs rounded-full px-1 py-1 italic font-bold text-white bg-red-500">New</span> <?php } ?><a class="cursor-pointer text-blue-600 hover:underline" href="/netcontrol-admin/devices.php?id=<?php echo $device['id']?>"><?php echo $device['name']; ?></a></td>
                    <td class="py-5 font-medium"><a class="cursor-pointer text-blue-600 hover:underline" href="/netcontrol-admin/users.php?id=<?php echo $device['user_id']; ?>"><?php echo $device['user_name']; ?></a></td>
                    <td class="py-5 font-medium hidden lg:inline-block"><?php echo $device['TypeName']; ?></td>
                    <td class="py-5 font-medium" title="<?php echo $modeTitle; ?>"><?php echo $modeText; if($onlineText){ ?><div class="<?php echo $onlineClass; ?>"><?php echo $onlineText; ?></div><?php } ?></td>
                    <td class="py-5 font-medium hidden md:inline-block <?php if(oldDate($device['updated_at'])){ ?> text-red-700 <?php } ?>" title="First Seen <?php echo timeAgo($device['created_at']); ?>"><?php echo timeAgo($device['updated_at']); ?></td>
                    <td>
                      <select onChange="window.document.location.href='deviceAction.php?id=<?php echo $device['id']; ?>&action='+this.options[this.selectedIndex].value;" name="action" class="w-5 md:w-full border shadow">
                        <option value="">-</option>
                        <optgroup label="Mode">
                          <option value="allow:0">Set to Allow</option>
                          <option value="block:0">Set to Block</option>
                          <option value="limit:0">Set to Limit</option>
                          <option value="schedule:0">Set to Schedule</option>
                        </optgroup>
                        <optgroup label="Allow">
                          <option value="allow:15">Allow for 15 minutes</option>
                          <option value="allow:30">Allow for 30 minutes</option>
                          <option value="allow:60">Allow for 1 hour</option>
                        </optgroup>
                        <optgroup label="Block">
                          <option value="block:15">Block for 15 minutes</option>
                          <option value="block:30">Block for 30 minutes</option>
                          <option value="block:60">Block for 1 hour</option>
                        </optgroup>
                        <optgroup label="Actions">
                          <option value="delete:d">Delete device</option>
                        </optgroup>
                      </select>
                    </td>
                  </tr>
                <?php } ?>
              </tbody>
            </table>
          </div>
          </div>

      </section>
<?php require_once 'html/footer.php'; ?>

