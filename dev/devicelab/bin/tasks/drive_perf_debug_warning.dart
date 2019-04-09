// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

Future<TaskResult> run() async {
  cd('${flutterDirectory.path}/examples/flutter_gallery');
  final Device device = await devices.workingDevice;
  await device.unlock();
  final String deviceId = device.deviceId;
  await flutter('packages', options: <String>['get']);

  final String output = await evalFlutter('drive', options: <String>[
    '-t',
    'test_driver/scroll_perf.dart',
    '-d',
    deviceId,
  ]);

  const String warningPiece = 'THIS BENCHMARK IS BEING RUN IN DEBUG MODE';
  if (output.contains(warningPiece)) {
    return TaskResult.success(null);
  } else {
    return TaskResult.failure(
      'Could not find the following warning message piece: $warningPiece'
    );
  }
}

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(run);
}
