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
    const readyMarker = 'OPENBOX_READY';
    Process? wmProcess;
    try {
      final wmReady = Completer<void>();
      wmProcess = await startProcess('openbox', const <String>[
        '--sm-disable',
        '--startup',
        'echo $readyMarker',
      ]);
      wmProcess.stdout
          .transform<String>(const Utf8Decoder())
          .transform<String>(const LineSplitter())
          .listen((String line) {
            print('[openbox stdout] $line');
            if (line.contains(readyMarker) && !wmReady.isCompleted) {
              wmReady.complete();
            }
          });
      wmProcess.stderr
          .transform<String>(const Utf8Decoder())
          .transform<String>(const LineSplitter())
          .listen((String line) {
            print('[openbox stderr] $line');
          });
      unawaited(
        wmProcess.exitCode.then((_) {
          if (!wmReady.isCompleted) {
            wmReady.complete();
          }
        }),
      );
      await wmReady.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => print('Timed out waiting for openbox startup marker.'),
      );
    } on ProcessException catch (e) {
      print('Could not start openbox: $e');
    }
    try {
      return await createWindowingDriverTest()();
    } finally {
      wmProcess?.kill();
    }
  });
}
