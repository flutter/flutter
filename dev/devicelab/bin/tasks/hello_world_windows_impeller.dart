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
  deviceOperatingSystem = DeviceOperatingSystem.windows;

  final Directory appDir = dir(path.join(flutterDirectory.path, 'examples/hello_world'));

  var res = TaskResult.success(null);

  try {
    await inDirectory(appDir, () async {
      await flutter('packages', options: <String>['get']);

      final Process process = await startFlutter(
        'run',
        options: <String>['--enable-impeller', '-d', 'windows'],
      );

      final completer = Completer<void>();
      var sawImpellerBackendMessage = false;

      final StreamSubscription<String> subscription = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
            print('[STDOUT]: $line');
            if (line.contains('Using the Impeller rendering backend (OpenGLESSDF).')) {
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
      await process.exitCode;
      await subscription.cancel();

      if (!sawImpellerBackendMessage) {
        res = TaskResult.failure(
          'Did not see "Using the Impeller rendering backend (OpenGLESSDF)." in output',
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
