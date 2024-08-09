// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

/// Smoke test of a task that fails by returning an unsuccessful response.
Future<void> main(List<String> arguments) async {
  final String stateFilePath = arguments[0];
  final io.File stateFile = io.File(stateFilePath);
  if (stateFile.existsSync()) {
    stateFile.deleteSync();
    await task(() async {
      return TaskResult.success(<String, String>{});
    });
  } else {
    print('adb: device offline');
    stateFile.createSync();
    await task(() async {
      return TaskResult.failure('Failed');
    });
  }
}
