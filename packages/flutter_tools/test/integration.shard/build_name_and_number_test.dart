// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_data/project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  final Project project = _BuildNameAndNumberProject();
  late Directory tempDir;
  late FlutterTestTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('build_name_and_number_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterTestTestDriver(tempDir);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext('Reads "version" build name and number in "flutter test"', () async {
    await flutter.test();

    // Without an assertion, this test always passes.
    final int? exitCode = await flutter.done;
    expect(exitCode, 0, reason: 'flutter test failed with exit code $exitCode');
  });
}

final class _BuildNameAndNumberProject extends Project {
  @override
  final main = r'''
    // Irrelevant to this test.
    void main() {}
  ''';

  @override
  final pubspec = r'''
  name: test
  environment:
    sdk: ^3.7.0-0

  version: 1.2.3+4

  dependencies:
    flutter:
      sdk: flutter
  dev_dependencies:
    flutter_test:
      sdk: flutter
  ''';

  @override
  final test = r'''
    import 'package:flutter/services.dart';
    import 'package:flutter_test/flutter_test.dart';

    void main() {
      test('receives build name and number with flutter test', () async {
        expect(appBuildName, '1.2.3');
        expect(appBuildNumber, '4');
      });
    }
  ''';
}
