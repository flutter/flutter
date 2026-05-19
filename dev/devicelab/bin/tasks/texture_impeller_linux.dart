// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<TaskResult> run() async {
  deviceOperatingSystem = DeviceOperatingSystem.linux;

  final Directory appDir = dir(path.join(flutterDirectory.path, 'examples/texture'));

  var res = TaskResult.success(null);

  try {
    await inDirectory(appDir, () async {
      await flutter('packages', options: <String>['get']);

      final Process process = await startFlutter(
        'run',
        options: <String>['--enable-impeller', '-d', 'linux'],
      );

      final completer = Completer<void>();
      var sawImpellerBackendMessage = false;
      const vulkanBackendMessage = 'Using the Impeller rendering backend (Vulkan).';
      const openGLBackendMessage = 'Using the Impeller rendering backend (OpenGL).';

      final StreamSubscription<String> subscription = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
            print('[STDOUT]: $line');
            if (line.contains(vulkanBackendMessage) || line.contains(openGLBackendMessage)) {
              sawImpellerBackendMessage = true;
              if (!completer.isCompleted) {
                completer.complete();
              }
            }
          });

      await Future.any(<Future<void>>[
        completer.future,
        Future<void>.delayed(const Duration(minutes: 2)),
      ]);

      process.stdin.writeln('q');
      final int exitCode = await process.exitCode;
      await subscription.cancel();

      if (exitCode != 0) {
        res = TaskResult.failure('Flutter process exited with non-zero exit code: $exitCode');
      } else if (!sawImpellerBackendMessage) {
        res = TaskResult.failure(
          'Did not see "$vulkanBackendMessage" or '
          '"$openGLBackendMessage" in output',
        );
      }
    });
  } catch (e) {
    res = TaskResult.failure('Test failed with exception: $e');
  }

  return res;
}

Future<void> main() async {
  await task(run);
}
