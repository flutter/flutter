// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:test/test.dart';

import '../src/context.dart';

const String _kBuildDirectory = '/build/app/outputs';

void main() {
  FileSystem fs;

  setUp(() {
    fs = new MemoryFileSystem();
    fs.directory('$_kBuildDirectory/release').createSync(recursive: true);
    fs.file('$_kBuildDirectory/app-debug.apk').createSync();
    fs.file('$_kBuildDirectory/release/app-release.apk').createSync();
  });

  group('gradle', () {
    testUsingContext('findApkFile', () {
      expect(findApkFile(_kBuildDirectory, 'debug').path,
             '/build/app/outputs/app-debug.apk');
      expect(findApkFile(_kBuildDirectory, 'release').path,
             '/build/app/outputs/release/app-release.apk');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });
  });
}
