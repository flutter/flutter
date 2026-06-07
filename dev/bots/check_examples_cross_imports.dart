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

  /// The known cross imports in the `examples/api/lib/animation`
  /// and `examples/api/test/animation` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiAnimationCrossImports = <String>{};

  /// The known cross imports in the `examples/api/lib/cupertino`
  /// and `examples/api/test/cupertino` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiCupertinoCrossImports = <String>{};

  /// The known cross imports in the `examples/api/lib/foundation`
  /// and `examples/api/test/foundation` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiFoundationCrossImports = <String>{};

  /// The known cross imports in the `examples/api/lib/gestures`
  /// and `examples/api/test/gestures` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiGesturesCrossImports = <String>{};

  /// The known cross imports in the `examples/api/lib/material`
  /// and `examples/api/test/material` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiMaterialCrossImports = <String>{};

  /// The known cross imports in the `examples/api/lib/painting`
  /// and `examples/api/test/painting` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiPaintingCrossImports = <String>{};

  /// The known cross imports in the `examples/api/lib/rendering`
  /// and `examples/api/test/rendering` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiRenderingCrossImports = <String>{};

  /// The known cross imports in the `examples/api/lib/sample_templates`
  /// and `examples/api/test/sample_templates` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiSampleTemplatesCrossImports = <String>{};

  /// The known cross imports in the `examples/api/lib/services`
  /// and `examples/api/test/services` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiServicesCrossImports = <String>{};

  /// The known cross imports in the `examples/api/lib/ui`
  /// and `examples/api/test/ui` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiUICrossImports = <String>{};

  /// The known cross imports in the `examples/api/lib/widgets`
  /// and `examples/api/test/widgets` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiWidgetsCrossImports = <String>{};

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
    ...knownExamplesSlashApiAnimationCrossImports,
    ...knownExamplesSlashApiCupertinoCrossImports,
    ...knownExamplesSlashApiFoundationCrossImports,
    ...knownExamplesSlashApiGesturesCrossImports,
    ...knownExamplesSlashApiMaterialCrossImports,
    ...knownExamplesSlashApiPaintingCrossImports,
    ...knownExamplesSlashApiRenderingCrossImports,
    ...knownExamplesSlashApiSampleTemplatesCrossImports,
    ...knownExamplesSlashApiServicesCrossImports,
    ...knownExamplesSlashApiUICrossImports,
    ...knownExamplesSlashApiWidgetsCrossImports,
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

  bool _canImport(
    CrossImportCheckedLibrary library,
    LibraryCrossImportStatementType import,
    String filePath,
  ) {
    if (library is! _ExamplesLibrary) {
      return false;
    }

    return switch (library) {
      _ApiExampleLibrary() ||
      _CupertinoApiExampleLibrary() ||
      _GenericExampleLibrary() ||
      _MaterialApiExampleLibrary() => library.canImport(import),
      _SampleTemplatesLibrary() => library.canImportInFile(import, filePath),
    };
  }

  /// Find the `examples/api/lib` and `examples/api/test` directories
  /// which contain the API examples and relevant tests.
  ///
  /// For the cross imports checker, only the `examples/api/lib` and `examples/api/test` directories are relevant.
  /// The other directories in `examples/api` are either generated (e.g. build or .dart_tool),
  /// platform directories for the samples (e.g. windows or linux),
  /// or a shim for the integration test driver.
  ({Directory libDirectory, Directory testDirectory}) _findExamplesSlashApiDirectories(
    Directory examplesSlashApiDirectory,
  ) {
    Directory? examplesSlashApiLibDirectory;
    Directory? examplesSlashApiTestDirectory;

    for (final Directory directory in examplesSlashApiDirectory.listSync().whereType<Directory>()) {
      final String directoryName = path.basename(directory.absolute.path);

      if (directoryName == 'lib' && examplesSlashApiLibDirectory == null) {
        examplesSlashApiLibDirectory = directory;
      } else if (directoryName == 'test' && examplesSlashApiTestDirectory == null) {
        examplesSlashApiTestDirectory = directory;
      }
    }

    if (examplesSlashApiLibDirectory == null) {
      throw StateError('Could not find lib directory in examples/api.');
    }

    if (examplesSlashApiTestDirectory == null) {
      throw StateError('Could not find test directory in examples/api.');
    }

    return (
      libDirectory: examplesSlashApiLibDirectory,
      testDirectory: examplesSlashApiTestDirectory,
    );
  }

  /// Get a list of all the filenames that end in ".dart", grouped by library.
  Map<_ExamplesLibrary, Set<File>> _getExampleFiles() {
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
          final examplesSlashApiLibrary = _ExamplesLibrary.fromDirectory(
            fileSystemEntity,
            flutterRoot: flutterRoot,
          );

          // First list the files directly under examples/api.
          mapping[examplesSlashApiLibrary] = {
            for (final File file in fileSystemEntity.listSync().whereType<File>())
              if (file.absolute.path.contains(dartFilePattern)) file,
          };

          final (:Directory libDirectory, :Directory testDirectory) =
              _findExamplesSlashApiDirectories(fileSystemEntity);

          // Handle the files under examples/api/lib/sample_templates and examples/api/test/sample_templates,
          // which list individual files with a specific file pattern.
          mapping.addAll(
            _getExamplesSlashApiSampleTemplatesFiles(
              libDirectory: libDirectory,
              testDirectory: testDirectory,
              dartFilePattern: dartFilePattern,
            ),
          );

          continue;
        }

        final library = _ExamplesLibrary.fromDirectory(fileSystemEntity, flutterRoot: flutterRoot);

        mapping[library] = _getExampleFilesForDirectory(
          fileSystemEntity,
          dartFilePattern: dartFilePattern,
        );
      }
    }

    return mapping;
  }

  /// Get a list of all the filenames that end in ".dart" for the given examples directory.
  ///
  /// The [directory] must not be a subdirectory of `examples/api`.
  Set<File> _getExampleFilesForDirectory(Directory directory, {required Pattern dartFilePattern}) {
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

  /// Get a list of all the filenames that end in ".dart", grouped by library,
  /// for the subdrectories of `examples/api/lib/sample_templates` and `examples/api/test/sample_templates`.
  Map<_SampleTemplatesLibrary, Set<File>> _getExamplesSlashApiSampleTemplatesFiles({
    required Directory libDirectory,
    required Directory testDirectory,
    required Pattern dartFilePattern,
  }) {
    final Directory sampleTemplatesLibDirectory = libDirectory.childDirectory('sample_templates');
    final Directory sampleTemplatesTestDirectory = testDirectory.childDirectory('sample_templates');

    final Set<File> sampleTemplateLibFiles = {};
    final Set<File> sampleTemplateTestFiles = {};

    for (final File file
        in sampleTemplatesLibDirectory.listSync(recursive: true).whereType<File>()) {
      if (file.absolute.path.contains(dartFilePattern)) {
        sampleTemplateLibFiles.add(file);
      }
    }

    for (final File file
        in sampleTemplatesTestDirectory.listSync(recursive: true).whereType<File>()) {
      if (file.absolute.path.contains(dartFilePattern)) {
        sampleTemplateTestFiles.add(file);
      }
    }

    return {
      _SampleTemplatesLibrary.libLibrary: sampleTemplateLibFiles,
      _SampleTemplatesLibrary.testLibrary: sampleTemplateTestFiles,
    };
  }

  /// Returns true if there are no errors, false otherwise.
  bool check() {
    filesystem.currentDirectory = flutterRoot;

    final Map<_ExamplesLibrary, Set<File>> filesByLibrary = _getExampleFiles();

    // Find all cross imports.
    final Map<CrossImportCheckedLibrary, CrossImportingFiles> crossImportsPerLibrary =
        getCrossImports(filesByLibrary, canImport: _canImport);

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
      // dart format off
      'knownExamplesCrossImports' => ExamplesCrossImportChecker.knownExamplesCrossImports,
      'knownExamplesSlashApiCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiCrossImports,
      'knownExamplesSlashApiAnimationCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiAnimationCrossImports,
      'knownExamplesSlashApiCupertinoCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiCupertinoCrossImports,
      'knownExamplesSlashApiFoundationCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiFoundationCrossImports,
      'knownExamplesSlashApiGesturesCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiGesturesCrossImports,
      'knownExamplesSlashApiMaterialCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiMaterialCrossImports,
      'knownExamplesSlashApiPaintingCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiPaintingCrossImports,
      'knownExamplesSlashApiRenderingCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiRenderingCrossImports,
      'knownExamplesSlashApiSampleTemplatesCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiSampleTemplatesCrossImports,
      'knownExamplesSlashApiServicesCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiServicesCrossImports,
      'knownExamplesSlashApiUICrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiUICrossImports,
      'knownExamplesSlashApiWidgetsCrossImports' => ExamplesCrossImportChecker.knownExamplesSlashApiWidgetsCrossImports,
      'knownExamplesFlutterViewCrossImports' => ExamplesCrossImportChecker.knownExamplesFlutterViewCrossImports,
      'knownExamplesHelloWorldCrossImports' => ExamplesCrossImportChecker.knownExamplesHelloWorldCrossImports,
      'knownExamplesImageListCrossImports' => ExamplesCrossImportChecker.knownExamplesImageListCrossImports,
      'knownExamplesLayersCrossImports' => ExamplesCrossImportChecker.knownExamplesLayersCrossImports,
      'knownExamplesMultipleWindowsCrossImports' => ExamplesCrossImportChecker.knownExamplesMultipleWindowsCrossImports,
      'knownExamplesPlatformChannelCrossImports' => ExamplesCrossImportChecker.knownExamplesPlatformChannelCrossImports,
      'knownExamplesPlatformChannelSwiftCrossImports' => ExamplesCrossImportChecker.knownExamplesPlatformChannelSwiftCrossImports,
      'knownExamplesPlatformViewCrossImports' => ExamplesCrossImportChecker.knownExamplesPlatformViewCrossImports,
      'knownExamplesSplashCrossImports' => ExamplesCrossImportChecker.knownExamplesSplashCrossImports,
      'knownExamplesTextureCrossImports' => ExamplesCrossImportChecker.knownExamplesTextureCrossImports,
      // dart format on
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
      _GenericExampleLibrary() || _ApiExampleLibrary() => false,
      _CupertinoApiExampleLibrary() => import == LibraryCrossImportStatementType.cupertino,
      _MaterialApiExampleLibrary() => import == LibraryCrossImportStatementType.material,
      _SampleTemplatesLibrary() => throw UnsupportedError(
        'The sample templates should use canImportInFile()',
      ),
    };
  }

  @override
  String getDisallowedImportMessage(String importedLibraryName, int filesCount) {
    return filesCount < 2
        ? 'The following file in $libraryName has a disallowed import of $importedLibraryName. '
              'Refactor it or move it to the $importedLibraryName examples.\n'
        : 'The following $filesCount files in $libraryName have a disallowed import of $importedLibraryName. '
              'Refactor them or move them to the $importedLibraryName examples.\n';
  }

  /// The name of the variable in [ExamplesCrossImportChecker]
  /// that contains the list of known cross imports for this library.
  ///
  /// This is used for reporting mismatched cross imports.
  String get crossImportsListSymbolName {
    return switch (libraryName) {
      'examples' => 'knownExamplesCrossImports',
      'examples/api' => 'knownExamplesSlashApiCrossImports',
      // dart format off
      'examples/api/lib/animation' || 'examples/api/test/animation' => 'knownExamplesSlashApiAnimationCrossImports',
      'examples/api/lib/cupertino' || 'examples/api/test/cupertino' => 'knownExamplesSlashApiCupertinoCrossImports',
      'examples/api/lib/foundation' || 'examples/api/test/foundation' => 'knownExamplesSlashApiFoundationCrossImports',
      'examples/api/lib/gestures' || 'examples/api/test/gestures' => 'knownExamplesSlashApiGesturesCrossImports',
      'examples/api/lib/material' || 'examples/api/test/material' => 'knownExamplesSlashApiMaterialCrossImports',
      'examples/api/lib/painting' || 'examples/api/test/painting' => 'knownExamplesSlashApiPaintingCrossImports',
      'examples/api/lib/rendering' || 'examples/api/test/rendering' => 'knownExamplesSlashApiRenderingCrossImports',
      'examples/api/lib/sample_templates' || 'examples/api/test/sample_templates' => 'knownExamplesSlashApiSampleTemplatesCrossImports',
      'examples/api/lib/services' || 'examples/api/test/services' => 'knownExamplesSlashApiServicesCrossImports',
      'examples/api/lib/ui' || 'examples/api/test/ui' => 'knownExamplesSlashApiUICrossImports',
      'examples/api/lib/widgets' || 'examples/api/test/widgets' => 'knownExamplesSlashApiWidgetsCrossImports',
      // dart format on
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

/// Any API example - not related to Material or Cupertino - inside `examples/api`, and its tests.
final class _ApiExampleLibrary extends _ExamplesLibrary {
  const _ApiExampleLibrary(super.name);
}

/// The examples in `examples/api/lib/cupertino`
/// and their tests in `examples/api/test/cupertino`.
final class _CupertinoApiExampleLibrary extends _ExamplesLibrary {
  const _CupertinoApiExampleLibrary(super.name);
}

/// Any non-API example, not in `examples/api`,
/// such as `examples/flutter_view` or `examples/hello_world`.
final class _GenericExampleLibrary extends _ExamplesLibrary {
  const _GenericExampleLibrary(super.name);
}

/// The examples in `examples/api/lib/material`
/// and their tests in `examples/api/test/material`.
final class _MaterialApiExampleLibrary extends _ExamplesLibrary {
  const _MaterialApiExampleLibrary(super.name);
}

/// The examples in `examples/api/lib/sample_templates`
/// and their tests in `examples/api/test/sample_templates`.
final class _SampleTemplatesLibrary extends _ExamplesLibrary {
  const _SampleTemplatesLibrary._(super.name);

  static const _SampleTemplatesLibrary libLibrary = _SampleTemplatesLibrary._(
    'examples/api/lib/sample_templates',
  );
  static const _SampleTemplatesLibrary testLibrary = _SampleTemplatesLibrary._(
    'examples/api/test/sample_templates',
  );

  /// Check wether the given [filePath] points to a sample file that can import the given [import].
  ///
  /// The Material templates can import Material, and the Cupertino templates can import Cupertino,
  /// but otherwise sample templates should not import either.
  bool canImportInFile(LibraryCrossImportStatementType import, String filePath) {
    return switch (import) {
      LibraryCrossImportStatementType.material => filePath.contains('material'),
      LibraryCrossImportStatementType.cupertino => filePath.contains('cupertino'),
    };
  }
}
