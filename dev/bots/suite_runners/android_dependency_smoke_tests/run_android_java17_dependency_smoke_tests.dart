// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import '../../test/common.dart';
import 'common.dart';

// Methodology:
// - AGP: all versions within our support range.
// - Gradle: The version that AGP lists as the default Gradle version for that
//           AGP version under the release notes, e.g.
//           https://developer.android.com/build/releases/past-releases/agp-8-4-0-release-notes.
// - Kotlin: No methodology as of yet.
List<VersionTuple> versionTuples = <VersionTuple>[
  VersionTuple(agpVersion: '8.0.0', gradleVersion: '8.0', kotlinVersion: '1.8.22'),
  VersionTuple(agpVersion: '8.1.0', gradleVersion: '8.0', kotlinVersion: '1.8.22'),
  VersionTuple(agpVersion: '8.2.0', gradleVersion: '8.2', kotlinVersion: '1.8.22'),
  VersionTuple(agpVersion: '8.3.0', gradleVersion: '8.4', kotlinVersion: '1.8.22'),
  VersionTuple(agpVersion: '8.4.0', gradleVersion: '8.6', kotlinVersion: '1.8.22'),
  VersionTuple(agpVersion: '8.5.0', gradleVersion: '8.7', kotlinVersion: '1.8.22'),
];

Future<void> androidJava17DependencySmokeTestsRunner() async {
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
      'flutter create -> flutter build apk succeeds across dependency support range (java 17 subset)', () {
    for (final VersionTuple versionTuple in versionTuples) {
      test('Flutter app builds successfully with AGP/Gradle/Kotlin versions of $versionTuple', () async {
        await buildFlutterApkWithSpecifiedDependencyVersions(versions: versionTuple, tempDir: tempDir, localFileSystem: fileSystem);
      });
    }
  });
}
