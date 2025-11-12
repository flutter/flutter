// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';
import 'android_utils.dart';

TaskFunction androidFlutterShellArgsTest() {
  return () async {
    section('Create new Flutter Android app');
    final Directory tempDir = Directory.systemTemp.createTempSync(
      'android_flutter_shell_args_test.',
    );

    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--platforms',
            'android',
            '--org',
            'io.flutter.devicelab',
            'androidfluttershellargstest',
          ],
        );
      });

      section('Insert metadata for testing into AndroidManifest.xml');
      final List<(String, String)> metadataKeyPairs = <(String, String)>[
        (
          'io.flutter.embedding.android.AOTSharedLibraryName',
          'something/completely/and/totally/invalid.so',
        ),
        ('io.flutter.embedding.android.UseTestFonts', 'true'),
      ];
      addMetadataToManifest(
        path.join(tempDir.path, 'androidfluttershellargstest'),
        metadataKeyPairs,
      );

      section('Run Flutter Android app in debug mode with modified manifest');
      final Completer<bool> foundInvalidAotLibraryLog = Completer<bool>();
      final Completer<bool> foundUseTestFontsNotAllowedLog = Completer<bool>();
      late Process run;

      await inDirectory(path.join(tempDir.path, 'androidfluttershellargstest'), () async {
        run = await startFlutter('run', options: <String>['--release', '--verbose']);
      });

      final StreamSubscription<void>
      stdout = run.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen((
        String line,
      ) {
        if (line.contains(
          "Skipping unsafe AOT shared library name flag: something/completely/and/totally/invalid.so. Please ensure that the library is vetted and placed in your application's internal storage.",
        )) {
          foundInvalidAotLibraryLog.complete(true);
        } else if (line.contains(
          'Flag with metadata key io.flutter.embedding.android.UseTestFonts is not allowed in release builds and will be ignored. Please remove this flag from your release build manifest.',
        )) {
          foundUseTestFontsNotAllowedLog.complete(true);
        }
      });

      section('Check that warning log for invalid AOT shared library name is in STDOUT');
      final Object result = await Future.any(<Future<Object>>[
        Future.wait<bool>(<Future<bool>>[
          foundInvalidAotLibraryLog.future,
          foundUseTestFontsNotAllowedLog.future,
        ]),
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
