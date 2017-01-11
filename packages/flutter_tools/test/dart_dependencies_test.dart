// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/dart/dependencies.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'src/context.dart';

void main()  {
  group('DartDependencySetBuilder', () {
    final String basePath = path.dirname(Platform.script.path);
    final String dataPath = path.join(basePath, 'data', 'dart_dependencies_test');
    testUsingContext('good', () {
      final String testPath = path.join(dataPath, 'good');
      final String mainPath = path.join(testPath, 'main.dart');
      final String packagesPath = path.join(testPath, '.packages');
      DartDependencySetBuilder builder =
          new DartDependencySetBuilder(mainPath, testPath, packagesPath);
      Set<String> dependencies = builder.build();
      expect(dependencies.contains('main.dart'), isTrue);
      expect(dependencies.contains('foo.dart'), isTrue);
    });
    testUsingContext('syntax_error', () {
      final String testPath = path.join(dataPath, 'syntax_error');
      final String mainPath = path.join(testPath, 'main.dart');
      final String packagesPath = path.join(testPath, '.packages');
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
