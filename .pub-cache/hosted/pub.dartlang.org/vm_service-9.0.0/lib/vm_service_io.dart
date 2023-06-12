// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'vm_service.dart';

@Deprecated('Prefer vmServiceConnectUri')
Future<VmService> vmServiceConnect(String host, int port, {Log? log}) async {
  final WebSocket socket = await WebSocket.connect('ws://$host:$port/ws');
  final StreamController<dynamic> controller = StreamController();
  final Completer streamClosedCompleter = Completer();

  socket.listen(
    (data) => controller.add(data),
    onDone: () => streamClosedCompleter.complete(),
  );

  return VmService(
    controller.stream,
    (String message) => socket.add(message),
    log: log,
    disposeHandler: () => socket.close(),
    streamClosed: streamClosedCompleter.future,
  );
}

/// Connect to the given uri and return a new [VmService] instance.
Future<VmService> vmServiceConnectUri(String wsUri, {Log? log}) async {
  final WebSocket socket = await WebSocket.connect(wsUri);
  final StreamController<dynamic> controller = StreamController();
  final Completer streamClosedCompleter = Completer();

  socket.listen(
    (data) => controller.add(data),
    onDone: () => streamClosedCompleter.complete(),
  );

  return VmService(
    controller.stream,
    (String message) => socket.add(message),
    log: log,
    disposeHandler: () => socket.close(),
    streamClosed: streamClosedCompleter.future,
  );
}
