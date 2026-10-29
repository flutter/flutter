// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension_linux_prototype/src/clean.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxCleanService', () {
    test('deletes linux build and ephemeral directories when present', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_clean_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final buildDir = Directory('${tempDir.path}/build')..createSync(recursive: true);
      final linuxBuildDir = Directory('${buildDir.path}/linux')..createSync(recursive: true);
      File('${linuxBuildDir.path}/app.so').writeAsStringSync('binary');

      final linuxEphemeralDir = Directory('${tempDir.path}/linux/flutter/ephemeral')
        ..createSync(recursive: true);
      File('${linuxEphemeralDir.path}/generated_config.cmake').writeAsStringSync('cmake');

      final service = LinuxCleanService();
      await service.clean(CleanEnvironment(buildDir: buildDir.uri, projectRoot: tempDir.uri));

      expect(linuxBuildDir.existsSync(), isFalse);
      expect(linuxEphemeralDir.existsSync(), isFalse);
      expect(buildDir.existsSync(), isTrue);
    });

    test('is a no-op when linux build and ephemeral directories do not exist', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_clean_noop_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final buildDir = Directory('${tempDir.path}/build');
      final service = LinuxCleanService();
      await service.clean(CleanEnvironment(buildDir: buildDir.uri, projectRoot: tempDir.uri));

      expect(buildDir.existsSync(), isFalse);
      expect(tempDir.existsSync(), isTrue);
    });
  });
}
