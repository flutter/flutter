// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:package_config/package_config.dart';

import '../src/common.dart';
import 'test_utils.dart';

// This test depends on some files in ///dev/automated_tests/flutter_test/*

final String automatedTestsDirectory = fileSystem.path.join('..', '..', 'dev', 'automated_tests');
final String missingDependencyDirectory = fileSystem.path.join(
  '..',
  '..',
  'dev',
  'missing_dependency_tests',
);
final String flutterTestDirectory = fileSystem.path.join(automatedTestsDirectory, 'flutter_test');
final String integrationTestDirectory = fileSystem.path.join(
  automatedTestsDirectory,
  'integration_test',
);

// Running Integration Tests in the Flutter Tester will still exercise the same
// flows specific to Integration Tests.
final List<String> integrationTestExtraArgs = <String>['-d', 'flutter-tester'];

void main() {
  testWithoutContext(
    'flutter_test should have all the transitive dependencies for the --experimental-faster-testing isolate spawner code',
    () async {
      final Directory dir = fileSystem.systemTempDirectory.createTempSync('test_dir');
      dir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
environment:
  sdk: ^3.7.0
dev_dependencies:
  flutter_test:
    sdk: flutter
''');
      expect(
        await processManager.run(<String>[flutterBin, 'pub', 'get'], workingDirectory: dir.path),
        const ProcessResultMatcher(),
      );

      final File packageConfigFile = dir
          .childDirectory('.dart_tool')
          .childFile('package_config.json');
      final PackageConfig packageConfig = PackageConfig.parseString(
        packageConfigFile.readAsStringSync(),
        packageConfigFile.uri,
      );
      expect(packageConfig['test_api'], isNotNull);
      expect(packageConfig['ffi'], isNotNull);
      expect(packageConfig['stream_channel'], isNotNull);
      expect(packageConfig['test_core'], isNotNull);
    },
  );
}
