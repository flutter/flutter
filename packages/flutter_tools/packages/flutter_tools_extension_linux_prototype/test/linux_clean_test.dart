// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/testing.dart';
import 'package:flutter_tools_extension_linux_prototype/src/clean.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxCleanService', () {
    test('deletes linux build and ephemeral directories when present', () async {
      final ExtensionDependencies dependencies = createTestDependencies();
      final ExtensionDirectory projectDir = dependencies.fileSystem.directory(
        Uri.parse('file:///project/'),
      )..createSync(recursive: true);

      final ExtensionDirectory buildDir = projectDir.childDirectory('build')
        ..createSync(recursive: true);
      final ExtensionDirectory linuxBuildDir = buildDir.childDirectory('linux')
        ..createSync(recursive: true);
      linuxBuildDir.childFile('app.so').writeAsStringSync('binary');

      final ExtensionDirectory linuxEphemeralDir =
          projectDir.childDirectory('linux').childDirectory('flutter').childDirectory('ephemeral')
            ..createSync(recursive: true);
      linuxEphemeralDir.childFile('generated_config.cmake').writeAsStringSync('cmake');

      final service = LinuxCleanService(dependencies: dependencies);
      await service.clean(CleanEnvironment(buildDir: buildDir.uri, projectRoot: projectDir.uri));

      expect(linuxBuildDir.existsSync(), isFalse);
      expect(linuxEphemeralDir.existsSync(), isFalse);
      expect(buildDir.existsSync(), isTrue);
    });

    test('is a no-op when linux build and ephemeral directories do not exist', () async {
      final ExtensionDependencies dependencies = createTestDependencies();
      final ExtensionDirectory projectDir = dependencies.fileSystem.directory(
        Uri.parse('file:///project/'),
      )..createSync(recursive: true);
      final ExtensionDirectory buildDir = projectDir.childDirectory('build');

      final service = LinuxCleanService(dependencies: dependencies);
      await service.clean(CleanEnvironment(buildDir: buildDir.uri, projectRoot: projectDir.uri));

      expect(buildDir.existsSync(), isFalse);
      expect(projectDir.existsSync(), isTrue);
    });
  });
}
