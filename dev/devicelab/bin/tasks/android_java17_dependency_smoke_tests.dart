// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/local.dart';
import 'package:flutter_devicelab/framework/dependency_smoke_test_task_definition.dart';
import 'package:flutter_devicelab/framework/framework.dart';

// Methodology:
// - AGP: versions within our support range (*). Minimum, Maximum known supported versions and template versions.
// - Gradle: The version that AGP lists as the default Gradle version for that
//           AGP version under the release notes, e.g.
//           https://developer.android.com/build/releases/past-releases/agp-8-4-0-release-notes.
// - Kotlin: No methodology as of yet.
// (*) - support range defined in packages/flutter_tools/gradle/src/main/kotlin/dependency_version_checker.gradle.kts.
List<VersionTuple> versionTuples = <VersionTuple>[
  // Minimum supported
  VersionTuple(agpVersion: '8.1.1', gradleVersion: '8.3', kotlinVersion: '1.8.10'),
  // Template
  VersionTuple(agpVersion: '8.9.1', gradleVersion: '8.12', kotlinVersion: '2.1.0'),
  // Max known
  VersionTuple(agpVersion: '8.13.0', gradleVersion: '9.1.0', kotlinVersion: '2.2.0'),
  /* Others */
  VersionTuple(agpVersion: '8.4.0', gradleVersion: '8.6', kotlinVersion: '1.8.22'),
  VersionTuple(agpVersion: '8.6.0', gradleVersion: '8.7', kotlinVersion: '1.8.22'),
  VersionTuple(agpVersion: '8.7.0', gradleVersion: '8.9', kotlinVersion: '2.1.0'),
  VersionTuple(agpVersion: '8.11.1', gradleVersion: '8.14', kotlinVersion: '2.2.20'),
]; // Max length is 7 entries until this test is split See https://github.com/flutter/flutter/issues/167495.

Future<void> main() async {
  /// The [FileSystem] for the integration test environment.
  const LocalFileSystem fileSystem = LocalFileSystem();

  /// The temp [Directory] purposedly has a space in it.
  final Directory tempDir = fileSystem.systemTempDirectory.createTempSync(
    'flutter android_dependency_version_tests',
  );
  await task(() {
    return buildFlutterApkWithSpecifiedDependencyVersions(
      versionTuples: versionTuples,
      tempDir: tempDir,
      localFileSystem: fileSystem,
    );
  });
}
