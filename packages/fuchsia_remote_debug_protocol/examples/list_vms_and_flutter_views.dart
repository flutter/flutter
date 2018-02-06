// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import 'package:logging/logging.dart';

import '../lib/fuchsia_remote_debug_protocol.dart';

/// Runs through a simple usage of the fuchsia_remote_debug_protocol library:
/// connects to a remote machine at the ipv4 address in argument 1 to list all
/// active flutter views and Dart VM's running on said device.
Future<Null> main(List<String> args) async {
  // Sets up a basic logger to see what's happening.
  Logger.root.onRecord.listen((LogRecord rec) {
    print('[${rec.level.name}] -- ${rec.time}: ${rec.message}');
  });
  final String address = args[0];
  final String root = '../../';
  final String build = 'release-x86-64';
  print('On ${address}, the following Dart VM ports are running:');
  for (int port in await FuchsiaRemoteConnection.getDeviceServicePorts(
      address, root, build)) {
    print('\t$port');
  }
  print('');

  final FuchsiaRemoteConnection driver =
      await FuchsiaRemoteConnection.connect(address, root, build);
  print('The following Flutter views are running:');
  for (FlutterView view in await driver.getFlutterViews()) {
    print('\t${view.name ?? view.id}');
  }
  await driver.stop();
}
