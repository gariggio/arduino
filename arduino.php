<?php
date_default_timezone_set('Europe/Rome');

$arduinoId = (intval($argv[1]) % 10) % 4;
echo "Arduino id = $arduinoId\n";


$port = 9876;
$broadcastIp = '192.168.0.255';
$remoteIp = '';
$remotePort = 0;

$messages = array('FREE', 'BUSY');

$socket = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP);
socket_set_option($socket, SOL_SOCKET, SO_BROADCAST, 1);
socket_bind($socket, $broadcastIp, $port);

$socket2 = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP);
socket_set_option($socket2, SOL_SOCKET, SO_BROADCAST, 1);

$sentTime = 0;

while (TRUE) {
	$read = array($socket);
	$write  = NULL;
	$except = NULL;
	$n = socket_select($read, $write, $except, 1);
	if ($n === FALSE) {
		echo "socket_select() failed, reason: " .  socket_strerror(socket_last_error()) . "\n";
		exit;
	} else if ($n > 0) {
		/* At least at one of the sockets something interesting happened */
		$bytes = socket_recvfrom($socket, $buffer, 65535, 0, $remoteIp, $remotePort);
		if ($buffer != $message) {
			echo date('d/m/Y H:i:s')." Received $remoteIp:$remotePort \"$buffer\"" . PHP_EOL;
		}
	} else {
	}

	$adesso = time();
	
	if ($adesso > $sentTime + 5) {
		// Invio dello stato
		$message = $arduinoId.$messages[rand(0,1)];
		socket_sendto($socket2, $message, strlen($message), MSG_EOR, $broadcastIp, $port);
		echo date('d/m/Y H:i:s')." Sent     $broadcastIp:$port \"$message\"" . PHP_EOL;
		$sentTime = $adesso;
	}
}
socket_close($socket);
socket_close($socket2);

