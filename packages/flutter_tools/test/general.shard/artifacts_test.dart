// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('Artifacts', () {
    MemoryFileSystem memoryFileSystem;
    Directory tempDir;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      tempDir = memoryFileSystem.systemTempDirectory.createTempSync('flutter_artifacts_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    group('CachedArtifacts', () {
      CachedArtifacts artifacts;

      setUp(() {
        artifacts = CachedArtifacts();
      });

      testUsingContext('getArtifactPath', () {
        expect(
          artifacts.getArtifactPath(Artifact.flutterFramework, platform: TargetPlatform.ios, mode: BuildMode.release),
          fs.path.join(tempDir.path, 'bin', 'cache', 'artifacts', 'engine', 'ios-release', 'Flutter.framework'),
        );
        expect(
          artifacts.getArtifactPath(Artifact.flutterTester),
          fs.path.join(tempDir.path, 'bin', 'cache', 'artifacts', 'engine', 'linux-x64', 'flutter_tester'),
        );
      }, overrides: <Type, Generator>{
        Cache: () => Cache(rootOverride: tempDir),
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(operatingSystem: 'linux'),
      });

      testUsingContext('getEngineType', () {
        expect(
          artifacts.getEngineType(TargetPlatform.android_arm, BuildMode.debug),
          'android-arm',
        );
        expect(
          artifacts.getEngineType(TargetPlatform.ios, BuildMode.release),
          'ios-release',
        );
        expect(
          artifacts.getEngineType(TargetPlatform.darwin_x64),
          'darwin-x64',
        );
      }, overrides: <Type, Generator>{
        Cache: () => Cache(rootOverride: tempDir),
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(operatingSystem: 'linux'),
      });
    });

    group('LocalEngineArtifacts', () {
      LocalEngineArtifacts artifacts;

      setUp(() {
        artifacts = LocalEngineArtifacts(tempDir.path,
          memoryFileSystem.path.join(tempDir.path, 'out', 'android_debug_unopt'),
          memoryFileSystem.path.join(tempDir.path, 'out', 'host_debug_unopt'),
        );
      });

      testUsingContext('getArtifactPath', () {
        expect(
          artifacts.getArtifactPath(Artifact.flutterFramework, platform: TargetPlatform.ios, mode: BuildMode.release),
          fs.path.join(tempDir.path, 'out', 'android_debug_unopt', 'Flutter.framework'),
        );
        expect(
          artifacts.getArtifactPath(Artifact.flutterTester),
          fs.path.join(tempDir.path, 'out', 'android_debug_unopt', 'flutter_tester'),
        );
        expect(
          artifacts.getArtifactPath(Artifact.engineDartSdkPath),
          fs.path.join(tempDir.path, 'out', 'host_debug_unopt', 'dart-sdk'),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(operatingSystem: 'linux'),
      });

      testUsingContext('getEngineType', () {
        expect(
          artifacts.getEngineType(TargetPlatform.android_arm, BuildMode.debug),
          'android_debug_unopt',
        );
        expect(
          artifacts.getEngineType(TargetPlatform.ios, BuildMode.release),
          'android_debug_unopt',
        );
        expect(
          artifacts.getEngineType(TargetPlatform.darwin_x64),
          'android_debug_unopt',
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(operatingSystem: 'linux'),
      });

      testUsingContext('Looks up dart.exe on windows platforms', () async {
        expect(artifacts.getArtifactPath(Artifact.engineDartBinary), contains('.exe'));
      }, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(operatingSystem: 'windows'),
      });

      testUsingContext('Looks up dart on linux platforms', () async {
        expect(artifacts.getArtifactPath(Artifact.engineDartBinary), isNot(contains('.exe')));
      }, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(operatingSystem: 'linux'),
      });
    });
  });
}
