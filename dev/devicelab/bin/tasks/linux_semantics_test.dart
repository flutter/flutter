// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/integration_tests.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.linux;
  await task(() async {
    // The test inspects the app over AT-SPI, which requires a D-Bus session
    // bus. A desktop session has one, but CICD requires us starting one. The
    // accessibility bus is then started on demand via D-Bus activation.
    Process? dbusDaemon;
    final environment = <String, String>{};
    if (!Platform.environment.containsKey('DBUS_SESSION_BUS_ADDRESS')) {
      dbusDaemon = await startProcess('dbus-daemon', const <String>[
        '--session',
        '--nofork',
        '--print-address',
      ]);
      dbusDaemon.stderr
          .transform<String>(const Utf8Decoder())
          .transform<String>(const LineSplitter())
          .listen((String line) => stderr.writeln('[dbus-daemon stderr] $line'));
      environment['DBUS_SESSION_BUS_ADDRESS'] = await dbusDaemon.stdout
          .transform<String>(const Utf8Decoder())
          .transform<String>(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 5));
    }

    try {
      return await DriverTest(
        '${flutterDirectory.path}/dev/integration_tests/linux_semantics_testing',
        'lib/main.dart',
        environment: environment,
      ).call();
    } finally {
      dbusDaemon?.kill();
    }
  });
}
