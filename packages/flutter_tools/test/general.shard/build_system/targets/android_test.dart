// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/android.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:mockito/mockito.dart';

import '../../../src/common.dart';
import '../../../src/testbed.dart';

void main() {
  final Testbed testbed = Testbed(overrides: <Type, Generator>{
    Cache: () => FakeCache(),
  });

  testbed.test('debug bundle contains expected resources', () async {
    final Environment environment = Environment(
      outputDir: fs.directory('out')..createSync(),
      projectDir: fs.currentDirectory,
      buildDir: fs.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'debug',
      }
    );
    environment.buildDir.createSync(recursive: true);

    // create pre-requisites.
    environment.buildDir.childFile('app.dill')
      ..writeAsStringSync('abcd');
    final Directory hostDirectory = fs.currentDirectory
      .childDirectory(getNameForHostPlatform(getCurrentHostPlatform()))
      ..createSync(recursive: true);
    hostDirectory.childFile('vm_isolate_snapshot.bin').createSync();
    hostDirectory.childFile('isolate_snapshot.bin').createSync();


    await const DebugAndroidApplication().build(environment);

    expect(fs.file(fs.path.join('out', 'flutter_assets', 'isolate_snapshot_data')).existsSync(), true);
    expect(fs.file(fs.path.join('out', 'flutter_assets', 'vm_snapshot_data')).existsSync(), true);
    expect(fs.file(fs.path.join('out', 'flutter_assets', 'kernel_blob.bin')).existsSync(), true);
  });

  testbed.test('profile bundle contains expected resources', () async {
    final Environment environment = Environment(
      outputDir: fs.directory('out')..createSync(),
      projectDir: fs.currentDirectory,
      buildDir: fs.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'profile',
      }
    );
    environment.buildDir.createSync(recursive: true);

    // create pre-requisites.
    environment.buildDir.childFile('app.so')
      ..writeAsStringSync('abcd');

    await const ProfileAndroidApplication().build(environment);

    expect(fs.file(fs.path.join('out', 'app.so')).existsSync(), true);
  });

  testbed.test('release bundle contains expected resources', () async {
    final Environment environment = Environment(
      outputDir: fs.directory('out')..createSync(),
      projectDir: fs.currentDirectory,
      buildDir: fs.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'release',
      }
    );
    environment.buildDir.createSync(recursive: true);

    // create pre-requisites.
    environment.buildDir.childFile('app.so')
      ..writeAsStringSync('abcd');

    await const ReleaseAndroidApplication().build(environment);

    expect(fs.file(fs.path.join('out', 'app.so')).existsSync(), true);
  });

  testbed.test('AndroidAot can build provided target platform', () async {
    final Environment environment = Environment(
      outputDir: fs.directory('out')..createSync(),
      projectDir: fs.currentDirectory,
      buildDir: fs.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'release',
      }
    );
    when(genSnapshot.run(
      snapshotType: anyNamed('snapshotType'),
      darwinArch: anyNamed('darwinArch'),
      additionalArgs: anyNamed('additionalArgs'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    environment.buildDir.createSync(recursive: true);
    environment.buildDir.childFile('app.dill').createSync();
    environment.projectDir.childFile('.packages')
      .writeAsStringSync('sky_engine:file:///\n');
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);

    await androidAot.build(environment);

    final SnapshotType snapshotType = verify(genSnapshot.run(
      snapshotType: captureAnyNamed('snapshotType'),
      darwinArch: anyNamed('darwinArch'),
      additionalArgs: anyNamed('additionalArgs')
    )).captured.single;

    expect(snapshotType.platform, TargetPlatform.android_arm64);
    expect(snapshotType.mode, BuildMode.release);
  }, overrides: <Type, Generator>{
    GenSnapshot: () => MockGenSnapshot(),
  });

  testbed.test('android aot bundle copies so from abi directory', () async {
    final Environment environment = Environment(
      outputDir: fs.directory('out')..createSync(),
      projectDir: fs.currentDirectory,
      buildDir: fs.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'release',
      }
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

class MockGenSnapshot extends Mock implements GenSnapshot {}

