// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/android.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/cache.dart';

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
}
