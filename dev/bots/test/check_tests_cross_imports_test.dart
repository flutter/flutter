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
  late FileSystem fs;
  late Directory examples;
  late Directory packages;
  late Directory dartUIPath;
  late Directory flutterRoot;

  // TODO(justinmc): Reuse from main file, or refactor?
  late Directory _testsDirectory;
  late Directory _testWidgetsDirectory;
  late Directory _testMaterialDirectory;
  late Directory _testCupertinoDirectory;
  late final Set<Directory> _testDirectories = <Directory>{};

  String getRelativePath(File file, [Directory? from]) {
    from ??= flutterRoot;
    return path.relative(file.absolute.path, from: flutterRoot.absolute.path);
  }

  // Writes a Material import into the given file.
  void writeImport(File file, [String importString = "import 'package:flutter/material.dart';"]) {
    file
      ..createSync(recursive: true)
      ..writeAsStringSync("import 'package:flutter/material.dart';");
  }

  File getFile(String filepath, Directory directory) {
    final String path = directory.path.substring('/flutter/sdk'.length);
    final String filename = filepath.substring(path.length);
    return directory.childFile(filename);
  }

  void buildTestFiles({
    Set<String> excludes = const <String>{},
    Set<String> extraCupertinos = const <String>{},
    Set<String> extraWidgetsImportingMaterial = const <String>{},
    Set<String> extraWidgetsImportingCupertino = const <String>{},
  }) {
    final Map<Directory, Set<String>> knownFiles = <Directory, Set<String>>{
      _testWidgetsDirectory: knownWidgetsCrossImports,
      _testCupertinoDirectory: knownCupertinoCrossImports,
    };

    for (final MapEntry<Directory, Set<String>>(key: Directory directory, value: Set<String> files)
        in knownFiles.entries) {
      for (final String filepath in files) {
        if (excludes.contains(filepath)) {
          continue;
        }
        writeImport(getFile(filepath, directory));
      }
    }

    for (final String filepath in extraWidgetsImportingMaterial) {
      writeImport(getFile(filepath, _testWidgetsDirectory));
    }
    for (final String filepath in extraWidgetsImportingCupertino) {
      writeImport(
        getFile(filepath, _testWidgetsDirectory),
        "import 'package:flutter/cupertino.dart';",
      );
    }
    for (final String filepath in extraCupertinos) {
      writeImport(getFile(filepath, _testCupertinoDirectory));
    }
  }

  setUp(() {
    fs = MemoryFileSystem(
      style: Platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
    );
    // Get the root prefix of the current directory so that on Windows we get a
    // correct root prefix.
    flutterRoot = fs.directory(
      path.join(path.rootPrefix(fs.currentDirectory.absolute.path), 'flutter/sdk'),
    )..createSync(recursive: true);
    fs.currentDirectory = flutterRoot;
    examples = flutterRoot.childDirectory('examples').childDirectory('api')
      ..createSync(recursive: true);
    packages = flutterRoot.childDirectory('packages')..createSync(recursive: true);
    dartUIPath =
        flutterRoot
            .childDirectory('bin')
            .childDirectory('cache')
            .childDirectory('pkg')
            .childDirectory('sky_engine')
            .childDirectory('lib')
          ..createSync(recursive: true);

    _testsDirectory =
        flutterRoot.childDirectory('packages').childDirectory('flutter').childDirectory('test')
          ..createSync(recursive: true);
    _testWidgetsDirectory = _testsDirectory.childDirectory('widgets')..createSync(recursive: true);
    _testMaterialDirectory = _testsDirectory.childDirectory('material')
      ..createSync(recursive: true);
    _testCupertinoDirectory = _testsDirectory.childDirectory('cupertino')
      ..createSync(recursive: true);
    _testDirectories.addAll(<Directory>[
      _testWidgetsDirectory,
      _testMaterialDirectory,
      _testCupertinoDirectory,
    ]);

    checker = TestsCrossImportChecker(
      testsDirectory: _testsDirectory,
      flutterRoot: flutterRoot,
      filesystem: fs,
    );
  });

  /*
  test('only all knowns have cross imports', () async {
    buildTestFiles();
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    });
    expect(result, equals(''));
    expect(success, isTrue);
  });

  test('not all widgets knowns have cross imports', () async {
    buildTestFiles(excludes: <String>{knownWidgetsCrossImports.first});
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    }, shouldHaveErrors: true);
    final String lines =
        <String>[
              '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
              '║ Huzzah! The following tests in Widgets no longer contain cross imports!',
              '║   packages/flutter/test/widgets/basic_test.dart',
              '║ However, they now need to be removed from the',
              '║ knownWidgetsCrossImports list in the script /usr/local/google/home/jmccandless/Projects/flutter/main.dart.',
              '╚═══════════════════════════════════════════════════════════════════════════════',
            ]
            .map((String line) {
              return line.replaceAll('/', Platform.isWindows ? r'\' : '/');
            })
            .join('\n');
    expect(result, equals('$lines\n'));
    expect(success, isFalse);
  });

  test('not all cupertino knowns have cross imports', () async {
    final String excluded = knownCupertinoCrossImports.first;
    buildTestFiles(excludes: <String>{excluded});
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    }, shouldHaveErrors: true);
    final String lines =
        <String>[
              '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
              '║ Huzzah! The following tests in Cupertino no longer contain cross imports!',
              '║   $excluded',
              '║ However, they now need to be removed from the',
              '║ knownCupertinoCrossImports list in the script /usr/local/google/home/jmccandless/Projects/flutter/main.dart.',
              '╚═══════════════════════════════════════════════════════════════════════════════',
            ]
            .map((String line) {
              return line.replaceAll('/', Platform.isWindows ? r'\' : '/');
            })
            .join('\n');
    expect(result, equals('$lines\n'));
    expect(success, isFalse);
  });

  test('unknown Widgets cross import of Material', () async {
    const String extra = 'packages/flutter/test/widgets/foo_test.dart';
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
  */

  test('unknown Widgets cross import of Cupertino', () async {
    const String extra = 'packages/flutter/test/widgets/foo_test.dart';
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

  /*
  test('unknown Cupertino cross importing Material', () async {
    const String extra = 'packages/flutter/test/cupertino/foo_test.dart';
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
  */

  /*
  test('check_code_samples.dart - checkCodeSamples catches missing tests', () async {
    buildTestFiles(missingTests: true);
    bool? success;
    final String result = await capture(() async {
      success = checker.checkCodeSamples();
    }, shouldHaveErrors: true);
    final String lines =
        <String>[
              '╔═╡ERROR╞═══════════════════════════════════════════════════════════════════════',
              '║ The following example test files are missing:',
              '║   examples/api/test/layer/bar_example.0_test.dart',
              '╚═══════════════════════════════════════════════════════════════════════════════',
            ]
            .map((String line) {
              return line.replaceAll('/', Platform.isWindows ? r'\' : '/');
            })
            .join('\n');
    expect(result, equals('$lines\n'));
    expect(success, equals(false));
  });

  test('check_code_samples.dart - checkCodeSamples succeeds', () async {
    buildTestFiles();
    bool? success;
    final String result = await capture(() async {
      success = checker.checkCodeSamples();
    });
    expect(result, isEmpty);
    expect(success, equals(true));
  });
  */
}

typedef AsyncVoidCallback = Future<void> Function();

Future<String> capture(AsyncVoidCallback callback, {bool shouldHaveErrors = false}) async {
  final StringBuffer buffer = StringBuffer();
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
