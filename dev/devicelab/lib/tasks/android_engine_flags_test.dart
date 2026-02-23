// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/android_utils.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

typedef TestFunction = Future<TaskResult> Function();

TaskFunction androidEngineFlagsTest(String buildMode) {
  final isReleaseMode = buildMode == 'release';
  final List<TaskFunction> tests = [
    _testInvalidFlag(buildMode),
    if (isReleaseMode) _testIllegalFlagInReleaseMode(),
    if (!isReleaseMode) _testCommandLineFlagPrecedence(),
  ];

  return () async {
    final List<TaskResult> results = [];
    for (final test in tests) {
      final TaskResult result = await test();
      results.add(result);
      if (result.failed) {
        return result;
      }
    }

    return TaskResult.success(null);
  };
}

TaskFunction _testInvalidFlag(String buildMode) {
  return () async {
    section('Create new Flutter Android app');
    final Directory tempDir = Directory.systemTemp.createTempSync(
      'android_flutter_shell_args_test.',
    );
    const projectName = 'androidfluttershellargstest';

    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--platforms', 'android', '--org', 'io.flutter.devicelab', projectName],
        );
      });

      section('Insert metadata with valid and invalid flags into AndroidManifest.xml');
      final metadataKeyPairs = <(String, String)>[
        (
          'io.flutter.embedding.android.AOTSharedLibraryName',
          'something/completely/and/totally/invalid.so',
        ),
        ('io.flutter.embedding.android.ImpellerLazyShaderInitialization', 'true'),
      ];
      addMetadataToManifest(path.join(tempDir.path, projectName), metadataKeyPairs);

      section('Run Flutter Android app with modified manifest');
      final foundInvalidAotLibraryLog = Completer<bool>();
      late Process run;

      await inDirectory(path.join(tempDir.path, projectName), () async {
        run = await startFlutter('run', options: <String>['--$buildMode', '--verbose']);
      });

      final StreamSubscription<void> stdout = run.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            if (line.contains(
              "Skipping unsafe AOT shared library name flag: something/completely/and/totally/invalid.so. Please ensure that the library is vetted and placed in your application's internal storage.",
            )) {
              foundInvalidAotLibraryLog.complete(true);
            }
          });

      section('Check that warning log for invalid AOT shared library name is in STDOUT');
      final Object result = await Future.any(<Future<Object>>[
        foundInvalidAotLibraryLog.future,
        run.exitCode,
      ]);

      if (result is int) {
        throw Exception('flutter run failed, exitCode=$result');
      }

      section('Stop listening to STDOUT');
      await stdout.cancel();
      run.kill();

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };
}

TaskFunction _testIllegalFlagInReleaseMode() {
  return () async {
    section('Create new Flutter Android app');
    final Directory tempDir = Directory.systemTemp.createTempSync(
      'android_flutter_shell_args_test.',
    );
    const projectName = 'androidfluttershellargstest';

    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--platforms', 'android', '--org', 'io.flutter.devicelab', projectName],
        );
      });

      section('Insert metadata only allowed in release mode for testing into AndroidManifest.xml');
      final metadataKeyPairs = <(String, String)>[
        ('io.flutter.embedding.android.UseTestFonts', 'true'),
      ];
      addMetadataToManifest(path.join(tempDir.path, projectName), metadataKeyPairs);

      section('Run Flutter Android app with modified manifest');
      final foundUseTestFontsLog = Completer<bool>();
      late Process run;

      await inDirectory(path.join(tempDir.path, projectName), () async {
        run = await startFlutter('run', options: <String>['--release', '--verbose']);
      });

      final StreamSubscription<void> stdout = run.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            if (line.contains(
              'Flag with metadata key io.flutter.embedding.android.UseTestFonts is not allowed in release builds and will be ignored if specified in the application manifest or via the command line.',
            )) {
              foundUseTestFontsLog.complete(true);
            }
          });

      section('Check that warning log for disallowed UseTestFonts flag is in STDOUT');
      final Object result = await Future.any(<Future<Object>>[
        foundUseTestFontsLog.future,
        run.exitCode,
      ]);

      if (result is int) {
        throw Exception('flutter run failed, exitCode=$result');
      }

      section('Stop listening to STDOUT');
      await stdout.cancel();
      run.kill();

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };
}

TaskFunction _testCommandLineFlagPrecedence() {
  return () async {
    section('Create new Flutter Android app');
    final Directory tempDir = Directory.systemTemp.createTempSync(
      'android_flutter_shell_args_test.',
    );
    const projectName = 'androidfluttershellargstest';

    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--platforms', 'android', '--org', 'io.flutter.devicelab', projectName],
        );
      });

      section('Insert metadata for test flag into the manifest');
      final metadataKeyPairs = <(String, String?)>[('io.flutter.embedding.android.TestFlag', null)];

      addMetadataToManifest(path.join(tempDir.path, projectName), metadataKeyPairs);

      section('Run Flutter Android app with modified manifest and --test-flag');
      final commandLinePrecedenceCompleter = Completer<bool>();
      late Process run;

      await inDirectory(path.join(tempDir.path, projectName), () async {
        run = await startFlutter('run', options: <String>['--test-flag', '--verbose']);
      });

      final StreamSubscription<void> stdoutSubscription = run.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            if (commandLinePrecedenceCompleter.isCompleted) {
              return;
            } else if (line.contains(
              'For testing purposes only: test flag specified on the command line was loaded by the FlutterLoader.',
            )) {
              commandLinePrecedenceCompleter.complete(true);
            } else if (line.contains(
              'For testing purposes only: test flag specified in the manifest was loaded by the FlutterLoader.',
            )) {
              commandLinePrecedenceCompleter.complete(false);
            }
          });

      section('Check that the test flag logs are found in the expected order in STDOUT');
      final Future<bool> commandLinePrecedenceFuture = commandLinePrecedenceCompleter.future;
      final Object result = await Future.any(<Future<Object>>[
        commandLinePrecedenceFuture,
        run.exitCode,
      ]);

      if (result is int) {
        throw Exception('flutter run failed, exitCode=$result');
      } else if (result is bool) {
        if (!result) {
          throw Exception(
            'Test flag specified in the manifest unexpectedly took precedence over that specified on the command line.',
          );
        }
      }

      section('Kill the app');
      await stdoutSubscription.cancel();
      run.kill();
      await run.exitCode;

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };
}
