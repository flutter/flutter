// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;

import '../check_tests_cross_imports.dart';
import '../utils.dart';
import 'common.dart';

void main() {
  late TestsCrossImportChecker checker;
  late _CrossImportsTestDirectories checkerDirectories;

  void buildKnownCrossImportTestFiles({Set<String> excludes = const <String>{}}) {
    final Map<Directory, Set<String>> knownFiles = checkerDirectories.getKnownFiles(
      checker.testsDirectory,
    );

    for (final MapEntry<Directory, Set<String>>(key: Directory directory, value: Set<String> files)
        in knownFiles.entries) {
      for (final filepath in files) {
        if (excludes.contains(filepath)) {
          continue;
        }
        writeImport(getFile(filepath, directory));
      }
    }
  }

  setUp(() {
    final fs = MemoryFileSystem(
      style: Platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
    );
    // Get the root prefix of the current directory so that on Windows we get a
    // correct root prefix.
    final Directory flutterRoot = fs.directory(
      path.join(path.rootPrefix(fs.currentDirectory.absolute.path), 'flutter sdk'),
    )..createSync(recursive: true);
    fs.currentDirectory = flutterRoot;

    final Directory testsDirectory =
        flutterRoot.childDirectory('packages').childDirectory('flutter').childDirectory('test')
          ..createSync(recursive: true);
    testsDirectory.childDirectory('material').createSync(recursive: true);

    checker = TestsCrossImportChecker(
      testsDirectory: testsDirectory,
      flutterRoot: flutterRoot,
      filesystem: fs,
    );
    checkerDirectories = _CrossImportsTestDirectories(testsDirectory)
      ..createTestDirectories(testsDirectory);
  });

  test('when only all knowns have cross imports', () async {
    buildKnownCrossImportTestFiles();
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    });
    expect(result, equals(''));
    expect(success, isTrue);
  });

  test('non-Dart files are ignored', () async {
    buildKnownCrossImportTestFiles();

    checker.testsDirectory.childFile('README.md')
      ..createSync()
      ..writeAsStringSync("import 'package:flutter/material.dart';");

    expect(checker.check(), isTrue);
  });

  test('non-Dart files with .dart in the filename are ignored', () async {
    buildKnownCrossImportTestFiles();

    checker.testsDirectory.childFile('foo.dart.md')
      ..createSync()
      ..writeAsStringSync("import 'package:flutter/material.dart';");

    expect(checker.check(), isTrue);
  });

  for (final (String libraryName, String knownCrossImportsListName, Set<String> knownCrossImports)
      in crossImportsTestCases) {
    test(
      'when not all $libraryName knowns have cross imports',
      () async {
        final String excludedSample = knownCrossImports.first;

        buildKnownCrossImportTestFiles(excludes: <String>{excludedSample});

        bool? success;
        final String result = await capture(() async {
          success = checker.check();
        }, shouldHaveErrors: true);
        final String lines = <String>[
          '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
          '║ Huzzah! The following tests in $libraryName no longer contain cross imports!',
          '║   $excludedSample',
          '║ However, they now need to be removed from the',
          '║ $knownCrossImportsListName list in the script /dev/bots/check_tests_cross_imports.dart.',
          '╚═══════════════════════════════════════════════════════════════════════════════',
        ].join('\n');
        expect(result, equals('$lines\n'));
        expect(success, isFalse);
      },
      skip: knownCrossImports.isEmpty, // [intended]: Nothing to log if there are no known imports
    );

    test('unknown $libraryName cross import of Material', () async {
      final testDartFile = '$libraryName/foo_test.dart';

      final Directory testFilesDirectory = checkerDirectories.testFilesDirectoryFor(
        libraryName,
        checker.testsDirectory,
      );

      buildKnownCrossImportTestFiles();
      writeImportInFiles({testDartFile}, inDirectory: testFilesDirectory);

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines = <String>[
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        '║ The following test in $libraryName has a disallowed import of Material. Refactor it or move it to Material.',
        '║   $testDartFile',
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ].join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    });

    test('multiple unknown $libraryName cross imports of Material', () async {
      final testDartFileOne = '$libraryName/foo_test.dart';
      final testDartFileTwo = '$libraryName/bar_test.dart';

      final Directory testFilesDirectory = checkerDirectories.testFilesDirectoryFor(
        libraryName,
        checker.testsDirectory,
      );

      buildKnownCrossImportTestFiles();
      writeImportInFiles({testDartFileOne, testDartFileTwo}, inDirectory: testFilesDirectory);

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines = <String>[
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        '║ The following 2 tests in $libraryName have a disallowed import of Material. Refactor them or move them to Material.',
        '║   $testDartFileOne',
        '║   $testDartFileTwo',
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ].join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    });

    test('unknown $libraryName cross import of Material in non-test file', () async {
      final testDartFile = '$libraryName/foo_utils.dart';

      final Directory testFilesDirectory = checkerDirectories.testFilesDirectoryFor(
        libraryName,
        checker.testsDirectory,
      );

      buildKnownCrossImportTestFiles();
      writeImportInFiles(<String>{testDartFile}, inDirectory: testFilesDirectory);

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines = <String>[
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        '║ The following test in $libraryName has a disallowed import of Material. Refactor it or move it to Material.',
        '║   $testDartFile',
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ].join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    });

    test(
      'unknown $libraryName cross import of Cupertino',
      () async {
        final testDartFile = '$libraryName/foo_test.dart';
        final Directory testFilesDirectory = checkerDirectories.testFilesDirectoryFor(
          libraryName,
          checker.testsDirectory,
        );

        buildKnownCrossImportTestFiles();
        writeImportInFiles(
          <String>{testDartFile},
          inDirectory: testFilesDirectory,
          importString: "import 'package:flutter/cupertino.dart';",
        );

        bool? success;
        final String result = await capture(() async {
          success = checker.check();
        }, shouldHaveErrors: true);
        final String lines = <String>[
          '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
          '║ The following test in $libraryName has a disallowed import of Cupertino. Refactor it or move it to Cupertino.',
          '║   $testDartFile',
          '╚═══════════════════════════════════════════════════════════════════════════════',
        ].join('\n');
        expect(result, equals('$lines\n'));
        expect(success, isFalse);
      },
      skip: isCupertino(libraryName), // [intended]: Cupertino can import itself
    );

    test(
      'multiple unknown $libraryName cross imports of Cupertino',
      () async {
        final testDartFileOne = '$libraryName/foo_test.dart';
        final testDartFileTwo = '$libraryName/bar_test.dart';

        final Directory testFilesDirectory = checkerDirectories.testFilesDirectoryFor(
          libraryName,
          checker.testsDirectory,
        );

        buildKnownCrossImportTestFiles();
        writeImportInFiles(
          {testDartFileOne, testDartFileTwo},
          inDirectory: testFilesDirectory,
          importString: "import 'package:flutter/cupertino.dart';",
        );

        bool? success;
        final String result = await capture(() async {
          success = checker.check();
        }, shouldHaveErrors: true);
        final String lines = <String>[
          '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
          '║ The following 2 tests in $libraryName have a disallowed import of Cupertino. Refactor them or move them to Cupertino.',
          '║   $testDartFileOne',
          '║   $testDartFileTwo',
          '╚═══════════════════════════════════════════════════════════════════════════════',
        ].join('\n');
        expect(result, equals('$lines\n'));
        expect(success, isFalse);
      },
      skip: isCupertino(libraryName), // [intended]: Cupertino can import itself
    );

    test(
      'unknown $libraryName cross import of Cupertino in non-test file',
      () async {
        final testDartFile = '$libraryName/foo_utils.dart';
        final Directory testFilesDirectory = checkerDirectories.testFilesDirectoryFor(
          libraryName,
          checker.testsDirectory,
        );

        buildKnownCrossImportTestFiles();
        writeImportInFiles(
          <String>{testDartFile},
          inDirectory: testFilesDirectory,
          importString: "import 'package:flutter/cupertino.dart';",
        );

        bool? success;
        final String result = await capture(() async {
          success = checker.check();
        }, shouldHaveErrors: true);
        final String lines = <String>[
          '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
          '║ The following test in $libraryName has a disallowed import of Cupertino. Refactor it or move it to Cupertino.',
          '║   $testDartFile',
          '╚═══════════════════════════════════════════════════════════════════════════════',
        ].join('\n');
        expect(result, equals('$lines\n'));
        expect(success, isFalse);
      },
      skip: isCupertino(libraryName), // [intended]: Cupertino can import itself
    );
  }
}

typedef AsyncVoidCallback = Future<void> Function();

Future<String> capture(AsyncVoidCallback callback, {bool shouldHaveErrors = false}) async {
  final buffer = StringBuffer();
  final PrintCallback oldPrint = print;
  try {
    print = (Object? line) {
      buffer.writeln(line);
    };
    await callback();
    expect(
      hasError,
      shouldHaveErrors,
      reason: buffer.isEmpty
          ? '(No output to report.)'
          : hasError
          ? 'Unexpected errors:\n$buffer'
          : 'Unexpected success:\n$buffer',
    );
  } finally {
    print = oldPrint;
    resetErrorStatus();
  }
  if (stdout.supportsAnsiEscapes) {
    // Remove ANSI escapes when this test is running on a terminal.
    return buffer.toString().replaceAll(RegExp(r'(\x9B|\x1B\[)[0-?]{1,3}[ -/]*[@-~]'), '');
  } else {
    return buffer.toString();
  }
}

/// Returns whether the given [libraryName] matches the Cupertino library under `flutter/test`.
bool isCupertino(String libraryName) => libraryName == 'packages/flutter/test/cupertino';

File getFile(String filepath, Directory directory) {
  final String platformFilepath = filepath.replaceAll('/', Platform.pathSeparator);
  final String searchPattern = directory.basename + Platform.pathSeparator;
  final int overlapIndex = platformFilepath.lastIndexOf(searchPattern);

  if (overlapIndex < 0) {
    throw ArgumentError('filepath $filepath must be located in directory ${directory.path}.');
  }

  final String filename = platformFilepath.substring(overlapIndex + searchPattern.length);
  return directory.childFile(filename);
}

/// Writes [importString] into the given file.
///
/// The default [importString] is `import 'package:flutter/material.dart';`.
void writeImport(File file, [String importString = "import 'package:flutter/material.dart';"]) {
  file
    ..createSync(recursive: true)
    ..writeAsStringSync(importString);
}

/// Writes [importString] into the given [filePaths] in [inDirectory].
///
/// The default [importString] is `import 'package:flutter/material.dart';`.
void writeImportInFiles(
  Iterable<String> filePaths, {
  required Directory inDirectory,
  String importString = "import 'package:flutter/material.dart';",
}) {
  for (final filepath in filePaths) {
    writeImport(getFile(filepath, inDirectory), importString);
  }
}

// A utility that keeps track of the directories under test,
// to avoid having to late initialize them individually in `setUp()`.
class _CrossImportsTestDirectories {
  factory _CrossImportsTestDirectories(Directory testsDirectory) {
    return _CrossImportsTestDirectories._(
      testAnimationDirectory: testsDirectory.childDirectory('animation'),
      testCupertinoDirectory: testsDirectory.childDirectory('cupertino'),
      testDartDirectory: testsDirectory.childDirectory('dart'),
      testExamplesDirectory: testsDirectory.childDirectory('examples'),
      testFoundationDirectory: testsDirectory.childDirectory('foundation'),
      testGesturesDirectory: testsDirectory.childDirectory('gestures'),
      testHarnessDirectory: testsDirectory.childDirectory('harness'),
      testPaintingDirectory: testsDirectory.childDirectory('painting'),
      testPhysicsDirectory: testsDirectory.childDirectory('physics'),
      testRenderingDirectory: testsDirectory.childDirectory('rendering'),
      testSchedulerDirectory: testsDirectory.childDirectory('scheduler'),
      testSemanticsDirectory: testsDirectory.childDirectory('semantics'),
      testServicesDirectory: testsDirectory.childDirectory('services'),
      testWidgetsDirectory: testsDirectory.childDirectory('widgets'),
    );
  }

  const _CrossImportsTestDirectories._({
    required this.testAnimationDirectory,
    required this.testCupertinoDirectory,
    required this.testDartDirectory,
    required this.testExamplesDirectory,
    required this.testFoundationDirectory,
    required this.testGesturesDirectory,
    required this.testHarnessDirectory,
    required this.testPaintingDirectory,
    required this.testPhysicsDirectory,
    required this.testRenderingDirectory,
    required this.testSchedulerDirectory,
    required this.testSemanticsDirectory,
    required this.testServicesDirectory,
    required this.testWidgetsDirectory,
  });

  final Directory testAnimationDirectory;
  final Directory testCupertinoDirectory;
  final Directory testDartDirectory;
  final Directory testExamplesDirectory;
  final Directory testFoundationDirectory;
  final Directory testGesturesDirectory;
  final Directory testHarnessDirectory;
  final Directory testPaintingDirectory;
  final Directory testPhysicsDirectory;
  final Directory testRenderingDirectory;
  final Directory testSchedulerDirectory;
  final Directory testSemanticsDirectory;
  final Directory testServicesDirectory;
  final Directory testWidgetsDirectory;

  /// A mapping of the `flutter/test/xyz` directories,
  /// to their corresponding known imports list in `check_tests_cross_imports.dart`,
  /// including `flutter/test` itself.
  Map<Directory, Set<String>> getKnownFiles(Directory flutterTestDirectory) {
    return <Directory, Set<String>>{
      flutterTestDirectory: TestsCrossImportChecker.knownFlutterSlashTestCrossImports,
      testCupertinoDirectory: TestsCrossImportChecker.knownCupertinoCrossImports,
      testAnimationDirectory: TestsCrossImportChecker.knownAnimationCrossImports,
      testDartDirectory: TestsCrossImportChecker.knownDartCrossImports,
      testExamplesDirectory: TestsCrossImportChecker.knownExamplesCrossImports,
      testFoundationDirectory: TestsCrossImportChecker.knownFoundationCrossImports,
      testGesturesDirectory: TestsCrossImportChecker.knownGesturesCrossImports,
      testHarnessDirectory: TestsCrossImportChecker.knownHarnessCrossImports,
      testPaintingDirectory: TestsCrossImportChecker.knownPaintingCrossImports,
      testPhysicsDirectory: TestsCrossImportChecker.knownPhysicsCrossImports,
      testRenderingDirectory: TestsCrossImportChecker.knownRenderingCrossImports,
      testSchedulerDirectory: TestsCrossImportChecker.knownSchedulerCrossImports,
      testSemanticsDirectory: TestsCrossImportChecker.knownSemanticsCrossImports,
      testServicesDirectory: TestsCrossImportChecker.knownServicesCrossImports,
      testWidgetsDirectory: TestsCrossImportChecker.knownWidgetsCrossImports,
    };
  }

  void createTestDirectories(Directory flutterTestDirectory) {
    final Map<Directory, Set<String>> knownFiles = getKnownFiles(flutterTestDirectory);

    for (final Directory directory in knownFiles.keys) {
      // The `flutter/test` directory is created in `setUp()`.
      if (directory == flutterTestDirectory) {
        continue;
      }

      directory.createSync(recursive: true);
    }
  }

  Directory testFilesDirectoryFor(String libraryName, Directory flutterTestDirectory) {
    return switch (libraryName) {
      'packages/flutter/test' => flutterTestDirectory,
      'packages/flutter/test/animation' => testAnimationDirectory,
      'packages/flutter/test/cupertino' => testCupertinoDirectory,
      'packages/flutter/test/dart' => testDartDirectory,
      'packages/flutter/test/examples' => testExamplesDirectory,
      'packages/flutter/test/foundation' => testFoundationDirectory,
      'packages/flutter/test/gestures' => testGesturesDirectory,
      'packages/flutter/test/harness' => testHarnessDirectory,
      'packages/flutter/test/painting' => testPaintingDirectory,
      'packages/flutter/test/physics' => testPhysicsDirectory,
      'packages/flutter/test/rendering' => testRenderingDirectory,
      'packages/flutter/test/scheduler' => testSchedulerDirectory,
      'packages/flutter/test/semantics' => testSemanticsDirectory,
      'packages/flutter/test/services' => testServicesDirectory,
      'packages/flutter/test/widgets' => testWidgetsDirectory,
      _ => throw ArgumentError('Unknown library name: $libraryName'),
    };
  }
}

// A mapping of test cases for the cross imports checker.
//
// Each entry contains:
// - a shortened directory name of the test folder for the library
// - the name of the known cross imports list variable in `check_tests_cross_imports.dart` for that library
// - the actual known cross imports list for that library
// dart format off
final crossImportsTestCases = <(String, String, Set<String>)>[
  ('packages/flutter/test', 'knownFlutterSlashTestCrossImports', TestsCrossImportChecker.knownFlutterSlashTestCrossImports),
  ('packages/flutter/test/animation', 'knownAnimationCrossImports', TestsCrossImportChecker.knownAnimationCrossImports),
  ('packages/flutter/test/cupertino', 'knownCupertinoCrossImports', TestsCrossImportChecker.knownCupertinoCrossImports),
  ('packages/flutter/test/dart', 'knownDartCrossImports', TestsCrossImportChecker.knownDartCrossImports),
  ('packages/flutter/test/examples', 'knownExamplesCrossImports', TestsCrossImportChecker.knownExamplesCrossImports),
  ('packages/flutter/test/foundation', 'knownFoundationCrossImports', TestsCrossImportChecker.knownFoundationCrossImports),
  ('packages/flutter/test/gestures', 'knownGesturesCrossImports', TestsCrossImportChecker.knownGesturesCrossImports),
  ('packages/flutter/test/harness', 'knownHarnessCrossImports', TestsCrossImportChecker.knownHarnessCrossImports),
  ('packages/flutter/test/painting', 'knownPaintingCrossImports', TestsCrossImportChecker.knownPaintingCrossImports),
  ('packages/flutter/test/physics', 'knownPhysicsCrossImports', TestsCrossImportChecker.knownPhysicsCrossImports),
  ('packages/flutter/test/rendering', 'knownRenderingCrossImports', TestsCrossImportChecker.knownRenderingCrossImports),
  ('packages/flutter/test/scheduler', 'knownSchedulerCrossImports', TestsCrossImportChecker.knownSchedulerCrossImports),
  ('packages/flutter/test/semantics', 'knownSemanticsCrossImports', TestsCrossImportChecker.knownSemanticsCrossImports),
  ('packages/flutter/test/services', 'knownServicesCrossImports', TestsCrossImportChecker.knownServicesCrossImports),
  ('packages/flutter/test/widgets', 'knownWidgetsCrossImports', TestsCrossImportChecker.knownWidgetsCrossImports),
];
// dart format on
