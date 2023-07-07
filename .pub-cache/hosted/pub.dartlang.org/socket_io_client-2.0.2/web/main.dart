import 'dart:async';
/**
 * main.dart
 *
 * Purpose:
 *
 * Description:
 *
 * History:
 *   26/07/2017, Created by jumperchen
 *
 * Copyright (C) 2017 Potix Corporation. All Rights Reserved.
 */
import 'package:socket_io_client/socket_io_client.dart' as io;

void main() {
  var socket = io.io('http://localhost:3000');
  socket.on('connect', (_) {
    print('connect');
    socket.emit('msg', 'init');
    var count = 0;
    Timer.periodic(const Duration(seconds: 1), (Timer countDownTimer) {
      socket.emit('msg', count++);
    });
  });
  socket.on('event', (data) => print(data));
  socket.on('disconnect', (_) => print('disconnect'));
  socket.on('fromServer', (_) => print(_));
}
