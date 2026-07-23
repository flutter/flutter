// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

import '../bin/generate_gradle_lockfiles.dart' as bin;

void main() {
  late MemoryFileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  test('hasDartSources returns true for a project with lib/main.dart', () {
    final Directory projectDirectory = fileSystem.directory('/project')
      ..createSync(recursive: true);
    projectDirectory.childDirectory('lib').childFile('main.dart').createSync(recursive: true);

    expect(bin.hasDartSources(projectDirectory), isTrue);
  });

  test(
    'hasDartSources returns true for a project with a differently named main like frame_rate_main.dart',
    () {
      final Directory projectDirectory = fileSystem.directory('/project')
        ..createSync(recursive: true);
      projectDirectory
          .childDirectory('lib')
          .childFile('frame_rate_main.dart')
          .createSync(recursive: true);

      expect(
        bin.hasDartSources(projectDirectory),
        isTrue,
        reason:
            'A project with a differently named main file should be detected as having a main file',
      );
    },
  );

  test(
    'hasDartSources returns true for a project with a main file in a nested subdirectory under lib',
    () {
      final Directory projectDirectory = fileSystem.directory('/project')
        ..createSync(recursive: true);
      projectDirectory
          .childDirectory('lib')
          .childDirectory('subdir')
          .childFile('my_main.dart')
          .createSync(recursive: true);

      expect(bin.hasDartSources(projectDirectory), isTrue);
    },
  );

  test('hasDartSources returns false if the lib directory does not exist', () {
    final Directory projectDirectory = fileSystem.directory('/project')
      ..createSync(recursive: true);
    expect(bin.hasDartSources(projectDirectory), isFalse);
  });

  test('hasDartSources returns false if the lib directory is empty', () {
    final Directory projectDirectory = fileSystem.directory('/project')
      ..createSync(recursive: true);
    projectDirectory.childDirectory('lib').createSync(recursive: true);
    expect(bin.hasDartSources(projectDirectory), isFalse);
  });

  test('hasDartSources returns false if lib directory contains only non-Dart files', () {
    final Directory projectDirectory = fileSystem.directory('/project')
      ..createSync(recursive: true);
    projectDirectory.childDirectory('lib').childFile('README.md').createSync(recursive: true);
    expect(bin.hasDartSources(projectDirectory), isFalse);
  });
}
