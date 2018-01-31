// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Provides an API to test Flutter applications on Fuchsia devices and
/// emulators.
///
/// The application runs in a separate process from the actual test.

import 'dart:async';
import 'dart:core';

import 'package:logging/logging.dart';

import '../flutter_fuchsia.dart';

/// Runs through a simple usage of the flutter_fuchsia library: connects to a
/// remote machine at the ipv4 address in argument 1 to list all active flutter
/// views running on fuchsia.
Future<Null> main(List<String> args) async {
  // Sets up a basic logger to see what's happening.
  Logger.root.onRecord.listen((LogRecord rec) {
    print('[${rec.level.name}] -- ${rec.time}: ${rec.message}');
  });
  final String address = args[0];
  final String root = '../../';
  final String build = 'release-x86-64';
  print('On ${address}, the following Dart VM ports are running:');
  for (int port in await FlutterFuchsiaDriver.getDeviceServicePorts(
      address, root, build)) {
    print('\t$port');
  }
  print('');

  final FlutterFuchsiaDriver driver =
      await FlutterFuchsiaDriver.connect(address, root, build);
  print('The following Flutter views are running:');
  for (FuchsiaFlutterView view in await driver.getFlutterViews()) {
    print('\t${view.name ?? view.id}');
  }
  await driver.stop();
}
