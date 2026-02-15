// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/src/interface/file_system_entity.dart';

import '../integration.shard/test_utils.dart';
import '../src/android_common.dart';
import '../src/common.dart';
import '../src/context.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
  });

  tearDownAll(() async {
    tryToDelete(tempDir as FileSystemEntity);
  });

  testUsingContext('AGP version out of "warn" support band but in "error" band builds '
      'successfully and prints warning', () async {
    final versionTuple = VersionTuple(
      agpVersion: '8.3.0',
      gradleVersion: '8.12',
      kotlinVersion: '2.1.0',
    );
    final ProcessResult result = await buildFlutterApkWithSpecifiedDependencyVersions(
      versions: versionTuple,
      tempDir: tempDir,
    );
    expect(result, const ProcessResultMatcher());
    expect(result.stderr, contains('Please upgrade your Android Gradle Plugin version'));
  });

  testUsingContext('Gradle version out of "warn" support band but in "error" band builds '
      'successfully and prints warning', () async {
    // Create a new flutter project.
    final versionTuple = VersionTuple(
      agpVersion: '8.3.0',
      gradleVersion: '8.4',
      kotlinVersion: '2.1.0',
    );
    final ProcessResult result = await buildFlutterApkWithSpecifiedDependencyVersions(
      versions: versionTuple,
      tempDir: tempDir,
    );
    expect(result, const ProcessResultMatcher());
    expect(result.stderr, contains('Please upgrade your Gradle version'));
  });

  testUsingContext('Kotlin version out of "warn" support band but in "error" band builds '
      'successfully and prints warning', () async {
    final versionTuple = VersionTuple(
      agpVersion: '8.9.1',
      gradleVersion: '8.12',
      kotlinVersion: '1.9.25',
    );
    final ProcessResult result = await buildFlutterApkWithSpecifiedDependencyVersions(
      versions: versionTuple,
      tempDir: tempDir,
    );

    expect(result, const ProcessResultMatcher());
    expect(result.stderr, contains('Please upgrade your Kotlin version'));
  });

  testUsingContext('No logs are printed when suppression flag is passed', () async {
    final versionTuple = VersionTuple(
      agpVersion: '8.3.0',
      gradleVersion: '8.12',
      kotlinVersion: '2.1.0',
    );
    final ProcessResult result = await buildFlutterApkWithSpecifiedDependencyVersions(
      versions: versionTuple,
      tempDir: tempDir,
      skipChecking: true,
    );
    expect(result, const ProcessResultMatcher());
    expect(result.stderr, isNot(contains('Please upgrade your Android Gradle Plugin version')));
  });
}
