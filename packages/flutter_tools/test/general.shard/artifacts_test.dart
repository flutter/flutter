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
      platform = FakePlatform();
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
          .childDirectory('ios-arm64')
          .childDirectory('Flutter.framework')
          .createSync(recursive: true);

      // TODO(jmagman): Remove ios-arm64_armv7 checks when armv7 engine artifacts are removed.
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
      final String actualReleaseFrameworkArtifact = artifacts.getArtifactPath(
        Artifact.flutterFramework,
        platform: TargetPlatform.ios,
        mode: BuildMode.release,
        environmentType: EnvironmentType.physical,
      );
      final String expectedArm64ReleaseFrameworkArtifact = fileSystem.path.join(
        xcframeworkPath,
        'ios-arm64',
        'Flutter.framework',
      );
      final String expectedArmv7ReleaseFrameworkArtifact = fileSystem.path.join(
        xcframeworkPath,
        'ios-arm64_armv7',
        'Flutter.framework',
      );

      // TODO(jmagman): Replace with expect(actualReleaseFrameworkArtifact, expectedArm64ReleaseFrameworkArtifact) when armv7 engine artifacts are removed.
      expect(
        actualReleaseFrameworkArtifact,
        anyOf(expectedArm64ReleaseFrameworkArtifact, expectedArmv7ReleaseFrameworkArtifact),
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
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        fileSystem.path.join('root', 'bin', 'cache', 'dart-sdk', 'bin', 'snapshots', 'frontend_server.dart.snapshot')
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
      platform = FakePlatform();
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
      fileSystem
          .directory('out')
          .childDirectory('host_debug_unopt')
          .childDirectory('dart-sdk')
          .childDirectory('bin')
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
      expect(
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        fileSystem.path.join('/out', 'host_debug_unopt', 'dart-sdk', 'bin',
          'snapshots', 'frontend_server.dart.snapshot')
      );


      fileSystem.file(fileSystem.path.join('/out', 'host_debug_unopt', 'impellerc'))
        .createSync(recursive: true);
      fileSystem.file(fileSystem.path.join('/out', 'host_debug_unopt', 'libtessellator.so'))
        .createSync(recursive: true);

      expect(
        artifacts.getHostArtifact(HostArtifact.impellerc).path,
        fileSystem.path.join('/out', 'host_debug_unopt', 'impellerc'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.libtessellator).path,
        fileSystem.path.join('/out', 'host_debug_unopt', 'libtessellator.so'),
      );
    });

    testWithoutContext('falls back to bundled impeller artifacts if the files do not exist in the local engine', () {
      expect(
        artifacts.getHostArtifact(HostArtifact.impellerc).path,
        fileSystem.path.join('root', 'bin', 'cache', 'artifacts', 'engine', 'linux-x64', 'impellerc'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.libtessellator).path,
        fileSystem.path.join('root', 'bin', 'cache', 'artifacts', 'engine', 'linux-x64', 'libtessellator.so'),
      );
    });

    testWithoutContext('falls back to prebuilt dart sdk', () {
      final String failureMessage = 'Unable to find a built dart sdk at:'
          ' "${fileSystem.path.join('/out', 'host_debug_unopt', 'dart-sdk')}"'
          ' or a prebuilt dart sdk at:'
          ' "${fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk')}"';

      expect(
        () => artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        throwsToolExit(message: failureMessage),
      );
      expect(
        () => artifacts.getHostArtifact(HostArtifact.engineDartSdkPath),
        throwsToolExit(message: failureMessage),
      );
      expect(
        () => artifacts.getHostArtifact(HostArtifact.engineDartBinary),
        throwsToolExit(message: failureMessage),
      );
      expect(
        () => artifacts.getHostArtifact(HostArtifact.dart2jsSnapshot),
        throwsToolExit(message: failureMessage),
      );
      expect(
        () => artifacts.getHostArtifact(HostArtifact.dartdevcSnapshot),
        throwsToolExit(message: failureMessage),
      );
      expect(
        () => artifacts.getHostArtifact(HostArtifact.kernelWorkerSnapshot),
        throwsToolExit(message: failureMessage),
      );

      fileSystem
          .directory('flutter')
          .childDirectory('prebuilts')
          .childDirectory('linux-x64')
          .childDirectory('dart-sdk')
          .childDirectory('bin')
          .createSync(recursive: true);

      expect(
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk', 'bin',
          'snapshots', 'frontend_server.dart.snapshot'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.engineDartSdkPath).path,
        fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.engineDartBinary).path,
        fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk', 'bin', 'dart'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.dart2jsSnapshot).path,
        fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk',
            'bin', 'snapshots', 'dart2js.dart.snapshot'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.dartdevcSnapshot).path,
        fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk',
            'bin', 'snapshots', 'dartdevc.dart.snapshot'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.kernelWorkerSnapshot).path,
        fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk',
            'bin', 'snapshots', 'kernel_worker.dart.snapshot'),
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

      fileSystem
          .directory('out')
          .childDirectory('host_debug_unopt')
          .childDirectory('dart-sdk')
          .childDirectory('bin')
          .createSync(recursive: true);

      expect(
        artifacts.getHostArtifact(HostArtifact.engineDartBinary).path,
        fileSystem.path.join('/out', 'host_debug_unopt', 'dart-sdk', 'bin', 'dart.exe'),
      );
    });

    testWithoutContext('Looks up dart on linux platforms', () async {
      fileSystem
          .directory('/out')
          .childDirectory('host_debug_unopt')
          .childDirectory('dart-sdk')
          .childDirectory('bin')
          .createSync(recursive: true);

      expect(
        artifacts.getHostArtifact(HostArtifact.engineDartBinary).path,
        fileSystem.path.join('/out', 'host_debug_unopt', 'dart-sdk', 'bin', 'dart'),
      );
    });

    testWithoutContext('Finds dart-sdk in windows prebuilts', () async {
      artifacts = LocalEngineArtifacts(
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'android_debug_unopt'),
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'host_debug_unopt'),
        cache: cache,
        fileSystem: fileSystem,
        platform: FakePlatform(operatingSystem: 'windows'),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );

      fileSystem
          .directory('/flutter')
          .childDirectory('prebuilts')
          .childDirectory('windows-x64')
          .childDirectory('dart-sdk')
          .childDirectory('bin')
          .createSync(recursive: true);

      expect(
        artifacts.getHostArtifact(HostArtifact.engineDartBinary).path,
        fileSystem.path.join('/flutter', 'prebuilts', 'windows-x64', 'dart-sdk', 'bin', 'dart.exe'),
      );
    });

    testWithoutContext('Finds dart-sdk in macos prebuilts', () async {
      artifacts = LocalEngineArtifacts(
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'android_debug_unopt'),
        fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'host_debug_unopt'),
        cache: cache,
        fileSystem: fileSystem,
        platform: FakePlatform(operatingSystem: 'macos'),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );

      fileSystem
          .directory('/flutter')
          .childDirectory('prebuilts')
          .childDirectory('macos-x64')
          .childDirectory('dart-sdk')
          .childDirectory('bin')
          .createSync(recursive: true);

      expect(
        artifacts.getHostArtifact(HostArtifact.engineDartBinary).path,
        fileSystem.path.join('/flutter', 'prebuilts', 'macos-x64', 'dart-sdk', 'bin', 'dart'),
      );
    });
  });
}
