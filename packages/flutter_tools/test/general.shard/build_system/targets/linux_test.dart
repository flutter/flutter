// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  testWithoutContext('Copies files to correct cache directory, excluding unrelated code', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Artifacts artifacts = Artifacts.test();
    setUpCacheDirectory(fileSystem, artifacts);

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

    await const UnpackLinux().build(testEnvironment);

    expect(fileSystem.file('linux/flutter/ephemeral/libflutter_linux_gtk.so'), exists);

    final String headersPath = artifacts.getArtifactPath(Artifact.linuxHeaders, platform: TargetPlatform.linux_x64, mode: BuildMode.debug);
    expect(fileSystem.file('linux/flutter/ephemeral/$headersPath/foo.h'), exists);

    final String icuDataPath = artifacts.getArtifactPath(Artifact.icuData, platform: TargetPlatform.linux_x64);
    expect(fileSystem.file('linux/flutter/ephemeral/$icuDataPath'), exists);
    expect(fileSystem.file('linux/flutter/ephemeral/unrelated-stuff'), isNot(exists));
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

    await const DebugBundleLinuxAssets().build(testEnvironment);
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

    await const LinuxAotBundle(AotElfProfile(TargetPlatform.linux_x64)).build(testEnvironment);
    await const ProfileBundleLinuxAssets().build(testEnvironment);
    final Directory libDir = testEnvironment.outputDir
      .childDirectory('lib');
    final Directory assetsDir = testEnvironment.outputDir
      .childDirectory('flutter_assets');

    expect(libDir.childFile('libapp.so'), exists);
    expect(assetsDir.childFile('AssetManifest.json'), exists);
    expect(assetsDir.childFile('version.json'), exists);
    // No bundled fonts
    expect(assetsDir.childFile('FontManifest.json'), isNot(exists));
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

    await const LinuxAotBundle(AotElfRelease(TargetPlatform.linux_x64)).build(testEnvironment);
    await const ReleaseBundleLinuxAssets().build(testEnvironment);
    final Directory libDir = testEnvironment.outputDir
      .childDirectory('lib');
    final Directory assetsDir = testEnvironment.outputDir
      .childDirectory('flutter_assets');

    expect(libDir.childFile('libapp.so'), exists);
    expect(assetsDir.childFile('AssetManifest.json'), exists);
    expect(assetsDir.childFile('version.json'), exists);
    // No bundled fonts
    expect(assetsDir.childFile('FontManifest.json'), isNot(exists));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}

void setUpCacheDirectory(FileSystem fileSystem, Artifacts artifacts) {
  final String desktopPath = artifacts.getArtifactPath(Artifact.linuxDesktopPath, platform: TargetPlatform.linux_x64, mode: BuildMode.debug);
  fileSystem.file('$desktopPath/unrelated-stuff').createSync(recursive: true);
  fileSystem.file('$desktopPath/libflutter_linux_gtk.so').createSync(recursive: true);

  final String headersPath = artifacts.getArtifactPath(Artifact.linuxHeaders, platform: TargetPlatform.linux_x64, mode: BuildMode.debug);
  fileSystem.file('$headersPath/foo.h').createSync(recursive: true);

  fileSystem.file(artifacts.getArtifactPath(Artifact.icuData, platform: TargetPlatform.linux_x64)).createSync();
  fileSystem.file('packages/flutter_tools/lib/src/build_system/targets/linux.dart').createSync(recursive: true);
}
