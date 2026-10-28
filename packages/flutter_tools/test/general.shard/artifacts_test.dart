// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';

void main() {
  group('CachedArtifacts', () {
    late CachedArtifacts artifacts;
    late Cache cache;
    late FileSystem fileSystem;
    late Platform platform;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      final Directory cacheRoot = fileSystem.directory('root')..createSync();
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
        throwsToolExit(message: 'No xcframework found at $xcframeworkPath.'),
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

      expect(
        artifacts.getArtifactPath(
          Artifact.flutterFramework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
          environmentType: EnvironmentType.simulator,
        ),
        fileSystem.path.join(xcframeworkPath, 'ios-arm64_x86_64-simulator', 'Flutter.framework'),
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
      expect(actualReleaseFrameworkArtifact, expectedArm64ReleaseFrameworkArtifact);
      expect(
        artifacts.getArtifactPath(
          Artifact.flutterXcframework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
        ),
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
        artifacts.getArtifactPath(Artifact.flutterTester),
        fileSystem.path.join(
          'root',
          'bin',
          'cache',
          'artifacts',
          'engine',
          'linux-x64',
          'flutter_tester',
        ),
      );
      expect(
        artifacts.getArtifactPath(Artifact.flutterTester, platform: TargetPlatform.linux_arm64),
        fileSystem.path.join(
          'root',
          'bin',
          'cache',
          'artifacts',
          'engine',
          'linux-arm64',
          'flutter_tester',
        ),
      );
      expect(
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        fileSystem.path.join(
          'root',
          'bin',
          'cache',
          'dart-sdk',
          'bin',
          'snapshots',
          'frontend_server_aot.dart.snapshot',
        ),
      );
    });

    testWithoutContext(
      'getArtifactPath for FlutterMacOS.framework and FlutterMacOS.xcframework',
      () {
        final String xcframeworkPath = fileSystem.path.join(
          'root',
          'bin',
          'cache',
          'artifacts',
          'engine',
          'darwin-x64-release',
          'FlutterMacOS.xcframework',
        );
        final String xcframeworkPathWithUnsetPlatform = fileSystem.path.join(
          'root',
          'bin',
          'cache',
          'artifacts',
          'engine',
          'linux-x64-release',
          'FlutterMacOS.xcframework',
        );
        expect(
          artifacts.getArtifactPath(
            Artifact.flutterMacOSXcframework,
            platform: TargetPlatform.darwin,
            mode: BuildMode.release,
          ),
          xcframeworkPath,
        );
        expect(
          artifacts.getArtifactPath(Artifact.flutterMacOSXcframework, mode: BuildMode.release),
          xcframeworkPathWithUnsetPlatform,
        );
        expect(
          () => artifacts.getArtifactPath(
            Artifact.flutterMacOSFramework,
            platform: TargetPlatform.darwin,
            mode: BuildMode.release,
          ),
          throwsToolExit(message: 'No xcframework found at $xcframeworkPath.'),
        );
        expect(
          () => artifacts.getArtifactPath(Artifact.flutterMacOSFramework, mode: BuildMode.release),
          throwsToolExit(message: 'No xcframework found at $xcframeworkPathWithUnsetPlatform.'),
        );
        fileSystem.directory(xcframeworkPath).createSync(recursive: true);
        expect(
          () => artifacts.getArtifactPath(
            Artifact.flutterMacOSFramework,
            platform: TargetPlatform.darwin,
            mode: BuildMode.release,
          ),
          throwsToolExit(message: 'No macOS frameworks found in $xcframeworkPath'),
        );
        fileSystem
            .directory(xcframeworkPath)
            .childDirectory('macos-arm64_x86_64')
            .childDirectory('FlutterMacOS.framework')
            .createSync(recursive: true);
        expect(
          artifacts.getArtifactPath(
            Artifact.flutterMacOSFramework,
            platform: TargetPlatform.darwin,
            mode: BuildMode.release,
          ),
          fileSystem.path.join(xcframeworkPath, 'macos-arm64_x86_64', 'FlutterMacOS.framework'),
        );
      },
    );

    testWithoutContext('Precompiled web DDC stable SDK artifact paths are correct', () {
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledDDCStableSdk).path,
        'root/bin/cache/flutter_web_sdk/kernel/ddc/stable/dart_sdk.js',
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledDDCStableSdkSourcemaps).path,
        'root/bin/cache/flutter_web_sdk/kernel/ddc/stable/dart_sdk.js.map',
      );
    });

    testWithoutContext('Precompiled web DDC canary SDK artifact paths are correct', () {
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledDDCCanarySdk).path,
        'root/bin/cache/flutter_web_sdk/kernel/ddc/canary/dart_sdk.js',
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.webPrecompiledDDCCanarySdkSourcemaps).path,
        'root/bin/cache/flutter_web_sdk/kernel/ddc/canary/dart_sdk.js.map',
      );
    });

    testWithoutContext('getEngineType', () {
      expect(artifacts.getEngineType(TargetPlatform.android_arm, BuildMode.debug), 'android-arm');
      expect(artifacts.getEngineType(TargetPlatform.ios, BuildMode.release), 'ios-release');
      expect(artifacts.getEngineType(TargetPlatform.darwin), 'darwin-x64');
    });

    testWithoutContext(
      'CachedLocalWebSdkArtifacts wrapping a versioned engine sets usesLocalArtifacts',
      () {
        final webArtifacts = CachedLocalWebSdkArtifacts(
          parent: artifacts,
          webSdkPath: fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'wasm_release'),
          fileSystem: fileSystem,
          platform: platform,
          operatingSystemUtils: FakeOperatingSystemUtils(),
        );
        expect(webArtifacts.usesLocalArtifacts, true);
      },
    );
  });

  group('LocalEngineArtifacts', () {
    late Artifacts artifacts;
    late Cache cache;
    late FileSystem fileSystem;
    late Platform platform;
    late FakeProcessManager processManager;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      final Directory cacheRoot = fileSystem.directory('root')..createSync();
      platform = FakePlatform();
      cache = Cache(
        rootOverride: cacheRoot,
        fileSystem: fileSystem,
        platform: platform,
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
        artifacts: <ArtifactSet>[],
      );
      processManager = FakeProcessManager.any();
      artifacts = CachedLocalWebSdkArtifacts(
        parent: CachedLocalEngineArtifacts(
          fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'host_debug_unopt'),
          engineOutPath: fileSystem.path.join(
            fileSystem.currentDirectory.path,
            'out',
            'android_debug_unopt',
          ),
          toolContext: FakeToolContext(
            cache: cache,
            fs: fileSystem,
            os: FakeOperatingSystemUtils(),
            platform: platform,
            processManager: processManager,
          ),
        ),
        webSdkPath: fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'wasm_release'),
        fileSystem: fileSystem,
        platform: platform,
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );
    });

    testWithoutContext(
      'getArtifactPath for FlutterMacOS.framework and FlutterMacOS.xcframework',
      () {
        final String xcframeworkPath = fileSystem.path.join(
          '/out',
          'android_debug_unopt',
          'FlutterMacOS.xcframework',
        );
        expect(
          artifacts.getArtifactPath(
            Artifact.flutterMacOSXcframework,
            platform: TargetPlatform.darwin,
            mode: BuildMode.release,
          ),
          xcframeworkPath,
        );
        expect(
          artifacts.getArtifactPath(Artifact.flutterMacOSXcframework, mode: BuildMode.release),
          xcframeworkPath,
        );
        expect(
          () => artifacts.getArtifactPath(
            Artifact.flutterMacOSFramework,
            platform: TargetPlatform.darwin,
            mode: BuildMode.release,
          ),
          throwsToolExit(
            message: 'No xcframework found at /out/android_debug_unopt/FlutterMacOS.xcframework',
          ),
        );
        expect(
          () => artifacts.getArtifactPath(Artifact.flutterMacOSFramework, mode: BuildMode.release),
          throwsToolExit(
            message: 'No xcframework found at /out/android_debug_unopt/FlutterMacOS.xcframework',
          ),
        );
        fileSystem.directory(xcframeworkPath).createSync(recursive: true);
        expect(
          () => artifacts.getArtifactPath(
            Artifact.flutterMacOSFramework,
            platform: TargetPlatform.darwin,
            mode: BuildMode.release,
          ),
          throwsToolExit(
            message:
                'No macOS frameworks found in /out/android_debug_unopt/FlutterMacOS.xcframework',
          ),
        );
        expect(
          () => artifacts.getArtifactPath(Artifact.flutterMacOSFramework, mode: BuildMode.release),
          throwsToolExit(
            message:
                'No macOS frameworks found in /out/android_debug_unopt/FlutterMacOS.xcframework',
          ),
        );

        fileSystem
            .directory(xcframeworkPath)
            .childDirectory('macos-arm64_x86_64')
            .childDirectory('FlutterMacOS.framework')
            .createSync(recursive: true);

        expect(
          artifacts.getArtifactPath(
            Artifact.flutterMacOSFramework,
            platform: TargetPlatform.darwin,
            mode: BuildMode.release,
          ),
          fileSystem.path.join(xcframeworkPath, 'macos-arm64_x86_64', 'FlutterMacOS.framework'),
        );
        expect(
          artifacts.getArtifactPath(Artifact.flutterMacOSFramework, mode: BuildMode.release),
          fileSystem.path.join(xcframeworkPath, 'macos-arm64_x86_64', 'FlutterMacOS.framework'),
        );
      },
    );

    testWithoutContext('getArtifactPath', () {
      final String xcframeworkPath = artifacts.getArtifactPath(
        Artifact.flutterXcframework,
        platform: TargetPlatform.ios,
        mode: BuildMode.release,
      );
      expect(
        xcframeworkPath,
        fileSystem.path.join('/out', 'android_debug_unopt', 'Flutter.xcframework'),
      );
      expect(
        () => artifacts.getArtifactPath(
          Artifact.flutterFramework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
          environmentType: EnvironmentType.simulator,
        ),
        throwsToolExit(
          message: 'No xcframework found at /out/android_debug_unopt/Flutter.xcframework',
        ),
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
          message: 'No iOS frameworks found in /out/android_debug_unopt/Flutter.xcframework',
        ),
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
        fileSystem.path.join(xcframeworkPath, 'ios-arm64_x86_64-simulator', 'Flutter.framework'),
      );
      expect(
        artifacts.getArtifactPath(
          Artifact.flutterFramework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
          environmentType: EnvironmentType.physical,
        ),
        fileSystem.path.join(xcframeworkPath, 'ios-arm64', 'Flutter.framework'),
      );
      expect(
        artifacts.getArtifactPath(
          Artifact.flutterXcframework,
          platform: TargetPlatform.ios,
          mode: BuildMode.release,
        ),
        fileSystem.path.join('/out', 'android_debug_unopt', 'Flutter.xcframework'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.flutterTester),
        fileSystem.path.join('/out', 'host_debug_unopt', 'flutter_tester'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        fileSystem.path.join('/out', 'host_debug_unopt', 'dart-sdk'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        fileSystem.path.join(
          '/out',
          'host_debug_unopt',
          'dart-sdk',
          'bin',
          'snapshots',
          'frontend_server_aot.dart.snapshot',
        ),
      );

      fileSystem
          .file(fileSystem.path.join('/out', 'host_debug_unopt', 'impellerc'))
          .createSync(recursive: true);
      fileSystem
          .file(fileSystem.path.join('/out', 'host_debug_unopt', 'libtessellator.so'))
          .createSync(recursive: true);
      fileSystem
          .directory(fileSystem.path.join('/out', 'host_debug_unopt', 'shader_lib'))
          .createSync(recursive: true);

      expect(
        artifacts.getHostArtifact(HostArtifact.impellerc).path,
        fileSystem.path.join('/out', 'host_debug_unopt', 'impellerc'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.shaderLib).path,
        fileSystem.path.join('/out', 'host_debug_unopt', 'shader_lib'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.libtessellator).path,
        fileSystem.path.join('/out', 'host_debug_unopt', 'libtessellator.so'),
      );

      processManager.excludedExecutables.add('/out/android_debug_unopt/./gen_snapshot');
      expect(
        artifacts.getArtifactPath(Artifact.genSnapshot),
        fileSystem.path.join('/out', 'android_debug_unopt', 'universal', 'gen_snapshot'),
      );
    });

    testWithoutContext(
      'falls back to bundled impeller artifacts if the files do not exist in the local engine',
      () {
        expect(
          artifacts.getHostArtifact(HostArtifact.impellerc).path,
          fileSystem.path.join(
            'root',
            'bin',
            'cache',
            'artifacts',
            'engine',
            'linux-x64',
            'impellerc',
          ),
        );
        expect(
          artifacts.getHostArtifact(HostArtifact.libtessellator).path,
          fileSystem.path.join(
            'root',
            'bin',
            'cache',
            'artifacts',
            'engine',
            'linux-x64',
            'libtessellator.so',
          ),
        );
        expect(
          artifacts.getHostArtifact(HostArtifact.shaderLib).path,
          fileSystem.path.join(
            'root',
            'bin',
            'cache',
            'artifacts',
            'engine',
            'linux-x64',
            'shader_lib',
          ),
        );
      },
    );

    testWithoutContext('uses prebuilt dart sdk for web platform', () {
      final webArtifacts = CachedLocalWebSdkArtifacts(
        parent: CachedArtifacts(
          fileSystem: fileSystem,
          cache: cache,
          platform: platform,
          operatingSystemUtils: FakeOperatingSystemUtils(),
        ),
        webSdkPath: fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'wasm_release'),
        fileSystem: fileSystem,
        platform: platform,
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );

      final failureMessage =
          'Unable to find a prebuilt dart sdk at:'
          ' "${fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk')}"';

      expect(
        () => webArtifacts.getArtifactPath(
          Artifact.frontendServerSnapshotForEngineDartSdk,
          platform: TargetPlatform.web_javascript,
        ),
        throwsToolExit(message: failureMessage),
      );
      expect(
        () => webArtifacts.getArtifactPath(
          Artifact.engineDartSdkPath,
          platform: TargetPlatform.web_javascript,
        ),
        throwsToolExit(message: failureMessage),
      );
      expect(
        () => webArtifacts.getArtifactPath(
          Artifact.engineDartBinary,
          platform: TargetPlatform.web_javascript,
        ),
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
        webArtifacts.getArtifactPath(
          Artifact.frontendServerSnapshotForEngineDartSdk,
          platform: TargetPlatform.web_javascript,
        ),
        fileSystem.path.join(
          '/flutter',
          'prebuilts',
          'linux-x64',
          'dart-sdk',
          'bin',
          'snapshots',
          'frontend_server_aot.dart.snapshot',
        ),
      );
      expect(
        webArtifacts.getArtifactPath(
          Artifact.engineDartSdkPath,
          platform: TargetPlatform.web_javascript,
        ),
        fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk'),
      );
      expect(
        webArtifacts.getArtifactPath(
          Artifact.engineDartBinary,
          platform: TargetPlatform.web_javascript,
        ),
        fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk', 'bin', 'dart'),
      );
      expect(
        webArtifacts.getArtifactPath(
          Artifact.engineDartAotRuntime,
          platform: TargetPlatform.web_javascript,
        ),
        fileSystem.path.join(
          '/flutter',
          'prebuilts',
          'linux-x64',
          'dart-sdk',
          'bin',
          'dartaotruntime',
        ),
      );
    });

    testWithoutContext('uses local dart sdk for web platform wrapping a local engine', () {
      final failureMessage =
          'Unable to find a built dart sdk at:'
          ' "${fileSystem.path.join('/out', 'host_debug_unopt', 'dart-sdk')}"'
          ' or a prebuilt dart sdk at:'
          ' "${fileSystem.path.join('/flutter', 'prebuilts', 'linux-x64', 'dart-sdk')}"';

      expect(
        () => artifacts.getArtifactPath(
          Artifact.engineDartSdkPath,
          platform: TargetPlatform.web_javascript,
        ),
        throwsToolExit(message: failureMessage),
      );

      fileSystem
          .directory('out')
          .childDirectory('host_debug_unopt')
          .childDirectory('dart-sdk')
          .childDirectory('bin')
          .createSync(recursive: true);

      expect(
        artifacts.getArtifactPath(
          Artifact.engineDartSdkPath,
          platform: TargetPlatform.web_javascript,
        ),
        fileSystem.path.join('/out', 'host_debug_unopt', 'dart-sdk'),
      );
    });

    testWithoutContext('getEngineType', () {
      expect(
        artifacts.getEngineType(TargetPlatform.android_arm, BuildMode.debug),
        'android_debug_unopt',
      );
      expect(artifacts.getEngineType(TargetPlatform.ios, BuildMode.release), 'android_debug_unopt');
      expect(artifacts.getEngineType(TargetPlatform.darwin), 'android_debug_unopt');
    });

    testWithoutContext('Looks up dart.exe on windows platforms', () async {
      artifacts = CachedLocalWebSdkArtifacts(
        parent: CachedLocalEngineArtifacts(
          fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'host_debug_unopt'),
          engineOutPath: fileSystem.path.join(
            fileSystem.currentDirectory.path,
            'out',
            'android_debug_unopt',
          ),
          toolContext: FakeToolContext(
            cache: cache,
            fs: fileSystem,
            os: FakeOperatingSystemUtils(),
            platform: FakePlatform(operatingSystem: 'windows'),
            processManager: FakeProcessManager.any(),
          ),
        ),
        webSdkPath: fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'wasm_release'),
        fileSystem: fileSystem,
        platform: FakePlatform(operatingSystem: 'windows'),
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );

      fileSystem
          .directory('out')
          .childDirectory('host_debug_unopt')
          .childDirectory('dart-sdk')
          .childDirectory('bin')
          .createSync(recursive: true);

      expect(
        artifacts.getArtifactPath(Artifact.engineDartBinary),
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
        artifacts.getArtifactPath(Artifact.engineDartBinary),
        fileSystem.path.join('/out', 'host_debug_unopt', 'dart-sdk', 'bin', 'dart'),
      );
    });

    testWithoutContext('Finds dart-sdk in windows prebuilts for web platform', () async {
      artifacts = CachedLocalWebSdkArtifacts(
        parent: CachedLocalEngineArtifacts(
          fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'host_debug_unopt'),
          engineOutPath: fileSystem.path.join(
            fileSystem.currentDirectory.path,
            'out',
            'android_debug_unopt',
          ),
          toolContext: FakeToolContext(
            cache: cache,
            fs: fileSystem,
            os: FakeOperatingSystemUtils(),
            platform: FakePlatform(operatingSystem: 'windows'),
            processManager: FakeProcessManager.any(),
          ),
        ),
        webSdkPath: fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'wasm_release'),
        fileSystem: fileSystem,
        platform: FakePlatform(operatingSystem: 'windows'),
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
        artifacts.getArtifactPath(
          Artifact.engineDartBinary,
          platform: TargetPlatform.web_javascript,
        ),
        fileSystem.path.join('/flutter', 'prebuilts', 'windows-x64', 'dart-sdk', 'bin', 'dart.exe'),
      );
    });

    testWithoutContext('Finds dart-sdk in macos prebuilts for web platform', () async {
      artifacts = CachedLocalWebSdkArtifacts(
        parent: CachedLocalEngineArtifacts(
          fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'host_debug_unopt'),
          engineOutPath: fileSystem.path.join(
            fileSystem.currentDirectory.path,
            'out',
            'android_debug_unopt',
          ),
          toolContext: FakeToolContext(
            cache: cache,
            fs: fileSystem,
            os: FakeOperatingSystemUtils(),
            platform: FakePlatform(operatingSystem: 'macos'),
            processManager: FakeProcessManager.any(),
          ),
        ),
        webSdkPath: fileSystem.path.join(fileSystem.currentDirectory.path, 'out', 'wasm_release'),
        fileSystem: fileSystem,
        platform: FakePlatform(operatingSystem: 'macos'),
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
        artifacts.getArtifactPath(
          Artifact.engineDartBinary,
          platform: TargetPlatform.web_javascript,
        ),
        fileSystem.path.join('/flutter', 'prebuilts', 'macos-x64', 'dart-sdk', 'bin', 'dart'),
      );
    });
  });

  group('LocalEngineInfo', () {
    late FileSystem fileSystem;
    late LocalEngineInfo localEngineInfo;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    testWithoutContext('determines the target device name from the path', () {
      localEngineInfo = LocalEngineInfo(
        targetOutPath: fileSystem.path.join(
          fileSystem.currentDirectory.path,
          'out',
          'android_debug_unopt',
        ),
        hostOutPath: fileSystem.path.join(
          fileSystem.currentDirectory.path,
          'out',
          'host_debug_unopt',
        ),
        fileSystem: fileSystem,
      );

      expect(localEngineInfo.localTargetName, 'android_debug_unopt');
    });

    testWithoutContext(
      'determines the target device name from the path when using a custom engine path',
      () {
        localEngineInfo = LocalEngineInfo(
          targetOutPath: fileSystem.path.join(
            fileSystem.currentDirectory.path,
            'out',
            'android_debug_unopt',
          ),
          hostOutPath: fileSystem.path.join(
            fileSystem.currentDirectory.path,
            'out',
            'host_debug_unopt',
          ),
          fileSystem: fileSystem,
        );

        expect(localEngineInfo.localHostName, 'host_debug_unopt');
      },
    );

    testWithoutContext('determines engine names using the file system path style', () {
      final windowsFileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
      final localArtifacts = Artifacts.testLocalEngine(
        localEngine: windowsFileSystem.path.join(
          windowsFileSystem.currentDirectory.path,
          'out',
          'android_debug_unopt',
        ),
        localEngineHost: windowsFileSystem.path.join(
          windowsFileSystem.currentDirectory.path,
          'out',
          'host_debug_unopt',
        ),
        fileSystem: windowsFileSystem,
      );

      expect(localArtifacts.localEngineInfo?.localTargetName, 'android_debug_unopt');
      expect(localArtifacts.localEngineInfo?.localHostName, 'host_debug_unopt');
    });

    testWithoutContext('Artifacts.getLocalEngine constructs local engine artifacts', () {
      final String targetEngine = fileSystem.path.join(
        fileSystem.currentDirectory.path,
        'out',
        'android_debug_unopt',
      );
      final String hostEngine = fileSystem.path.join(
        fileSystem.currentDirectory.path,
        'out',
        'host_debug_unopt',
      );
      final String webSdk = fileSystem.path.join(
        fileSystem.currentDirectory.path,
        'out',
        'wasm_release',
      );
      final Artifacts localArtifacts = Artifacts.getLocalEngine(
        EngineBuildPaths(targetEngine: targetEngine, hostEngine: hostEngine, webSdk: webSdk),
        toolContext: FakeToolContext(fs: fileSystem),
      );

      expect(localArtifacts.usesLocalArtifacts, isTrue);
      expect(localArtifacts.localEngineInfo?.localTargetName, 'android_debug_unopt');
      expect(localArtifacts.localEngineInfo?.localHostName, 'host_debug_unopt');
      expect(
        localArtifacts.getArtifactPath(Artifact.icuData, platform: TargetPlatform.android_arm64),
        fileSystem.path.join(targetEngine, 'icudtl.dat'),
      );
    });

    testWithoutContext(
      "names GN's build directories to a re-entrant build by name, with the engine source",
      () {
        localEngineInfo = LocalEngineInfo(
          targetOutPath: '/engine/src/out/linux_debug_unopt',
          hostOutPath: '/engine/src/out/host_debug_unopt',
          fileSystem: fileSystem,
        );
        expect(
          localEngineInfo.toReentrantBuildEnvironment(fileSystem: fileSystem),
          <String, String>{
            'FLUTTER_ENGINE': '/engine/src',
            'LOCAL_ENGINE': 'linux_debug_unopt',
            'LOCAL_ENGINE_HOST': 'host_debug_unopt',
          },
        );
      },
    );

    testWithoutContext(
      'names a Bazel build directory to a re-entrant build by its path, without a source',
      () {
        // A Bazel build directory is known by its manifest; its path is what
        // --local-engine takes, and the tool finds the source as for any
        // absolute path.
        const bazelBin = '/checkout/engine/src/bazel-bin/engine/src/flutter';
        fileSystem.file(fileSystem.path.join(bazelBin, 'local_engine.json'))
          ..createSync(recursive: true)
          ..writeAsStringSync('{"name": "host_debug_unopt", "entries": {}}');
        localEngineInfo = LocalEngineInfo(
          targetOutPath: bazelBin,
          hostOutPath: bazelBin,
          fileSystem: fileSystem,
          targetName: 'host_debug_unopt',
          hostName: 'host_debug_unopt',
        );
        expect(
          localEngineInfo.toReentrantBuildEnvironment(fileSystem: fileSystem),
          <String, String>{'LOCAL_ENGINE': bazelBin, 'LOCAL_ENGINE_HOST': bazelBin},
        );
      },
    );
  });

  group('LocalEngineLayout', () {
    late FileSystem fileSystem;
    late Cache cache;
    late Platform platform;
    late FakeProcessManager processManager;
    late String bazelBin;
    late String execroot;

    // A Bazel build's output directory, with the manifest local_engine
    // writes beside its outputs: GN's paths to the files relative to the
    // manifest's directory, through `..` for another repository's.
    setUp(() {
      fileSystem = MemoryFileSystem.test();
      final Directory cacheRoot = fileSystem.directory('root')..createSync();
      platform = FakePlatform();
      cache = Cache(
        rootOverride: cacheRoot,
        fileSystem: fileSystem,
        platform: platform,
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
        artifacts: <ArtifactSet>[],
      );
      processManager = FakeProcessManager.any();
      execroot = fileSystem.path.join(fileSystem.currentDirectory.path, 'execroot', '_main');
      bazelBin = fileSystem.path.join(
        execroot,
        'bazel-out',
        'k8-dbg',
        'bin',
        'engine',
        'src',
        'flutter',
      );
      fileSystem.directory(bazelBin).createSync(recursive: true);
      fileSystem
          .directory(fileSystem.path.join(execroot, 'external', 'dart_sdk', 'bin'))
          .createSync(recursive: true);
      fileSystem
          .file(fileSystem.path.join(bazelBin, 'local_engine.json'))
          .writeAsStringSync(
            json.encode(<String, Object>{
              'name': 'host_debug_unopt',
              'entries': <String, String>{
                'flutter_tester': 'shell/testing/shipped/flutter_tester',
                'gen_snapshot': 'build/bazel/dart_wrap/dart_sdk/gen_snapshot',
                'icudtl.dat': '../../../../../../external/icu/common/icudtl.dat',
                'flutter_patched_sdk': 'lib/snapshot/flutter_patched_sdk',
                'flutter_patched_sdk/platform_strong.dill':
                    'lib/snapshot/flutter_patched_sdk/platform_strong.dill',
                'gen/flutter/lib/snapshot/isolate_snapshot.bin':
                    'lib/snapshot/isolate_snapshot.bin',
                'gen/dart-pkg/sky_engine': 'local_engine/sky_engine',
                'dart-sdk': '../../../../../../external/dart_sdk',
                'font-subset': 'tools/font_subset/shipped/font-subset',
                'libflutter_linux_gtk.so': 'shell/platform/linux/shipped/libflutter_linux_gtk.so',
                'flutter_linux': '../../../../../../engine/src/flutter/shell/platform/linux/public/flutter_linux',
                'impellerc': 'impeller/compiler/shipped/impellerc',
                'shader_lib': 'local_engine/shader_lib',
              },
            }),
          );
    });

    Artifacts bazelArtifacts() => CachedLocalEngineArtifacts(
      bazelBin,
      engineOutPath: bazelBin,
      toolContext: FakeToolContext(
        cache: cache,
        fs: fileSystem,
        os: FakeOperatingSystemUtils(),
        platform: platform,
        processManager: processManager,
      ),
    );

    testWithoutContext('resolves GN paths through the manifest', () {
      final layout = LocalEngineLayout.of(bazelBin, fileSystem: fileSystem);
      expect(layout.hasManifest, isTrue);
      expect(layout.name, 'host_debug_unopt');
      // A file of the build.
      expect(
        layout.resolve(<String>['flutter_tester']),
        fileSystem.path.join(bazelBin, 'shell', 'testing', 'shipped', 'flutter_tester'),
      );
      // A file under a mapped directory, by the longest entry.
      expect(
        layout.resolve(<String>['gen', 'dart-pkg', 'sky_engine', 'lib', 'ui', 'ui.dart']),
        fileSystem.path.join(bazelBin, 'local_engine', 'sky_engine', 'lib', 'ui', 'ui.dart'),
      );
      expect(
        layout.resolve(<String>['flutter_patched_sdk', 'platform_strong.dill']),
        fileSystem.path.join(
          bazelBin,
          'lib',
          'snapshot',
          'flutter_patched_sdk',
          'platform_strong.dill',
        ),
      );
      // Another repository's files, through `..` from the manifest's directory.
      expect(
        layout.resolve(<String>['dart-sdk', 'bin', 'dart']),
        fileSystem.path.join(execroot, 'external', 'dart_sdk', 'bin', 'dart'),
      );
      expect(
        layout.resolve(<String>['icudtl.dat']),
        fileSystem.path.join(execroot, 'external', 'icu', 'common', 'icudtl.dat'),
      );
      // A path the manifest does not know stays where GN would have it.
      expect(
        layout.resolve(<String>['clang_x64', 'gen_snapshot']),
        fileSystem.path.join(bazelBin, 'clang_x64', 'gen_snapshot'),
      );
    });

    testWithoutContext("is GN's layout without a manifest", () {
      final String gnOut = fileSystem.path.join('/out', 'host_debug_unopt');
      final layout = LocalEngineLayout.of(gnOut, fileSystem: fileSystem);
      expect(layout.hasManifest, isFalse);
      expect(layout.name, isNull);
      expect(
        layout.resolve(<String>['gen', 'dart-pkg', 'sky_engine']),
        fileSystem.path.join(gnOut, 'gen', 'dart-pkg', 'sky_engine'),
      );
    });

    testWithoutContext('rejects a manifest without entries', () {
      fileSystem.file(fileSystem.path.join(bazelBin, 'local_engine.json')).writeAsStringSync('{}');
      expect(
        () => LocalEngineLayout.of(bazelBin, fileSystem: fileSystem),
        throwsToolExit(message: 'has no "entries" map'),
      );
    });

    testWithoutContext('CachedLocalEngineArtifacts reads a Bazel build directory', () {
      final Artifacts artifacts = bazelArtifacts();
      expect(artifacts.localEngineInfo!.localTargetName, 'host_debug_unopt');
      expect(artifacts.localEngineInfo!.localHostName, 'host_debug_unopt');
      expect(artifacts.getEngineType(TargetPlatform.linux_x64), 'host_debug_unopt');
      expect(
        artifacts.getArtifactPath(Artifact.flutterTester),
        fileSystem.path.join(bazelBin, 'shell', 'testing', 'shipped', 'flutter_tester'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.genSnapshot),
        fileSystem.path.join(bazelBin, 'build', 'bazel', 'dart_wrap', 'dart_sdk', 'gen_snapshot'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.icuData),
        fileSystem.path.join(execroot, 'external', 'icu', 'common', 'icudtl.dat'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.platformKernelDill),
        fileSystem.path.join(
          bazelBin,
          'lib',
          'snapshot',
          'flutter_patched_sdk',
          'platform_strong.dill',
        ),
      );
      expect(
        artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
        fileSystem.path.join(bazelBin, 'lib', 'snapshot', 'flutter_patched_sdk'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.isolateSnapshotData),
        fileSystem.path.join(bazelBin, 'lib', 'snapshot', 'isolate_snapshot.bin'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.skyEnginePath),
        fileSystem.path.join(bazelBin, 'local_engine', 'sky_engine'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.fontSubset),
        fileSystem.path.join(bazelBin, 'tools', 'font_subset', 'shipped', 'font-subset'),
      );
      // The directory the GTK library is copied from.
      expect(
        artifacts.getArtifactPath(Artifact.linuxDesktopPath),
        fileSystem.path.join(bazelBin, 'shell', 'platform', 'linux', 'shipped'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.linuxHeaders),
        fileSystem.path.join(
          execroot,
          'engine',
          'src',
          'flutter',
          'shell',
          'platform',
          'linux',
          'public',
          'flutter_linux',
        ),
      );
      // The shader compiler, and the GLSL library it includes from: assembled
      // as one directory by local_engine, not beside the compiler as GN lays it.
      fileSystem
          .file(fileSystem.path.join(bazelBin, 'impeller', 'compiler', 'shipped', 'impellerc'))
          .createSync(recursive: true);
      fileSystem
          .directory(fileSystem.path.join(bazelBin, 'local_engine', 'shader_lib'))
          .createSync(recursive: true);
      expect(
        artifacts.getHostArtifact(HostArtifact.impellerc).path,
        fileSystem.path.join(bazelBin, 'impeller', 'compiler', 'shipped', 'impellerc'),
      );
      expect(
        artifacts.getHostArtifact(HostArtifact.shaderLib).path,
        fileSystem.path.join(bazelBin, 'local_engine', 'shader_lib'),
      );
      // The Dart SDK: the repository the manifest names, since it has a bin/.
      final String dartSdk = fileSystem.path.join(execroot, 'external', 'dart_sdk');
      expect(artifacts.getArtifactPath(Artifact.engineDartSdkPath), dartSdk);
      expect(
        artifacts.getArtifactPath(Artifact.engineDartBinary),
        fileSystem.path.join(dartSdk, 'bin', 'dart'),
      );
      expect(
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        fileSystem.path.join(dartSdk, 'bin', 'snapshots', 'frontend_server_aot.dart.snapshot'),
      );
    });

    testWithoutContext(
      'finds the Apple frameworks inside the xcframeworks the manifest places',
      () {
        // A Mac host build's and an iOS simulator build's manifests: each
        // xcframework is one entry (a directory the build assembles), and the
        // framework is its slice's, as in GN's build directory.
        final String macosBin = fileSystem.path.join(
          execroot,
          'bazel-out',
          'macos_arm64_debug-dbg',
          'bin',
          'engine',
          'src',
          'flutter',
        );
        final String iosBin = fileSystem.path.join(
          execroot,
          'bazel-out',
          'ios_sim_arm64_debug-dbg',
          'bin',
          'engine',
          'src',
          'flutter',
        );
        final String macosFramework = fileSystem.path.join(
          macosBin,
          'shell',
          'platform',
          'darwin',
          'macos',
          'FlutterMacOS.xcframework',
          'macos-arm64',
          'FlutterMacOS.framework',
        );
        final String iosFramework = fileSystem.path.join(
          iosBin,
          'shell',
          'platform',
          'darwin',
          'ios',
          'Flutter.xcframework',
          'ios-arm64-simulator',
          'Flutter.framework',
        );
        fileSystem.directory(macosFramework).createSync(recursive: true);
        fileSystem.directory(iosFramework).createSync(recursive: true);
        fileSystem
            .file(fileSystem.path.join(macosBin, 'local_engine.json'))
            .writeAsStringSync(
              json.encode(<String, Object>{
                'name': 'host_debug_unopt_arm64',
                'entries': <String, String>{
                  'FlutterMacOS.xcframework':
                      'shell/platform/darwin/macos/FlutterMacOS.xcframework',
                  'flutter_tester': 'shell/testing/flutter_tester',
                },
              }),
            );
        fileSystem
            .file(fileSystem.path.join(iosBin, 'local_engine.json'))
            .writeAsStringSync(
              json.encode(<String, Object>{
                'name': 'ios_debug_sim_unopt_arm64',
                'entries': <String, String>{
                  'Flutter.xcframework': 'shell/platform/darwin/ios/Flutter.xcframework',
                },
              }),
            );
        final macPlatform = FakePlatform(operatingSystem: 'macos');
        final Artifacts macos = CachedLocalEngineArtifacts(
          macosBin,
          engineOutPath: macosBin,
          toolContext: FakeToolContext(
            cache: cache,
            fs: fileSystem,
            os: FakeOperatingSystemUtils(),
            platform: macPlatform,
            processManager: processManager,
          ),
        );
        expect(
          macos.getArtifactPath(Artifact.flutterMacOSXcframework, platform: TargetPlatform.darwin),
          fileSystem.path.dirname(fileSystem.path.dirname(macosFramework)),
        );
        expect(
          macos.getArtifactPath(Artifact.flutterMacOSFramework, platform: TargetPlatform.darwin),
          macosFramework,
        );
        expect(
          macos.getArtifactPath(
            Artifact.flutterMacOSFrameworkDsym,
            platform: TargetPlatform.darwin,
          ),
          fileSystem.path.join(
            fileSystem.path.dirname(macosFramework),
            'dSYMs',
            'FlutterMacOS.framework.dSYM',
          ),
        );
        final Artifacts ios = CachedLocalEngineArtifacts(
          macosBin,
          engineOutPath: iosBin,
          toolContext: FakeToolContext(
            cache: cache,
            fs: fileSystem,
            os: FakeOperatingSystemUtils(),
            platform: macPlatform,
            processManager: processManager,
          ),
        );
        expect(ios.localEngineInfo!.localTargetName, 'ios_debug_sim_unopt_arm64');
        expect(
          ios.getArtifactPath(Artifact.flutterXcframework, platform: TargetPlatform.ios),
          fileSystem.path.dirname(fileSystem.path.dirname(iosFramework)),
        );
        expect(
          ios.getArtifactPath(
            Artifact.flutterFramework,
            platform: TargetPlatform.ios,
            mode: BuildMode.debug,
            environmentType: EnvironmentType.simulator,
          ),
          iosFramework,
        );
        // The host's tools come from the host build.
        expect(
          ios.getArtifactPath(Artifact.flutterTester),
          fileSystem.path.join(macosBin, 'shell', 'testing', 'flutter_tester'),
        );
      },
    );
  });

  group('DeferredArtifacts', () {
    late Artifacts cached;
    late Artifacts localEngine;

    setUp(() {
      final fileSystem = MemoryFileSystem.test();
      cached = Artifacts.test(fileSystem: fileSystem);
      localEngine = Artifacts.testLocalEngine(
        localEngine: '/out/host_debug',
        localEngineHost: '/out/host_debug',
        fileSystem: fileSystem,
      );
    });

    testWithoutContext('builds against the artifacts it was given', () {
      final artifacts = DeferredArtifacts(cached);

      expect(artifacts.usesLocalArtifacts, isFalse);
      expect(
        artifacts.getArtifactPath(Artifact.flutterTester),
        cached.getArtifactPath(Artifact.flutterTester),
      );
    });

    testWithoutContext('builds against the artifacts it is resolved to', () {
      final artifacts = DeferredArtifacts(cached);

      artifacts.resolve(localEngine);

      expect(artifacts.usesLocalArtifacts, isTrue);
      expect(artifacts.localEngineInfo?.targetOutPath, '/out/host_debug');
      expect(
        artifacts.getArtifactPath(Artifact.flutterTester),
        localEngine.getArtifactPath(Artifact.flutterTester),
      );
    });

    testWithoutContext('cannot be resolved twice', () {
      final artifacts = DeferredArtifacts(cached);

      artifacts.resolve(localEngine);

      expect(() => artifacts.resolve(localEngine), throwsAssertionError);
    });
  });
}
