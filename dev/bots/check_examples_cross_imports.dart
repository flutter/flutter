// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// To run this, from the root of the Flutter repository:
//   bin/cache/dart-sdk/bin/dart --enable-asserts dev/bots/check_examples_cross_imports.dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

import 'cross_imports_checker_utils.dart';
import 'utils.dart';

final String _scriptLocation = path.fromUri(Platform.script);
final String _flutterRoot = path.dirname(path.dirname(path.dirname(_scriptLocation)));
final String _examplesDirectoryPath = path.join(_flutterRoot, 'examples');

void main(List<String> args) {
  final argParser = ArgParser();
  argParser.addFlag('help', negatable: false, help: 'Print help for this command.');
  argParser.addOption(
    'examples',
    valueHelp: 'path',
    defaultsTo: _examplesDirectoryPath,
    help: 'A location where the examples are found.',
  );
  argParser.addOption(
    'flutter-root',
    valueHelp: 'path',
    defaultsTo: _flutterRoot,
    help: 'The path to the root of the Flutter repo.',
  );
  final ArgResults parsedArgs;

  void usage() {
    print('dart --enable-asserts ${path.basename(_scriptLocation)} [options]');
    print(argParser.usage);
  }

  try {
    parsedArgs = argParser.parse(args);
  } on FormatException catch (e) {
    print(e.message);
    usage();
    exit(1);
  }

  if (parsedArgs['help'] as bool) {
    usage();
    exit(0);
  }

  const FileSystem filesystem = LocalFileSystem();
  final Directory examplesDirectory = filesystem.directory(parsedArgs['examples']! as String);
  final Directory flutterRoot = filesystem.directory(parsedArgs['flutter-root']! as String);

  final checker = ExamplesCrossImportChecker(
    examplesDirectory: examplesDirectory,
    flutterRoot: flutterRoot,
  );

  if (!checker.check()) {
    reportErrorsAndExit('Some errors were found in the examples imports.');
  }
  reportSuccessAndExit('No errors were detected with examples cross imports.');
}

/// Checks the examples in `examples/**` libraries for cross imports.
///
/// Excludes known examples that contain cross imports, i.e.
/// [ExamplesCrossImportChecker.knownExamplesFlutterViewCrossImports] and
/// [ExamplesCrossImportChecker.knownExamplesImageListCrossImports].
///
/// In short, the Material examples can import the Material library.
/// Otherwise, examples should not import Material.
///
/// The guiding principles behind this organization of our examples are as follows:
///
///  - Cupertino examples can import the Cupertino library.
///  - Material examples can import the Material library.
///  - Any other examples should not import Material or Cupertino.
class ExamplesCrossImportChecker {
  ExamplesCrossImportChecker({
    required this.examplesDirectory,
    required this.flutterRoot,
    this.filesystem = const LocalFileSystem(),
  });

  final Directory examplesDirectory;
  final Directory flutterRoot;
  final FileSystem filesystem;

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesCrossImports = <String>{};

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesFlutterViewCrossImports = <String>{};

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesHelloWorldCrossImports = <String>{};

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesImageListCrossImports = <String>{};

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesLayersCrossImports = <String>{};

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesMultipleWindowsCrossImports = <String>{};

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesPlatformChannelCrossImports = <String>{};

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesPlatformChannelSwiftCrossImports = <String>{};

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesPlatformViewCrossImports = <String>{};

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSplashCrossImports = <String>{};

  /// These examples are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesTextureCrossImports = <String>{};

  static final Set<String> _knownCrossImports = {
    ...knownExamplesCrossImports,
    ...knownExamplesFlutterViewCrossImports,
    ...knownExamplesHelloWorldCrossImports,
    ...knownExamplesImageListCrossImports,
    ...knownExamplesLayersCrossImports,
    ...knownExamplesMultipleWindowsCrossImports,
    ...knownExamplesPlatformChannelCrossImports,
    ...knownExamplesPlatformChannelSwiftCrossImports,
    ...knownExamplesPlatformViewCrossImports,
    ...knownExamplesSplashCrossImports,
    ...knownExamplesTextureCrossImports,
  };

  static final RegExp _examplesPrefix = RegExp(r'examples');

  /// Returns true if there are no errors, false otherwise.
  bool check() {
    filesystem.currentDirectory = flutterRoot;

    final Map<_Library, Set<File>> filesByLibrary = _getExamplesFiles();

    // Find all cross imports.
    final Map<CrossImportCheckedLibrary, CrossImportingFiles> crossImportsPerLibrary =
        getCrossImports(filesByLibrary);

    var valid = true;

    // Find any cross imports that are not in the known list.
    for (final MapEntry<CrossImportCheckedLibrary, CrossImportingFiles> entry
        in crossImportsPerLibrary.entries) {
      final Set<File> unknownCupertinoImports = getUnknowns(
        _knownCrossImports,
        entry.value.cupertinoImports,
        prefix: _examplesPrefix,
      );
      final Set<File> unknownMaterialImports = getUnknowns(
        _knownCrossImports,
        entry.value.materialImports,
        prefix: _examplesPrefix,
      );

      if (unknownMaterialImports.isNotEmpty) {
        valid = false;
        foundError(
          getImportError(
            flutterRoot: flutterRoot,
            files: unknownMaterialImports,
            checkedLibrary: entry.key,
            importStatement: LibraryCrossImportStatementType.material,
          ).split('\n'),
        );
      }

      if (unknownCupertinoImports.isNotEmpty) {
        valid = false;
        foundError(
          getImportError(
            flutterRoot: flutterRoot,
            files: unknownCupertinoImports,
            checkedLibrary: entry.key,
            importStatement: LibraryCrossImportStatementType.cupertino,
          ).split('\n'),
        );
      }
    }

    // Find any known cross imports that weren't found, and are therefore fixed.
    // TODO(justinmc): Remove this after all known cross imports have been
    // fixed.
    // See https://github.com/flutter/flutter/issues/187645.
    for (final MapEntry<CrossImportCheckedLibrary, CrossImportingFiles> entry
        in crossImportsPerLibrary.entries) {
      final Set<File> crossImportsForLibrary = entry.value.cupertinoImports.union(
        entry.value.materialImports,
      );
      final Set<String> knownCrossImportsForLibrary = entry.key.knownCrossImports;

      final Set<String> fixedCrossImports = differencePaths(
        knownCrossImportsForLibrary,
        crossImportsForLibrary,
        prefix: _examplesPrefix,
      );

      if (fixedCrossImports.isNotEmpty) {
        valid = false;
        foundError(getFixedImportError(fixedCrossImports, entry.key).split('\n'));
      }
    }

    return valid;
  }
}
