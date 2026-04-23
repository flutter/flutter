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
    for (final MapEntry<Directory, Set<String>>(key: Directory directory, value: Set<String> files)
        in checkerDirectories.knownFiles.entries) {
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

    final Directory testDir =
        flutterRoot.childDirectory('packages').childDirectory('flutter').childDirectory('test')
          ..createSync(recursive: true);
    testDir.childDirectory('material').createSync(recursive: true);

    checker = TestsCrossImportChecker(
      testsDirectory: testDir,
      flutterRoot: flutterRoot,
      filesystem: fs,
    );
    checkerDirectories = _CrossImportsTestDirectories(testDir)..createTestDirectories();
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

  for (final (String libraryName, String knownCrossImportsListName, Set<String> knownCrossImports)
      in crossImportsTestCases) {
    test('when not all $libraryName knowns have cross imports', () async {
      if (knownCrossImports.isEmpty) {
        return;
      }

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
    });

    test('unknown $libraryName cross import of Material', () async {
      final String extra = 'packages/flutter/$libraryName/foo_test.dart'.replaceAll(
        '/',
        Platform.isWindows ? r'\' : '/',
      );
      final Directory testFilesDirectory = checkerDirectories.testFilesDirectoryFor(libraryName);

      buildKnownCrossImportTestFiles();
      writeImportInFiles(<String>{extra}, inDirectory: testFilesDirectory);

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines =
          <String>[
                '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
                '║ The following test in $libraryName has a disallowed import of Material. Refactor it or move it to Material.',
                '║   $extra',
                '╚═══════════════════════════════════════════════════════════════════════════════',
              ]
              .map((String line) {
                return line.replaceAll('/', Platform.isWindows ? r'\' : '/');
              })
              .join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    });

    test('unknown $libraryName cross import of Cupertino', () async {
      final String extra = 'packages/flutter/$libraryName/foo_test.dart'.replaceAll(
        '/',
        Platform.isWindows ? r'\' : '/',
      );
      final Directory testFilesDirectory = checkerDirectories.testFilesDirectoryFor(libraryName);

      buildKnownCrossImportTestFiles();
      writeImportInFiles(
        <String>{extra},
        inDirectory: testFilesDirectory,
        importString: "import 'package:flutter/cupertino.dart';",
      );

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines =
          <String>[
                '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
                '║ The following test in $libraryName has a disallowed import of Cupertino. Refactor it or move it to Cupertino.',
                '║   $extra',
                '╚═══════════════════════════════════════════════════════════════════════════════',
              ]
              .map((String line) {
                return line.replaceAll('/', Platform.isWindows ? r'\' : '/');
              })
              .join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    }, skip: libraryName == 'test/cupertino'); // [intended]: Cupertino can import itself
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

File getFile(String filepath, Directory directory) {
  final String platformFilepath = filepath.replaceAll('/', Platform.isWindows ? r'\' : '/');
  final int overlapIndex = platformFilepath.lastIndexOf(directory.basename);
  if (overlapIndex < 0) {
    throw ArgumentError('filepath $filepath must be located in directory ${directory.path}.');
  }
  final String filename = platformFilepath.substring(overlapIndex + directory.basename.length + 1);
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
  factory _CrossImportsTestDirectories(Directory testsDir) {
    return _CrossImportsTestDirectories._(
      testAnimationDirectory: testsDir.childDirectory('animation'),
      testCupertinoDirectory: testsDir.childDirectory('cupertino'),
      testDartDirectory: testsDir.childDirectory('dart'),
      testExamplesDirectory: testsDir.childDirectory('examples'),
      testFoundationDirectory: testsDir.childDirectory('foundation'),
      testGesturesDirectory: testsDir.childDirectory('gestures'),
      testHarnessDirectory: testsDir.childDirectory('harness'),
      testPaintingDirectory: testsDir.childDirectory('painting'),
      testPhysicsDirectory: testsDir.childDirectory('physics'),
      testRenderingDirectory: testsDir.childDirectory('rendering'),
      testSchedulerDirectory: testsDir.childDirectory('scheduler'),
      testSemanticsDirectory: testsDir.childDirectory('semantics'),
      testServicesDirectory: testsDir.childDirectory('services'),
      testWidgetsDirectory: testsDir.childDirectory('widgets'),
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
  /// to their corresponding known imports list in `check_tests_cross_imports.dart`.
  Map<Directory, Set<String>> get knownFiles => <Directory, Set<String>>{
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

  void createTestDirectories() {
    for (final Directory directory in knownFiles.keys) {
      directory.createSync(recursive: true);
    }
  }

  Directory testFilesDirectoryFor(String libraryName) {
    return switch (libraryName) {
      'test/animation' => testAnimationDirectory,
      'test/cupertino' => testCupertinoDirectory,
      'test/dart' => testDartDirectory,
      'test/examples' => testExamplesDirectory,
      'test/foundation' => testFoundationDirectory,
      'test/gestures' => testGesturesDirectory,
      'test/harness' => testHarnessDirectory,
      'test/painting' => testPaintingDirectory,
      'test/physics' => testPhysicsDirectory,
      'test/rendering' => testRenderingDirectory,
      'test/scheduler' => testSchedulerDirectory,
      'test/semantics' => testSemanticsDirectory,
      'test/services' => testServicesDirectory,
      'test/widgets' => testWidgetsDirectory,
      _ => throw ArgumentError('Unknown library name: $libraryName'),
    };
  }
}

// A mapping of test cases for the cross imports checker.
//
// Each entry contains:
// - a shortened directory name of the test folder for the library, without the `flutter/` prefix
// - the name of the known cross imports list variable in `check_tests_cross_imports.dart` for that library
// - the actual known cross imports list for that library
// dart format off
final crossImportsTestCases = <(String, String, Set<String>)>[
  ('test/animation', 'knownAnimationCrossImports', TestsCrossImportChecker.knownAnimationCrossImports),
  ('test/cupertino', 'knownCupertinoCrossImports', TestsCrossImportChecker.knownCupertinoCrossImports),
  ('test/dart', 'knownDartCrossImports', TestsCrossImportChecker.knownDartCrossImports),
  ('test/examples', 'knownExamplesCrossImports', TestsCrossImportChecker.knownExamplesCrossImports),
  ('test/foundation', 'knownFoundationCrossImports', TestsCrossImportChecker.knownFoundationCrossImports),
  ('test/gestures', 'knownGesturesCrossImports', TestsCrossImportChecker.knownGesturesCrossImports),
  ('test/harness', 'knownHarnessCrossImports', TestsCrossImportChecker.knownHarnessCrossImports),
  ('test/painting', 'knownPaintingCrossImports', TestsCrossImportChecker.knownPaintingCrossImports),
  ('test/physics', 'knownPhysicsCrossImports', TestsCrossImportChecker.knownPhysicsCrossImports),
  ('test/rendering', 'knownRenderingCrossImports', TestsCrossImportChecker.knownRenderingCrossImports),
  ('test/scheduler', 'knownSchedulerCrossImports', TestsCrossImportChecker.knownSchedulerCrossImports),
  ('test/semantics', 'knownSemanticsCrossImports', TestsCrossImportChecker.knownSemanticsCrossImports),
  ('test/services', 'knownServicesCrossImports', TestsCrossImportChecker.knownServicesCrossImports),
  ('test/widgets', 'knownWidgetsCrossImports', TestsCrossImportChecker.knownWidgetsCrossImports),
];
// dart format on
