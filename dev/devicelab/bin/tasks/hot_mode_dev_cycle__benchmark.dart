// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

void main() {
  task(() async {
    Device device = await devices.workingDevice;
    await device.unlock();
    Directory appDir =
        dir(path.join(flutterDirectory.path, 'examples/flutter_gallery'));
    File benchmarkFile = file(path.join(appDir.path, 'hot_benchmark.json'));
    rm(benchmarkFile);
    await inDirectory(appDir, () async {
      return await flutter('run',
          options: <String>['--hot', '-d', device.deviceId, '--benchmark'],
          canFail: false);
    });
    return new TaskResult.successFromFile(benchmarkFile,
        benchmarkScoreKeys: <String>[
          'hotReloadMillisecondsToFrame',
          'hotRestartMillisecondsToFrame'
        ]);
  });
}
