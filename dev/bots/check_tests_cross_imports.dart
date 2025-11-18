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
  final ArgParser argParser = ArgParser();
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

  final TestsCrossImportChecker checker = TestsCrossImportChecker(
    testsDirectory: tests,
    flutterRoot: flutterRoot,
  );

  if (!checker.checkCodeSamples()) {
    reportErrorsAndExit('Some errors were found in the API docs code samples.');
  }
  reportSuccessAndExit('All examples are linked and have tests.');
}

class TestsCrossImportChecker {
  TestsCrossImportChecker({
    required this.testsDirectory,
    required this.flutterRoot,
    this.filesystem = const LocalFileSystem(),
  });

  final Directory testsDirectory;
  final Directory flutterRoot;
  final FileSystem filesystem;

  bool checkCodeSamples() {
    filesystem.currentDirectory = flutterRoot;

    final Map<Library, Set<File>> filesByLibrary = <Library, Set<File>>{};
    for (final Library library in Library.values) {
      filesByLibrary[library] = getTestFiles(testsDirectory, library);
    }

    final Set<File> widgetsTestsImportingMaterial = getFilesWithImports(
      filesByLibrary[Library.widgets]!,
      Library.material,
    );
    final Set<File> widgetsTestsImportingCupertino = getFilesWithImports(
      filesByLibrary[Library.widgets]!,
      Library.cupertino,
    );
    final Set<File> cupertinoTestsImportingMaterial = getFilesWithImports(
      filesByLibrary[Library.cupertino]!,
      Library.material,
    );

    // TODO(justinmc): If all good, return true.

    if (widgetsTestsImportingMaterial.isNotEmpty) {
      foundError(
        getImportError(
          widgetsTestsImportingMaterial,
          Library.widgets.name,
          Library.material.name,
        ).split('\n'),
      );
    }
    if (widgetsTestsImportingCupertino.isNotEmpty) {
      foundError(
        getImportError(
          widgetsTestsImportingCupertino,
          Library.widgets.name,
          Library.cupertino.name,
        ).split('\n'),
      );
    }
    if (cupertinoTestsImportingMaterial.isNotEmpty) {
      foundError(
        getImportError(
          cupertinoTestsImportingMaterial,
          Library.cupertino.name,
          Library.material.name,
        ).split('\n'),
      );
    }

    final Set<String> fixedWidgetsCrossImports = differencePaths(
      _knownWidgetsCrossImports,
      widgetsTestsImportingMaterial.union(widgetsTestsImportingCupertino),
    );
    if (fixedWidgetsCrossImports.isNotEmpty) {
      foundError(getFixedImportError(fixedWidgetsCrossImports, Library.widgets).split('\n'));
    }

    final Set<String> fixedCupertinoCrossImports = differencePaths(
      _knownCupertinoCrossImports,
      cupertinoTestsImportingMaterial,
    );
    if (fixedCupertinoCrossImports.isNotEmpty) {
      foundError(getFixedImportError(fixedCupertinoCrossImports, Library.cupertino).split('\n'));
    }

    return false;

    /*
    // Also add in any that might be found in the dart:ui directory.
    exampleLinks.addAll(getExampleLinks(dartUIPath));

    // Get a list of the filenames that were not found in the source files.
    final List<String> missingFilenames = checkForMissingLinks(testFilenames, exampleLinks);

    // Get a list of any tests that are missing, as well as any that used to be
    // missing, but have been implemented.
    final (List<File> missingTests, List<File> noLongerMissing) = checkForMissingTests(
      testFilenames,
    );

    // Remove any that we know are exceptions (examples that aren't expected to be
    // linked into any source files). These are typically template files used to
    // generate new examples.
    missingFilenames.removeWhere((String file) => _knownUnlinkedExamples.contains(file));

    if (missingFilenames.isEmpty && missingTests.isEmpty && noLongerMissing.isEmpty) {
      return true;
    }

    if (noLongerMissing.isNotEmpty) {
      final StringBuffer buffer = StringBuffer(
        'The following tests have been implemented! Huzzah!:\n',
      );
      for (final File name in noLongerMissing) {
        buffer.writeln('  ${getRelativePath(name)}');
      }
      buffer.writeln('However, they now need to be removed from the _knownMissingTests');
      buffer.write('list in the script $_scriptLocation.');
      foundError(buffer.toString().split('\n'));
    }

    if (missingTests.isNotEmpty) {
      final StringBuffer buffer = StringBuffer('The following example test files are missing:\n');
      for (final File name in missingTests) {
        buffer.writeln('  ${getRelativePath(name)}');
      }
      foundError(buffer.toString().trimRight().split('\n'));
    }

    if (missingFilenames.isNotEmpty) {
      final StringBuffer buffer = StringBuffer(
        'The following examples are not linked from any source file API doc comments:\n',
      );
      for (final String name in missingFilenames) {
        buffer.writeln('  $name');
      }
      buffer.write('Either link them to a source file API doc comment, or remove them.');
      foundError(buffer.toString().split('\n'));
    }
    return false;
    */
  }

  String getRelativePath(File file, [Directory? root]) {
    root ??= flutterRoot;
    return path.relative(file.absolute.path, from: root.absolute.path);
  }

  static Set<String> differencePaths(Set<String> knownPaths, Set<File> files) {
    final Set<String> testPaths = files.map((File file) {
      final int index = file.absolute.path.indexOf('packages/flutter/test');
      final int indexNormalized = index == -1 ? 0 : index;
      return file.absolute.path.substring(indexNormalized);
    }).toSet();
    return knownPaths.difference(testPaths);
  }

  /// Returns a list of files in the given directory optionally matching the
  /// given filenamePattern.
  static List<File> getFiles(Directory directory, [Pattern? filenamePattern]) {
    final List<File> files = directory
        .listSync(recursive: true)
        .map((FileSystemEntity entity) {
          if (entity is File) {
            return entity;
          } else {
            return null;
          }
        })
        .where((File? file) {
          if (file == null) {
            return false;
          }
          if (filenamePattern == null) {
            return true;
          }
          return file.absolute.path.contains(filenamePattern);
          /*
          if (!file.absolute.path.contains(filenamePattern)) {
            return false;
          }

          final int index = file.absolute.path.indexOf('packages/flutter/test');
          if (index == -1) {
            return true;
          }

          final String comparablePath = file.absolute.path.substring(index);
          return !_knownTestsWithCrossImports.contains(comparablePath);
          */
        })
        .map<File>((File? s) => s!)
        .toList();
    return files;
  }

  // Get a list of all the filenames in the source directory that end in "_test.dart".
  static Set<File> getTestFiles(Directory directory, Library library) {
    return getFiles(directory.childDirectory(library.directory), RegExp(r'_test\.dart$')).toSet();
  }

  /// Returns true only if the file imports the given Library.
  static bool containsImport(File testFile, Library library) {
    final String contents = testFile.readAsStringSync();
    return contents.contains(library.regExp);
  }

  static Set<File> getFilesWithImports(Set<File> testFiles, Library library) {
    final Set<File> filesWithCrossImports = <File>{};
    for (final File testFile in testFiles) {
      if (containsImport(testFile, library)) {
        filesWithCrossImports.add(testFile);
      }
    }
    return filesWithCrossImports;
  }

  String getImportError(Set<File> files, String testLibraryName, String importedLibraryName) {
    final StringBuffer buffer = StringBuffer(
      files.length < 2
          ? 'The following test in $testLibraryName has a disallowed import of $importedLibraryName. Refactor it or move it to $importedLibraryName.\n'
          : 'The following ${files.length} tests in $testLibraryName have a disallowed import of $importedLibraryName. Refactor them or move them to $importedLibraryName.\n',
    );
    for (final File file in files) {
      buffer.writeln('  ${getRelativePath(file)}');
    }
    return buffer.toString().trimRight();
  }

  /// Returns the error message for the given known paths that no longer have a
  /// cross import.
  ///
  /// `library` must not be `Library.Material`, because Material is allowed to
  /// cross-import.
  static String getFixedImportError(Set<String> fixedPaths, Library library) {
    assert(fixedPaths.isNotEmpty);
    final StringBuffer buffer = StringBuffer(
      'Huzzah! The following tests in ${library.name} no longer contain cross imports!\n',
    );
    for (final String path in fixedPaths) {
      buffer.writeln('  $path');
    }
    final String knownListName = switch (library) {
      Library.widgets => '_knownWidgetsCrossImports',
      Library.cupertino => '_knownCupertinoCrossImports',
      Library.material => throw UnimplementedError(
        'Material is responsible for testing its interactions with Cupertino, so it is allowed to cross-import.',
      ),
    };
    buffer.writeln('However, they now need to be removed from the');
    buffer.write('$knownListName list in the script $_scriptLocation.');
    return buffer.toString().trimRight();
  }

  List<String> checkForMissingLinks(List<File> exampleFilenames, Set<String> searchStrings) {
    final List<String> missingFilenames = <String>[];
    for (final File example in exampleFilenames) {
      final String relativePath = getRelativePath(example);
      if (!searchStrings.contains(relativePath)) {
        missingFilenames.add(relativePath);
      }
    }
    return missingFilenames;
  }

  String getTestNameForExample(File example, Directory examples) {
    final String testPath = path.dirname(
      path.join(
        examples.absolute.path,
        'test',
        getRelativePath(example, examples.childDirectory('lib')),
      ),
    );
    return '${path.join(testPath, path.basenameWithoutExtension(example.path))}_test.dart';
  }

  /*
  (List<File>, List<File>) checkForMissingTests(List<File> exampleFilenames) {
    final List<File> missingTests = <File>[];
    final List<File> noLongerMissingTests = <File>[];
    for (final File example in exampleFilenames) {
      final File testFile = filesystem.file(getTestNameForExample(example, tests));
      final String name = path.relative(testFile.absolute.path, from: flutterRoot.absolute.path);
      if (!testFile.existsSync()) {
        missingTests.add(testFile);
      } else if (_knownMissingTests.contains(name.replaceAll(r'\', '/'))) {
        noLongerMissingTests.add(testFile);
      }
    }
    // Skip any that we know are missing.
    missingTests.removeWhere((File test) {
      final String name = path
          .relative(test.absolute.path, from: flutterRoot.absolute.path)
          .replaceAll(r'\', '/');
      return _knownMissingTests.contains(name);
    });
    return (missingTests, noLongerMissingTests);
  }
  */
}

// These tests are known to have cross imports. These cross imports should all
// eventually be resolved, but until they are we allow them, so that we can
// catch any new cross imports that are added.
//
// TODO(justinmc): Fix all of these tests so there are no cross imports.
// See https://github.com/flutter/flutter/issues/177028.
final Set<String> _knownWidgetsCrossImports = <String>{
  'packages/flutter/test/widgets/basic_test.dart',
  'packages/flutter/test/widgets/text_test.dart',
  'packages/flutter/test/widgets/reorderable_list_test.dart',
  'packages/flutter/test/widgets/semantics_tester_generate_test_semantics_expression_for_current_semantics_tree_test.dart',
  'packages/flutter/test/widgets/async_lifecycle_test.dart',
  'packages/flutter/test/widgets/slivers_appbar_floating_pinned_test.dart',
  'packages/flutter/test/widgets/scrollable_restoration_test.dart',
  'packages/flutter/test/widgets/text_golden_test.dart',
  'packages/flutter/test/widgets/multi_view_parent_data_test.dart',
  'packages/flutter/test/widgets/view_test.dart',
  'packages/flutter/test/widgets/two_dimensional_viewport_test.dart',
  'packages/flutter/test/widgets/list_view_viewporting_test.dart',
  'packages/flutter/test/widgets/table_test.dart',
  'packages/flutter/test/widgets/shortcuts_test.dart',
  'packages/flutter/test/widgets/ticker_provider_test.dart',
  'packages/flutter/test/widgets/slotted_render_object_widget_test.dart',
  'packages/flutter/test/widgets/semantics_2_test.dart',
  'packages/flutter/test/widgets/semantics_clipping_test.dart',
  'packages/flutter/test/widgets/reparent_state_test.dart',
  'packages/flutter/test/widgets/transitions_test.dart',
  'packages/flutter/test/widgets/restoration_scopes_moving_test.dart',
  'packages/flutter/test/widgets/linked_scroll_view_test.dart',
  'packages/flutter/test/widgets/sliver_floating_header_test.dart',
  'packages/flutter/test/widgets/page_transitions_test.dart',
  'packages/flutter/test/widgets/parent_data_test.dart',
  'packages/flutter/test/widgets/editable_text_scribble_test.dart',
  'packages/flutter/test/widgets/draggable_scrollable_sheet_test.dart',
  'packages/flutter/test/widgets/autofill_group_test.dart',
  'packages/flutter/test/widgets/box_decoration_test.dart',
  'packages/flutter/test/widgets/range_maintaining_scroll_physics_test.dart',
  'packages/flutter/test/widgets/scroll_position_test.dart',
  'packages/flutter/test/widgets/sliver_tree_test.dart',
  'packages/flutter/test/widgets/binding_live_test.dart',
  'packages/flutter/test/widgets/interactive_viewer_test.dart',
  'packages/flutter/test/widgets/list_view_fling_test.dart',
  'packages/flutter/test/widgets/selectable_region_test.dart',
  'packages/flutter/test/widgets/selectable_text_test.dart',
  'packages/flutter/test/widgets/editable_text_scribe_test.dart',
  'packages/flutter/test/widgets/semantics_7_test.dart',
  'packages/flutter/test/widgets/scrollable_test.dart',
  'packages/flutter/test/widgets/semantics_debugger_test.dart',
  'packages/flutter/test/widgets/semantics_test.dart',
  'packages/flutter/test/widgets/page_route_builder_test.dart',
  'packages/flutter/test/widgets/opacity_repaint_test.dart',
  'packages/flutter/test/widgets/two_dimensional_scroll_view_test.dart',
  'packages/flutter/test/widgets/routes_test.dart',
  'packages/flutter/test/widgets/listener_test.dart',
  'packages/flutter/test/widgets/text_selection_test.dart',
  'packages/flutter/test/widgets/list_view_relayout_test.dart',
  'packages/flutter/test/widgets/semantics_4_test.dart',
  'packages/flutter/test/widgets/multi_view_binding_test.dart',
  'packages/flutter/test/widgets/app_test.dart',
  'packages/flutter/test/widgets/widget_inspector_test.dart',
  'packages/flutter/test/widgets/radio_group_test.dart',
  'packages/flutter/test/widgets/list_view_test.dart',
  'packages/flutter/test/widgets/binding_deferred_first_frame_test.dart',
  'packages/flutter/test/widgets/sliver_resizing_header_test.dart',
  'packages/flutter/test/widgets/navigator_replacement_test.dart',
  'packages/flutter/test/widgets/scroll_delegate_test.dart',
  'packages/flutter/test/widgets/implicit_animations_test.dart',
  'packages/flutter/test/widgets/list_view_correction_test.dart',
  'packages/flutter/test/widgets/default_text_editing_shortcuts_test.dart',
  'packages/flutter/test/widgets/page_storage_test.dart',
  'packages/flutter/test/widgets/sliver_main_axis_group_test.dart',
  'packages/flutter/test/widgets/semantics_zero_surface_size_test.dart',
  'packages/flutter/test/widgets/color_filter_test.dart',
  'packages/flutter/test/widgets/semantics_merge_test.dart',
  'packages/flutter/test/widgets/semantics_9_test.dart',
  'packages/flutter/test/widgets/modal_barrier_test.dart',
  'packages/flutter/test/widgets/sliver_semantics_test.dart',
  'packages/flutter/test/widgets/slivers_padding_test.dart',
  'packages/flutter/test/widgets/sliver_constraints_test.dart',
  'packages/flutter/test/widgets/autocomplete_test.dart',
  'packages/flutter/test/widgets/icon_data_test.dart',
  'packages/flutter/test/widgets/expansible_test.dart',
  'packages/flutter/test/widgets/decorated_sliver_test.dart',
  'packages/flutter/test/widgets/shape_decoration_test.dart',
  'packages/flutter/test/widgets/semantics_refactor_regression_test.dart',
  'packages/flutter/test/widgets/run_app_test.dart',
  'packages/flutter/test/widgets/animated_opacity_repaint_test.dart',
  'packages/flutter/test/widgets/semantics_6_test.dart',
  'packages/flutter/test/widgets/shadow_test.dart',
  'packages/flutter/test/widgets/routes_transition_test.dart',
  'packages/flutter/test/widgets/placeholder_test.dart',
  'packages/flutter/test/widgets/animated_image_filtered_repaint_test.dart',
  'packages/flutter/test/widgets/route_notification_messages_test.dart',
  'packages/flutter/test/widgets/animated_cross_fade_test.dart',
  'packages/flutter/test/widgets/editable_text_shortcuts_test.dart',
  'packages/flutter/test/widgets/gesture_detector_test.dart',
  'packages/flutter/test/widgets/tree_shape_test.dart',
  'packages/flutter/test/widgets/rich_text_test.dart',
  'packages/flutter/test/widgets/router_test.dart',
  'packages/flutter/test/widgets/scroll_notification_test.dart',
  'packages/flutter/test/widgets/sensitive_content_error_handling_test.dart',
  'packages/flutter/test/widgets/magnifier_test.dart',
  'packages/flutter/test/widgets/backdrop_filter_test.dart',
  'packages/flutter/test/widgets/editable_text_test.dart',
  'packages/flutter/test/widgets/dual_transition_builder_test.dart',
  'packages/flutter/test/widgets/icon_test.dart',
  'packages/flutter/test/widgets/scrollable_helpers_test.dart',
  'packages/flutter/test/widgets/slivers_appbar_stretch_test.dart',
  'packages/flutter/test/widgets/sliver_cross_axis_group_test.dart',
  'packages/flutter/test/widgets/drag_boundary_test.dart',
  'packages/flutter/test/widgets/semantics_traversal_test.dart',
  'packages/flutter/test/widgets/sensitive_content_unknown_test.dart',
  'packages/flutter/test/widgets/overlay_test.dart',
  'packages/flutter/test/widgets/semantics_8_test.dart',
  'packages/flutter/test/widgets/list_wheel_scroll_view_test.dart',
  'packages/flutter/test/widgets/scrollable_dispose_test.dart',
  'packages/flutter/test/widgets/pop_scope_test.dart',
  'packages/flutter/test/widgets/scrollbar_test.dart',
  'packages/flutter/test/widgets/actions_test.dart',
  'packages/flutter/test/widgets/scroll_physics_test.dart',
  'packages/flutter/test/widgets/obscured_animated_image_test.dart',
  'packages/flutter/test/widgets/platform_menu_bar_test.dart',
  'packages/flutter/test/widgets/inherited_test.dart',
  'packages/flutter/test/widgets/sliver_fill_viewport_test.dart',
  'packages/flutter/test/widgets/wrap_test.dart',
  'packages/flutter/test/widgets/heroes_test.dart',
  'packages/flutter/test/widgets/overlay_portal_test.dart',
  'packages/flutter/test/widgets/slivers_evil_test.dart',
  'packages/flutter/test/widgets/semantics_11_test.dart',
  'packages/flutter/test/widgets/container_test.dart',
  'packages/flutter/test/widgets/drawer_test.dart',
  'packages/flutter/test/widgets/framework_test.dart',
  'packages/flutter/test/widgets/ticker_mode_test.dart',
  'packages/flutter/test/widgets/absorb_pointer_test.dart',
  'packages/flutter/test/widgets/semantics_role_checks_test.dart',
  'packages/flutter/test/widgets/binding_first_frame_rasterized_test.dart',
  'packages/flutter/test/widgets/media_query_test.dart',
  'packages/flutter/test/widgets/editable_text_cursor_test.dart',
  'packages/flutter/test/widgets/sliver_fill_remaining_test.dart',
  'packages/flutter/test/widgets/router_restoration_test.dart',
  'packages/flutter/test/widgets/semantics_keep_alive_offstage_test.dart',
  'packages/flutter/test/widgets/editable_text_show_on_screen_test.dart',
  'packages/flutter/test/widgets/system_context_menu_test.dart',
  'packages/flutter/test/widgets/error_widget_test.dart',
  'packages/flutter/test/widgets/semantics_checks_test.dart',
  'packages/flutter/test/widgets/scrollable_fling_test.dart',
  'packages/flutter/test/widgets/debug_test.dart',
  'packages/flutter/test/widgets/banner_test.dart',
  'packages/flutter/test/widgets/sensitive_content_test.dart',
  'packages/flutter/test/widgets/semantics_10_test.dart',
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
  'packages/flutter/test/widgets/semantics_1_test.dart',
  'packages/flutter/test/widgets/sensitive_content_host_test.dart',
  'packages/flutter/test/widgets/mouse_region_test.dart',
  'packages/flutter/test/widgets/draggable_test.dart',
  'packages/flutter/test/widgets/page_transitions_builder_test.dart',
  'packages/flutter/test/widgets/selectable_region_context_menu_test.dart',
  'packages/flutter/test/widgets/default_colors_test.dart',
  'packages/flutter/test/widgets/multi_view_tree_updates_test.dart',
  'packages/flutter/test/widgets/sliversemantics_test.dart',
  'packages/flutter/test/widgets/scroll_activity_test.dart',
  'packages/flutter/test/widgets/tap_region_test.dart',
  'packages/flutter/test/widgets/lookup_boundary_test.dart',
  'packages/flutter/test/widgets/reassemble_test.dart',
  'packages/flutter/test/widgets/semantics_5_test.dart',
  'packages/flutter/test/widgets/clip_test.dart',
  'packages/flutter/test/widgets/independent_widget_layout_test.dart',
  'packages/flutter/test/widgets/binding_first_frame_developer_test.dart',
  'packages/flutter/test/widgets/html_element_view_test.dart',
  'packages/flutter/test/widgets/navigator_test.dart',
  'packages/flutter/test/widgets/multi_view_no_implicit_view_binding_test.dart',
  'packages/flutter/test/widgets/text_semantics_test.dart',
  'packages/flutter/test/widgets/safe_area_test.dart',
  'packages/flutter/test/widgets/page_view_test.dart',
  'packages/flutter/test/widgets/undo_history_test.dart',
  'packages/flutter/test/widgets/scroll_view_test.dart',
  'packages/flutter/test/widgets/focus_traversal_test.dart',
  'packages/flutter/test/widgets/sliver_list_test.dart',
  'packages/flutter/test/widgets/reparent_state_with_layout_builder_test.dart',
  'packages/flutter/test/widgets/page_forward_transitions_test.dart',
  'packages/flutter/test/widgets/context_menu_controller_test.dart',
  'packages/flutter/test/widgets/semantics_3_test.dart',
  'packages/flutter/test/widgets/slivers_test.dart',
  'packages/flutter/test/widgets/navigator_restoration_test.dart',
  'packages/flutter/test/widgets/sliver_prototype_item_extent_test.dart',
  'packages/flutter/test/widgets/simple_semantics_test.dart',
  'packages/flutter/test/widgets/sliver_appbar_opacity_test.dart',
  'packages/flutter/test/widgets/image_filter_test.dart',
  'packages/flutter/test/widgets/navigator_on_did_remove_page_test.dart',
  'packages/flutter/test/widgets/opacity_test.dart',
  'packages/flutter/test/widgets/baseline_test.dart',
  'packages/flutter/test/widgets/selection_container_test.dart',
  'packages/flutter/test/widgets/scrollable_semantics_test.dart',
  'packages/flutter/test/widgets/sliver_visibility_test.dart',
  'packages/flutter/test/widgets/rotated_box_test.dart',
  'packages/flutter/test/widgets/sliver_constrained_cross_axis_test.dart',
  'packages/flutter/test/widgets/single_child_scroll_view_test.dart',
  'packages/flutter/test/widgets/pinned_header_sliver_test.dart',
  'packages/flutter/test/widgets/focus_manager_test.dart',
  'packages/flutter/test/widgets/raw_radio_test.dart',
  'packages/flutter/test/widgets/syncing_test.dart',
  'packages/flutter/test/widgets/form_test.dart',
  'packages/flutter/test/widgets/implicit_semantics_test.dart',
  'packages/flutter/test/widgets/shrink_wrapping_viewport_test.dart',
};
final Set<String> _knownCupertinoCrossImports = <String>{
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
  'packages/flutter/test/cupertino/action_sheet_test.dart',
  'packages/flutter/test/cupertino/form_row_test.dart',
  'packages/flutter/test/cupertino/colors_test.dart',
  'packages/flutter/test/cupertino/text_form_field_row_restoration_test.dart',
  'packages/flutter/test/cupertino/slider_test.dart',
};

enum Library {
  widgets(directory: 'widgets', name: 'Widgets'),
  material(directory: 'material', name: 'Material'),
  cupertino(directory: 'cupertino', name: 'Cupertino');

  const Library({required this.directory, required this.name});

  final String directory;
  final String name;

  static final RegExp cupertinoImportRegExp = RegExp(r"import 'package:flutter\/cupertino.dart'");
  static final RegExp materialImportRegExp = RegExp(r"import 'package:flutter\/material.dart'");
  static final RegExp widgetsImportRegExp = RegExp(r"import 'package:flutter\/widgets.dart'");

  /// The RegExp that finds an import of this library.
  RegExp get regExp {
    return switch (this) {
      Library.widgets => widgetsImportRegExp,
      Library.material => materialImportRegExp,
      Library.cupertino => cupertinoImportRegExp,
    };
  }
}
