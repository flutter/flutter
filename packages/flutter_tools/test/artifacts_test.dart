// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('CachedArtifacts', () {

    Directory tempDir;
    CachedArtifacts artifacts;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_temp');
      artifacts = new CachedArtifacts();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    testUsingContext('getArtifactPath', () {
      expect(
          artifacts.getArtifactPath(Artifact.flutterFramework, TargetPlatform.ios, BuildMode.release),
          fs.path.join(tempDir.path, 'bin', 'cache', 'artifacts', 'engine', 'ios-release', 'Flutter.framework')
      );
      expect(
          artifacts.getArtifactPath(Artifact.entryPointsExtraJson, TargetPlatform.android_arm64, BuildMode.release),
          fs.path.join(tempDir.path, 'bin', 'cache', 'artifacts', 'engine', 'android-arm64-release', 'entry_points_extra.json')
      );
      expect(
          artifacts.getArtifactPath(Artifact.flutterTester),
          fs.path.join(tempDir.path, 'bin', 'cache', 'artifacts', 'engine', 'linux-x64', 'flutter_tester')
      );
    }, overrides: <Type, Generator> {
      Cache: () => new Cache(rootOverride: tempDir),
      Platform: () => new FakePlatform(operatingSystem: 'linux')
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
      Cache: () => new Cache(rootOverride: tempDir),
      Platform: () => new FakePlatform(operatingSystem: 'linux')
    });
  });

  group('LocalEngineArtifacts', () {

    Directory tempDir;
    LocalEngineArtifacts artifacts;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_temp');
      artifacts = new LocalEngineArtifacts(tempDir.path,
        fs.path.join(tempDir.path, 'out', 'android_debug_unopt'),
        fs.path.join(tempDir.path, 'out', 'host_debug_unopt'),
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    testUsingContext('getArtifactPath', () {
      expect(
          artifacts.getArtifactPath(Artifact.dartIoEntriesTxt, TargetPlatform.android_arm, BuildMode.debug),
          fs.path.join(tempDir.path, 'third_party', 'dart', 'runtime', 'bin', 'dart_io_entries.txt')
      );
      expect(
          artifacts.getArtifactPath(Artifact.entryPointsJson, TargetPlatform.android_arm, BuildMode.profile),
          fs.path.join(tempDir.path, 'out', 'android_debug_unopt', 'dart_entry_points', 'entry_points.json')
      );
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
      Platform: () => new FakePlatform(operatingSystem: 'linux')
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
      Platform: () => new FakePlatform(operatingSystem: 'linux')
    });
  });
}