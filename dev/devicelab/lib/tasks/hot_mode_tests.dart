// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/utils.dart';

TaskFunction createHotModeTest({ bool isPreviewDart2: false }) {
  return () async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final Directory appDir =
    dir(path.join(flutterDirectory.path, 'examples/flutter_gallery'));
    final File benchmarkFile = file(path.join(appDir.path, 'hot_benchmark.json'));
    rm(benchmarkFile);
    final List<String> options = <String>[
      '--hot', '-d', device.deviceId, '--benchmark', '--verbose'
    ];
    if (isPreviewDart2)
      options.add('--preview-dart-2');
    await inDirectory(appDir, () async {
      return await flutter('run', options: options, canFail: false);
    });
    return new TaskResult.successFromFile(benchmarkFile,
        benchmarkScoreKeys: <String>[
          'hotReloadInitialDevFSSyncMilliseconds',
          'hotReloadMillisecondsToFrame',
          'hotRestartMillisecondsToFrame',
          'hotReloadDevFSSyncMilliseconds',
          'hotReloadFlutterReassembleMilliseconds',
          'hotReloadVMReloadMilliseconds',
        ]);
  };
}
