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
  late Directory testWidgetsDirectory;
  late Directory testCupertinoDirectory;

  // Writes a Material import into the given file.
  void writeImport(File file, [String importString = "import 'package:flutter/material.dart';"]) {
    file
      ..createSync(recursive: true)
      ..writeAsStringSync(importString);
  }

  File getFile(String filepath, Directory directory) {
    final String platformFilepath = filepath.replaceAll('/', Platform.isWindows ? r'\' : '/');
    final int overlapIndex = platformFilepath.lastIndexOf(directory.basename);
    if (overlapIndex < 0) {
      throw ArgumentError('filepath $filepath must be located in directory ${directory.path}.');
    }
    final String filename = platformFilepath.substring(
      overlapIndex + directory.basename.length + 1,
    );
    return directory.childFile(filename);
  }

  void buildTestFiles({
    Set<String> excludes = const <String>{},
    Set<String> extraCupertinos = const <String>{},
    Set<String> extraWidgetsImportingMaterial = const <String>{},
    Set<String> extraWidgetsImportingCupertino = const <String>{},
  }) {
    final knownFiles = <Directory, Set<String>>{
      testWidgetsDirectory: TestsCrossImportChecker.knownWidgetsCrossImports,
      testCupertinoDirectory: TestsCrossImportChecker.knownCupertinoCrossImports,
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
    for (final filepath in extraCupertinos) {
      writeImport(getFile(filepath, testCupertinoDirectory));
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
    testWidgetsDirectory = testsDirectory.childDirectory('widgets')..createSync(recursive: true);
    testsDirectory.childDirectory('material').createSync(recursive: true);
    testCupertinoDirectory = testsDirectory.childDirectory('cupertino')
      ..createSync(recursive: true);

    checker = TestsCrossImportChecker(
      testsDirectory: testsDirectory,
      flutterRoot: flutterRoot,
      filesystem: fs,
    );
  });

  test('when only all knowns have cross imports', () async {
    buildTestFiles();
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    });
    expect(result, equals(''));
    expect(success, isTrue);
  });

  test('when not all widgets knowns have cross imports', () async {
    final String excluded = TestsCrossImportChecker.knownWidgetsCrossImports.first;
    buildTestFiles(excludes: <String>{excluded});
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    }, shouldHaveErrors: true);
    final String lines = <String>[
      '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
      '║ Huzzah! The following tests in Widgets no longer contain cross imports!',
      '║   $excluded',
      '║ However, they now need to be removed from the',
      '║ knownWidgetsCrossImports list in the script /dev/bots/check_tests_cross_imports.dart.',
      '╚═══════════════════════════════════════════════════════════════════════════════',
    ].join('\n');
    expect(result, equals('$lines\n'));
    expect(success, isFalse);
  });

  test('when not all cupertino knowns have cross imports', () async {
    final String excluded = TestsCrossImportChecker.knownCupertinoCrossImports.first;
    buildTestFiles(excludes: <String>{excluded});
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    }, shouldHaveErrors: true);
    final String lines = <String>[
      '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
      '║ Huzzah! The following tests in Cupertino no longer contain cross imports!',
      '║   $excluded',
      '║ However, they now need to be removed from the',
      '║ knownCupertinoCrossImports list in the script /dev/bots/check_tests_cross_imports.dart.',
      '╚═══════════════════════════════════════════════════════════════════════════════',
    ].join('\n');
    expect(result, equals('$lines\n'));
    expect(success, isFalse);
  });

  test('unknown Widgets cross import of Material', () async {
    final String extra = 'packages/flutter/test/widgets/foo_test.dart'.replaceAll(
      '/',
      Platform.isWindows ? r'\' : '/',
    );
    buildTestFiles(extraWidgetsImportingMaterial: <String>{extra});
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

  test('unknown Widgets cross import of Cupertino', () async {
    final String extra = 'packages/flutter/test/widgets/foo_test.dart'.replaceAll(
      '/',
      Platform.isWindows ? r'\' : '/',
    );
    buildTestFiles(extraWidgetsImportingCupertino: <String>{extra});
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

  test('unknown Cupertino cross importing Material', () async {
    final String extra = 'packages/flutter/test/cupertino/foo_test.dart'.replaceAll(
      '/',
      Platform.isWindows ? r'\' : '/',
    );
    buildTestFiles(extraCupertinos: <String>{extra});
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
