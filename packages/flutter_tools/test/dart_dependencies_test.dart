// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/dart/dependencies.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('DartDependencySetBuilder', () {
    final String dataPath = fs.path.join(
      getFlutterRoot(),
      'packages',
      'flutter_tools',
      'test',
      'data',
      'dart_dependencies_test',
    );

    testUsingContext('good', () {
      final String testPath = fs.path.join(dataPath, 'good');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');
      final DartDependencySetBuilder builder =
          DartDependencySetBuilder(mainPath, packagesPath);
      final Set<String> dependencies = builder.build();
      expect(dependencies.contains(canonicalizePath(mainPath)), isTrue);
      expect(dependencies.contains(canonicalizePath(fs.path.join(testPath, 'foo.dart'))), isTrue);
    });

    testUsingContext('syntax_error', () {
      final String testPath = fs.path.join(dataPath, 'syntax_error');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');
      final DartDependencySetBuilder builder =
          DartDependencySetBuilder(mainPath, packagesPath);
      try {
        builder.build();
        fail('expect an exception to be thrown.');
      } on DartDependencyException catch (error) {
        expect(error.toString(), contains('foo.dart: Expected a string literal'));
      }
    });

    testUsingContext('bad_path', () {
      final String testPath = fs.path.join(dataPath, 'bad_path');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');
      final DartDependencySetBuilder builder =
          DartDependencySetBuilder(mainPath, packagesPath);
      try {
        builder.build();
        fail('expect an exception to be thrown.');
      } on DartDependencyException catch (error) {
        expect(error.toString(), contains('amaze${fs.path.separator}and${fs.path.separator}astonish.dart'));
      }
    });

    testUsingContext('bad_package', () {
      final String testPath = fs.path.join(dataPath, 'bad_package');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');
      final DartDependencySetBuilder builder =
          DartDependencySetBuilder(mainPath, packagesPath);
      try {
        builder.build();
        fail('expect an exception to be thrown.');
      } on DartDependencyException catch (error) {
        expect(error.toString(), contains('rochambeau'));
        expect(error.toString(), contains('pubspec.yaml'));
      }
    });

    testUsingContext('does not change ASCII casing of path', () {
      final String testPath = fs.path.join(dataPath, 'asci_casing');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');
      final DartDependencySetBuilder builder = DartDependencySetBuilder(mainPath, packagesPath);
      final Set<String> deps = builder.build();
      expect(deps, contains(endsWith('This_Import_Has_fuNNy_casING.dart')));
    });

    testUsingContext('bad_import', () {
      final String testPath = fs.path.join(dataPath, 'bad_import');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');
      final DartDependencySetBuilder builder =
          DartDependencySetBuilder(mainPath, packagesPath);
      try {
        builder.build();
        fail('expect an exception to be thrown.');
      } on DartDependencyException catch (error) {
        expect(error.toString(), contains('Unable to parse URI'));
      }
    });
  });
}
