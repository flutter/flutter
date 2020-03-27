// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/android.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/cache.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/testbed.dart';

void main() {
  FakeProcessManager fakeProcessManager;
  final Testbed testbed = Testbed(overrides: <Type, Generator>{
    Cache: () => FakeCache(),
    Platform: () => FakePlatform(operatingSystem: 'linux', environment: const <String, String>{}),
  });

  test('Android AOT targets has analyicsName', () {
    expect(androidArmProfile.analyticsName, 'android_aot');
  });

  testbed.test('debug bundle contains expected resources', () async {
    final Environment environment = Environment.test(
      globals.fs.currentDirectory,
      outputDir: globals.fs.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'debug',
      },
      processManager: fakeProcessManager,
      artifacts: MockArtifacts(),
      fileSystem: globals.fs,
      logger: globals.logger,
    );
    environment.buildDir.createSync(recursive: true);

    // create pre-requisites.
    environment.buildDir.childFile('app.dill')
      .writeAsStringSync('abcd');
    final Directory hostDirectory = globals.fs.currentDirectory
      .childDirectory(getNameForHostPlatform(getCurrentHostPlatform()))
      ..createSync(recursive: true);
    hostDirectory.childFile('vm_isolate_snapshot.bin').createSync();
    hostDirectory.childFile('isolate_snapshot.bin').createSync();

    await const DebugAndroidApplication().build(environment);

    expect(globals.fs.file(globals.fs.path.join('out', 'flutter_assets', 'isolate_snapshot_data')).existsSync(), true);
    expect(globals.fs.file(globals.fs.path.join('out', 'flutter_assets', 'vm_snapshot_data')).existsSync(), true);
    expect(globals.fs.file(globals.fs.path.join('out', 'flutter_assets', 'kernel_blob.bin')).existsSync(), true);
  });

  testbed.test('profile bundle contains expected resources', () async {
    final Environment environment = Environment.test(
      globals.fs.currentDirectory,
      outputDir: globals.fs.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'profile',
      },
      artifacts: MockArtifacts(),
      processManager: fakeProcessManager,
      fileSystem: globals.fs,
      logger: globals.logger,
    );
    environment.buildDir.createSync(recursive: true);

    // create pre-requisites.
    environment.buildDir.childFile('app.so')
      .writeAsStringSync('abcd');

    await const ProfileAndroidApplication().build(environment);

    expect(globals.fs.file(globals.fs.path.join('out', 'app.so')).existsSync(), true);
  });

  testbed.test('release bundle contains expected resources', () async {
    final Environment environment = Environment.test(
      globals.fs.currentDirectory,
      outputDir: globals.fs.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'release',
      },
      artifacts: MockArtifacts(),
      processManager: fakeProcessManager,
      fileSystem: globals.fs,
      logger: globals.logger,
    );
    environment.buildDir.createSync(recursive: true);

    // create pre-requisites.
    environment.buildDir.childFile('app.so')
      .writeAsStringSync('abcd');

    await const ReleaseAndroidApplication().build(environment);

    expect(globals.fs.file(globals.fs.path.join('out', 'app.so')).existsSync(), true);
  });

  testbed.test('AndroidAot can build provided target platform', () async {
    fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
    final Environment environment = Environment.test(
      globals.fs.currentDirectory,
      outputDir: globals.fs.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'release',
      },
      artifacts: MockArtifacts(),
      processManager: FakeProcessManager.list(<FakeCommand>[]),
      fileSystem: globals.fs,
      logger: globals.logger,
    );
    fakeProcessManager.addCommand(FakeCommand(command: <String>[
        globals.fs.path.absolute(globals.fs.path.join('android-arm64-release', 'linux-x64', 'gen_snapshot')),
        '--deterministic',
        '--snapshot_kind=app-aot-elf',
        '--elf=${environment.buildDir.childDirectory('arm64-v8a').childFile('app.so').path}',
        '--strip',
        '--no-causal-async-stacks',
        '--lazy-async-stacks',
        environment.buildDir.childFile('app.dill').path,
        ],
      )
    );
    environment.buildDir.createSync(recursive: true);
    environment.buildDir.childFile('app.dill').createSync();
    environment.projectDir.childFile('.packages').writeAsStringSync('\n');
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);

    await androidAot.build(environment);

    expect(fakeProcessManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    ProcessManager: () => fakeProcessManager,
  });

  testbed.test('kExtraGenSnapshotOptions passes values to gen_snapshot', () async {
    fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
    final Environment environment = Environment.test(
      globals.fs.currentDirectory,
      outputDir: globals.fs.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'release',
        kExtraGenSnapshotOptions: 'foo,bar,baz=2',
        kTargetPlatform: 'android-arm',
      },
      processManager: fakeProcessManager,
      artifacts: MockArtifacts(),
      fileSystem: globals.fs,
      logger: globals.logger,
    );
    fakeProcessManager.addCommand(
      FakeCommand(command: <String>[
         globals.fs.path.absolute(globals.fs.path.join('android-arm64-release', 'linux-x64', 'gen_snapshot')),
        '--deterministic',
        'foo',
        'bar',
        'baz=2',
        '--snapshot_kind=app-aot-elf',
        '--elf=${environment.buildDir.childDirectory('arm64-v8a').childFile('app.so').path}',
        '--strip',
        '--no-causal-async-stacks',
        '--lazy-async-stacks',
        environment.buildDir.childFile('app.dill').path
      ]));
    environment.buildDir.createSync(recursive: true);
    environment.buildDir.childFile('app.dill').createSync();
    environment.projectDir.childFile('.packages').writeAsStringSync('\n');

    await const AndroidAot(TargetPlatform.android_arm64, BuildMode.release)
      .build(environment);
  }, overrides: <Type, Generator>{
    ProcessManager: () => fakeProcessManager,
  });

  testbed.test('android aot bundle copies so from abi directory', () async {
    final Environment environment = Environment.test(
      globals.fs.currentDirectory,
      outputDir: globals.fs.directory('out')..createSync(),
      defines: <String, String>{
        kBuildMode: 'release',
      },
      processManager: fakeProcessManager,
      artifacts: MockArtifacts(),
      fileSystem: globals.fs,
      logger: globals.logger,
    );
    environment.buildDir.createSync(recursive: true);
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);
    const AndroidAotBundle androidAotBundle = AndroidAotBundle(androidAot);
    // Create required files.
    environment.buildDir
      .childDirectory('arm64-v8a')
      .childFile('app.so')
      .createSync(recursive: true);

    await androidAotBundle.build(environment);

    expect(environment.outputDir
      .childDirectory('arm64-v8a')
      .childFile('app.so').existsSync(), true);
  });
}

class MockArtifacts extends Mock implements Artifacts {}