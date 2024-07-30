// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import '../../test/common.dart';
import 'common.dart';

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
  /// The [FileSystem] for the integration test environment.
  const LocalFileSystem fileSystem = LocalFileSystem();

  setUp(() async {
    tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_android_dependency_version_tests');
  });

  tearDown(() async {
    tempDir.deleteSync(recursive: true);
  });

  group(
      'flutter create -> flutter build apk succeeds across dependency support range (java 11 subset)', () {
    for (final VersionTuple versionTuple in versionTuples) {
      test('Flutter app builds successfully with AGP/Gradle/Kotlin versions of $versionTuple', () async {
        await buildFlutterApkWithSpecifiedDependencyVersions(versions: versionTuple, tempDir: tempDir, localFileSystem: fileSystem);
      });
    }
  });
}
