// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/src/interface/file_system_entity.dart';
import '../../../../packages/flutter_tools/test/integration.shard/test_utils.dart';
import '../../../../packages/flutter_tools/test/src/android_common.dart';
import '../../../../packages/flutter_tools/test/src/common.dart';
import '../../../../packages/flutter_tools/test/src/context.dart';

List<VersionTuple> versionTuples = <VersionTuple>[
  VersionTuple(agpVersion: '7.0.1', gradleVersion: '7.0.2', kotlinVersion: '1.7.10'),
  VersionTuple(agpVersion: '7.1.0', gradleVersion: '7.2', kotlinVersion: '1.7.10'),
  VersionTuple(agpVersion: '7.2.0', gradleVersion: '7.3.3', kotlinVersion: '1.7.10'),
  VersionTuple(agpVersion: '7.3.0', gradleVersion: '7.4', kotlinVersion: '1.7.10'),
  VersionTuple(agpVersion: '7.4.0', gradleVersion: '7.5', kotlinVersion: '1.8.10'),
];

// This test requires Java 11 due to the intentionally low version of Gradle.
Future<void> androidJava11DependencySmokeTestsRunner() async {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir as FileSystemEntity);
  });

  group(
      'flutter create -> flutter build apk succeeds across dependency support range (java 11 subset)', () {
    for (final VersionTuple versionTuple in versionTuples) {
      testUsingContext('Flutter app builds successfully with AGP/Gradle/Kotlin versions of $versionTuple', () async {
        final ProcessResult result = await buildFlutterApkWithSpecifiedDependencyVersions(versions: versionTuple, tempDir: tempDir);
        expect(result, const ProcessResultMatcher());
      });
    }
  });
}