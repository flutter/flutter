// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/utils.dart';

Future<TaskResult> runDartDefinesTask() async {
  final Device device = await devices.workingDevice;
  await device.unlock();
  final String deviceId = device.deviceId;
  final Directory testDirectory = dir('${flutterDirectory.path}/dev/integration_tests/ui');
  await inDirectory<void>(testDirectory, () async {
    await flutter('packages', options: <String>['get']);

    await flutter('drive', options: <String>[
      '--verbose',
      '-d',
      deviceId,
      '--dart-define=test.valueA=Example',
      '--dart-define=test.valueB=Value',
      'lib/defines.dart',
    ]);
  });

  return TaskResult.success(<String, dynamic>{});
}
