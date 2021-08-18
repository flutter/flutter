// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart';

void main() {
  group('CachedArtifacts', () {
    late CachedArtifacts artifacts;
    late Cache cache;
    late FileSystem fileSystem;
    late Platform platform;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      final Directory cacheRoot = fileSystem.directory('root')
        ..createSync();
      platform = FakePlatform(operatingSystem: 'linux');
      cache = Cache(
        rootOverride: cacheRoot,
        fileSystem: fileSystem,
        platform: platform,
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
        artifacts: <ArtifactSet>[],
      );
      artifacts = CachedArtifacts(
        fileSystem: fileSystem,
        cache: cache,
        platform: platform,
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );
    });

    testWithoutContext('getArtifactPath', () {
      final String xcframeworkPath = artifacts.getArtifactPath(
        Artifact.flutterXcframework,
        platform: TargetPlatform.ios,
        mode: BuildMode.release,
      );
      expect(
        xcframeworkPath,
        fileSystem.path.join(
          'root',
          'bin',
          'cache',
          'artifacts',
          'engine',
          'ios-release',
          'Flutter.xcframework',
        ),
      );
      expect(
        () => artifacts.getArtifactPath(
          Artifact.flutterFramework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
          environmentType: EnvironmentType.simulator,
        ),
        throwsToolExit(
            message:
                'No xcframework found at $xcframeworkPath.'),
      );
      fileSystem.directory(xcframeworkPath).createSync(recursive: true);
      expect(
        () => artifacts.getArtifactPath(
          Artifact.flutterFramework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
          environmentType: EnvironmentType.simulator,
        ),
        throwsToolExit(message: 'No iOS frameworks found in $xcframeworkPath'),
      );

      fileSystem
          .directory(xcframeworkPath)
          .childDirectory('ios-arm64_x86_64-simulator')
          .childDirectory('Flutter.framework')
          .createSync(recursive: true);
      fileSystem
          .directory(xcframeworkPath)
          .childDirectory('ios-arm64_armv7')
          .childDirectory('Flutter.framework')
          .createSync(recursive: true);
      expect(
        artifacts.getArtifactPath(Artifact.flutterFramework,
            platform: TargetPlatform.ios,
            mode: BuildMode.release,
            environmentType: EnvironmentType.simulator),
        fileSystem.path
            .join(xcframeworkPath, 'ios-arm64_x86_64-simulator', 'Flutter.framework'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.flutterFramework,
            platform: TargetPlatform.ios, mode: BuildMode.release, environmentType: EnvironmentType.physical),
        fileSystem.path.join(xcframeworkPath, 'ios-arm64_armv7', 'Flutter.framework'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.flutterXcframework, platform: TargetPlatform.ios, mode: BuildMode.release),
        fileSystem.path.join('root', 'bin', 'cache', 'artifacts', 'engine', 'ios-release', 'Flutter.xcframework'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.flutterTester),
        fileSystem.path.join('root', 'bin', 'cache', 'artifacts', 'engine', 'linux-x64', 'flutter_tester'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.flutterTester, platform: TargetPlatform.linux_arm64),
        fileSystem.path.join('root', 'bin', 'cache', 'artifacts', 'engine', 'linux-arm64', 'flutter_tester'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.windowsUwpDesktopPath, platform: TargetPlatform.windows_uwp_x64, mode: BuildMode.debug),
        fileSystem.path.join('root', 'bin', 'cache', 'artifacts', 'engine', 'windows-uwp-x64-debug'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.windowsUwpDesktopPath, platform: TargetPlatform.windows_uwp_x64, mode: BuildMode.profile),
        fileSystem.path.join('root', 'bin', 'cache', 'artifacts', 'engine', 'windows-uwp-x64-profile'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.windowsUwpDesktopPath, platform: TargetPlatform.windows_uwp_x64, mode: BuildMode.release),
        fileSystem.path.join('root', 'bin', 'cache', 'artifacts', 'engine', 'windows-uwp-x64-release'),
      );
    });

    testWithoutContext('precompiled web artifact paths are correct', () {
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledSdk).path,
        'root/bin/cache/flutter_web_sdk/kernel/amd/dart_sdk.js',
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledSdkSourcemaps).path,
        'root/bin/cache/flutter_web_sdk/kernel/amd/dart_sdk.js.map',
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledCanvaskitSdk).path,
        'root/bin/cache/flutter_web_sdk/kernel/amd-canvaskit/dart_sdk.js',
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledCanvaskitSdkSourcemaps).path,
        'root/bin/cache/flutter_web_sdk/kernel/amd-canvaskit/dart_sdk.js.map',
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledSoundSdk).path,
        'root/bin/cache/flutter_web_sdk/kernel/amd-sound/dart_sdk.js',
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledSoundSdkSourcemaps).path,
        'root/bin/cache/flutter_web_sdk/kernel/amd-sound/dart_sdk.js.map',
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledCanvaskitSoundSdk).path,
        'root/bin/cache/flutter_web_sdk/kernel/amd-canvaskit-sound/dart_sdk.js',
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledCanvaskitSoundSdkSourcemaps).path,
        'root/bin/cache/flutter_web_sdk/kernel/amd-canvaskit-sound/dart_sdk.js.map',
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
    late LocalEngineArtifacts artifacts;
    late Cache cache;
    late FileSystem fileSystem;
    late Platform platform;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      final Directory cacheRoot = fileSystem.directory('root')
        ..createSync();
      platform = FakePlatform(operatingSystem: 'linux');
      cache = Cache(
        rootOverride: cacheRoot,
        fileSystem: fileSystem,
        platform: platform,
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
        artifacts: <ArtifactSet>[],
      );
      artifacts = LocalEngineArtifacts(
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'android_debug_unopt'),
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'host_debug_unopt'),
        cache: cache,
        fileSystem: fileSystem,
        platform: platform,
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );
    });

    testWithoutContext('getArtifactPath', () {
      final String xcframeworkPath = artifacts.getArtifactPath(
        Artifact.flutterXcframework,
        platform: TargetPlatform.ios,
        mode: BuildMode.release,
      );
      expect(
        xcframeworkPath,
        fileSystem.path
            .join('/out', 'android_debug_unopt', 'Flutter.xcframework'),
      );
      expect(
        () => artifacts.getArtifactPath(
          Artifact.flutterFramework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
          environmentType: EnvironmentType.simulator,
        ),
        throwsToolExit(
            message:
                'No xcframework found at /out/android_debug_unopt/Flutter.xcframework'),
      );
      fileSystem.directory(xcframeworkPath).createSync(recursive: true);
      expect(
        () => artifacts.getArtifactPath(
          Artifact.flutterFramework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
          environmentType: EnvironmentType.simulator,
        ),
        throwsToolExit(
            message:
                'No iOS frameworks found in /out/android_debug_unopt/Flutter.xcframework'),
      );

      fileSystem
          .directory(xcframeworkPath)
          .childDirectory('ios-arm64_x86_64-simulator')
          .childDirectory('Flutter.framework')
          .createSync(recursive: true);
      fileSystem
          .directory(xcframeworkPath)
          .childDirectory('ios-arm64_armv7')
          .childDirectory('Flutter.framework')
          .createSync(recursive: true);
      expect(
        artifacts.getArtifactPath(
          Artifact.flutterFramework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
          environmentType: EnvironmentType.simulator,
        ),
        fileSystem.path
            .join(xcframeworkPath, 'ios-arm64_x86_64-simulator', 'Flutter.framework'),
      );
      expect(
        artifacts.getArtifactPath(
          Artifact.flutterFramework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
          environmentType: EnvironmentType.physical,
        ),
        fileSystem.path
            .join(xcframeworkPath, 'ios-arm64_armv7', 'Flutter.framework'),
      );
      expect(
        artifacts.getArtifactPath(
          Artifact.flutterXcframework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
        ),
        fileSystem.path
            .join('/out', 'android_debug_unopt', 'Flutter.xcframework'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.flutterTester),
        fileSystem.path.join('/out', 'android_debug_unopt', 'flutter_tester'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.engineDartSdkPath).path,
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
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );

      expect(artifacts.getHostArtifact(HostArtifact.engineDartBinary).path, contains('.exe'));
    });

    testWithoutContext('Looks up windows UWP artifacts in host engine', () async {
      artifacts = LocalEngineArtifacts(
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'winuwp_debug_unopt'),
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'winuwp_debug_unopt'),
        cache: cache,
        fileSystem: fileSystem,
        platform: FakePlatform(operatingSystem: 'windows'),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );

      expect(artifacts.getArtifactPath(Artifact.windowsUwpDesktopPath), '/out/winuwp_debug_unopt');
    });

    testWithoutContext('Looks up dart on linux platforms', () async {
      expect(artifacts.getHostArtifact(HostArtifact.engineDartBinary).path, isNot(contains('.exe')));
    });
  });
}
