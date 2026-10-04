// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test exercises dynamic libraries added to a flutter app or package.
// It covers:
//  * `flutter run`, including hot reload and hot restart
//  * `flutter test`
//  * `flutter build`

@Timeout(Duration(minutes: 10))
library;

import 'dart:io';

import 'package:file/file.dart';

import '../../src/common.dart';
import '../test_utils.dart' show fileSystem, platform;
import '../transition_test_utils.dart';
import 'native_assets_test_utils.dart';

final String hostOs = platform.operatingSystem;

final devices = <String>['flutter-tester', hostOs];

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    // TODO(dacoharkes): Implement Fuchsia. https://github.com/flutter/flutter/issues/129757
    return;
  }

  for (final String device in devices) {
    testWithoutContext('flutter test integration_test $device native assets', () async {
      await inTempDir((Directory tempDirectory) async {
        final Directory packageDirectory = await createTestProject(packageName, tempDirectory);

        final Uri exampleDirectory = Uri.directory(packageDirectory.path).resolve('example/');
        _addIntegrationTest(exampleDirectory, packageName);

        final ProcessTestResult result = await runFlutter(
          <String>['test', 'integration_test', '-d', device],
          exampleDirectory.toFilePath(),
          <Transition>[Barrier(RegExp('.* All tests passed!'))],
          logging: false,
        );
        if (result.exitCode != 0) {
          throw Exception(
            'flutter test integration_test failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
          );
        }
      });
    });
  }
}

void _addIntegrationTest(Uri exampleDirectory, String packageName) {
  final ProcessResult result = processManager.runSync(<String>[
    'flutter',
    'pub',
    'add',
    'dev:integration_test:{"sdk":"flutter"}',
  ], workingDirectory: exampleDirectory.toFilePath());
  if (result.exitCode != 0) {
    throw Exception(
      'flutter pub add failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
    );
  }

  final Uri integrationTestPath = exampleDirectory.resolve('integration_test/my_test.dart');
  final File integrationTestFile = fileSystem.file(integrationTestPath);
  integrationTestFile.createSync(recursive: true);
  integrationTestFile.writeAsStringSync('''
import 'package:flutter_test/flutter_test.dart';
import 'package:${packageName}_example/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('invoke native code', (tester) async {
      // Load app widget.
      await tester.pumpWidget(const MyApp());

      // Verify the native function was called.
      expect(find.text('sum(1, 2) = 3'), findsOneWidget);
    });
  });
}
''');
}
