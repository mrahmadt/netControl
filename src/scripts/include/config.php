<?php

define('__SCRIPT_DIR__', dirname(dirname(__FILE__)) );
define('__APP_DIR__', dirname(__SCRIPT_DIR__) );
define('__ETC_DIR__', __APP_DIR__  . '/etc');

require_once __SCRIPT_DIR__ . '/include/functions.php';

$dblink = new \PDO("sqlite:" . __ETC_DIR__ . '/home.sqlite3');

$stmt = $dblink->query('SELECT * FROM config');
$config = [];
while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
    $config[$row['name']] = $row['value'];
}

