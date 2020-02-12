// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';

void main() {
  final String flutterTools = globals.fs.path.join(getFlutterRoot(), 'packages', 'flutter_tools');

  test('no imports of commands/* or test/* in lib/src/*', () {
    final List<String> skippedPaths = <String> [
      globals.fs.path.join(flutterTools, 'lib', 'src', 'commands'),
      globals.fs.path.join(flutterTools, 'lib', 'src', 'test'),
    ];
    bool _isNotSkipped(FileSystemEntity entity) => skippedPaths.every((String path) => !entity.path.startsWith(path));

    final Iterable<File> files = globals.fs.directory(globals.fs.path.join(flutterTools, 'lib', 'src'))
      .listSync(recursive: true)
      .where(_isDartFile)
      .where(_isNotSkipped)
      .map(_asFile);
    for (final File file in files) {
      for (final String line in file.readAsLinesSync()) {
        if (line.startsWith(RegExp(r'import.*package:'))) {
          continue;
        }
        if (line.startsWith(RegExp(r'import.*commands/'))
         || line.startsWith(RegExp(r'import.*test/'))) {
          final String relativePath = globals.fs.path.relative(file.path, from:flutterTools);
          fail('$relativePath imports $line. This import introduces a layering violation. '
               'Please find another way to access the information you are using.');
        }
      }
    }
  });

  test('no imports of globals without a global prefix', () {
    final List<String> skippedPaths = <String> [];
    bool _isNotSkipped(FileSystemEntity entity) => skippedPaths.every((String path) => !entity.path.startsWith(path));

    final Iterable<File> files = globals.fs.directory(globals.fs.path.join(flutterTools, 'lib', 'src'))
      .listSync(recursive: true)
      .followedBy(globals.fs.directory(globals.fs.path.join(flutterTools, 'test',)).listSync(recursive: true))
      .where(_isDartFile)
      .where(_isNotSkipped)
      .map(_asFile);
    for (final File file in files) {
      for (final String line in file.readAsLinesSync()) {
        if (line.startsWith(RegExp(r'import.*globals.dart'))
         && !line.contains(r'as globals')) {
          final String relativePath = globals.fs.path.relative(file.path, from:flutterTools);
          fail('$relativePath imports globals.dart without a globals prefix.');
        }
      }
    }
  });

  test('no unauthorized imports of dart:io', () {
    final List<String> whitelistedPaths = <String>[
      globals.fs.path.join(flutterTools, 'lib', 'src', 'base', 'io.dart'),
      globals.fs.path.join(flutterTools, 'lib', 'src', 'base', 'error_handling_file_system.dart'),
    ];
    bool _isNotWhitelisted(FileSystemEntity entity) => whitelistedPaths.every((String path) => path != entity.path);

    for (final String dirName in <String>['lib', 'bin']) {
      final Iterable<File> files = globals.fs.directory(globals.fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .where(_isNotWhitelisted)
        .map(_asFile);
      for (final File file in files) {
        for (final String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*dart:io')) &&
              !line.contains('ignore: dart_io_import')) {
            final String relativePath = globals.fs.path.relative(file.path, from:flutterTools);
            fail("$relativePath imports 'dart:io'; import 'lib/src/base/io.dart' instead");
          }
        }
      }
    }
  });

  test('no unauthorized imports of test_api', () {
    final List<String> whitelistedPaths = <String>[
      globals.fs.path.join(flutterTools, 'lib', 'src', 'build_runner', 'build_script.dart'),
      globals.fs.path.join(flutterTools, 'lib', 'src', 'test', 'flutter_platform.dart'),
      globals.fs.path.join(flutterTools, 'lib', 'src', 'test', 'flutter_web_platform.dart'),
      globals.fs.path.join(flutterTools, 'lib', 'src', 'test', 'test_wrapper.dart'),
    ];
    bool _isNotWhitelisted(FileSystemEntity entity) => whitelistedPaths.every((String path) => path != entity.path);

    for (final String dirName in <String>['lib']) {
      final Iterable<File> files = globals.fs.directory(globals.fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .where(_isNotWhitelisted)
        .map(_asFile);
      for (final File file in files) {
        for (final String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*package:test_api')) &&
              !line.contains('ignore: test_api_import')) {
            final String relativePath = globals.fs.path.relative(file.path, from:flutterTools);
            fail("$relativePath imports 'package:test_api/test_api.dart';");
          }
        }
      }
    }
  });

  test('no unauthorized imports of package:path', () {
    final List<String> whitelistedPath = <String>[
      globals.fs.path.join(flutterTools, 'lib', 'src', 'build_runner', 'web_compilation_delegate.dart'),
      globals.fs.path.join(flutterTools, 'test', 'general.shard', 'platform_plugins_test.dart'),
    ];
    for (final String dirName in <String>['lib', 'bin', 'test']) {
      final Iterable<File> files =  globals.fs.directory(globals.fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .where((FileSystemEntity entity) => !whitelistedPath.contains(entity.path))
        .map(_asFile);
      for (final File file in files) {
        for (final String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*package:path/path.dart')) &&
              !line.contains('ignore: package_path_import')) {
            final String relativePath = globals.fs.path.relative(file.path, from:flutterTools);
            fail("$relativePath imports 'package:path/path.dart'; use 'globals.fs.path' instead");
          }
        }
      }
    }
  });

  test('no unauthorized imports of dart:convert', () {
    final List<String> whitelistedPaths = <String>[
      globals.fs.path.join(flutterTools, 'lib', 'src', 'convert.dart'),
      globals.fs.path.join(flutterTools, 'lib', 'src', 'base', 'error_handling_file_system.dart'),
    ];
    bool _isNotWhitelisted(FileSystemEntity entity) => whitelistedPaths.every((String path) => path != entity.path);

    for (final String dirName in <String>['lib']) {
      final Iterable<File> files = globals.fs.directory(globals.fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .where(_isNotWhitelisted)
        .map(_asFile);
      for (final File file in files) {
        for (final String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*dart:convert')) &&
              !line.contains('ignore: dart_convert_import')) {
            final String relativePath = globals.fs.path.relative(file.path, from:flutterTools);
            fail("$relativePath imports 'dart:convert'; import 'lib/src/convert.dart' instead");
          }
        }
      }
    }
  });

  test('no unauthorized imports of build_runner', () {
    final List<String> whitelistedPaths = <String>[
      globals.fs.path.join(flutterTools, 'test', 'src', 'build_runner'),
      globals.fs.path.join(flutterTools, 'lib', 'src', 'build_runner'),
      globals.fs.path.join(flutterTools, 'lib', 'executable.dart'),
    ];
    bool _isNotWhitelisted(FileSystemEntity entity) => whitelistedPaths.every((String path) => !entity.path.contains(path));

    for (final String dirName in <String>['lib']) {
      final Iterable<File> files = globals.fs.directory(globals.fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .where(_isNotWhitelisted)
        .map(_asFile);
      for (final File file in files) {
        for (final String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*package:build_runner_core/build_runner_core.dart')) ||
              line.startsWith(RegExp(r'import.*package:build_runner/build_runner.dart')) ||
              line.startsWith(RegExp(r'import.*package:build_config/build_config.dart')) ||
              line.startsWith(RegExp(r'import.*build_runner/.*.dart'))) {
            final String relativePath = globals.fs.path.relative(file.path, from:flutterTools);
            fail('$relativePath imports a build_runner package');
          }
        }
      }
    }
  });
}

bool _isDartFile(FileSystemEntity entity) => entity is File && entity.path.endsWith('.dart');

File _asFile(FileSystemEntity entity) => entity as File;
