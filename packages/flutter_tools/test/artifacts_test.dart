// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/artifacts.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('CachedArtifacts', () {

    Directory tempDir;
    CachedArtifacts artifacts;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_artifacts_test_cached.');
      artifacts = CachedArtifacts();
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('getArtifactPath', () {
      expect(
          artifacts.getArtifactPath(Artifact.flutterFramework, TargetPlatform.ios, BuildMode.release),
          fs.path.join(tempDir.path, 'bin', 'cache', 'artifacts', 'engine', 'ios-release', 'Flutter.framework')
      );
      expect(
          artifacts.getArtifactPath(Artifact.flutterTester),
          fs.path.join(tempDir.path, 'bin', 'cache', 'artifacts', 'engine', 'linux-x64', 'flutter_tester')
      );
    }, overrides: <Type, Generator> {
      Cache: () => Cache(rootOverride: tempDir),
      Platform: () => FakePlatform(operatingSystem: 'linux')
    });

    testUsingContext('getEngineType', () {
      expect(
          artifacts.getEngineType(TargetPlatform.android_arm, BuildMode.debug),
          'android-arm'
      );
      expect(
          artifacts.getEngineType(TargetPlatform.ios, BuildMode.release),
          'ios-release'
      );
      expect(
          artifacts.getEngineType(TargetPlatform.darwin_x64),
          'darwin-x64'
      );
    }, overrides: <Type, Generator> {
      Cache: () => Cache(rootOverride: tempDir),
      Platform: () => FakePlatform(operatingSystem: 'linux')
    });
  });

  group('LocalEngineArtifacts', () {

    Directory tempDir;
    LocalEngineArtifacts artifacts;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_artifacts_test_local.');
      artifacts = LocalEngineArtifacts(tempDir.path,
        fs.path.join(tempDir.path, 'out', 'android_debug_unopt'),
        fs.path.join(tempDir.path, 'out', 'host_debug_unopt'),
      );
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('getArtifactPath', () {
      expect(
          artifacts.getArtifactPath(Artifact.flutterFramework, TargetPlatform.ios, BuildMode.release),
          fs.path.join(tempDir.path, 'out', 'android_debug_unopt', 'Flutter.framework')
      );
      expect(
          artifacts.getArtifactPath(Artifact.flutterTester),
          fs.path.join(tempDir.path, 'out', 'android_debug_unopt', 'flutter_tester')
      );
      expect(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        fs.path.join(tempDir.path, 'out', 'host_debug_unopt', 'dart-sdk')
      );
    }, overrides: <Type, Generator> {
      Platform: () => FakePlatform(operatingSystem: 'linux')
    });

    testUsingContext('getEngineType', () {
      expect(
          artifacts.getEngineType(TargetPlatform.android_arm, BuildMode.debug),
          'android_debug_unopt'
      );
      expect(
          artifacts.getEngineType(TargetPlatform.ios, BuildMode.release),
          'android_debug_unopt'
      );
      expect(
          artifacts.getEngineType(TargetPlatform.darwin_x64),
          'android_debug_unopt'
      );
    }, overrides: <Type, Generator> {
      Platform: () => FakePlatform(operatingSystem: 'linux')
    });
  });
}
