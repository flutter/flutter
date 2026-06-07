// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;

import '../check_examples_cross_imports.dart';
import 'common.dart';
import 'cross_imports_checker_test_utils.dart';

void main() {
  late ExamplesCrossImportChecker checker;
  late _CrossImportsExamplesDirectories checkerDirectories;

  void buildKnownCrossImportExamplesFiles({Set<String> excludes = const <String>{}}) {
    final Map<Directory, Set<String>> knownFiles = checkerDirectories.getKnownFiles(
      checker.examplesDirectory,
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

    final Directory examplesDirectory = flutterRoot.childDirectory('examples')..createSync();

    checker = ExamplesCrossImportChecker(
      examplesDirectory: examplesDirectory,
      flutterRoot: flutterRoot,
      filesystem: fs,
    );
    checkerDirectories = _CrossImportsExamplesDirectories(examplesDirectory)
      ..createExamplesDirectories(examplesDirectory);
  });

  test('when only all knowns have cross imports', () async {
    buildKnownCrossImportExamplesFiles();
    bool? success;
    final String result = await capture(() async {
      success = checker.check();
    });
    expect(result, equals(''));
    expect(success, isTrue);
  });

  test('non-Dart files are ignored', () async {
    buildKnownCrossImportExamplesFiles();

    checker.examplesDirectory.childFile('README.md')
      ..createSync()
      ..writeAsStringSync("import 'package:flutter/material.dart';");

    expect(checker.check(), isTrue);
  });

  test('non-Dart files with .dart in the filename are ignored', () async {
    buildKnownCrossImportExamplesFiles();

    checker.examplesDirectory.childFile('foo.dart.md')
      ..createSync()
      ..writeAsStringSync("import 'package:flutter/material.dart';");

    expect(checker.check(), isTrue);
  });

  for (final (String libraryName, String knownCrossImportsListName, Set<String> knownCrossImports)
      in crossImportsGenericExamplesTestCases) {
    test(
      'when not all $libraryName knowns have cross imports',
      () async {
        final String excludedSample = knownCrossImports.first;

        buildKnownCrossImportExamplesFiles(excludes: <String>{excludedSample});

        bool? success;
        final String result = await capture(() async {
          success = checker.check();
        }, shouldHaveErrors: true);
        final String lines = <String>[
          '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
          '║ Huzzah! The following files in $libraryName no longer contain cross imports!',
          '║   $excludedSample',
          '║ However, they now need to be removed from the',
          '║ $knownCrossImportsListName list in the script /dev/bots/check_examples_cross_imports.dart.',
          '╚═══════════════════════════════════════════════════════════════════════════════',
        ].join('\n');
        expect(result, equals('$lines\n'));
        expect(success, isFalse);
      },
      skip: knownCrossImports.isEmpty, // [intended]: Nothing to log if there are no known imports
    );

    test('unknown $libraryName cross import of Material', () async {
      final dartFile = '$libraryName/foo.dart';

      final Directory examplesFilesDirectory = checkerDirectories.examplesFilesDirectoryFor(
        libraryName,
        checker.examplesDirectory,
      );

      buildKnownCrossImportExamplesFiles();
      writeImportInFiles({dartFile}, inDirectory: examplesFilesDirectory);

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines = <String>[
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        '║ The following file in $libraryName has a disallowed import of Material. Refactor it or move it to Material.',
        '║   $dartFile',
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ].join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    });

    test('multiple unknown $libraryName cross imports of Material', () async {
      final dartFileOne = '$libraryName/foo.dart';
      final dartFileTwo = '$libraryName/bar.dart';

      final Directory examplesFilesDirectory = checkerDirectories.examplesFilesDirectoryFor(
        libraryName,
        checker.examplesDirectory,
      );

      buildKnownCrossImportExamplesFiles();
      writeImportInFiles({dartFileOne, dartFileTwo}, inDirectory: examplesFilesDirectory);

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines = <String>[
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        '║ The following 2 files in $libraryName have a disallowed import of Material. Refactor them or move them to Material.',
        '║   $dartFileOne',
        '║   $dartFileTwo',
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ].join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    });

    test('unknown $libraryName cross import of Material in test file', () async {
      final testDartFile = '$libraryName/foo_test.dart';

      final Directory examplesFilesDirectory = checkerDirectories.examplesFilesDirectoryFor(
        libraryName,
        checker.examplesDirectory,
      );

      buildKnownCrossImportExamplesFiles();
      writeImportInFiles(<String>{testDartFile}, inDirectory: examplesFilesDirectory);

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines = <String>[
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        '║ The following file in $libraryName has a disallowed import of Material. Refactor it or move it to Material.',
        '║   $testDartFile',
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ].join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    });

    test('unknown $libraryName cross import of Cupertino', () async {
      final dartFile = '$libraryName/foo.dart';
      final Directory examplesFilesDirectory = checkerDirectories.examplesFilesDirectoryFor(
        libraryName,
        checker.examplesDirectory,
      );

      buildKnownCrossImportExamplesFiles();
      writeImportInFiles(
        <String>{dartFile},
        inDirectory: examplesFilesDirectory,
        importString: "import 'package:flutter/cupertino.dart';",
      );

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines = <String>[
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        '║ The following file in $libraryName has a disallowed import of Cupertino. Refactor it or move it to Cupertino.',
        '║   $dartFile',
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ].join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    });

    test('multiple unknown $libraryName cross imports of Cupertino', () async {
      final dartFileOne = '$libraryName/foo.dart';
      final dartFileTwo = '$libraryName/bar.dart';

      final Directory examplesFilesDirectory = checkerDirectories.examplesFilesDirectoryFor(
        libraryName,
        checker.examplesDirectory,
      );

      buildKnownCrossImportExamplesFiles();
      writeImportInFiles(
        {dartFileOne, dartFileTwo},
        inDirectory: examplesFilesDirectory,
        importString: "import 'package:flutter/cupertino.dart';",
      );

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines = <String>[
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        '║ The following 2 files in $libraryName have a disallowed import of Cupertino. Refactor them or move them to Cupertino.',
        '║   $dartFileOne',
        '║   $dartFileTwo',
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ].join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    });

    test('unknown $libraryName cross import of Cupertino in test file', () async {
      final testDartFile = '$libraryName/foo_test.dart';
      final Directory examplesFilesDirectory = checkerDirectories.examplesFilesDirectoryFor(
        libraryName,
        checker.examplesDirectory,
      );

      buildKnownCrossImportExamplesFiles();
      writeImportInFiles(
        <String>{testDartFile},
        inDirectory: examplesFilesDirectory,
        importString: "import 'package:flutter/cupertino.dart';",
      );

      bool? success;
      final String result = await capture(() async {
        success = checker.check();
      }, shouldHaveErrors: true);
      final String lines = <String>[
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        '║ The following file in $libraryName has a disallowed import of Cupertino. Refactor it or move it to Cupertino.',
        '║   $testDartFile',
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ].join('\n');
      expect(result, equals('$lines\n'));
      expect(success, isFalse);
    });

    test('files under $libraryName/build are ignored', () async {
      buildKnownCrossImportExamplesFiles();

      final Directory examplesFilesDirectory = checkerDirectories.examplesFilesDirectoryFor(
        libraryName,
        checker.examplesDirectory,
      );

      final Directory buildDirectory = examplesFilesDirectory.childDirectory('build')..createSync();
      buildDirectory.childFile('foo.dart')
        ..createSync()
        ..writeAsStringSync("import 'package:flutter/material.dart';");

      expect(checker.check(), isTrue);
    });

    test('files under $libraryName/.dart_tool are ignored', () async {
      buildKnownCrossImportExamplesFiles();

      final Directory examplesFilesDirectory = checkerDirectories.examplesFilesDirectoryFor(
        libraryName,
        checker.examplesDirectory,
      );

      final Directory dartToolDirectory = examplesFilesDirectory.childDirectory('.dart_tool')
        ..createSync();
      dartToolDirectory.childFile('foo.dart')
        ..createSync()
        ..writeAsStringSync("import 'package:flutter/material.dart';");

      expect(checker.check(), isTrue);
    });
  }
}

// A utility that keeps track of the directories under test,
// to avoid having to late initialize them individually in `setUp()`.
class _CrossImportsExamplesDirectories {
  factory _CrossImportsExamplesDirectories(Directory examplesDirectory) {
    return _CrossImportsExamplesDirectories._(
      examplesSlashApiDirectory: examplesDirectory.childDirectory('api'),
      examplesFlutterViewDirectory: examplesDirectory.childDirectory('flutter_view'),
      examplesHelloWorldDirectory: examplesDirectory.childDirectory('hello_world'),
      examplesImageListDirectory: examplesDirectory.childDirectory('image_list'),
      examplesLayersDirectory: examplesDirectory.childDirectory('layers'),
      examplesMultipleWindowsDirectory: examplesDirectory.childDirectory('multiple_windows'),
      examplesPlatformChannelDirectory: examplesDirectory.childDirectory('platform_channel'),
      examplesPlatformChannelSwiftDirectory: examplesDirectory.childDirectory(
        'platform_channel_swift',
      ),
      examplesPlatformViewDirectory: examplesDirectory.childDirectory('platform_view'),
      examplesSplashDirectory: examplesDirectory.childDirectory('splash'),
      examplesTextureDirectory: examplesDirectory.childDirectory('texture'),
    );
  }

  const _CrossImportsExamplesDirectories._({
    required this.examplesSlashApiDirectory,
    required this.examplesFlutterViewDirectory,
    required this.examplesHelloWorldDirectory,
    required this.examplesImageListDirectory,
    required this.examplesLayersDirectory,
    required this.examplesMultipleWindowsDirectory,
    required this.examplesPlatformChannelDirectory,
    required this.examplesPlatformChannelSwiftDirectory,
    required this.examplesPlatformViewDirectory,
    required this.examplesSplashDirectory,
    required this.examplesTextureDirectory,
  });

  final Directory examplesSlashApiDirectory;
  final Directory examplesFlutterViewDirectory;
  final Directory examplesHelloWorldDirectory;
  final Directory examplesImageListDirectory;
  final Directory examplesLayersDirectory;
  final Directory examplesMultipleWindowsDirectory;
  final Directory examplesPlatformChannelDirectory;
  final Directory examplesPlatformChannelSwiftDirectory;
  final Directory examplesPlatformViewDirectory;
  final Directory examplesSplashDirectory;
  final Directory examplesTextureDirectory;

  /// A mapping of `examples/xyz` directories
  /// to their corresponding known imports list in `check_examples_cross_imports.dart`
  Map<Directory, Set<String>> getKnownFiles(Directory examplesDirectory) {
    return <Directory, Set<String>>{
      examplesDirectory: ExamplesCrossImportChecker.knownExamplesCrossImports,
      examplesSlashApiDirectory: ExamplesCrossImportChecker.knownExamplesSlashApiCrossImports,
      examplesFlutterViewDirectory: ExamplesCrossImportChecker.knownExamplesFlutterViewCrossImports,
      examplesHelloWorldDirectory: ExamplesCrossImportChecker.knownExamplesHelloWorldCrossImports,
      examplesImageListDirectory: ExamplesCrossImportChecker.knownExamplesImageListCrossImports,
      examplesLayersDirectory: ExamplesCrossImportChecker.knownExamplesLayersCrossImports,
      examplesMultipleWindowsDirectory:
          ExamplesCrossImportChecker.knownExamplesMultipleWindowsCrossImports,
      examplesPlatformChannelDirectory:
          ExamplesCrossImportChecker.knownExamplesPlatformChannelCrossImports,
      examplesPlatformChannelSwiftDirectory:
          ExamplesCrossImportChecker.knownExamplesPlatformChannelSwiftCrossImports,
      examplesPlatformViewDirectory:
          ExamplesCrossImportChecker.knownExamplesPlatformViewCrossImports,
      examplesSplashDirectory: ExamplesCrossImportChecker.knownExamplesSplashCrossImports,
      examplesTextureDirectory: ExamplesCrossImportChecker.knownExamplesTextureCrossImports,
    };
  }

  void createExamplesDirectories(Directory examplesDirectory) {
    final Map<Directory, Set<String>> knownFiles = getKnownFiles(examplesDirectory);

    for (final Directory directory in knownFiles.keys) {
      // The `examples` directory is created in `setUp()`.
      if (directory == examplesDirectory) {
        continue;
      }

      directory.createSync(recursive: true);
    }
  }

  Directory examplesFilesDirectoryFor(String libraryName, Directory examplesDirectory) {
    return switch (libraryName) {
      'examples' => examplesDirectory,
      'examples/api' => examplesSlashApiDirectory,
      'examples/flutter_view' => examplesFlutterViewDirectory,
      'examples/hello_world' => examplesHelloWorldDirectory,
      'examples/image_list' => examplesImageListDirectory,
      'examples/layers' => examplesLayersDirectory,
      'examples/multiple_windows' => examplesMultipleWindowsDirectory,
      'examples/platform_channel' => examplesPlatformChannelDirectory,
      'examples/platform_channel_swift' => examplesPlatformChannelSwiftDirectory,
      'examples/platform_view' => examplesPlatformViewDirectory,
      'examples/splash' => examplesSplashDirectory,
      'examples/texture' => examplesTextureDirectory,
      _ => throw ArgumentError('Unknown library name: $libraryName'),
    };
  }
}

// A mapping of `examples/**` test cases for the cross imports checker, excluding `examples/api/**`.
//
// Each entry contains:
// - a shortened directory name of the examples folder for the library
// - the name of the known cross imports list variable in `check_examples_cross_imports.dart` for that library
// - the actual known cross imports list for that library
// dart format off
final crossImportsGenericExamplesTestCases = <(String, String, Set<String>)>[
  ('examples', 'knownExamplesCrossImports', ExamplesCrossImportChecker.knownExamplesCrossImports),
  ('examples/api', 'knownExamplesSlashApiCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiCrossImports),
  ('examples/flutter_view', 'knownExamplesFlutterViewCrossImports', ExamplesCrossImportChecker.knownExamplesFlutterViewCrossImports),
  ('examples/hello_world', 'knownExamplesHelloWorldCrossImports', ExamplesCrossImportChecker.knownExamplesHelloWorldCrossImports),
  ('examples/image_list', 'knownExamplesImageListCrossImports', ExamplesCrossImportChecker.knownExamplesImageListCrossImports),
  ('examples/layers', 'knownExamplesLayersCrossImports', ExamplesCrossImportChecker.knownExamplesLayersCrossImports),
  ('examples/multiple_windows', 'knownExamplesMultipleWindowsCrossImports', ExamplesCrossImportChecker.knownExamplesMultipleWindowsCrossImports),
  ('examples/platform_channel', 'knownExamplesPlatformChannelCrossImports', ExamplesCrossImportChecker.knownExamplesPlatformChannelCrossImports),
  ('examples/platform_channel_swift', 'knownExamplesPlatformChannelSwiftCrossImports', ExamplesCrossImportChecker.knownExamplesPlatformChannelSwiftCrossImports),
  ('examples/platform_view', 'knownExamplesPlatformViewCrossImports', ExamplesCrossImportChecker.knownExamplesPlatformViewCrossImports),
  ('examples/splash', 'knownExamplesSplashCrossImports', ExamplesCrossImportChecker.knownExamplesSplashCrossImports),
  ('examples/texture', 'knownExamplesTextureCrossImports', ExamplesCrossImportChecker.knownExamplesTextureCrossImports),
];
// dart format on

// A mapping of `examples/api/lib/**` and `examples/api/test/**` test cases for the cross imports checker,
// excluding `examples/api/lib/samples_templates` and `examples/api/test/samples_templates`.
final crossImportsExamplesApiTestCases = <(String, String, Set<String>)>[
  // dart format off
  ('examples/api/lib/animation', 'knownExamplesSlashApiAnimationCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiAnimationCrossImports),
  ('examples/api/lib/cupertino', 'knownExamplesSlashApiCupertinoCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiCupertinoCrossImports),
  ('examples/api/lib/foundation', 'knownExamplesSlashApiFoundationCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiFoundationCrossImports),
  ('examples/api/lib/gestures', 'knownExamplesSlashApiGesturesCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiGesturesCrossImports),
  ('examples/api/lib/material', 'knownExamplesSlashApiMaterialCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiMaterialCrossImports),
  ('examples/api/lib/painting', 'knownExamplesSlashApiPaintingCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiPaintingCrossImports),
  ('examples/api/lib/rendering', 'knownExamplesSlashApiRenderingCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiRenderingCrossImports),
  ('examples/api/lib/services', 'knownExamplesSlashApiServicesCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiServicesCrossImports),
  ('examples/api/lib/ui', 'knownExamplesSlashApiUICrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiUICrossImports),
  ('examples/api/lib/widgets', 'knownExamplesSlashApiWidgetsCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiWidgetsCrossImports),

  ('examples/api/test/animation', 'knownExamplesSlashApiAnimationCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiAnimationCrossImports),
  ('examples/api/test/cupertino', 'knownExamplesSlashApiCupertinoCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiCupertinoCrossImports),
  ('examples/api/test/foundation', 'knownExamplesSlashApiFoundationCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiFoundationCrossImports),
  ('examples/api/test/gestures', 'knownExamplesSlashApiGesturesCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiGesturesCrossImports),
  ('examples/api/test/material', 'knownExamplesSlashApiMaterialCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiMaterialCrossImports),
  ('examples/api/test/painting', 'knownExamplesSlashApiPaintingCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiPaintingCrossImports),
  ('examples/api/test/rendering', 'knownExamplesSlashApiRenderingCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiRenderingCrossImports),
  ('examples/api/test/services', 'knownExamplesSlashApiServicesCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiServicesCrossImports),
  ('examples/api/test/ui', 'knownExamplesSlashApiUICrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiUICrossImports),
  ('examples/api/test/widgets', 'knownExamplesSlashApiWidgetsCrossImports', ExamplesCrossImportChecker.knownExamplesSlashApiWidgetsCrossImports),
  // dart format on
];
