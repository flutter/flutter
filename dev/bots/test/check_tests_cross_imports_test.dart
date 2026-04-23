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
  late Directory testCupertinoDirectory;
  late Directory testAnimationDirectory;
  late Directory testDartDirectory;
  late Directory testExamplesDirectory;
  late Directory testFoundationDirectory;
  late Directory testGesturesDirectory;
  late Directory testHarnessDirectory;
  late Directory testPaintingDirectory;
  late Directory testPhysicsDirectory;
  late Directory testRenderingDirectory;
  late Directory testSchedulerDirectory;
  late Directory testSemanticsDirectory;
  late Directory testServicesDirectory;
  late Directory testWidgetsDirectory;

  void buildKnownCrossImportTestFiles({
    Set<String> excludes = const <String>{},
    Set<String> extraWidgetsImportingMaterial = const <String>{},
    Set<String> extraWidgetsImportingCupertino = const <String>{},
  }) {
    final knownFiles = <Directory, Set<String>>{
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

    for (final MapEntry<Directory, Set<String>>(key: Directory directory, value: Set<String> files)
        in knownFiles.entries) {
      for (final filepath in files) {
        if (excludes.contains(filepath)) {
          continue;
        }
        writeImport(getFile(filepath, directory));
      }
    }

    for (final filepath in extraWidgetsImportingMaterial) {
      writeImport(getFile(filepath, testWidgetsDirectory));
    }
    for (final filepath in extraWidgetsImportingCupertino) {
      writeImport(
        getFile(filepath, testWidgetsDirectory),
        "import 'package:flutter/cupertino.dart';",
      );
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

    final Directory testsDir =
        flutterRoot.childDirectory('packages').childDirectory('flutter').childDirectory('test')
          ..createSync(recursive: true);

    testAnimationDirectory = testsDir.childDirectory('animation')..createSync(recursive: true);
    testCupertinoDirectory = testsDir.childDirectory('cupertino')..createSync(recursive: true);
    testDartDirectory = testsDir.childDirectory('dart')..createSync(recursive: true);
    testExamplesDirectory = testsDir.childDirectory('examples')..createSync(recursive: true);
    testFoundationDirectory = testsDir.childDirectory('foundation')..createSync(recursive: true);
    testGesturesDirectory = testsDir.childDirectory('gestures')..createSync(recursive: true);
    testHarnessDirectory = testsDir.childDirectory('harness')..createSync(recursive: true);
    // tests/material sits between tests/harness and tests/painting,
    // but the test does not need a reference to the directory.
    testsDir.childDirectory('material').createSync(recursive: true);
    testPaintingDirectory = testsDir.childDirectory('painting')..createSync(recursive: true);
    testPhysicsDirectory = testsDir.childDirectory('physics')..createSync(recursive: true);
    testRenderingDirectory = testsDir.childDirectory('rendering')..createSync(recursive: true);
    testSchedulerDirectory = testsDir.childDirectory('scheduler')..createSync(recursive: true);
    testSemanticsDirectory = testsDir.childDirectory('semantics')..createSync(recursive: true);
    testServicesDirectory = testsDir.childDirectory('services')..createSync(recursive: true);
    testWidgetsDirectory = testsDir.childDirectory('widgets')..createSync(recursive: true);

    checker = TestsCrossImportChecker(
      testsDirectory: testsDir,
      flutterRoot: flutterRoot,
      filesystem: fs,
    );
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

  // dart format off
  final fixedCrossImportsTestCases = <(String, String, Set<String>)>[
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

  for (final (String libraryName, String knownCrossImportsListName, Set<String> knownCrossImports)
      in fixedCrossImportsTestCases) {
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
  }

  test('unknown Widgets cross import of Material', () async {
    final String extra = 'packages/flutter/test/widgets/foo_test.dart'.replaceAll(
      '/',
      Platform.isWindows ? r'\' : '/',
    );
    buildKnownCrossImportTestFiles(extraWidgetsImportingMaterial: <String>{extra});
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    }, shouldHaveErrors: true);
    final String lines =
        <String>[
              '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
              '║ The following test in Widgets has a disallowed import of Material. Refactor it or move it to Material.',
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

  test('unknown Cupertino cross importing Material', () async {
    final String extra = 'packages/flutter/test/cupertino/foo_test.dart'.replaceAll(
      '/',
      Platform.isWindows ? r'\' : '/',
    );
    buildKnownCrossImportTestFiles();
    writeImportInFiles(<String>{extra}, inDirectory: testCupertinoDirectory);
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    }, shouldHaveErrors: true);
    final String lines =
        <String>[
              '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
              '║ The following test in Cupertino has a disallowed import of Material. Refactor it or move it to Material.',
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

  test('unknown Widgets cross import of Cupertino', () async {
    final String extra = 'packages/flutter/test/widgets/foo_test.dart'.replaceAll(
      '/',
      Platform.isWindows ? r'\' : '/',
    );
    buildKnownCrossImportTestFiles(extraWidgetsImportingCupertino: <String>{extra});
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    }, shouldHaveErrors: true);
    final String lines =
        <String>[
              '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
              '║ The following test in Widgets has a disallowed import of Cupertino. Refactor it or move it to Cupertino.',
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
