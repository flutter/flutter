// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/linux.dart';
import 'package:flutter_tools/src/convert.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

void main() {
  final List<TargetPlatform> targetPlatforms = <TargetPlatform>[
    TargetPlatform.linux_arm64,
    TargetPlatform.linux_arm64
  ];

  testWithoutContext('Copies files to correct cache directory, excluding unrelated code', () async {
    for (final TargetPlatform targetPlatform in targetPlatforms) {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final Artifacts artifacts = Artifacts.test();
      setUpCacheDirectory(fileSystem, artifacts, targetPlatform);

      final Environment testEnvironment = Environment.test(
        fileSystem.currentDirectory,
        defines: <String, String>{
          kBuildMode: 'debug',
        },
        artifacts: artifacts,
        processManager: FakeProcessManager.any(),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
      );
      testEnvironment.buildDir.createSync(recursive: true);

      switch (targetPlatform) {
      case TargetPlatform.linux_arm64:
        await const UnpackLinux(TargetPlatform.linux_arm64).build(testEnvironment);
        break;
      case TargetPlatform.linux_x64:
      default:
        await const UnpackLinux(TargetPlatform.linux_x64).build(testEnvironment);
        break;
      }

      expect(fileSystem.file('linux/flutter/ephemeral/libflutter_linux_gtk.so'), exists);

      final String headersPath = artifacts.getArtifactPath(Artifact.linuxHeaders, platform: targetPlatform, mode: BuildMode.debug);
      expect(fileSystem.file('linux/flutter/ephemeral/$headersPath/foo.h'), exists);

      final String icuDataPath = artifacts.getArtifactPath(Artifact.icuData, platform: targetPlatform);
      expect(fileSystem.file('linux/flutter/ephemeral/$icuDataPath'), exists);
      expect(fileSystem.file('linux/flutter/ephemeral/unrelated-stuff'), isNot(exists));
    }
  });

  // Only required for the test below that still depends on the context.
  FileSystem fileSystem;
  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  testUsingContext('DebugBundleLinuxAssets copies artifacts to out directory', () async {
    final Environment testEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'debug',
      },
      inputs: <String, String>{
        kBundleSkSLPath: 'bundle.sksl',
      },
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      engineVersion: '2',
    );

    testEnvironment.buildDir.createSync(recursive: true);

    // Create input files.
    testEnvironment.buildDir.childFile('app.dill').createSync();
    fileSystem.file('bundle.sksl').writeAsStringSync(json.encode(
      <String, Object>{
        'engineRevision': '2',
        'platform': 'ios',
        'data': <String, Object>{
          'A': 'B',
        }
      }
    ));

    for (final TargetPlatform targetPlatform in targetPlatforms) {
      switch (targetPlatform) {
      case TargetPlatform.linux_arm64:
        await const DebugBundleLinuxAssets(TargetPlatform.linux_arm64).build(testEnvironment);
        break;
      case TargetPlatform.linux_x64:
      default:
        await const DebugBundleLinuxAssets(TargetPlatform.linux_x64).build(testEnvironment);
        break;
      }
      final Directory output = testEnvironment.outputDir
        .childDirectory('flutter_assets');

      expect(output.childFile('kernel_blob.bin'), exists);
      expect(output.childFile('AssetManifest.json'), exists);
      expect(output.childFile('version.json'), exists);
      // SkSL
      expect(output.childFile('io.flutter.shaders.json'), exists);
      expect(output.childFile('io.flutter.shaders.json').readAsStringSync(), '{"data":{"A":"B"}}');

      // No bundled fonts
      expect(output.childFile('FontManifest.json'), isNot(exists));
    }
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('ProfileBundleLinuxAssets copies artifacts to out directory', () async {
    final Environment testEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'profile',
      },
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );

    testEnvironment.buildDir.createSync(recursive: true);

    // Create input files.
    testEnvironment.buildDir.childFile('app.so').createSync();

    for (final TargetPlatform targetPlatform in targetPlatforms) {
      switch (targetPlatform) {
      case TargetPlatform.linux_arm64:
        await const LinuxAotBundle(AotElfProfile(TargetPlatform.linux_arm64)).build(testEnvironment);
        await const ProfileBundleLinuxAssets(TargetPlatform.linux_arm64).build(testEnvironment);
        break;
      case TargetPlatform.linux_x64:
      default:
        await const LinuxAotBundle(AotElfProfile(TargetPlatform.linux_x64)).build(testEnvironment);
        await const ProfileBundleLinuxAssets(TargetPlatform.linux_x64).build(testEnvironment);
        break;
      }

      final Directory libDir = testEnvironment.outputDir
        .childDirectory('lib');
      final Directory assetsDir = testEnvironment.outputDir
        .childDirectory('flutter_assets');

      expect(libDir.childFile('libapp.so'), exists);
      expect(assetsDir.childFile('AssetManifest.json'), exists);
      expect(assetsDir.childFile('version.json'), exists);
      // No bundled fonts
      expect(assetsDir.childFile('FontManifest.json'), isNot(exists));
    }
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('ReleaseBundleLinuxAssets copies artifacts to out directory', () async {
    final Environment testEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'release',
      },
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );

    testEnvironment.buildDir.createSync(recursive: true);

    // Create input files.
    testEnvironment.buildDir.childFile('app.so').createSync();

    for (final TargetPlatform targetPlatform in targetPlatforms) {
      switch (targetPlatform) {
      case TargetPlatform.linux_arm64:
        await const LinuxAotBundle(AotElfRelease(TargetPlatform.linux_arm64)).build(testEnvironment);
        await const ReleaseBundleLinuxAssets(TargetPlatform.linux_arm64).build(testEnvironment);
        break;
      case TargetPlatform.linux_x64:
      default:
        await const LinuxAotBundle(AotElfRelease(TargetPlatform.linux_x64)).build(testEnvironment);
        await const ReleaseBundleLinuxAssets(TargetPlatform.linux_x64).build(testEnvironment);
        break;
      }
      final Directory libDir = testEnvironment.outputDir
        .childDirectory('lib');
      final Directory assetsDir = testEnvironment.outputDir
        .childDirectory('flutter_assets');

      expect(libDir.childFile('libapp.so'), exists);
      expect(assetsDir.childFile('AssetManifest.json'), exists);
      expect(assetsDir.childFile('version.json'), exists);
      // No bundled fonts
      expect(assetsDir.childFile('FontManifest.json'), isNot(exists));
    }
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}

void setUpCacheDirectory(
    FileSystem fileSystem, Artifacts artifacts, TargetPlatform targetPlatform) {
  final String desktopPath = artifacts.getArtifactPath(Artifact.linuxDesktopPath, platform: targetPlatform, mode: BuildMode.debug);
  fileSystem.file('$desktopPath/unrelated-stuff').createSync(recursive: true);
  fileSystem.file('$desktopPath/libflutter_linux_gtk.so').createSync(recursive: true);

  final String headersPath = artifacts.getArtifactPath(Artifact.linuxHeaders, platform: targetPlatform, mode: BuildMode.debug);
  fileSystem.file('$headersPath/foo.h').createSync(recursive: true);

  fileSystem.file(artifacts.getArtifactPath(Artifact.icuData, platform: targetPlatform)).createSync();
  fileSystem.file('packages/flutter_tools/lib/src/build_system/targets/linux.dart').createSync(recursive: true);
}
