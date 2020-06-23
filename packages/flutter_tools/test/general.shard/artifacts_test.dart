// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('CachedArtifacts', () {
    CachedArtifacts artifacts;
    Cache cache;
    FileSystem fileSystem;
    Platform platform;

    setUp(() {
      fileSystem = MemoryFileSystem();
      final Directory cacheRoot = fileSystem.directory('root')
        ..createSync();
      platform = FakePlatform(operatingSystem: 'linux');
      cache = Cache(
        rootOverride: cacheRoot,
        fileSystem: fileSystem,
        platform: platform,
        logger: BufferLogger.test(),
        osUtils: MockOperatingSystemUtils(),
      );
      artifacts = CachedArtifacts(
        fileSystem: fileSystem,
        cache: cache,
        platform: platform,
      );
    });

    testWithoutContext('getArtifactPath', () {
      expect(
        artifacts.getArtifactPath(Artifact.flutterFramework, platform: TargetPlatform.ios, mode: BuildMode.release),
        fileSystem.path.join('root', 'bin', 'cache', 'artifacts', 'engine', 'ios-release', 'Flutter.framework'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.flutterTester),
        fileSystem.path.join('root', 'bin', 'cache', 'artifacts', 'engine', 'linux-x64', 'flutter_tester'),
      );
    });

    testWithoutContext('getEngineType', () {
      expect(
        artifacts.getEngineType(TargetPlatform.android_arm, BuildMode.debug),
        'android-arm',
      );
      expect(
        artifacts.getEngineType(TargetPlatform.ios, BuildMode.release),
        'ios-release',
      );
      expect(
        artifacts.getEngineType(TargetPlatform.darwin),
        'darwin-x64',
      );
    });
  });

  group('LocalEngineArtifacts', () {
    LocalEngineArtifacts artifacts;
    Cache cache;
    FileSystem fileSystem;
    Platform platform;

    setUp(() {
      fileSystem = MemoryFileSystem();
      final Directory cacheRoot = fileSystem.directory('root')
        ..createSync();
      platform = FakePlatform(operatingSystem: 'linux');
      cache = Cache(
        rootOverride: cacheRoot,
        fileSystem: fileSystem,
        platform: platform,
        logger: BufferLogger.test(),
        osUtils: MockOperatingSystemUtils(),
      );
      artifacts = LocalEngineArtifacts(
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'android_debug_unopt'),
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'host_debug_unopt'),
        cache: cache,
        fileSystem: fileSystem,
        platform: platform,
        processManager: FakeProcessManager.any(),
      );
    });

    testWithoutContext('getArtifactPath', () {
      expect(
        artifacts.getArtifactPath(Artifact.flutterFramework, platform: TargetPlatform.ios, mode: BuildMode.release),
        fileSystem.path.join('/out', 'android_debug_unopt', 'Flutter.framework'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.flutterTester),
        fileSystem.path.join('/out', 'android_debug_unopt', 'flutter_tester'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        fileSystem.path.join('/out', 'host_debug_unopt', 'dart-sdk'),
      );
    });

    testWithoutContext('getEngineType', () {
      expect(
        artifacts.getEngineType(TargetPlatform.android_arm, BuildMode.debug),
        'android_debug_unopt',
      );
      expect(
        artifacts.getEngineType(TargetPlatform.ios, BuildMode.release),
        'android_debug_unopt',
      );
      expect(
        artifacts.getEngineType(TargetPlatform.darwin),
        'android_debug_unopt',
      );
    });

    testWithoutContext('Looks up dart.exe on windows platforms', () async {
      artifacts = LocalEngineArtifacts(
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'android_debug_unopt'),
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'host_debug_unopt'),
        cache: cache,
        fileSystem: fileSystem,
        platform: FakePlatform(operatingSystem: 'windows'),
        processManager: FakeProcessManager.any(),
      );

      expect(artifacts.getArtifactPath(Artifact.engineDartBinary), contains('.exe'));
    });

    testWithoutContext('Looks up dart on linux platforms', () async {
      expect(artifacts.getArtifactPath(Artifact.engineDartBinary), isNot(contains('.exe')));
    });
  });
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
