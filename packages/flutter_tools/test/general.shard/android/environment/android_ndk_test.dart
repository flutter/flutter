// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/environment/environment.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../../src/common.dart';

void main() {
  late Config config;
  late MemoryFileSystem fs;

  setUp(() {
    config = Config.test();
    fs = MemoryFileSystem.test();
  });

  group(AndroidNdk, () {
    testWithoutContext('locates latest NDK version and compiler toolchain binaries', () {
      final Directory sdkRoot = fs.directory('/sdk')..createSync();
      final Directory ndkDir = sdkRoot.childDirectory('ndk')..createSync();
      final Directory ndk27 = ndkDir.childDirectory('27.0.12077973')..createSync();

      // Create clang inside ndk 27
      final Directory binDir =
          ndk27
              .childDirectory('toolchains')
              .childDirectory('llvm')
              .childDirectory('prebuilt')
              .childDirectory('linux-x86_64')
              .childDirectory('bin')
            ..createSync(recursive: true);
      final File clang = binDir.childFile('clang')..createSync();
      final File ar = binDir.childFile('llvm-ar')..createSync();
      final File ld = binDir.childFile('ld.lld')..createSync();

      final AndroidNdk? ndk = AndroidNdk.locate(
        config: config,
        platform: FakePlatform(),
        sdkDir: sdkRoot,
      );

      expect(ndk, isNotNull);
      expect(ndk!.directory.path, ndk27.path);
      expect(ndk.clangPath, clang.path);
      expect(ndk.arPath, ar.path);
      expect(ndk.ldPath, ld.path);
    });
  });
}
