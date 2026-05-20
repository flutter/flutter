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
  final Directory tests = filesystem.directory(parsedArgs['test']! as String);
  final Directory flutterRoot = filesystem.directory(parsedArgs['flutter-root']! as String);

  final checker = TestsCrossImportChecker(testsDirectory: tests, flutterRoot: flutterRoot);

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
    required this.testsDirectory,
    required this.flutterRoot,
    this.filesystem = const LocalFileSystem(),
  });

  final Directory testsDirectory;
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
    'packages/flutter/test/widgets/navigator_replacement_test.dart',
    'packages/flutter/test/widgets/implicit_animations_test.dart',
    'packages/flutter/test/widgets/routes_transition_test.dart',
    'packages/flutter/test/widgets/editable_text_test.dart',
    'packages/flutter/test/widgets/scrollbar_test.dart',
    'packages/flutter/test/widgets/inherited_test.dart',
    'packages/flutter/test/widgets/heroes_test.dart',
    'packages/flutter/test/widgets/drawer_test.dart',
    'packages/flutter/test/widgets/editable_text_cursor_test.dart',
    'packages/flutter/test/widgets/nested_scroll_view_test.dart',
    'packages/flutter/test/widgets/scrollable_selection_test.dart',
    'packages/flutter/test/widgets/page_transitions_builder_test.dart',
    'packages/flutter/test/widgets/selectable_region_context_menu_test.dart',
    'packages/flutter/test/widgets/navigator_test.dart',
    'packages/flutter/test/widgets/navigator_restoration_test.dart',
    'packages/flutter/test/widgets/scrollable_semantics_test.dart',
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
  static final Set<String> knownAnimationCrossImports = <String>{
    'packages/flutter/test/animation/animation_sheet_test.dart',
  };
  static final Set<String> knownCupertinoCrossImports = <String>{};
  static final Set<String> knownDartCrossImports = <String>{};
  static final Set<String> knownExamplesCrossImports = <String>{};
  static final Set<String> knownFoundationCrossImports = <String>{};
  static final Set<String> knownGesturesCrossImports = <String>{};
  static final Set<String> knownHarnessCrossImports = <String>{};
  static final Set<String> knownPaintingCrossImports = <String>{
    'packages/flutter/test/painting/system_fonts_test.dart',
    'packages/flutter/test/painting/decoration_image_lerp_test.dart',
    'packages/flutter/test/painting/continuous_rectangle_border_test.dart',
    'packages/flutter/test/painting/colors_test.dart',
  };
  static final Set<String> knownPhysicsCrossImports = <String>{};
  static final Set<String> knownRenderingCrossImports = <String>{
    'packages/flutter/test/rendering/aligning_shifted_box_baseline_test.dart',
    'packages/flutter/test/rendering/localized_fonts_test.dart',
    'packages/flutter/test/rendering/editable_gesture_test.dart',
    'packages/flutter/test/rendering/box_test.dart',
    'packages/flutter/test/rendering/pipeline_owner_tree_test.dart',
    'packages/flutter/test/rendering/proxy_getters_and_setters_test.dart',
    'packages/flutter/test/rendering/view_chrome_style_test.dart',
    'packages/flutter/test/rendering/proxy_box_test.dart',
    'packages/flutter/test/rendering/sliver_tree_test.dart',
    'packages/flutter/test/rendering/editable_test.dart',
    'packages/flutter/test/rendering/object_test.dart',
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

  static final Set<String> _knownCrossImports = {
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

  static final RegExp _flutterTestPrefix = RegExp(r'packages[/\\]flutter[/\\]test');

  /// Returns the [Set] of paths in [knownPaths] that are not in [files].
  static Set<String> _differencePaths(Set<String> knownPaths, Set<File> files) {
    final Set<String> testPaths = files.map((File file) {
      final int index = file.absolute.path.indexOf(_flutterTestPrefix);
      if (index < 0) {
        throw ArgumentError('All files must include $_flutterTestPrefix in their path.', 'files');
      }
      return file.absolute.path.substring(index).replaceAll(Platform.pathSeparator, '/');
    }).toSet();
    return knownPaths.difference(testPaths);
  }

  /// Get the [Map] of files, per [_Library], of the files that have cross imports on Material and Cupertino.
  static Map<_Library, _CrossImportingFiles> _getCrossImports(Map<_Library, Set<File>> libraries) {
    final Map<_Library, _CrossImportingFiles> crossImports = {};

    for (final MapEntry<_Library, Set<File>> entry in libraries.entries) {
      final Set<File> cupertinoImports = {};
      final Set<File> materialImports = {};

      for (final File file in entry.value) {
        final String contents = file.readAsStringSync();

        if (!entry.key.canImport(_LibraryImportStatement.cupertino) &&
            contents.contains(_LibraryImportStatement.cupertino.importString)) {
          cupertinoImports.add(file);
        }

        if (!entry.key.canImport(_LibraryImportStatement.material) &&
            contents.contains(_LibraryImportStatement.material.importString)) {
          materialImports.add(file);
        }
      }

      crossImports[entry.key] = (
        cupertinoImports: cupertinoImports,
        materialImports: materialImports,
      );
    }

    return crossImports;
  }

  /// Returns the [Set] of files that are not in [knownPaths].
  static Set<File> _getUnknowns(Set<String> knownPaths, Set<File> files) {
    return files.where((File file) {
      final int index = file.absolute.path.indexOf(_flutterTestPrefix);
      if (index < 0) {
        throw ArgumentError('All files must include $_flutterTestPrefix in their path.', 'files');
      }
      final String comparablePath = file.absolute.path
          .substring(index)
          .replaceAll(Platform.pathSeparator, '/');
      return !knownPaths.contains(comparablePath);
    }).toSet();
  }

  /// Returns the error message for the given [fixedPaths] that no longer have a
  /// cross import.
  ///
  /// The [library] must not be [_MaterialLibrary], because Material is allowed to
  /// cross-import.
  static String _getFixedImportError(Set<String> fixedPaths, _Library library) {
    assert(fixedPaths.isNotEmpty);
    final buffer = StringBuffer(
      'Huzzah! The following tests in ${library.name} no longer contain cross imports!\n',
    );
    for (final path in fixedPaths) {
      buffer.writeln('  $path');
    }
    buffer.writeln('However, they now need to be removed from the');
    buffer.write(
      '${library.crossImportsListSymbolName} list in the script /dev/bots/check_tests_cross_imports.dart.',
    );
    return buffer.toString().trimRight();
  }

  /// Returns the [file]'s relative path, relative to [flutterRoot].
  String _getRelativePath(File file) {
    return path.relative(file.absolute.path, from: flutterRoot.absolute.path);
  }

  /// Get a list of all the filenames that end in ".dart", grouped by library.
  Map<_Library, Set<File>> _getTestFiles() {
    final dartFilePattern = RegExp(r'\.dart$');
    const _Library flutterTest = _OtherLibrary('packages/flutter/test');
    final Map<_Library, Set<File>> mapping = {flutterTest: {}};

    // List the files directly under `packages/flutter/test` and then walk the subdirectories.
    for (final FileSystemEntity fileOrDirectory in testsDirectory.listSync()) {
      if (fileOrDirectory is File && fileOrDirectory.absolute.path.contains(dartFilePattern)) {
        mapping[flutterTest]?.add(fileOrDirectory);

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

    return mapping;
  }

  /// Returns the import error for the [files] in [testLibrary] which contain the given [importStatement].
  ///
  /// Import errors only occur when:
  /// - any library that is not Material or Cupertino, imports Material or Cupertino
  /// - Cupertino imports Material
  String _getImportError({
    required Set<File> files,
    required _Library testLibrary,
    required _LibraryImportStatement importStatement,
  }) {
    assert(
      !testLibrary.canImport(importStatement),
      'any library that is not Material or Cupertino, imports Material or Cupertino, '
      'and when Cupertino imports Material.',
    );

    final String importedLibraryName = importStatement.readableName;
    final buffer = StringBuffer(
      files.length < 2
          ? 'The following test in ${testLibrary.name} has a disallowed import of $importedLibraryName. Refactor it or move it to $importedLibraryName.\n'
          : 'The following ${files.length} tests in ${testLibrary.name} have a disallowed import of $importedLibraryName. Refactor them or move them to $importedLibraryName.\n',
    );
    for (final file in files) {
      buffer.writeln('  ${_getRelativePath(file).replaceAll(Platform.pathSeparator, '/')}');
    }
    return buffer.toString().trimRight();
  }

  /// Returns true if there are no errors, false otherwise.
  bool check() {
    filesystem.currentDirectory = flutterRoot;

    final Map<_Library, Set<File>> filesByLibrary = _getTestFiles();

    // Find all cross imports.
    final Map<_Library, _CrossImportingFiles> crossImportsPerLibrary = _getCrossImports(
      filesByLibrary,
    );

    var valid = true;

    // Find any cross imports that are not in the known list.
    for (final MapEntry<_Library, _CrossImportingFiles> entry in crossImportsPerLibrary.entries) {
      final Set<File> unknownCupertinoImports = _getUnknowns(
        _knownCrossImports,
        entry.value.cupertinoImports,
      );
      final Set<File> unknownMaterialImports = _getUnknowns(
        _knownCrossImports,
        entry.value.materialImports,
      );

      if (unknownMaterialImports.isNotEmpty) {
        valid = false;
        foundError(
          _getImportError(
            files: unknownMaterialImports,
            testLibrary: entry.key,
            importStatement: _LibraryImportStatement.material,
          ).split('\n'),
        );
      }

      if (unknownCupertinoImports.isNotEmpty) {
        valid = false;
        foundError(
          _getImportError(
            files: unknownCupertinoImports,
            testLibrary: entry.key,
            importStatement: _LibraryImportStatement.cupertino,
          ).split('\n'),
        );
      }
    }

    // Find any known cross imports that weren't found, and are therefore fixed.
    // TODO(justinmc): Remove this after all known cross imports have been
    // fixed.
    // See https://github.com/flutter/flutter/issues/177028.
    for (final MapEntry<_Library, _CrossImportingFiles> entry in crossImportsPerLibrary.entries) {
      final Set<File> crossImportsForLibrary = entry.value.cupertinoImports.union(
        entry.value.materialImports,
      );
      final Set<String> knownCrossImportsForLibrary = entry.key.knownCrossImports;
      final Set<String> fixedCrossImports = _differencePaths(
        knownCrossImportsForLibrary,
        crossImportsForLibrary,
      );

      if (fixedCrossImports.isNotEmpty) {
        valid = false;
        foundError(_getFixedImportError(fixedCrossImports, entry.key).split('\n'));
      }
    }

    return valid;
  }
}

/// The set of files that import Cupertino and Material for a given [_Library].
typedef _CrossImportingFiles = ({Set<File> cupertinoImports, Set<File> materialImports});

enum _LibraryImportStatement {
  material('Material', "import 'package:flutter/material.dart'"),
  cupertino('Cupertino', "import 'package:flutter/cupertino.dart'");

  const _LibraryImportStatement(this.readableName, this.importString);

  final String readableName;
  final String importString;
}

/// The libraries that we are concerned with cross importing.
sealed class _Library {
  const _Library(this.name);

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
  final String name;

  /// The name of the variable in [TestsCrossImportChecker]
  /// that contains the list of known cross imports for this library.
  ///
  /// This is used for reporting mismatched cross imports.
  String get crossImportsListSymbolName {
    return switch (name) {
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
      _ => throw UnimplementedError('Unknown library: $name'),
    };
  }

  /// Get the list of known cross imports for this [_Library].
  Set<String> get knownCrossImports {
    // Material is allowed to cross import.
    if (this is _MaterialLibrary) {
      return const <String>{};
    }

    return switch (crossImportsListSymbolName) {
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
      _ => throw UnimplementedError('Unknown library: $name'),
    };
  }

  /// Returns whether this library can contain the given [import].
  bool canImport(_LibraryImportStatement import) {
    return switch (this) {
      _MaterialLibrary() =>
        import == _LibraryImportStatement.material || import == _LibraryImportStatement.cupertino,
      _CupertinoLibrary() => import == _LibraryImportStatement.cupertino,
      _OtherLibrary() => false,
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
