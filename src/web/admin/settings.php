<?php
  require_once 'validLogin.php';

  define('PAGE_TITLE', 'Settings');
  require_once 'html/header.php';
  require_once 'html/menu.php';

$bandwidths = getBandwidths();
// $sth = $dblink->prepare('SELECT devices.*,users.name as user_name,deviceTypes.name as TypeName FROM devices LEFT JOIN users ON (users.id=devices.user_id) LEFT JOIN deviceTypes ON (deviceTypes.id=devices.deviceType_id)');
// $sth->execute();
// $devices = $sth->fetchAll(PDO::FETCH_ASSOC);
if (isset($_POST['system_status'])) {
    $new_config = [
    'device.new.mode' => $_POST['device_new_mode'],
    'device.new.bandwidth' => $_POST['device_new_bandwidth'],
    'system.status' => $_POST['system_status'],
  ];

    if ($new_config['system.status'] != $config['system.status']) {
        if ($new_config['system.status'] == 1) {
            execCmd(__SCRIPT_DIR__ . '/enable.sh');
        } else {
            execCmd(__SCRIPT_DIR__ . '/disable.sh');
        }
    }


    $sql = 'UPDATE config SET value=:value WHERE name=:name';
    $stmt = $dblink->prepare($sql);

    foreach ($new_config as $name => $val) {
        $stmt->execute(['name'=>$name,'value'=>$val]);
        $config[$name] = $val;
    }
}

?>
<section class="py-4 px-4">
  <div class="container px-0 mx-auto">
    <div class="p-4 mb-6 bg-white shadow rounded ">
      <form action="settings.php" method="post">
        <table class="text-sm table-auto w-full">
          <tbody>
            <tr class="text-left">
              <td class="p-4">Enable/Disable System</td>
              <td>
                <div><input type="radio" class="shadow" <?php if ($config['system.status'] == 1) {?>
                  checked="checked" <?php }?> id="status1"
                  name="system_status" value=1> <label for="status1">Yes</label></div>
                <div><input type="radio" class="shadow" <?php if ($config['system.status'] == 0) {?>
                  checked="checked" <?php }?> id="status0"
                  name="system_status" value=0> <label for="status0">No</label></div>
              </td>
            </tr>


            <tr class="text-left">
              <td class="p-4">Default mode for new device</td>
              <td>
                <select name="device_new_mode" class="pl-5 shadow border w-full">
                  <?php foreach ([['id'=>1,'name'=>'Allow'],['id'=>2,'name'=>'Block'],['id'=>3,'name'=>'Limit']] as $mode) { ?>
                  <option <?php if ($config['device.new.mode'] == $mode['id']) {?>
                    selected="selected" <?php }?> value="<?php echo $mode['id'];?>"><?php echo $mode['name'];?>
                  </option>
                  <?php } ?>
                </select>
              </td>
            </tr>
            <tr class="text-left">
              <td class="p-4">Default speed for new device (if default mode is "limit")</td>
              <td>
                <select name="device_new_bandwidth" class="pl-5 shadow border w-full">
                  <?php foreach ($bandwidths as $bandwidth) { ?>
                  <option <?php if ($config['device.new.bandwidth'] == $bandwidth['id']) {?>
                    selected="selected" <?php }?> value="<?php echo $bandwidth['id'];?>"><?php echo $bandwidth['name'];?>
                  </option>
                  <?php } ?>
                </select>
              </td>
            </tr>

            <tr class="text-left">
              <td class="p-4">WAN Interface</td>
              <td><?php echo $config['wan.interface'];?>
              </td>
            </tr>
            <tr class="text-left">
              <td class="p-4">WAN IP Address</td>
              <td><?php echo $config['wan.ipaddr'];?>
              </td>
            </tr>
            <tr class="text-left">
              <td class="p-4">LAN Interface</td>
              <td><?php echo $config['lan.interface'];?>
              </td>
            </tr>
            <tr class="text-left">
              <td class="p-4">LAN IP Address</td>
              <td><?php echo $config['lan.ipaddr'];?>
              </td>
            </tr>
            <tr class="text-left">
              <td class="p-4">Portal URL</td>
              <td><?php echo $config['system.portal.ip'];?>
              </td>
            </tr>
            <tr class="text-left">
              <td class="p-4">DNS Server</td>
              <td><?php echo $config['lan.dnsserver1'];?>
              </td>
            </tr>
          </tbody>

        </table>
        <div class="py-5 text-center"><input type="submit"
            class="px-5 py-2 mx-auto bg-blue-500 hover:bg-blue-600 cursor-pointer text-lg font-bold text-white shadow-md rounded-full"
            value="Save"></div>
      </form>
    </div>
  </div>

</section>
<?php
  require_once 'html/footer.php';
