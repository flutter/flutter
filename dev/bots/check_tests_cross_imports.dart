// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// To run this, from the root of the Flutter repository:
//   bin/cache/dart-sdk/bin/dart --enable-asserts dev/bots/check_tests_cross_imports.dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

import 'cross_imports_checker_utils.dart';
import 'utils.dart';

final String _scriptLocation = path.fromUri(Platform.script);
final String _flutterRoot = path.dirname(path.dirname(path.dirname(_scriptLocation)));
final String _testDirectoryPath = path.join(_flutterRoot, 'packages', 'flutter', 'test');

void main(List<String> args) {
  final argParser = ArgParser();
  argParser.addFlag('help', negatable: false, help: 'Print help for this command.');
  argParser.addOption(
    'test',
    valueHelp: 'path',
    defaultsTo: _testDirectoryPath,
    help: 'A location where the tests are found.',
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
  final Directory flutterSlashTestDirectory = filesystem.directory(parsedArgs['test']! as String);
  final Directory flutterRoot = filesystem.directory(parsedArgs['flutter-root']! as String);
  final Directory flutterTestLibraryDirectory = flutterRoot
      .childDirectory('packages')
      .childDirectory('flutter_test');

  final checker = TestsCrossImportChecker(
    flutterSlashTestDirectory: flutterSlashTestDirectory,
    flutterTestLibraryDirectory: flutterTestLibraryDirectory,
    flutterRoot: flutterRoot,
  );

  if (!checker.check()) {
    reportErrorsAndExit('Some errors were found in the framework test imports.');
  }
  reportSuccessAndExit('No errors were detected with test cross imports.');
}

/// Checks the tests in the `flutter/test/**` libraries for cross imports.
///
/// Excludes known tests that contain cross imports, i.e.
/// [TestsCrossImportChecker.knownWidgetsCrossImports] and
/// [TestsCrossImportChecker.knownCupertinoCrossImports].
///
/// In short, the Material library should contain tests that verify behaviors
/// involving multiple libraries, such as platform adaptivity. Otherwise, these
/// libraries should not import each other in tests.
///
/// The guiding principles behind this organization of our tests are as follows:
///
///  - Cupertino should test its widgets under a full-Cupertino scenario. The
///  Cupertino library and tests should never import Material.
///  - The Material library should test its widgets in a full-Material scenario.
///  - Design languages are responsible for testing their own interoperability
///  with the Widgets library.
///  - Tests that cover interoperability between Material and Cupertino should
///  go in Material.
///  - The Widgets library and tests should never import Cupertino or Material.
///  - Libraries that do not have anything to do with Cupertino or Material should never import them.
class TestsCrossImportChecker {
  TestsCrossImportChecker({
    required this.flutterSlashTestDirectory,
    required this.flutterTestLibraryDirectory,
    required this.flutterRoot,
    this.filesystem = const LocalFileSystem(),
  });

  final Directory flutterSlashTestDirectory;
  final Directory flutterTestLibraryDirectory;
  final Directory flutterRoot;
  final FileSystem filesystem;

  /// These Widgets tests are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  ///
  /// See also:
  ///
  ///  * [knownCupertinoCrossImports], which is like this list, but for
  ///    Cupertino tests importing Material.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/177028.
  static final Set<String> knownWidgetsCrossImports = <String>{
    'packages/flutter/test/widgets/page_transitions_test.dart',
    'packages/flutter/test/widgets/routes_test.dart',
    'packages/flutter/test/widgets/app_test.dart',
    'packages/flutter/test/widgets/routes_transition_test.dart',
    'packages/flutter/test/widgets/editable_text_test.dart',
    'packages/flutter/test/widgets/scrollbar_test.dart',
    'packages/flutter/test/widgets/inherited_test.dart',
    'packages/flutter/test/widgets/heroes_test.dart',
    'packages/flutter/test/widgets/drawer_test.dart',
    'packages/flutter/test/widgets/nested_scroll_view_test.dart',
    'packages/flutter/test/widgets/scrollable_selection_test.dart',
    'packages/flutter/test/widgets/page_transitions_builder_test.dart',
    'packages/flutter/test/widgets/navigator_test.dart',
    'packages/flutter/test/widgets/navigator_restoration_test.dart',
    'packages/flutter/test/widgets/form_test.dart',
    'packages/flutter/test/widgets/text_selection_toolbar_utils.dart',
    'packages/flutter/test/widgets/live_text_utils.dart',
  };

  /// These tests are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  ///
  /// Each set corresponds to a subdirectory under `flutter/test`,
  /// for example `knownWidgetsCrossImports` corresponds to `flutter/test/widgets`
  /// and `knownSchedulerCrossImports` corresponds to `flutter/test/scheduler`.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/177028.
  static final Set<String> knownAnimationCrossImports = <String>{};
  static final Set<String> knownCupertinoCrossImports = <String>{};
  static final Set<String> knownDartCrossImports = <String>{};
  static final Set<String> knownExamplesCrossImports = <String>{};
  static final Set<String> knownFoundationCrossImports = <String>{};
  static final Set<String> knownGesturesCrossImports = <String>{};
  static final Set<String> knownHarnessCrossImports = <String>{};
  static final Set<String> knownPaintingCrossImports = <String>{
    'packages/flutter/test/painting/system_fonts_test.dart',
    'packages/flutter/test/painting/colors_test.dart',
  };
  static final Set<String> knownPhysicsCrossImports = <String>{};
  static final Set<String> knownRenderingCrossImports = <String>{
    'packages/flutter/test/rendering/aligning_shifted_box_baseline_test.dart',
    'packages/flutter/test/rendering/localized_fonts_test.dart',
  };
  static final Set<String> knownSchedulerCrossImports = <String>{};
  static final Set<String> knownSemanticsCrossImports = <String>{};
  static final Set<String> knownServicesCrossImports = <String>{};

  /// These tests are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  ///
  /// This set corresponds to violations in `packages/flutter/test` itself,
  /// for the lists for the subdirectories of `packages/flutter/test`,
  /// see [knownWidgetsCrossImports] and related lists.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/177028.
  static final Set<String> knownFlutterSlashTestCrossImports = <String>{};

  /// These tests are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  ///
  /// The files in this set belong to `packages/flutter_test`, or one of its subdirectories.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/177028.
  static final Set<String> knownFlutterTestLibraryCrossImports = <String>{
    'packages/flutter_test/lib/src/widget_tester.dart',
    'packages/flutter_test/lib/src/finders.dart',
    'packages/flutter_test/lib/src/matchers.dart',
    'packages/flutter_test/test_fixes/flutter_test/animation_sheet_builder.dart',
    'packages/flutter_test/test_fixes/flutter_test/matchers.dart',
    'packages/flutter_test/test/navigator_test.dart',
    'packages/flutter_test/test/mock_canvas_test.dart',
    'packages/flutter_test/test/semantics_finder_test.dart',
    'packages/flutter_test/test/accessibility_window_test.dart',
    'packages/flutter_test/test/widget_tester_live_device_test.dart',
    'packages/flutter_test/test/all_elements_test.dart',
    'packages/flutter_test/test/utils/memory_leak_tests.dart',
    'packages/flutter_test/test/widget_tester_test.dart',
    'packages/flutter_test/test/live_widget_controller_test.dart',
    'packages/flutter_test/test/accessibility_test.dart',
    'packages/flutter_test/test/finders_test.dart',
    'packages/flutter_test/test/controller_test.dart',
    'packages/flutter_test/test/recording_canvas_test.dart',
  };

  static final Set<String> _knownCrossImports = {
    ...knownFlutterTestLibraryCrossImports,
    ...knownFlutterSlashTestCrossImports,
    ...knownWidgetsCrossImports,
    ...knownAnimationCrossImports,
    ...knownCupertinoCrossImports,
    ...knownDartCrossImports,
    ...knownExamplesCrossImports,
    ...knownFoundationCrossImports,
    ...knownGesturesCrossImports,
    ...knownHarnessCrossImports,
    ...knownPaintingCrossImports,
    ...knownPhysicsCrossImports,
    ...knownRenderingCrossImports,
    ...knownSchedulerCrossImports,
    ...knownSemanticsCrossImports,
    ...knownServicesCrossImports,
  };

  // This matches both `packages/flutter/test` and `packages/flutter_test`.
  static final RegExp _flutterTestPrefix = RegExp(r'packages[/\\]flutter[/\\_]test');

  /// Get a list of all the filenames that end in ".dart", grouped by library.
  Map<_Library, Set<File>> _getTestFiles() {
    final dartFilePattern = RegExp(r'\.dart$');
    const _Library flutterSlashTest = _OtherLibrary('packages/flutter/test');
    const _Library flutterTestLibrary = _OtherLibrary('packages/flutter_test');
    final Map<_Library, Set<File>> mapping = {flutterSlashTest: {}, flutterTestLibrary: {}};

    // List the files directly under `packages/flutter/test` and then walk the subdirectories.
    for (final FileSystemEntity fileOrDirectory in flutterSlashTestDirectory.listSync()) {
      if (fileOrDirectory is File && fileOrDirectory.absolute.path.contains(dartFilePattern)) {
        mapping[flutterSlashTest]?.add(fileOrDirectory);

        continue;
      }

      if (fileOrDirectory is Directory) {
        final library = _Library.fromDirectory(fileOrDirectory, flutterRoot: flutterRoot);
        mapping[library] = {
          for (final File file in fileOrDirectory.listSync(recursive: true).whereType<File>())
            if (file.absolute.path.contains(dartFilePattern)) file,
        };
      }
    }

    // List the files directly under `packages/flutter_test` and then walk the subdirectories.
    // Since packages/flutter_test is a library in itself,
    // exclude generated directories like `packages/flutter_test/build` and `packages/flutter_test/.dart_tool`.
    for (final FileSystemEntity fileSystemEntity in flutterTestLibraryDirectory.listSync()) {
      if (fileSystemEntity is File && fileSystemEntity.absolute.path.contains(dartFilePattern)) {
        mapping[flutterTestLibrary]?.add(fileSystemEntity);

        continue;
      }

      if (fileSystemEntity is Directory) {
        final String directoryName = path.basename(fileSystemEntity.absolute.path);

        if (directoryName == 'build' || directoryName == '.dart_tool') {
          continue;
        }

        for (final File file in fileSystemEntity.listSync(recursive: true).whereType<File>()) {
          if (file.absolute.path.contains(dartFilePattern)) {
            mapping[flutterTestLibrary]?.add(file);
          }
        }
      }
    }

    return mapping;
  }

  /// Returns true if there are no errors, false otherwise.
  bool check() {
    filesystem.currentDirectory = flutterRoot;

    final Map<_Library, Set<File>> filesByLibrary = _getTestFiles();

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
        prefix: _flutterTestPrefix,
      );
      final Set<File> unknownMaterialImports = getUnknowns(
        _knownCrossImports,
        entry.value.materialImports,
        prefix: _flutterTestPrefix,
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
    // See https://github.com/flutter/flutter/issues/177028.
    for (final MapEntry<CrossImportCheckedLibrary, CrossImportingFiles> entry
        in crossImportsPerLibrary.entries) {
      final Set<File> crossImportsForLibrary = entry.value.cupertinoImports.union(
        entry.value.materialImports,
      );
      final Set<String> knownCrossImportsForLibrary = entry.key.knownCrossImports;
      final Set<String> fixedCrossImports = differencePaths(
        knownCrossImportsForLibrary,
        crossImportsForLibrary,
        prefix: _flutterTestPrefix,
      );

      if (fixedCrossImports.isNotEmpty) {
        valid = false;
        foundError(getFixedImportError(fixedCrossImports, entry.key).split('\n'));
      }
    }

    return valid;
  }
}

/// The libraries that we are concerned with cross importing.
sealed class _Library implements CrossImportCheckedLibrary {
  const _Library(this._name);

  /// Construct a [_Library] from a given [directory].
  ///
  /// The [directory] must be inside the [flutterRoot].
  factory _Library.fromDirectory(Directory directory, {required Directory flutterRoot}) {
    if (!directory.absolute.path.startsWith(flutterRoot.absolute.path)) {
      throw ArgumentError('Directory must be inside ${flutterRoot.absolute.path}.', 'directory');
    }

    final String relativePath = path
        .relative(directory.absolute.path, from: flutterRoot.absolute.path)
        .replaceAll(Platform.pathSeparator, '/');

    return switch (relativePath) {
      'packages/flutter/test/material' => const _MaterialLibrary(),
      'packages/flutter/test/cupertino' => const _CupertinoLibrary(),
      _ => _OtherLibrary(relativePath),
    };
  }

  /// The short name of the library, for example `packages/flutter/test/widgets`.
  final String _name;

  @override
  String get cannotImportMessage {
    return 'any library that is not Material or Cupertino, imports Material or Cupertino, '
        'and when Cupertino imports Material.';
  }

  @override
  Set<String> get knownCrossImports {
    // Material is allowed to cross import.
    if (this is _MaterialLibrary) {
      return const <String>{};
    }

    return switch (crossImportsListSymbolName) {
      'knownFlutterTestLibraryCrossImports' =>
        TestsCrossImportChecker.knownFlutterTestLibraryCrossImports,
      'knownFlutterSlashTestCrossImports' =>
        TestsCrossImportChecker.knownFlutterSlashTestCrossImports,
      'knownAnimationCrossImports' => TestsCrossImportChecker.knownAnimationCrossImports,
      'knownCupertinoCrossImports' => TestsCrossImportChecker.knownCupertinoCrossImports,
      'knownDartCrossImports' => TestsCrossImportChecker.knownDartCrossImports,
      'knownExamplesCrossImports' => TestsCrossImportChecker.knownExamplesCrossImports,
      'knownFoundationCrossImports' => TestsCrossImportChecker.knownFoundationCrossImports,
      'knownGesturesCrossImports' => TestsCrossImportChecker.knownGesturesCrossImports,
      'knownHarnessCrossImports' => TestsCrossImportChecker.knownHarnessCrossImports,
      'knownPaintingCrossImports' => TestsCrossImportChecker.knownPaintingCrossImports,
      'knownPhysicsCrossImports' => TestsCrossImportChecker.knownPhysicsCrossImports,
      'knownRenderingCrossImports' => TestsCrossImportChecker.knownRenderingCrossImports,
      'knownSchedulerCrossImports' => TestsCrossImportChecker.knownSchedulerCrossImports,
      'knownSemanticsCrossImports' => TestsCrossImportChecker.knownSemanticsCrossImports,
      'knownServicesCrossImports' => TestsCrossImportChecker.knownServicesCrossImports,
      'knownWidgetsCrossImports' => TestsCrossImportChecker.knownWidgetsCrossImports,
      _ => throw UnimplementedError('Unknown library: $libraryName'),
    };
  }

  @override
  String get libraryName => _name;

  @override
  String get removeCrossImportsInstructionMessage {
    return 'However, they now need to be removed from the\n'
        '$crossImportsListSymbolName list in the script /dev/bots/check_tests_cross_imports.dart.';
  }

  @override
  bool canImport(LibraryCrossImportStatementType import) {
    return switch (this) {
      _MaterialLibrary() => import == .material || import == .cupertino,
      _CupertinoLibrary() => import == .cupertino,
      _OtherLibrary() => false,
    };
  }

  @override
  String getDisallowedImportMessage(String importedLibraryName, int filesCount) {
    return filesCount < 2
        ? 'The following test in $libraryName has a disallowed import of $importedLibraryName. '
              'Refactor it or move it to $importedLibraryName.\n'
        : 'The following $filesCount tests in $libraryName have a disallowed import of $importedLibraryName. '
              'Refactor them or move them to $importedLibraryName.\n';
  }

  /// The name of the variable in [TestsCrossImportChecker]
  /// that contains the list of known cross imports for this library.
  ///
  /// This is used for reporting mismatched cross imports.
  String get crossImportsListSymbolName {
    return switch (libraryName) {
      'packages/flutter_test' => 'knownFlutterTestLibraryCrossImports',
      'packages/flutter/test' => 'knownFlutterSlashTestCrossImports',
      'packages/flutter/test/animation' => 'knownAnimationCrossImports',
      'packages/flutter/test/cupertino' => 'knownCupertinoCrossImports',
      'packages/flutter/test/dart' => 'knownDartCrossImports',
      'packages/flutter/test/examples' => 'knownExamplesCrossImports',
      'packages/flutter/test/foundation' => 'knownFoundationCrossImports',
      'packages/flutter/test/gestures' => 'knownGesturesCrossImports',
      'packages/flutter/test/harness' => 'knownHarnessCrossImports',
      'packages/flutter/test/material' => throw UnsupportedError(
        'Material is responsible for testing its interactions with Cupertino, so it is allowed to cross-import.',
      ),
      'packages/flutter/test/painting' => 'knownPaintingCrossImports',
      'packages/flutter/test/physics' => 'knownPhysicsCrossImports',
      'packages/flutter/test/rendering' => 'knownRenderingCrossImports',
      'packages/flutter/test/scheduler' => 'knownSchedulerCrossImports',
      'packages/flutter/test/semantics' => 'knownSemanticsCrossImports',
      'packages/flutter/test/services' => 'knownServicesCrossImports',
      'packages/flutter/test/widgets' => 'knownWidgetsCrossImports',
      _ => throw UnimplementedError('Unknown library: $libraryName'),
    };
  }
}

/// The Material library, also known as `packages/flutter/test/material`.
final class _MaterialLibrary extends _Library {
  const _MaterialLibrary() : super('packages/flutter/test/material');
}

/// The Cupertino library, also known as `packages/flutter/test/cupertino`.
final class _CupertinoLibrary extends _Library {
  const _CupertinoLibrary() : super('packages/flutter/test/cupertino');
}

/// Any library that is not [_MaterialLibrary] or [_CupertinoLibrary],
/// such as `packages/flutter/test/widgets` or `packages/flutter/test/services`.
final class _OtherLibrary extends _Library {
  const _OtherLibrary(super.name);
}
