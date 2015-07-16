// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_controller_service_isolate;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:vmservice';

part 'loader.dart';
part 'resources.dart';
part 'server.dart';

// The TCP ip/port that the HTTP server listens on.
int _port;
String _ip;
// Should the HTTP server auto start?
bool _autoStart;

// HTTP server.
Server server;

_onShutdown() {
  if (server != null) {
    server.close(true).catchError((e, st) {
      print(e);
    }).whenComplete(_shutdown);
  } else {
    _shutdown();
  }
}

void _bootServer() {
  // Load resources.
  _triggerResourceLoad();
  // Lazily create service.
  var service = new VMService();
  service.onShutdown = _onShutdown;
  // Lazily create server.
  server = new Server(service, _ip, _port);
}

main() {
  if (_autoStart) {
    _bootServer();
    if (server != null) {
      server.startup();
    }
  }
  scriptLoadPort.handler = _processLoadRequest;
  // It's just here to push an event on the event loop so that we invoke the
  // scheduled microtasks.
  Timer.run(() {});
  return scriptLoadPort;
}

_shutdown() native "ServiceIsolate_Shutdown";
