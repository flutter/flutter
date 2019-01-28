// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/codegen'));
    final Map<String, dynamic> data = <String, dynamic>{};
    final int exitCode = await inDirectory<int>(appDir, () async {
      final Process cleanUp = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['clean', '-v'],
        environment: <String, String>{
          'FLUTTER_EXPERIMENTAL_BUILD': 'true',
        },
      );
      if (await cleanUp.exitCode != 0) {
        return 1;
      }
      final Stopwatch stopwatch = Stopwatch()..start();
      final Process generate = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['generate', '-v'],
        environment: <String, String>{
          'FLUTTER_EXPERIMENTAL_BUILD': 'true',
        },
      );
      if (await generate.exitCode != 0) {
        return 1;
      }
      stopwatch.stop();
      data['full_codegen_ms'] = stopwatch.elapsedMilliseconds;
      stopwatch
        ..reset()
        ..start();
      final Process incrementalGenerate = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['generate', '-v'],
        environment: <String, String>{
          'FLUTTER_EXPERIMENTAL_BUILD': 'true',
        },
      );
      if (await incrementalGenerate.exitCode != 0) {
        return 1;
      }
      data['incremental_codegen_ms'] = stopwatch.elapsedMilliseconds;
      return 0;
    });
    return exitCode == 0
        ? TaskResult.success(data, benchmarkScoreKeys: const <String>[
            'incremental_codegen_ms',
            'full_codegen_ms',
          ])
        : TaskResult.failure('Codegeneration failed');
  });
}
