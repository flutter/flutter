// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:flutter_tools/src/dart/dependencies.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main()  {
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
          new DartDependencySetBuilder(mainPath, packagesPath);
      final Set<String> dependencies = builder.build();
      expect(dependencies.contains(fs.path.canonicalize(mainPath)), isTrue);
      expect(dependencies.contains(fs.path.canonicalize(fs.path.join(testPath, 'foo.dart'))), isTrue);
    });

    testUsingContext('syntax_error', () {
      final String testPath = fs.path.join(dataPath, 'syntax_error');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');
      final DartDependencySetBuilder builder =
          new DartDependencySetBuilder(mainPath, packagesPath);
      try {
        builder.build();
        fail('expect an assertion to be thrown.');
      } on AnalyzerErrorGroup catch (e) {
        expect(e.toString(), contains('foo.dart: Expected a string literal'));
      }
    });
  });
}
