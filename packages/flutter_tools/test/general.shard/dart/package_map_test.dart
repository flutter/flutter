// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:package_config/package_config.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('findPackageConfigFile', () {
    late FileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    test('should find an immediate .dart_tool/package_config.json', () {
      fileSystem.file('.dart_tool/package_config.json').createSync(recursive: true);
      expect(findPackageConfigFile(fileSystem.currentDirectory), isNotNull);
    });

    test('should find a parent .dart_tool/package_config.json', () {
      fileSystem.file('.dart_tool/package_config.json').createSync(recursive: true);
      fileSystem.currentDirectory.childDirectory('child').createSync(recursive: true);
      expect(findPackageConfigFile(fileSystem.currentDirectory.childDirectory('child')), isNotNull);
    });

    test('should not find a .dart_tool/package_config.json in an existing directory', () {
      fileSystem.currentDirectory.childDirectory('child').createSync(recursive: true);
      expect(findPackageConfigFile(fileSystem.currentDirectory.childDirectory('child')), isNull);
    });

    // Regression test: https://github.com/flutter/flutter/issues/163901.
    test('should not find a .dart_tool/package_config.json in a missing directory', () {
      expect(findPackageConfigFile(fileSystem.currentDirectory.childDirectory('missing')), isNull);
    });

    // Regression test: https://github.com/flutter/flutter/issues/163901.
    test('should find a .dart_tool/package_config.json in a parent of a missing directory', () {
      fileSystem.file('.dart_tool/package_config.json').createSync(recursive: true);
      expect(
        findPackageConfigFile(fileSystem.currentDirectory.childDirectory('missing')),
        isNotNull,
      );
    });

    test('Works with a relative directory', () {
      final Directory child = fileSystem.currentDirectory.childDirectory('child');

      child.createSync(recursive: true);
      fileSystem.file('.dart_tool/package_config.json').createSync(recursive: true);
      fileSystem.currentDirectory = child;
      expect(findPackageConfigFile(fileSystem.directory('.')), isNotNull);
    });
  });

  group('currentPackageConfig', () {
    late FileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    tearDown(() {
      debugIgnorePackageConfigSync = false;
    });

    testUsingContext(
      'should load from CWD if Isolate.packageConfigSync is null',
      () async {
        debugIgnorePackageConfigSync = true;

        // Create a valid package config in CWD
        final File packageConfig = fileSystem.file('.dart_tool/package_config.json');
        packageConfig.createSync(recursive: true);
        packageConfig.writeAsStringSync('{"configVersion": 2, "packages": []}');

        final PackageConfig config = await currentPackageConfig();
        expect(config.version, 2);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(script: Uri.parse('file:///ambient/bin/main.dart')),
      },
    );

    testUsingContext(
      'should load from script directory if CWD has no package config',
      () async {
        debugIgnorePackageConfigSync = true;

        // CWD = '/cwd_dir'
        // Script = '/script_dir/bin/flutter_tools.dart'
        // Package config = '/script_dir/.dart_tool/package_config.json'

        final Directory cwd = fileSystem.directory('/cwd_dir')..createSync();
        fileSystem.currentDirectory = cwd;

        final File packageConfig = fileSystem.file('/script_dir/.dart_tool/package_config.json');
        packageConfig.createSync(recursive: true);
        packageConfig.writeAsStringSync('{"configVersion": 2, "packages": []}');

        final PackageConfig config = await currentPackageConfig();
        expect(config.version, 2);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () =>
            FakePlatform(script: Uri.parse('file:///script_dir/bin/flutter_tools.dart')),
      },
    );

    testUsingContext(
      'should throw ToolExit if package config cannot be found',
      () async {
        debugIgnorePackageConfigSync = true;

        expect(
          () => currentPackageConfig(),
          throwsToolExit(message: 'Failed to resolve package configuration'),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () =>
            FakePlatform(script: Uri.parse('file:///script_dir/bin/flutter_tools.dart')),
      },
    );
  });
}
