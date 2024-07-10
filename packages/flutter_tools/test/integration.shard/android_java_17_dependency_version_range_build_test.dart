// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/src/interface/file_system_entity.dart';

import '../integration.shard/test_utils.dart';
import '../src/android_common.dart';
import '../src/common.dart';
import '../src/context.dart';

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
];

// This test requires Java 11 due to the intentionally low version of Gradle.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir as FileSystemEntity);
  });

  group(
      'flutter create -> flutter build apk succeeds across dependency support range (java 17 subset)', () {
    for (final VersionTuple versionTuple in versionTuples) {
      testUsingContext('Flutter app builds successfully with AGP/Gradle/Kotlin versions of $versionTuple', () async {
        final ProcessResult result = await buildFlutterApkWithSpecifiedDependencyVersions(versions: versionTuple, tempDir: tempDir);
        expect(result, const ProcessResultMatcher());
      });
    }
  });
}
