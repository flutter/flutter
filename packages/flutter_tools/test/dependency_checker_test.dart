// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/dart/dependencies.dart';
import 'package:flutter_tools/src/dependency_checker.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'src/common.dart';
import 'src/context.dart';

void main()  {
  group('DependencyChecker', () {
    final String basePath = path.dirname(Platform.script.path);
    final String dataPath = path.join(basePath, 'data', 'dart_dependencies_test');
    testUsingContext('good', () {
      final String testPath = path.join(dataPath, 'good');
      final String mainPath = path.join(testPath, 'main.dart');
      final String fooPath = path.join(testPath, 'foo.dart');
      final String barPath = path.join(testPath, 'lib', 'bar.dart');
      final String packagesPath = path.join(testPath, '.packages');
      DartDependencySetBuilder builder =
          new DartDependencySetBuilder(mainPath, testPath, packagesPath);
      DependencyChecker dependencyChecker =
          new DependencyChecker(builder, null);

      // Set file modification time on all dependencies to be in the past.
      DateTime baseTime = new DateTime.now();
      updateFileModificationTime(packagesPath, baseTime, -10);
      updateFileModificationTime(mainPath, baseTime, -10);
      updateFileModificationTime(fooPath, baseTime, -10);
      updateFileModificationTime(barPath, baseTime, -10);
      expect(dependencyChecker.check(baseTime), isFalse);

      // Set .packages file modification time to be in the future.
      updateFileModificationTime(packagesPath, baseTime, 20);
      expect(dependencyChecker.check(baseTime), isTrue);

      // Reset .packages file modification time.
      updateFileModificationTime(packagesPath, baseTime, 0);
      expect(dependencyChecker.check(baseTime), isFalse);

      // Set 'package:self/bar.dart' file modification time to be in the future.
      updateFileModificationTime(barPath, baseTime, 10);
      expect(dependencyChecker.check(baseTime), isTrue);
    });
    testUsingContext('syntax error', () {
      final String testPath = path.join(dataPath, 'syntax_error');
      final String mainPath = path.join(testPath, 'main.dart');
      final String fooPath = path.join(testPath, 'foo.dart');
      final String packagesPath = path.join(testPath, '.packages');

      DartDependencySetBuilder builder =
          new DartDependencySetBuilder(mainPath, testPath, packagesPath);
      DependencyChecker dependencyChecker =
          new DependencyChecker(builder, null);

      DateTime baseTime = new DateTime.now();

      // Set file modification time on all dependencies to be in the past.
      updateFileModificationTime(packagesPath, baseTime, -10);
      updateFileModificationTime(mainPath, baseTime, -10);
      updateFileModificationTime(fooPath, baseTime, -10);

      // Dependencies are considered dirty because there is a syntax error in
      // the .dart file.
      expect(dependencyChecker.check(baseTime), isTrue);
    });
  });
}
