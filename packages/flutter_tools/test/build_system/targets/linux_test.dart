// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/linux.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('unpack_linux', () {
    Testbed testbed;
    BuildSystem buildSystem;
    Environment environment;
    MockPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockPlatform();
      when(mockPlatform.isWindows).thenReturn(false);
      testbed = Testbed(setup: () {
        final Directory cacheDir = fs.currentDirectory.childDirectory('cache');
        environment = Environment(
          projectDir: fs.currentDirectory,
          cacheDir: cacheDir,
        );
        buildSystem = const BuildSystem(<Target>[
          unpackLinux,
        ]);
        fs.file('cache/linux-x64/libflutter_linux.so').createSync(recursive: true);
        fs.file('cache/linux-x64/flutter_export.h').createSync();
        fs.file('cache/linux-x64/flutter_messenger.h').createSync();
        fs.file('cache/linux-x64/flutter_plugin_registrar.h').createSync();
        fs.file('cache/linux-x64/flutter_glfw.h').createSync();
        fs.file('cache/linux-x64/icudtl.dat').createSync();
        fs.file('cache/linux-x64/cpp_client_wrapper/foo').createSync(recursive: true);
        fs.directory('linux').createSync();
      }, overrides: <Type, Generator>{
        Platform: () => mockPlatform,
      });
    });

    test('Copies files to correct cache directory', () => testbed.run(() async {
      await buildSystem.build('unpack_linux', environment, const BuildSystemConfig());

      expect(fs.file('linux/flutter/libflutter_linux.so').existsSync(), true);
      expect(fs.file('linux/flutter/flutter_export.h').existsSync(), true);
      expect(fs.file('linux/flutter/flutter_messenger.h').existsSync(), true);
      expect(fs.file('linux/flutter/flutter_plugin_registrar.h').existsSync(), true);
      expect(fs.file('linux/flutter/flutter_glfw.h').existsSync(), true);
      expect(fs.file('linux/flutter/icudtl.dat').existsSync(), true);
      expect(fs.file('linux/flutter/cpp_client_wrapper/foo').existsSync(), true);
    }));

    test('Does not re-copy files unecessarily', () => testbed.run(() async {
      await buildSystem.build('unpack_linux', environment, const BuildSystemConfig());
      final DateTime modified = fs.file('linux/flutter/libflutter_linux.so').statSync().modified;
      await buildSystem.build('unpack_linux', environment, const BuildSystemConfig());

      expect(fs.file('linux/flutter/libflutter_linux.so').statSync().modified, equals(modified));
    }));

    test('Detects changes in input cache files', () => testbed.run(() async {
      await buildSystem.build('unpack_linux', environment, const BuildSystemConfig());
      final DateTime modified = fs.file('linux/flutter/libflutter_linux.so').statSync().modified;
      fs.file('cache/linux-x64/libflutter_linux.so').writeAsStringSync('asd'); // modify cache.

      await buildSystem.build('unpack_linux', environment, const BuildSystemConfig());

      expect(fs.file('linux/flutter/libflutter_linux.so').statSync().modified, isNot(modified));
    }));
  });
}

class MockPlatform extends Mock implements Platform {}
