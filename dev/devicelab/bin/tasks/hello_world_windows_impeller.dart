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
  final String mainCppPath = path.join(appDir.path, 'windows', 'runner', 'main.cpp');
  final mainCppFile = File(mainCppPath);

  const impellerBackendMessage = 'Using the Impeller rendering backend (OpenGLESSDF).';

  var res = TaskResult.success(null);

  try {
    await inDirectory(appDir, () async {
      await flutter('packages', options: <String>['get']);

      // Step 1: Test using command line flag.
      {
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
              print('[STDOUT 1]: $line');
              if (line.contains(impellerBackendMessage)) {
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
          res = TaskResult.failure('Flutter process 1 exited with non-zero exit code: $exitCode');
          return;
        } else if (!sawImpellerBackendMessage) {
          res = TaskResult.failure('Did not see "$impellerBackendMessage" in output (Step 1)');
          return;
        }
      }

      // Step 2: Test using project flag.
      {
        if (!mainCppFile.existsSync()) {
          res = TaskResult.failure('main.cpp not found at $mainCppPath');
          return;
        }

        final String originalContent = mainCppFile.readAsStringSync();
        final String modifiedContent = originalContent.replaceFirst(
          'flutter::DartProject project(L"data");',
          'flutter::DartProject project(L"data");\n  project.set_impeller_switch(flutter::ImpellerSwitch::Enabled);',
        );
        if (modifiedContent == originalContent) {
          res = TaskResult.failure('Failed to modify main.cpp');
          return;
        }
        mainCppFile.writeAsStringSync(modifiedContent);

        // Run 'flutter run' without command-line flag --enable-impeller.
        final Process process = await startFlutter('run', options: <String>['-d', 'windows']);

        final completer = Completer<void>();
        var sawImpellerBackendMessage = false;

        final StreamSubscription<String> subscription = process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) {
              print('[STDOUT 2]: $line');
              if (line.contains(impellerBackendMessage)) {
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
          res = TaskResult.failure('Flutter process 2 exited with non-zero exit code: $exitCode');
          return;
        } else if (!sawImpellerBackendMessage) {
          res = TaskResult.failure('Did not see "$impellerBackendMessage" in output (Step 2)');
          return;
        }
      }
    });
  } catch (e) {
    res = TaskResult.failure('Test failed with exception: $e');
  } finally {
    if (mainCppFile.existsSync()) {
      await exec('git', <String>['checkout', mainCppPath]);
    }
  }

  return res;
}

Future<void> main() async {
  await task(run);
}
