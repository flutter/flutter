// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/apk_locator.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('ApkLocator can locate exact debug APK', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    // Create unrelated APK to verify it is not returned as a candidate.
    fileSystem.file('app.apk').createSync();
    fileSystem.file('debug/app-debug.apk').createSync(recursive: true);

    final List<File> candidates = apkLocator.locate(
      fileSystem.currentDirectory,
      androidBuildInfo: const AndroidBuildInfo(BuildInfo.debug),
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.path, '/debug/app-debug.apk');
  });

  testWithoutContext('ApkLocator can locate exact profile APK', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    // Create unrelated APK to verify it is not returned as a candidate.
    fileSystem.file('app.apk').createSync();
    fileSystem.file('profile/app-profile.apk').createSync(recursive: true);

    final List<File> candidates = apkLocator.locate(
      fileSystem.currentDirectory,
      androidBuildInfo: const AndroidBuildInfo(BuildInfo.profile),
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.path, '/profile/app-profile.apk');
  });

  testWithoutContext('ApkLocator can locate exact release APK', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    // Create unrelated APK to verify it is not returned as a candidate.
    fileSystem.file('app.apk').createSync();
    fileSystem.file('release/app-release.apk').createSync(recursive: true);

    final List<File> candidates = apkLocator.locate(
      fileSystem.currentDirectory,
      androidBuildInfo: const AndroidBuildInfo(BuildInfo.release),
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.path, '/release/app-release.apk');
  });

  testWithoutContext('ApkLocator can locate exact release APK with split-per-abi', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    // Create unrelated APK to verify it is not returned as a candidate.
    fileSystem.file('app.apk').createSync();

    // Create 3 different ABIs
    fileSystem.file('release/app-armeabi-v7a-release.apk').createSync(recursive: true);
    fileSystem.file('release/app-arm64-v8a-release.apk').createSync(recursive: true);
    fileSystem.file('release/app-x86_64-release.apk').createSync(recursive: true);

    final List<File> candidates = apkLocator.locate(
      fileSystem.currentDirectory,
      androidBuildInfo: const AndroidBuildInfo(BuildInfo.release, splitPerAbi: true),
    );

    expect(candidates, hasLength(3));
    expect(candidates.map((File file) => file.path), containsAll(<String>[
      '/release/app-armeabi-v7a-release.apk',
      '/release/app-arm64-v8a-release.apk',
      '/release/app-x86_64-release.apk',
    ]));
  });


  testWithoutContext('ApkLocator can locate exact release APK with flavor', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    // Create unrelated APK to verify it is not returned as a candidate.
    fileSystem.file('app.apk').createSync();
    fileSystem.file('paid/release/app-paid-release.apk').createSync(recursive: true);

    final List<File> candidates = apkLocator.locate(
      fileSystem.currentDirectory,
      androidBuildInfo: const AndroidBuildInfo(
        BuildInfo(BuildMode.release, 'paid', treeShakeIcons: false)),
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.path, '/paid/release/app-paid-release.apk');
  });

   testWithoutContext('ApkLocator heuristics ignores excludePath APKs', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    fileSystem.file('app.apk').createSync();

    final List<File> candidates = apkLocator.locate(
      fileSystem.currentDirectory,
      androidBuildInfo: const AndroidBuildInfo(BuildInfo.debug),
      excludePaths: <String> { 'app.apk' },
    );

    expect(candidates, isEmpty);
  });

  testWithoutContext('ApkLocator heuristics sorts recently modified files first', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    fileSystem.file('app.a.apk')
      ..createSync()
      ..setLastModifiedSync(DateTime(1991));
    fileSystem.file('app.b.apk')
      ..createSync()
      ..setLastModifiedSync(DateTime(2020));

    final List<File> candidates = apkLocator.locate(
      fileSystem.currentDirectory,
      androidBuildInfo: const AndroidBuildInfo(BuildInfo.debug),
    );

    expect(candidates, hasLength(2));
    expect(candidates.map((File file) => file.path), containsAllInOrder(<String>[
      'app.b.apk',
      'app.a.apk',
    ]));
  });

  testWithoutContext('ApkLocator heuristics ignores files without a .apk file extension', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    fileSystem.file('app.foo').createSync();

    final List<File> candidates = apkLocator.locate(
      fileSystem.currentDirectory,
      androidBuildInfo: const AndroidBuildInfo(BuildInfo.debug),
    );

    expect(candidates, isEmpty);
  });

  testWithoutContext('ApkLocator heuristics sorts APKs matching the build mode first', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    fileSystem.file('debug/app.apk').createSync(recursive: true);
    fileSystem.file('release/app.apk').createSync(recursive: true);

    final List<File> candidates = apkLocator.locate(
      fileSystem.currentDirectory,
      androidBuildInfo: const AndroidBuildInfo(BuildInfo.debug),
    );

    expect(candidates, hasLength(2));
    expect(candidates.map((File file) => file.path), containsAllInOrder(<String>[
      'debug/app.apk',
      'release/app.apk',
    ]));
  });

  testWithoutContext('ApkLocator heuristics sorts APKs matching the flavor first', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    fileSystem.file('free/app.apk').createSync(recursive: true);
    fileSystem.file('paid/app.apk').createSync(recursive: true);

    final List<File> candidates = apkLocator.locate(
      fileSystem.currentDirectory,
      androidBuildInfo: const AndroidBuildInfo(
        BuildInfo(BuildMode.debug, 'free', treeShakeIcons: false)),
    );

    expect(candidates, hasLength(2));
    expect(candidates.map((File file) => file.path), containsAllInOrder(<String>[
      'free/app.apk',
      'paid/app.apk',
    ]));
  });

  testWithoutContext('ApkLocator does not crash when output directory does not exist', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ApkLocator apkLocator = ApkLocator(fileSystem: fileSystem);

    final Directory missingDirectory = fileSystem.directory('does-not-exist');
    final List<File> candidates = apkLocator.locate(
      missingDirectory,
      androidBuildInfo: const AndroidBuildInfo(BuildInfo.debug),
    );

    expect(candidates, isEmpty);
  });
}
