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
    // This test requires a window manager in order to test out placement.
    // On a normal linux machine, you already have a window manager running -
    // GNOME, KDE, etc.  CICD requires us starting one.
    final windowManager = WindowManager();
    await windowManager.tryStart();

    try {
      return await createWindowingDriverTest()();
    } finally {
      windowManager.tryKill();
    }
  });
}

class WindowManager {
  static const readyMarker = 'OPENBOX_READY';

  Process? _process;

  Future<void> tryStart() async {
    try {
      final windowManagerReady = Completer<void>();

      final Process process = _process = await startProcess('openbox', const <String>[
        '--sm-disable',
        '--startup',
        'echo $readyMarker',
      ]);
      process.stdout
          .transform<String>(const Utf8Decoder())
          .transform<String>(const LineSplitter())
          .listen((String line) {
            stdout.writeln('[openbox stdout] $line');
            if (line.contains(readyMarker) && !windowManagerReady.isCompleted) {
              windowManagerReady.complete();
            }
          });
      process.stderr
          .transform<String>(const Utf8Decoder())
          .transform<String>(const LineSplitter())
          .listen((String line) {
            stderr.writeln('[openbox stderr] $line');
          });
      unawaited(
        process.exitCode.then((_) {
          if (!windowManagerReady.isCompleted) {
            windowManagerReady.complete();
          }
        }),
      );
      await windowManagerReady.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => print('Timed out waiting for openbox startup marker.'),
      );
    } on ProcessException catch (e) {
      // It is OK for this to fail - you may not have openbox on your system and
      // the test will continue to run. On CICD, the test will fail.
      stderr.writeln('Could not start openbox: $e');
    }
  }

  void tryKill() {
    _process?.kill();
  }
}
