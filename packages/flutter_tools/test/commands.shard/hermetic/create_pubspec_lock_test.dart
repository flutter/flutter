// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';

import '../../src/common.dart';

void main() {
  late FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    Cache.flutterRoot = '/flutter';
  });

  // Writes a minimal SDK package pubspec with a single hosted dependency.
  void writeSdkPackagePubspec(String path, String name) {
    fileSystem.file(path)
      ..createSync(recursive: true)
      ..writeAsStringSync('name: $name\ndependencies:\n  vector_math: 2.1.4\n');
  }

  Directory writeProject(String pubspec) {
    final Directory projectDir = fileSystem.directory('/project')..createSync();
    projectDir.childFile('pubspec.yaml').writeAsStringSync(pubspec);
    return projectDir;
  }

  testWithoutContext('resolves SDK packages vendored under bin/cache/pkg', () {
    // `flutter` lives under packages/, while `flutter_gpu` is vendored into
    // bin/cache/pkg. Both must be resolved without throwing.
    writeSdkPackagePubspec('/flutter/packages/flutter/pubspec.yaml', 'flutter');
    writeSdkPackagePubspec('/flutter/bin/cache/pkg/flutter_gpu/pubspec.yaml', 'flutter_gpu');

    final Directory projectDir = writeProject(
      'name: my_app\n'
      'dependencies:\n'
      '  flutter:\n'
      '    sdk: flutter\n'
      '  flutter_gpu:\n'
      '    sdk: flutter\n',
    );

    expect(() => gatherSdkPackageDependencies(projectDir), returnsNormally);
    expect(gatherSdkPackageDependencies(projectDir), contains('vector_math'));
  });

  testWithoutContext('skips an SDK package whose pubspec cannot be found', () {
    writeSdkPackagePubspec('/flutter/packages/flutter/pubspec.yaml', 'flutter');

    final Directory projectDir = writeProject(
      'name: my_app\n'
      'dependencies:\n'
      '  flutter:\n'
      '    sdk: flutter\n'
      '  not_a_real_sdk_package:\n'
      '    sdk: flutter\n',
    );

    expect(() => gatherSdkPackageDependencies(projectDir), returnsNormally);
    expect(gatherSdkPackageDependencies(projectDir), contains('vector_math'));
  });

  testWithoutContext('skips an SDK package whose directory exists but has no pubspec', () {
    writeSdkPackagePubspec('/flutter/packages/flutter/pubspec.yaml', 'flutter');
    // The package directory exists, but does not contain a pubspec.yaml.
    fileSystem.directory('/flutter/bin/cache/pkg/empty_pkg').createSync(recursive: true);

    final Directory projectDir = writeProject(
      'name: my_app\n'
      'dependencies:\n'
      '  flutter:\n'
      '    sdk: flutter\n'
      '  empty_pkg:\n'
      '    sdk: flutter\n',
    );

    expect(() => gatherSdkPackageDependencies(projectDir), returnsNormally);
    expect(gatherSdkPackageDependencies(projectDir), contains('vector_math'));
  });

  testWithoutContext('throws ToolExit if project pubspec.yaml is empty', () {
    final Directory projectDir = writeProject('');
    expect(() => gatherSdkPackageDependencies(projectDir), throwsA(isA<ToolExit>()));
  });

  testWithoutContext('does not throw if project pubspec.yaml has no dependencies', () {
    final Directory projectDir = writeProject('name: my_app\n');
    expect(() => gatherSdkPackageDependencies(projectDir), returnsNormally);
    expect(gatherSdkPackageDependencies(projectDir), isEmpty);
  });
}
