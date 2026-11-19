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

  final Directory appDir = dir(path.join(flutterDirectory.path, 'examples/hello_world'));
  final String myApplicationPath = path.join(appDir.path, 'linux', 'runner', 'my_application.cc');
  final myApplicationFile = File(myApplicationPath);

  const vulkanBackendMessage = 'Using the Impeller rendering backend (VulkanSDF).';
  const openGLBackendMessage = 'Using the Impeller rendering backend (OpenGLESSDF).';

  var res = TaskResult.success(null);

  try {
    await inDirectory(appDir, () async {
      await flutter('packages', options: <String>['get']);

      // Step 1: Test using default (should be enabled).
      {
        final Process process = await startFlutter('run', options: <String>['-d', 'linux']);

        final completer = Completer<void>();
        var sawImpellerBackendMessage = false;

        final StreamSubscription<String> subscription = process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) {
              print('[STDOUT 1]: $line');
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
          res = TaskResult.failure('Flutter process 1 exited with non-zero exit code: $exitCode');
          return;
        } else if (!sawImpellerBackendMessage) {
          res = TaskResult.failure(
            'Did not see "$vulkanBackendMessage" or '
            '"$openGLBackendMessage" in output (Step 1)',
          );
          return;
        }
      }

      // Step 2: Test disabling using project flag.
      {
        if (!myApplicationFile.existsSync()) {
          res = TaskResult.failure('my_application.cc not found at $myApplicationPath');
          return;
        }

        final String originalContent = myApplicationFile.readAsStringSync();
        final String modifiedContent = originalContent.replaceFirst(
          'g_autoptr(FlDartProject) project = fl_dart_project_new();',
          'g_autoptr(FlDartProject) project = fl_dart_project_new();\n  fl_dart_project_set_enable_impeller(project, FALSE);',
        );
        if (modifiedContent == originalContent) {
          res = TaskResult.failure('Failed to modify my_application.cc');
          return;
        }

        try {
          myApplicationFile.writeAsStringSync(modifiedContent);

          // Run 'flutter run' without command-line flag.
          final Process process = await startFlutter('run', options: <String>['-d', 'linux']);

          final completer = Completer<void>();
          var sawImpellerBackendMessage = false;
          var sawVMServiceMessage = false;

          final StreamSubscription<String> subscription = process.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen((String line) {
                print('[STDOUT 2]: $line');
                if (line.contains(vulkanBackendMessage) || line.contains(openGLBackendMessage)) {
                  sawImpellerBackendMessage = true;
                }
                if (line.contains('The Dart VM service is listening on') ||
                    line.contains('A Dart VM Service')) {
                  sawVMServiceMessage = true;
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
          } else if (sawImpellerBackendMessage) {
            res = TaskResult.failure(
              'Saw "$vulkanBackendMessage" or '
              '"$openGLBackendMessage" in output but Impeller should be disabled (Step 2)',
            );
            return;
          } else if (!sawVMServiceMessage) {
            res = TaskResult.failure('Did not see VM Service message (Step 2)');
            return;
          }
        } finally {
          myApplicationFile.writeAsStringSync(originalContent);
        }
      }

      // Step 3: Test disabling using command line flag.
      {
        final Process process = await startFlutter(
          'run',
          options: <String>['--no-enable-impeller', '-d', 'linux'],
        );

        final completer = Completer<void>();
        var sawImpellerBackendMessage = false;
        var sawVMServiceMessage = false;

        final StreamSubscription<String> subscription = process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) {
              print('[STDOUT 3]: $line');
              if (line.contains(vulkanBackendMessage) || line.contains(openGLBackendMessage)) {
                sawImpellerBackendMessage = true;
              }
              if (line.contains('The Dart VM service is listening on') ||
                  line.contains('A Dart VM Service')) {
                sawVMServiceMessage = true;
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
          res = TaskResult.failure('Flutter process 3 exited with non-zero exit code: $exitCode');
          return;
        } else if (sawImpellerBackendMessage) {
          res = TaskResult.failure(
            'Saw "$vulkanBackendMessage" or '
            '"$openGLBackendMessage" in output but Impeller should be disabled (Step 3)',
          );
          return;
        } else if (!sawVMServiceMessage) {
          res = TaskResult.failure('Did not see VM Service message (Step 3)');
          return;
        }
      }
    });
  } catch (e) {
    res = TaskResult.failure('Test failed with exception: $e');
  } finally {
    if (myApplicationFile.existsSync()) {
      await exec('git', <String>['checkout', myApplicationPath]);
    }
  }

  return res;
}

Future<void> main() async {
  await task(run);
}
