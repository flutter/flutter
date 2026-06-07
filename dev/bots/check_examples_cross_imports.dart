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

  /// The known cross imports in the `examples/` directory itself.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesCrossImports = <String>{};

  /// The known cross imports in the `examples/api` directory itself.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiCrossImports = <String>{};

  /// The known cross imports in the `examples/flutter_view` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesFlutterViewCrossImports = <String>{};

  /// The known cross imports in the `examples/hello_world` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesHelloWorldCrossImports = <String>{};

  /// The known cross imports in the `examples/image_list` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesImageListCrossImports = <String>{};

  /// The known cross imports in the `examples/layers` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesLayersCrossImports = <String>{};

  /// The known cross imports in the `examples/multiple_windows` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesMultipleWindowsCrossImports = <String>{};

  /// The known cross imports in the `examples/platform_channel` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesPlatformChannelCrossImports = <String>{};

  /// The known cross imports in the `examples/platform_channel_swift` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesPlatformChannelSwiftCrossImports = <String>{};

  /// The known cross imports in the `examples/platform_view` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesPlatformViewCrossImports = <String>{};

  /// The known cross imports in the `examples/splash` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSplashCrossImports = <String>{};

  /// The known cross imports in the `examples/texture` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesTextureCrossImports = <String>{};

  static final Set<String> _knownCrossImports = {
    ...knownExamplesCrossImports,
    ...knownExamplesSlashApiCrossImports,
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

  /// Get a list of all the filenames that end in ".dart" for the given examples directory.
  ///
  /// The [directory] must not be a subdirectory of `examples/api`.
  Set<File> _getExampleFiles(Directory directory, {required Pattern dartFilePattern}) {
    final String examplesSlashApiPath = path.join(flutterRoot.absolute.path, 'examples', 'api');

    if (directory.absolute.path.startsWith(examplesSlashApiPath)) {
      throw ArgumentError('Directory must not be an examples/api subdirectory.', 'directory');
    }

    final files = <File>{};

    for (final FileSystemEntity fileSystemEntity in directory.listSync()) {
      if (fileSystemEntity is File && fileSystemEntity.absolute.path.contains(dartFilePattern)) {
        files.add(fileSystemEntity);

        continue;
      }

      if (fileSystemEntity is Directory) {
        final String directoryName = path.basename(fileSystemEntity.absolute.path);

        if (directoryName == 'build' || directoryName == '.dart_tool') {
          continue;
        }

        for (final File file in fileSystemEntity.listSync().whereType<File>()) {
          if (file.absolute.path.contains(dartFilePattern)) {
            files.add(file);
          }
        }
      }
    }

    return files;
  }

  /// Get a list of all the filenames that end in ".dart", grouped by library.
  Map<_ExamplesLibrary, Set<File>> _getExamplesFiles() {
    final dartFilePattern = RegExp(r'\.dart$');

    const _ExamplesLibrary examplesRoot = _GenericExampleLibrary('examples');
    final Map<_ExamplesLibrary, Set<File>> mapping = {examplesRoot: {}};

    // List the files directly under `examples` and then walk the subdirectories.
    for (final FileSystemEntity fileSystemEntity in examplesDirectory.listSync()) {
      if (fileSystemEntity is File && fileSystemEntity.absolute.path.contains(dartFilePattern)) {
        mapping[examplesRoot]?.add(fileSystemEntity);

        continue;
      }

      if (fileSystemEntity is Directory) {
        final String directoryName = path.basename(fileSystemEntity.absolute.path);

        if (directoryName == 'build' || directoryName == '.dart_tool') {
          continue;
        }

        // The examples/api folder contains examples in a single Flutter project,
        // grouped in subfolders in lib/ and test/, so these need to be handled separately.
        if (directoryName == 'api') {
          // First list the files directly under examples/api.
          final examplesSlashApiLibrary = _ExamplesLibrary.fromDirectory(
            fileSystemEntity,
            flutterRoot: flutterRoot,
          );

          mapping[examplesSlashApiLibrary] = {
            for (final File file in fileSystemEntity.listSync().whereType<File>())
              if (file.absolute.path.contains(dartFilePattern)) file,
          };

          // Then handle the subfolder examples separately.

          continue;
        }

        final library = _ExamplesLibrary.fromDirectory(fileSystemEntity, flutterRoot: flutterRoot);

        mapping[library] = _getExampleFiles(fileSystemEntity, dartFilePattern: dartFilePattern);
      }
    }

    return mapping;
  }

  /// Returns true if there are no errors, false otherwise.
  bool check() {
    filesystem.currentDirectory = flutterRoot;

    final Map<_ExamplesLibrary, Set<File>> filesByLibrary = _getExamplesFiles();

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

/// The examples that we are concerned with cross importing.
sealed class _ExamplesLibrary implements CrossImportCheckedLibrary {
  const _ExamplesLibrary(this._name);

  /// Construct a [_ExamplesLibrary] from a given [directory].
  ///
  /// The [directory] must be inside the [flutterRoot].
  factory _ExamplesLibrary.fromDirectory(Directory directory, {required Directory flutterRoot}) {
    if (!directory.absolute.path.startsWith(flutterRoot.absolute.path)) {
      throw ArgumentError('Directory must be inside ${flutterRoot.absolute.path}.', 'directory');
    }

    final String relativePath = path
        .relative(directory.absolute.path, from: flutterRoot.absolute.path)
        .replaceAll(Platform.pathSeparator, '/');

    return switch (relativePath) {
      'examples' => const _GenericExampleLibrary('examples'),
      'examples/api' => const _GenericExampleLibrary('examples/api'),
      'examples/flutter_view' => const _GenericExampleLibrary('examples/flutter_view'),
      'examples/hello_world' => const _GenericExampleLibrary('examples/hello_world'),
      'examples/image_list' => const _GenericExampleLibrary('examples/image_list'),
      'examples/layers' => const _GenericExampleLibrary('examples/layers'),
      'examples/multiple_windows' => const _GenericExampleLibrary('examples/multiple_windows'),
      'examples/platform_channel' => const _GenericExampleLibrary('examples/platform_channel'),
      'examples/platform_channel_swift' => const _GenericExampleLibrary(
        'examples/platform_channel_swift',
      ),
      'examples/platform_view' => const _GenericExampleLibrary('examples/platform_view'),
      'examples/splash' => const _GenericExampleLibrary('examples/splash'),
      'examples/texture' => const _GenericExampleLibrary('examples/texture'),
      _ => throw UnimplementedError('Unknown library: $relativePath'),
    };
  }

  /// The short name of the library, for example `examples/flutter_view`.
  final String _name;

  @override
  String get cannotImportMessage {
    return 'Only Material examples can import Material and only Cupertino examples can import Cupertino.';
  }

  @override
  Set<String> get knownCrossImports {
    return switch (crossImportsListSymbolName) {
      'knownExamplesCrossImports' => ExamplesCrossImportChecker.knownExamplesCrossImports,
      'knownExamplesSlashApiCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesSlashApiCrossImports,
      'knownExamplesFlutterViewCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesFlutterViewCrossImports,
      'knownExamplesHelloWorldCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesHelloWorldCrossImports,
      'knownExamplesImageListCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesImageListCrossImports,
      'knownExamplesLayersCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesLayersCrossImports,
      'knownExamplesMultipleWindowsCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesMultipleWindowsCrossImports,
      'knownExamplesPlatformChannelCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesPlatformChannelCrossImports,
      'knownExamplesPlatformChannelSwiftCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesPlatformChannelSwiftCrossImports,
      'knownExamplesPlatformViewCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesPlatformViewCrossImports,
      'knownExamplesSplashCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesSplashCrossImports,
      'knownExamplesTextureCrossImports' =>
        ExamplesCrossImportChecker.knownExamplesTextureCrossImports,
      _ => throw UnimplementedError('Unknown cross imports list: $crossImportsListSymbolName'),
    };
  }

  @override
  String get libraryName => _name;

  @override
  String get removeCrossImportsInstructionMessage {
    return 'However, they now need to be removed from the\n'
        '$crossImportsListSymbolName list in the script /dev/bots/check_examples_cross_imports.dart.';
  }

  @override
  bool canImport(LibraryCrossImportStatementType import) {
    return switch (this) {
      _GenericExampleLibrary() => false,
    };
  }

  @override
  String getDisallowedImportMessage(String importedLibraryName, int filesCount) {
    return filesCount < 2
        ? 'The following file in $libraryName has a disallowed import of $importedLibraryName. '
              'Refactor it or move it to $importedLibraryName.\n'
        : 'The following $filesCount files in $libraryName have a disallowed import of $importedLibraryName. '
              'Refactor them or move them to $importedLibraryName.\n';
  }

  /// The name of the variable in [ExamplesCrossImportChecker]
  /// that contains the list of known cross imports for this library.
  ///
  /// This is used for reporting mismatched cross imports.
  String get crossImportsListSymbolName {
    return switch (libraryName) {
      'examples' => 'knownExamplesCrossImports',
      'examples/api' => 'knownExamplesSlashApiCrossImports',
      'examples/flutter_view' => 'knownExamplesFlutterViewCrossImports',
      'examples/hello_world' => 'knownExamplesHelloWorldCrossImports',
      'examples/image_list' => 'knownExamplesImageListCrossImports',
      'examples/layers' => 'knownExamplesLayersCrossImports',
      'examples/multiple_windows' => 'knownExamplesMultipleWindowsCrossImports',
      'examples/platform_channel' => 'knownExamplesPlatformChannelCrossImports',
      'examples/platform_channel_swift' => 'knownExamplesPlatformChannelSwiftCrossImports',
      'examples/platform_view' => 'knownExamplesPlatformViewCrossImports',
      'examples/splash' => 'knownExamplesSplashCrossImports',
      'examples/texture' => 'knownExamplesTextureCrossImports',
      _ => throw UnimplementedError('Unknown library: $libraryName'),
    };
  }
}

/// Any example that is not related to Material or Cupertino.
///
/// For example `examples/flutter_view` or `examples/hello_world`.
final class _GenericExampleLibrary extends _ExamplesLibrary {
  const _GenericExampleLibrary(super.name);
}
