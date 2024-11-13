// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:file/file.dart';

import '../integration.shard/test_utils.dart';
import '../src/common.dart';

void main() {
  final String flutterRoot = getFlutterRoot();
  final String flutterBin = fileSystem.path.join(flutterRoot, 'bin', 'flutter');

  late Directory tmpDir;

  setUp(() {
    tmpDir = fileSystem.systemTempDirectory.createTempSync();
  });

  tearDown(() {
    tryToDelete(tmpDir);
  });

  // Normally these tests should take about a minute, but sometimes for
  // unknown reasons they can take 30m+ and timeout. The intent behind this loop
  // is to get more information on what exactly is happening.
  for (int i = 1; i <= 10; i++) {
    test('flutter build apk | attempt $i of 10', () async {
      final String package = 'flutter_build_apk_test_$i';

      // Create a new Flutter app.
      await expectLater(
        processManager.run(
          <String>[
            flutterBin,
            'create',
            '--no-pub',
            package,
          ],
          workingDirectory: tmpDir.path,
        ),
        completion(const ProcessResultMatcher()),
        reason: 'Should create a new blank Flutter project',
      );

      // Build the APK.
      final List<String> args = <String>[
        flutterBin,
        '--verbose',
        'build',
        'apk',
        '--debug',
      ];
      io.stderr.writeln('Running $args...');

      final io.Process process = await processManager.start(
        args,
        workingDirectory: tmpDir.childDirectory(package).path,
        mode: io.ProcessStartMode.inheritStdio,
      );
      await expectLater(process.exitCode, completion(0));
    });
  }
}
