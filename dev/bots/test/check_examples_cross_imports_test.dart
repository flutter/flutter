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
}

// A utility that keeps track of the directories under test,
// to avoid having to late initialize them individually in `setUp()`.
class _CrossImportsExamplesDirectories {
  factory _CrossImportsExamplesDirectories(Directory examplesDirectory) {
    return _CrossImportsExamplesDirectories._(
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
