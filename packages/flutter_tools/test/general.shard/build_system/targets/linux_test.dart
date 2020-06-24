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
import 'package:mockito/mockito.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

void main() {
  testWithoutContext('Copies files to correct cache directory, excluding unrelated code', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    setUpCacheDirectory(fileSystem);
    final MockArtifacts mockArtifacts = MockArtifacts();
    when(mockArtifacts.getArtifactPath(
      Artifact.linuxDesktopPath,
      mode: anyNamed('mode'),
      platform: anyNamed('platform'),
    )).thenReturn('linux-x64');
    when(mockArtifacts.getArtifactPath(
      Artifact.linuxHeaders,
      mode: anyNamed('mode'),
      platform: anyNamed('platform'),
    )).thenReturn('linux-x64/flutter_linux');
    when(mockArtifacts.getArtifactPath(
      Artifact.icuData,
      mode: anyNamed('mode'),
      platform: anyNamed('platform'),
    )).thenReturn(r'linux-x64/icudtl.dat');

    final Environment testEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'debug',
      },
      artifacts: mockArtifacts,
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
    testEnvironment.buildDir.createSync(recursive: true);

    await const UnpackLinux().build(testEnvironment);

    expect(fileSystem.file('linux/flutter/ephemeral/libflutter_linux_gtk.so'), exists);
    expect(fileSystem.file('linux/flutter/ephemeral/flutter_linux/foo.h'), exists);
    expect(fileSystem.file('linux/flutter/ephemeral/icudtl.dat'), exists);
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
      artifacts: MockArtifacts(),
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
      artifacts: MockArtifacts(),
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
      artifacts: MockArtifacts(),
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
    // No bundled fonts
    expect(assetsDir.childFile('FontManifest.json'), isNot(exists));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}

void setUpCacheDirectory(FileSystem fileSystem) {
  fileSystem.file('linux-x64/unrelated-stuff').createSync(recursive: true);
  fileSystem.file('linux-x64/libflutter_linux_gtk.so').createSync(recursive: true);
  fileSystem.file('linux-x64/flutter_linux/foo.h').createSync(recursive: true);
  fileSystem.file('linux-x64/icudtl.dat').createSync();
  fileSystem.file('packages/flutter_tools/lib/src/build_system/targets/linux.dart').createSync(recursive: true);
}

class MockArtifacts extends Mock implements Artifacts {}
