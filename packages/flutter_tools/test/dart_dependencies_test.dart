// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/dart/dependencies.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:test/test.dart';
import 'src/context.dart';

void main()  {
  group('DartDependencySetBuilder', () {
    final String basePath = fs.path.dirname(fs.path.fromUri(platform.script));
    final String dataPath = fs.path.join(basePath, 'data', 'dart_dependencies_test');
    testUsingContext('good', () {
      final String testPath = fs.path.join(dataPath, 'good');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');
      DartDependencySetBuilder builder =
          new DartDependencySetBuilder(mainPath, testPath, packagesPath);
      Set<String> dependencies = builder.build();
      expect(dependencies.contains(mainPath), isTrue);
      expect(dependencies.contains(fs.path.join(testPath, 'foo.dart')), isTrue);
    });
    testUsingContext('syntax_error', () {
      final String testPath = fs.path.join(dataPath, 'syntax_error');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');
      DartDependencySetBuilder builder =
          new DartDependencySetBuilder(mainPath, testPath, packagesPath);
      try {
        builder.build();
        fail('expect an assertion to be thrown.');
      } catch (e) {
        expect(e, const isInstanceOf<String>());
        expect(e.contains('unexpected token \'bad\''), isTrue);
      }
    });
  });
}
