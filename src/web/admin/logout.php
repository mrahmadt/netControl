<?php
   session_start();
   session_destroy();
   header('Location: /netcontrol-admin/login.php');
   exit;
?>