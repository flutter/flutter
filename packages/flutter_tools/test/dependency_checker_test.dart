// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/dart/dependencies.dart';
import 'package:flutter_tools/src/dependency_checker.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('DependencyChecker', () {
    final String dataPath = fs.path.join(
        getFlutterRoot(),
        'packages',
        'flutter_tools',
        'test',
        'data',
        'dart_dependencies_test',
    );

    FileSystem testFileSystem;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      testFileSystem = MemoryFileSystem();
    });

    testUsingContext('good', () {
      final String testPath = fs.path.join(dataPath, 'good');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String fooPath = fs.path.join(testPath, 'foo.dart');
      final String barPath = fs.path.join(testPath, 'lib', 'bar.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');
      final DartDependencySetBuilder builder =
          DartDependencySetBuilder(mainPath, packagesPath);
      final DependencyChecker dependencyChecker =
          DependencyChecker(builder, null);

      // Set file modification time on all dependencies to be in the past.
      final DateTime baseTime = DateTime.now();
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
      final String testPath = fs.path.join(dataPath, 'syntax_error');
      final String mainPath = fs.path.join(testPath, 'main.dart');
      final String fooPath = fs.path.join(testPath, 'foo.dart');
      final String packagesPath = fs.path.join(testPath, '.packages');

      final DartDependencySetBuilder builder =
          DartDependencySetBuilder(mainPath, packagesPath);
      final DependencyChecker dependencyChecker =
          DependencyChecker(builder, null);

      final DateTime baseTime = DateTime.now();

      // Set file modification time on all dependencies to be in the past.
      updateFileModificationTime(packagesPath, baseTime, -10);
      updateFileModificationTime(mainPath, baseTime, -10);
      updateFileModificationTime(fooPath, baseTime, -10);

      // Dependencies are considered dirty because there is a syntax error in
      // the .dart file.
      expect(dependencyChecker.check(baseTime), isTrue);
    });

    /// Test a flutter tool move.
    ///
    /// Tests that the flutter tool doesn't crash and displays a warning when its own location
    /// changed since it was last referenced to in a package's .packages file.
    testUsingContext('moved flutter sdk', () async {
      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_dependency_checker_test.');

      // Copy the golden input and let the test run in an isolated temporary in-memory file system.
      const LocalFileSystem localFileSystem = LocalFileSystem();
      final Directory sourcePath = localFileSystem.directory(localFileSystem.path.join(dataPath, 'changed_sdk_location'));
      copyDirectorySync(sourcePath, tempDir);
      fs.currentDirectory = tempDir;

      // Doesn't matter what commands we run. Arbitrarily list devices here.
      await createTestCommandRunner(DevicesCommand()).run(<String>['devices']);
      expect(testLogger.errorText, contains('.packages'));
      tryToDelete(tempDir);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
    });
  });
}
