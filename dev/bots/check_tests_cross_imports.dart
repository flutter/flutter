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

/// Checks the tests in the Widgets and Cupertino libraries for cross imports.
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
    'packages/flutter/test/widgets/basic_test.dart',
    'packages/flutter/test/widgets/text_test.dart',
    'packages/flutter/test/widgets/reorderable_list_test.dart',
    'packages/flutter/test/widgets/semantics_tester_generate_test_semantics_expression_for_current_semantics_tree_test.dart',
    'packages/flutter/test/widgets/slivers_appbar_floating_pinned_test.dart',
    'packages/flutter/test/widgets/scrollable_restoration_test.dart',
    'packages/flutter/test/widgets/text_golden_test.dart',
    'packages/flutter/test/widgets/two_dimensional_viewport_test.dart',
    'packages/flutter/test/widgets/list_view_viewporting_test.dart',
    'packages/flutter/test/widgets/table_test.dart',
    'packages/flutter/test/widgets/shortcuts_test.dart',
    'packages/flutter/test/widgets/ticker_provider_test.dart',
    'packages/flutter/test/widgets/semantics_clipping_test.dart',
    'packages/flutter/test/widgets/restoration_scopes_moving_test.dart',
    'packages/flutter/test/widgets/linked_scroll_view_test.dart',
    'packages/flutter/test/widgets/sliver_floating_header_test.dart',
    'packages/flutter/test/widgets/page_transitions_test.dart',
    'packages/flutter/test/widgets/editable_text_scribble_test.dart',
    'packages/flutter/test/widgets/draggable_scrollable_sheet_test.dart',
    'packages/flutter/test/widgets/autofill_group_test.dart',
    'packages/flutter/test/widgets/box_decoration_test.dart',
    'packages/flutter/test/widgets/range_maintaining_scroll_physics_test.dart',
    'packages/flutter/test/widgets/scroll_position_test.dart',
    'packages/flutter/test/widgets/sliver_tree_test.dart',
    'packages/flutter/test/widgets/interactive_viewer_test.dart',
    'packages/flutter/test/widgets/selectable_region_test.dart',
    'packages/flutter/test/widgets/editable_text_scribe_test.dart',
    'packages/flutter/test/widgets/scrollable_test.dart',
    'packages/flutter/test/widgets/semantics_debugger_test.dart',
    'packages/flutter/test/widgets/semantics_test.dart',
    'packages/flutter/test/widgets/page_route_builder_test.dart',
    'packages/flutter/test/widgets/two_dimensional_scroll_view_test.dart',
    'packages/flutter/test/widgets/routes_test.dart',
    'packages/flutter/test/widgets/listener_test.dart',
    'packages/flutter/test/widgets/text_selection_test.dart',
    'packages/flutter/test/widgets/app_test.dart',
    'packages/flutter/test/widgets/widget_inspector_test.dart',
    'packages/flutter/test/widgets/radio_group_test.dart',
    'packages/flutter/test/widgets/list_view_test.dart',
    'packages/flutter/test/widgets/sliver_resizing_header_test.dart',
    'packages/flutter/test/widgets/navigator_replacement_test.dart',
    'packages/flutter/test/widgets/implicit_animations_test.dart',
    'packages/flutter/test/widgets/default_text_editing_shortcuts_test.dart',
    'packages/flutter/test/widgets/page_storage_test.dart',
    'packages/flutter/test/widgets/sliver_main_axis_group_test.dart',
    'packages/flutter/test/widgets/color_filter_test.dart',
    'packages/flutter/test/widgets/semantics_merge_test.dart',
    'packages/flutter/test/widgets/modal_barrier_test.dart',
    'packages/flutter/test/widgets/sliver_semantics_test.dart',
    'packages/flutter/test/widgets/slivers_padding_test.dart',
    'packages/flutter/test/widgets/sliver_constraints_test.dart',
    'packages/flutter/test/widgets/autocomplete_test.dart',
    'packages/flutter/test/widgets/expansible_test.dart',
    'packages/flutter/test/widgets/decorated_sliver_test.dart',
    'packages/flutter/test/widgets/shape_decoration_test.dart',
    'packages/flutter/test/widgets/run_app_test.dart',
    'packages/flutter/test/widgets/shadow_test.dart',
    'packages/flutter/test/widgets/routes_transition_test.dart',
    'packages/flutter/test/widgets/placeholder_test.dart',
    'packages/flutter/test/widgets/route_notification_messages_test.dart',
    'packages/flutter/test/widgets/animated_cross_fade_test.dart',
    'packages/flutter/test/widgets/editable_text_shortcuts_test.dart',
    'packages/flutter/test/widgets/gesture_detector_test.dart',
    'packages/flutter/test/widgets/router_test.dart',
    'packages/flutter/test/widgets/scroll_notification_test.dart',
    'packages/flutter/test/widgets/magnifier_test.dart',
    'packages/flutter/test/widgets/backdrop_filter_test.dart',
    'packages/flutter/test/widgets/editable_text_test.dart',
    'packages/flutter/test/widgets/dual_transition_builder_test.dart',
    'packages/flutter/test/widgets/icon_test.dart',
    'packages/flutter/test/widgets/scrollable_helpers_test.dart',
    'packages/flutter/test/widgets/slivers_appbar_stretch_test.dart',
    'packages/flutter/test/widgets/sliver_cross_axis_group_test.dart',
    'packages/flutter/test/widgets/list_wheel_scroll_view_test.dart',
    'packages/flutter/test/widgets/scrollable_dispose_test.dart',
    'packages/flutter/test/widgets/pop_scope_test.dart',
    'packages/flutter/test/widgets/scrollbar_test.dart',
    'packages/flutter/test/widgets/actions_test.dart',
    'packages/flutter/test/widgets/scroll_physics_test.dart',
    'packages/flutter/test/widgets/obscured_animated_image_test.dart',
    'packages/flutter/test/widgets/platform_menu_bar_test.dart',
    'packages/flutter/test/widgets/inherited_test.dart',
    'packages/flutter/test/widgets/heroes_test.dart',
    'packages/flutter/test/widgets/slivers_evil_test.dart',
    'packages/flutter/test/widgets/container_test.dart',
    'packages/flutter/test/widgets/drawer_test.dart',
    'packages/flutter/test/widgets/framework_test.dart',
    'packages/flutter/test/widgets/ticker_mode_test.dart',
    'packages/flutter/test/widgets/absorb_pointer_test.dart',
    'packages/flutter/test/widgets/semantics_role_checks_test.dart',
    'packages/flutter/test/widgets/media_query_test.dart',
    'packages/flutter/test/widgets/editable_text_cursor_test.dart',
    'packages/flutter/test/widgets/sliver_fill_remaining_test.dart',
    'packages/flutter/test/widgets/semantics_keep_alive_offstage_test.dart',
    'packages/flutter/test/widgets/editable_text_show_on_screen_test.dart',
    'packages/flutter/test/widgets/system_context_menu_test.dart',
    'packages/flutter/test/widgets/scrollable_fling_test.dart',
    'packages/flutter/test/widgets/debug_test.dart',
    'packages/flutter/test/widgets/banner_test.dart',
    'packages/flutter/test/widgets/sliver_persistent_header_test.dart',
    'packages/flutter/test/widgets/transformed_scrollable_test.dart',
    'packages/flutter/test/widgets/run_app_async_test.dart',
    'packages/flutter/test/widgets/scrollable_in_overlay_test.dart',
    'packages/flutter/test/widgets/navigator_and_layers_test.dart',
    'packages/flutter/test/widgets/snapshot_widget_test.dart',
    'packages/flutter/test/widgets/inherited_model_test.dart',
    'packages/flutter/test/widgets/nested_scroll_view_test.dart',
    'packages/flutter/test/widgets/scrollable_selection_test.dart',
    'packages/flutter/test/widgets/physical_model_test.dart',
    'packages/flutter/test/widgets/spell_check_test.dart',
    'packages/flutter/test/widgets/slivers_appbar_floating_test.dart',
    'packages/flutter/test/widgets/toggleable_test.dart',
    'packages/flutter/test/widgets/mouse_region_test.dart',
    'packages/flutter/test/widgets/draggable_test.dart',
    'packages/flutter/test/widgets/page_transitions_builder_test.dart',
    'packages/flutter/test/widgets/selectable_region_context_menu_test.dart',
    'packages/flutter/test/widgets/sliversemantics_test.dart',
    'packages/flutter/test/widgets/scroll_activity_test.dart',
    'packages/flutter/test/widgets/tap_region_test.dart',
    'packages/flutter/test/widgets/lookup_boundary_test.dart',
    'packages/flutter/test/widgets/reassemble_test.dart',
    'packages/flutter/test/widgets/html_element_view_test.dart',
    'packages/flutter/test/widgets/navigator_test.dart',
    'packages/flutter/test/widgets/text_semantics_test.dart',
    'packages/flutter/test/widgets/safe_area_test.dart',
    'packages/flutter/test/widgets/page_view_test.dart',
    'packages/flutter/test/widgets/undo_history_test.dart',
    'packages/flutter/test/widgets/scroll_view_test.dart',
    'packages/flutter/test/widgets/focus_traversal_test.dart',
    'packages/flutter/test/widgets/sliver_list_test.dart',
    'packages/flutter/test/widgets/page_forward_transitions_test.dart',
    'packages/flutter/test/widgets/context_menu_controller_test.dart',
    'packages/flutter/test/widgets/slivers_test.dart',
    'packages/flutter/test/widgets/navigator_restoration_test.dart',
    'packages/flutter/test/widgets/sliver_prototype_item_extent_test.dart',
    'packages/flutter/test/widgets/simple_semantics_test.dart',
    'packages/flutter/test/widgets/image_filter_test.dart',
    'packages/flutter/test/widgets/navigator_on_did_remove_page_test.dart',
    'packages/flutter/test/widgets/opacity_test.dart',
    'packages/flutter/test/widgets/baseline_test.dart',
    'packages/flutter/test/widgets/selection_container_test.dart',
    'packages/flutter/test/widgets/scrollable_semantics_test.dart',
    'packages/flutter/test/widgets/sliver_visibility_test.dart',
    'packages/flutter/test/widgets/rotated_box_test.dart',
    'packages/flutter/test/widgets/single_child_scroll_view_test.dart',
    'packages/flutter/test/widgets/pinned_header_sliver_test.dart',
    'packages/flutter/test/widgets/raw_radio_test.dart',
    'packages/flutter/test/widgets/syncing_test.dart',
    'packages/flutter/test/widgets/form_test.dart',
  };

  /// These Cupertino tests are known to have cross imports. These cross imports
  /// should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  ///
  /// See also:
  ///
  ///  * [knownWidgetsCrossImports], which is like this list, but for
  ///    Widgets tests importing Material or Cupertino.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/177028.
  static final Set<String> knownCupertinoCrossImports = <String>{
    'packages/flutter/test/cupertino/material/tab_scaffold_test.dart',
    'packages/flutter/test/cupertino/route_test.dart',
    'packages/flutter/test/cupertino/text_selection_test.dart',
    'packages/flutter/test/cupertino/app_test.dart',
    'packages/flutter/test/cupertino/picker_test.dart',
    'packages/flutter/test/cupertino/text_field_test.dart',
    'packages/flutter/test/cupertino/dialog_test.dart',
    'packages/flutter/test/cupertino/date_picker_test.dart',
    'packages/flutter/test/cupertino/switch_test.dart',
    'packages/flutter/test/cupertino/magnifier_test.dart',
    'packages/flutter/test/cupertino/text_field_restoration_test.dart',
    'packages/flutter/test/cupertino/sheet_test.dart',
    'packages/flutter/test/cupertino/form_row_test.dart',
    'packages/flutter/test/cupertino/colors_test.dart',
    'packages/flutter/test/cupertino/text_form_field_row_restoration_test.dart',
    'packages/flutter/test/cupertino/slider_test.dart',
  };

  static final Set<String> _knownCrossImports = knownWidgetsCrossImports.union(
    knownCupertinoCrossImports,
  );

  /// Returns the Set of paths in `knownPaths` that are not in `files`.
  static Set<String> _differencePaths(Set<String> knownPaths, Set<File> files) {
    final Set<String> testPaths = files.map((File file) {
      final prefix = RegExp(r'packages[/\\]flutter[/\\]test');
      final int index = file.absolute.path.indexOf(prefix);
      if (index < 0) {
        throw ArgumentError('All files must include $prefix in their path.', 'files');
      }
      return file.absolute.path.substring(index).replaceAll(r'\', '/');
    }).toSet();
    return knownPaths.difference(testPaths);
  }

  /// Returns a list of files in the given directory optionally matching the
  /// given filenamePattern.
  static List<File> _getFiles(Directory directory, [Pattern? filenamePattern]) {
    return directory.listSync(recursive: true).whereType<File>().where((File file) {
      if (filenamePattern == null) {
        return true;
      }
      return file.absolute.path.contains(filenamePattern);
    }).toList();
  }

  /// Returns the Set of Files that are not in knownPaths.
  static Set<File> _getUnknowns(Set<String> knownPaths, Set<File> files) {
    return files.where((File file) {
      final prefix = RegExp(r'packages[/\\]flutter[/\\]test');
      final int index = file.absolute.path.indexOf(prefix);
      if (index < 0) {
        throw ArgumentError('All files must include $prefix in their path.', 'files');
      }
      final String comparablePath = file.absolute.path.substring(index).replaceAll(r'\', '/');
      return !knownPaths.contains(comparablePath);
    }).toSet();
  }

  /// Get a list of all the filenames in the source directory that end in
  /// "_test.dart".
  static Set<File> _getTestFiles(Directory directory, _Library library) {
    return _getFiles(directory.childDirectory(library.directory), RegExp(r'_test\.dart$')).toSet();
  }

  /// Returns true only if the file imports the given Library.
  static bool _containsImport(File testFile, _Library library) {
    final String contents = testFile.readAsStringSync();
    return contents.contains(library.import);
  }

  /// Returns a Set of all Files that import the given Library.
  static Set<File> _getFilesWithImports(Set<File> testFiles, _Library library) {
    final filesWithCrossImports = <File>{};
    for (final testFile in testFiles) {
      if (_containsImport(testFile, library)) {
        filesWithCrossImports.add(testFile);
      }
    }
    return filesWithCrossImports;
  }

  /// Returns the error message for the given known paths that no longer have a
  /// cross import.
  ///
  /// `library` must not be `_Library.Material`, because Material is allowed to
  /// cross-import.
  static String _getFixedImportError(Set<String> fixedPaths, _Library library) {
    assert(fixedPaths.isNotEmpty);
    final buffer = StringBuffer(
      'Huzzah! The following tests in ${library.name} no longer contain cross imports!\n',
    );
    for (final path in fixedPaths) {
      buffer.writeln('  $path');
    }
    final String knownListName = switch (library) {
      _Library.widgets => 'knownWidgetsCrossImports',
      _Library.cupertino => 'knownCupertinoCrossImports',
      _Library.material => throw UnimplementedError(
        'Material is responsible for testing its interactions with Cupertino, so it is allowed to cross-import.',
      ),
    };
    buffer.writeln('However, they now need to be removed from the');
    buffer.write('$knownListName list in the script /dev/bots/check_tests_cross_imports.dart.');
    return buffer.toString().trimRight();
  }

  /// Returns the File's relative path.
  String _getRelativePath(File file, [Directory? root]) {
    root ??= flutterRoot;
    return path.relative(file.absolute.path, from: root.absolute.path);
  }

  /// Returns the import error for the `files` in `testLibrary` which import
  /// `importedLibrary`.
  ///
  /// Import errors only occur when Widgets imports Material or Cupertino, and
  /// when Cupertino imports Material.
  String _getImportError({
    required Set<File> files,
    required _Library testLibrary,
    required _Library importedLibrary,
  }) {
    assert(
      switch ((testLibrary, importedLibrary)) {
        (_Library.widgets, _Library.material) => true,
        (_Library.widgets, _Library.cupertino) => true,
        (_Library.cupertino, _Library.material) => true,
        (_, _) => false,
      },
      'Import errors only occur when Widgets imports Material or Cupertino, and when Cupertino imports Material.',
    );
    final buffer = StringBuffer(
      files.length < 2
          ? 'The following test in ${testLibrary.name} has a disallowed import of ${importedLibrary.name}. Refactor it or move it to ${importedLibrary.name}.\n'
          : 'The following ${files.length} tests in ${testLibrary.name} have a disallowed import of ${importedLibrary.name}. Refactor them or move them to ${importedLibrary.name}.\n',
    );
    for (final file in files) {
      buffer.writeln('  ${_getRelativePath(file)}');
    }
    return buffer.toString().trimRight();
  }

  /// Returns true if there are no errors, false otherwise.
  bool check() {
    filesystem.currentDirectory = flutterRoot;

    final filesByLibrary = <_Library, Set<File>>{};
    for (final _Library library in _Library.values) {
      filesByLibrary[library] = _getTestFiles(testsDirectory, library);
    }

    // Find all cross imports.
    final Set<File> widgetsTestsImportingMaterial = _getFilesWithImports(
      filesByLibrary[_Library.widgets]!,
      _Library.material,
    );
    final Set<File> widgetsTestsImportingCupertino = _getFilesWithImports(
      filesByLibrary[_Library.widgets]!,
      _Library.cupertino,
    );
    final Set<File> cupertinoTestsImportingMaterial = _getFilesWithImports(
      filesByLibrary[_Library.cupertino]!,
      _Library.material,
    );

    // Find any cross imports that are not in the known list.
    var valid = true;
    final Set<File> unknownWidgetsTestsImportingMaterial = _getUnknowns(
      _knownCrossImports,
      widgetsTestsImportingMaterial,
    );
    if (unknownWidgetsTestsImportingMaterial.isNotEmpty) {
      valid = false;
      foundError(
        _getImportError(
          files: unknownWidgetsTestsImportingMaterial,
          testLibrary: _Library.widgets,
          importedLibrary: _Library.material,
        ).split('\n'),
      );
    }
    final Set<File> unknownWidgetsTestsImportingCupertino = _getUnknowns(
      _knownCrossImports,
      widgetsTestsImportingCupertino,
    );
    if (unknownWidgetsTestsImportingCupertino.isNotEmpty) {
      valid = false;
      foundError(
        _getImportError(
          files: unknownWidgetsTestsImportingCupertino,
          testLibrary: _Library.widgets,
          importedLibrary: _Library.cupertino,
        ).split('\n'),
      );
    }
    final Set<File> unknownCupertinoTestsImportingMaterial = _getUnknowns(
      _knownCrossImports,
      cupertinoTestsImportingMaterial,
    );
    if (unknownCupertinoTestsImportingMaterial.isNotEmpty) {
      valid = false;
      foundError(
        _getImportError(
          files: unknownCupertinoTestsImportingMaterial,
          testLibrary: _Library.cupertino,
          importedLibrary: _Library.material,
        ).split('\n'),
      );
    }

    // Find any known cross imports that weren't found, and are therefore fixed.
    // TODO(justinmc): Remove this after all known cross imports have been
    // fixed.
    // See https://github.com/flutter/flutter/issues/177028.
    final Set<String> fixedWidgetsCrossImports = _differencePaths(
      knownWidgetsCrossImports,
      widgetsTestsImportingMaterial.union(widgetsTestsImportingCupertino),
    );
    if (fixedWidgetsCrossImports.isNotEmpty) {
      valid = false;
      foundError(_getFixedImportError(fixedWidgetsCrossImports, _Library.widgets).split('\n'));
    }
    final Set<String> fixedCupertinoCrossImports = _differencePaths(
      knownCupertinoCrossImports,
      cupertinoTestsImportingMaterial,
    );
    if (fixedCupertinoCrossImports.isNotEmpty) {
      valid = false;
      foundError(_getFixedImportError(fixedCupertinoCrossImports, _Library.cupertino).split('\n'));
    }

    return valid;
  }
}

/// The libraries that we are concerned with cross importing.
enum _Library {
  widgets(directory: 'widgets', name: 'Widgets', import: "import 'package:flutter/widgets.dart'"),
  material(
    directory: 'material',
    name: 'Material',
    import: "import 'package:flutter/material.dart'",
  ),
  cupertino(
    directory: 'cupertino',
    name: 'Cupertino',
    import: "import 'package:flutter/cupertino.dart'",
  );

  const _Library({required this.directory, required this.name, required this.import});

  final String directory;
  final String name;
  final String import;
}
