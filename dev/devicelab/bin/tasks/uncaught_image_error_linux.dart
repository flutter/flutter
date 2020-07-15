// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(() async {
    return inDirectory<TaskResult>('${flutterDirectory.path}/dev/integration_tests/image_loading', () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);
      bool passed = false;

      final List<String> options = <String>[
        '-v',
        '-t',
        'lib/main.dart',
        '-d',
        deviceId,
      ];
      final Process process = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['run', ...options],
      );

      final Stream<String> lines = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());

      await for (final String line in lines) {
        print(line);
        if (line.contains('ERROR caught by framework')) {
          passed = true;
          break;
        }
        if (line.contains('EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ')) {
          passed = false;
          break;
        }
      }
      if (passed) {
        return TaskResult.success(null);
      } else {
        return TaskResult.failure('Failed to catch sync error in image loading.');
      }
    });
  });
}
