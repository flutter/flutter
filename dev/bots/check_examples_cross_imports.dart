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

  static const String _kSampleTemplatesDirectoryName = 'sample_templates';

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
  static final Set<String> knownExamplesSlashApiAnimationCrossImports = <String>{
    'examples/api/lib/animation/animation_controller/animated_digit.0.dart',
    'examples/api/lib/animation/curves/curve2_d.0.dart',
    'examples/api/test/animation/animation_controller/animated_digit.0_test.dart',
    'examples/api/test/animation/curves/curve2_d.0_test.dart',
  };

  /// The known cross imports in the `examples/api/lib/cupertino`
  /// and `examples/api/test/cupertino` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiCupertinoCrossImports = <String>{
    'examples/api/lib/cupertino/list_tile/cupertino_list_tile.0.dart',
    'examples/api/test/cupertino/list_tile/cupertino_list_tile.0_test.dart',
    'examples/api/test/cupertino/context_menu/cupertino_context_menu.1_test.dart',
    'examples/api/test/cupertino/context_menu/cupertino_context_menu.0_test.dart',
  };

  /// The known cross imports in the `examples/api/lib/foundation`
  /// and `examples/api/test/foundation` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiFoundationCrossImports = <String>{
    'examples/api/lib/foundation/key/value_key.0.dart',
    'examples/api/test/foundation/key/value_key.0_test.dart',
  };

  /// The known cross imports in the `examples/api/lib/gestures`
  /// and `examples/api/test/gestures` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiGesturesCrossImports = <String>{
    'examples/api/lib/gestures/pointer_signal_resolver/pointer_signal_resolver.0.dart',
    'examples/api/lib/gestures/tap_and_drag/tap_and_drag.0.dart',
    'examples/api/test/gestures/pointer_signal_resolver/pointer_signal_resolver.0_test.dart',
    'examples/api/test/gestures/tap_and_drag/tap_and_drag.0_test.dart',
  };

  /// The known cross imports in the `examples/api/lib/material`
  /// and `examples/api/test/material` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiMaterialCrossImports = <String>{
    'examples/api/lib/material/page_transitions_theme/page_transitions_theme.0.dart',
    'examples/api/lib/material/dialog/adaptive_alert_dialog.0.dart',
    'examples/api/lib/material/switch/switch.3.dart',
    'examples/api/lib/material/context_menu/editable_text_toolbar_builder.0.dart',
    'examples/api/test/material/page_transitions_theme/page_transitions_theme.0_test.dart',
    'examples/api/test/material/context_menu/editable_text_toolbar_builder.2_test.dart',
    'examples/api/test/material/context_menu/editable_text_toolbar_builder.0_test.dart',
  };

  /// The known cross imports in the `examples/api/lib/painting`
  /// and `examples/api/test/painting` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiPaintingCrossImports = <String>{
    'examples/api/lib/painting/gradient/linear_gradient.0.dart',
    'examples/api/lib/painting/star_border/star_border.0.dart',
    'examples/api/lib/painting/axis_direction/axis_direction.0.dart',
    'examples/api/lib/painting/borders/border_side.stroke_align.0.dart',
    'examples/api/lib/painting/linear_border/linear_border.0.dart',
    'examples/api/lib/painting/image_provider/image_provider.0.dart',
    'examples/api/lib/painting/rounded_superellipse_border/rounded_superellipse_border.0.dart',
    'examples/api/test/painting/gradient/linear_gradient.0_test.dart',
    'examples/api/test/painting/star_border/star_border.0_test.dart',
    'examples/api/test/painting/axis_direction/axis_direction.0_test.dart',
    'examples/api/test/painting/borders/border_side.stroke_align.0_test.dart',
    'examples/api/test/painting/linear_border/linear_border.0_test.dart',
    'examples/api/test/painting/rounded_superellipse_border/rounded_superellipse_border.0_test.dart',
  };

  /// The known cross imports in the `examples/api/lib/rendering`
  /// and `examples/api/test/rendering` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiRenderingCrossImports = <String>{
    'examples/api/lib/rendering/sliver_grid/sliver_grid_delegate_with_fixed_cross_axis_count.0.dart',
    'examples/api/lib/rendering/sliver_grid/sliver_grid_delegate_with_fixed_cross_axis_count.1.dart',
    'examples/api/lib/rendering/growth_direction/growth_direction.0.dart',
    'examples/api/lib/rendering/box/parent_data.0.dart',
    'examples/api/lib/rendering/scroll_direction/scroll_direction.0.dart',
    'examples/api/test/rendering/sliver_grid/sliver_grid_delegate_with_fixed_cross_axis_count.1_test.dart',
    'examples/api/test/rendering/sliver_grid/sliver_grid_delegate_with_fixed_cross_axis_count.0_test.dart',
    'examples/api/test/rendering/growth_direction/growth_direction.0_test.dart',
    'examples/api/test/rendering/box/parent_data.0_test.dart',
    'examples/api/test/rendering/scroll_direction/scroll_direction.0_test.dart',
  };

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
  static final Set<String> knownExamplesSlashApiServicesCrossImports = <String>{
    'examples/api/lib/services/mouse_cursor/mouse_cursor.0.dart',
    'examples/api/lib/services/binding/handle_request_app_exit.0.dart',
    'examples/api/lib/services/text_input/text_input_control.0.dart',
    'examples/api/lib/services/keyboard_key/physical_keyboard_key.0.dart',
    'examples/api/lib/services/keyboard_key/logical_keyboard_key.0.dart',
    'examples/api/lib/services/system_chrome/system_chrome.set_system_u_i_overlay_style.0.dart',
    'examples/api/lib/services/system_chrome/system_chrome.set_system_u_i_overlay_style.1.dart',
    'examples/api/test/services/text_input/text_input_control.0_test.dart',
    'examples/api/test/services/system_chrome/system_chrome.set_system_u_i_overlay_style.0_test.dart',
    'examples/api/test/services/system_chrome/system_chrome.set_system_u_i_overlay_style.1_test.dart',
  };

  /// The known cross imports in the `examples/api/lib/ui`
  /// and `examples/api/test/ui` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiUICrossImports = <String>{
    'examples/api/test/ui/text/font_feature.font_feature_ordinal_forms.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_contextual_alternates.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_alternative_fractions.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_oldstyle_figures.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_stylistic_alternates.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_historical_forms.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_stylistic_set.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_slashed_zero.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_superscripts.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_case_sensitive_forms.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_proportional_figures.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_historical_ligatures.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_tabular_figures.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_notational_forms.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_stylistic_set.1_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_alternative.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_locale_aware.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_fractions.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_denominator.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_lining_figures.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_numerators.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_swash.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_scientific_inferiors.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_subscripts.0_test.dart',
    'examples/api/test/ui/text/font_feature.font_feature_character_variant.0_test.dart',
  };

  /// The known cross imports in the `examples/api/lib/widgets`
  /// and `examples/api/test/widgets` directories.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSlashApiWidgetsCrossImports = <String>{
    'examples/api/lib/widgets/animated_grid/sliver_animated_grid.0.dart',
    'examples/api/lib/widgets/animated_grid/animated_grid.0.dart',
    'examples/api/lib/widgets/navigator_pop_handler/navigator_pop_handler.1.dart',
    'examples/api/lib/widgets/navigator_pop_handler/navigator_pop_handler.0.dart',
    'examples/api/lib/widgets/editable_text/editable_text.on_changed.0.dart',
    'examples/api/lib/widgets/editable_text/text_editing_controller.0.dart',
    'examples/api/lib/widgets/editable_text/text_editing_controller.1.dart',
    'examples/api/lib/widgets/editable_text/editable_text.on_content_inserted.0.dart',
    'examples/api/lib/widgets/page/page_can_pop.0.dart',
    'examples/api/lib/widgets/undo_history/undo_history_controller.0.dart',
    'examples/api/lib/widgets/raw_tooltip/raw_tooltip.0.dart',
    'examples/api/lib/widgets/form/form.1.dart',
    'examples/api/lib/widgets/form/form.0.dart',
    'examples/api/lib/widgets/layout_builder/layout_builder.0.dart',
    'examples/api/lib/widgets/tap_region/text_field_tap_region.0.dart',
    'examples/api/lib/widgets/restoration/restoration_mixin.0.dart',
    'examples/api/lib/widgets/app/widgets_app.widgets_app.0.dart',
    'examples/api/lib/widgets/drag_target/draggable.0.dart',
    'examples/api/lib/widgets/autocomplete/raw_autocomplete.focus_node.0.dart',
    'examples/api/lib/widgets/autocomplete/raw_autocomplete.2.dart',
    'examples/api/lib/widgets/autocomplete/raw_autocomplete.1.dart',
    'examples/api/lib/widgets/autocomplete/raw_autocomplete.0.dart',
    'examples/api/lib/widgets/keep_alive/automatic_keep_alive_client_mixin.0.dart',
    'examples/api/lib/widgets/keep_alive/automatic_keep_alive.0.dart',
    'examples/api/lib/widgets/keep_alive/keep_alive.0.dart',
    'examples/api/lib/widgets/safe_area/safe_area.0.dart',
    'examples/api/lib/widgets/scroll_notification_observer/scroll_notification_observer.0.dart',
    'examples/api/lib/widgets/animated_size/animated_size.0.dart',
    'examples/api/lib/widgets/framework/error_widget.0.dart',
    'examples/api/lib/widgets/framework/build_owner.0.dart',
    'examples/api/lib/widgets/sliver/pinned_header_sliver.1.dart',
    'examples/api/lib/widgets/sliver/sliver_list.0.dart',
    'examples/api/lib/widgets/sliver/pinned_header_sliver.0.dart',
    'examples/api/lib/widgets/sliver/sliver_constrained_cross_axis.0.dart',
    'examples/api/lib/widgets/sliver/sliver_tree.1.dart',
    'examples/api/lib/widgets/sliver/sliver_tree.0.dart',
    'examples/api/lib/widgets/sliver/sliver_floating_header.0.dart',
    'examples/api/lib/widgets/sliver/decorated_sliver.1.dart',
    'examples/api/lib/widgets/sliver/sliver_opacity.1.dart',
    'examples/api/lib/widgets/sliver/decorated_sliver.0.dart',
    'examples/api/lib/widgets/sliver/sliver_ensure_semantics.0.dart',
    'examples/api/lib/widgets/sliver/sliver_resizing_header.0.dart',
    'examples/api/lib/widgets/sliver/sliver_cross_axis_group.0.dart',
    'examples/api/lib/widgets/sliver/sliver_main_axis_group.0.dart',
    'examples/api/lib/widgets/heroes/hero.0.dart',
    'examples/api/lib/widgets/heroes/hero.1.dart',
    'examples/api/lib/widgets/dismissible/dismissible.0.dart',
    'examples/api/lib/widgets/overflow_bar/overflow_bar.0.dart',
    'examples/api/lib/widgets/preferred_size/preferred_size.0.dart',
    'examples/api/lib/widgets/media_query/media_query_data.system_gesture_insets.0.dart',
    'examples/api/lib/widgets/focus_traversal/ordered_traversal_policy.0.dart',
    'examples/api/lib/widgets/focus_traversal/focus_traversal_group.0.dart',
    'examples/api/lib/widgets/value_listenable_builder/value_listenable_builder.0.dart',
    'examples/api/lib/widgets/raw_menu_anchor/raw_menu_anchor.1.dart',
    'examples/api/lib/widgets/raw_menu_anchor/raw_menu_anchor.0.dart',
    'examples/api/lib/widgets/raw_menu_anchor/raw_menu_anchor.3.dart',
    'examples/api/lib/widgets/raw_menu_anchor/raw_menu_anchor.2.dart',
    'examples/api/lib/widgets/async/stream_builder.0.dart',
    'examples/api/lib/widgets/async/future_builder.0.dart',
    'examples/api/lib/widgets/shared_app_data/shared_app_data.1.dart',
    'examples/api/lib/widgets/shared_app_data/shared_app_data.0.dart',
    'examples/api/lib/widgets/animated_list/animated_list_separated.0.dart',
    'examples/api/lib/widgets/animated_list/sliver_animated_list.0.dart',
    'examples/api/lib/widgets/animated_list/animated_list.0.dart',
    'examples/api/lib/widgets/basic/fractionally_sized_box.0.dart',
    'examples/api/lib/widgets/basic/physical_shape.0.dart',
    'examples/api/lib/widgets/basic/aspect_ratio.2.dart',
    'examples/api/lib/widgets/basic/flow.0.dart',
    'examples/api/lib/widgets/basic/aspect_ratio.0.dart',
    'examples/api/lib/widgets/basic/clip_rrect.0.dart',
    'examples/api/lib/widgets/basic/ignore_pointer.0.dart',
    'examples/api/lib/widgets/basic/fitted_box.0.dart',
    'examples/api/lib/widgets/basic/custom_multi_child_layout.0.dart',
    'examples/api/lib/widgets/basic/listener.0.dart',
    'examples/api/lib/widgets/basic/clip_rrect.1.dart',
    'examples/api/lib/widgets/basic/offstage.0.dart',
    'examples/api/lib/widgets/basic/aspect_ratio.1.dart',
    'examples/api/lib/widgets/basic/overflowbox.0.dart',
    'examples/api/lib/widgets/basic/indexed_stack.0.dart',
    'examples/api/lib/widgets/basic/mouse_region.on_exit.1.dart',
    'examples/api/lib/widgets/basic/expanded.1.dart',
    'examples/api/lib/widgets/basic/mouse_region.0.dart',
    'examples/api/lib/widgets/basic/expanded.0.dart',
    'examples/api/lib/widgets/basic/mouse_region.on_exit.0.dart',
    'examples/api/lib/widgets/basic/absorb_pointer.0.dart',
    'examples/api/lib/widgets/single_child_scroll_view/single_child_scroll_view.1.dart',
    'examples/api/lib/widgets/single_child_scroll_view/single_child_scroll_view.0.dart',
    'examples/api/lib/widgets/scroll_end_notification/scroll_end_notification.1.dart',
    'examples/api/lib/widgets/scroll_end_notification/scroll_end_notification.0.dart',
    'examples/api/lib/widgets/autofill/autofill_group.0.dart',
    'examples/api/lib/widgets/scroll_view/list_view.1.dart',
    'examples/api/lib/widgets/scroll_view/list_view.0.dart',
    'examples/api/lib/widgets/scroll_view/grid_view.0.dart',
    'examples/api/lib/widgets/scroll_view/custom_scroll_view.1.dart',
    'examples/api/lib/widgets/binding/widget_binding_observer.0.dart',
    'examples/api/lib/widgets/image/image.loading_builder.0.dart',
    'examples/api/lib/widgets/image/image.error_builder.0.dart',
    'examples/api/lib/widgets/image/image.frame_builder.0.dart',
    'examples/api/lib/widgets/app_lifecycle_listener/app_lifecycle_listener.0.dart',
    'examples/api/lib/widgets/app_lifecycle_listener/app_lifecycle_listener.1.dart',
    'examples/api/lib/widgets/slotted_render_object_widget/slotted_multi_child_render_object_widget_mixin.0.dart',
    'examples/api/lib/widgets/color_filter/color_filtered.0.dart',
    'examples/api/lib/widgets/implicit_animations/animated_padding.0.dart',
    'examples/api/lib/widgets/implicit_animations/animated_positioned.0.dart',
    'examples/api/lib/widgets/implicit_animations/animated_align.0.dart',
    'examples/api/lib/widgets/implicit_animations/animated_slide.0.dart',
    'examples/api/lib/widgets/implicit_animations/animated_container.0.dart',
    'examples/api/lib/widgets/implicit_animations/sliver_animated_opacity.0.dart',
    'examples/api/lib/widgets/implicit_animations/animated_fractionally_sized_box.0.dart',
    'examples/api/lib/widgets/radio_group/radio_group.0.dart',
    'examples/api/lib/widgets/inherited_theme/inherited_theme.0.dart',
    'examples/api/lib/widgets/scroll_position/scroll_metrics_notification.0.dart',
    'examples/api/lib/widgets/scroll_position/scroll_controller_on_attach.0.dart',
    'examples/api/lib/widgets/scroll_position/is_scrolling_listener.0.dart',
    'examples/api/lib/widgets/scroll_position/scroll_controller_notification.0.dart',
    'examples/api/lib/widgets/page_transitions_builder/page_transitions_builder.0.dart',
    'examples/api/lib/widgets/page_storage/page_storage.0.dart',
    'examples/api/lib/widgets/table/table.0.dart',
    'examples/api/lib/widgets/notification_listener/notification.0.dart',
    'examples/api/lib/widgets/inherited_model/inherited_model.0.dart',
    'examples/api/lib/widgets/focus_scope/focus.2.dart',
    'examples/api/lib/widgets/focus_scope/focus_scope.0.dart',
    'examples/api/lib/widgets/focus_scope/focus.1.dart',
    'examples/api/lib/widgets/focus_scope/focus.0.dart',
    'examples/api/lib/widgets/pop_scope/pop_scope.1.dart',
    'examples/api/lib/widgets/pop_scope/pop_scope.0.dart',
    'examples/api/lib/widgets/animated_switcher/animated_switcher.0.dart',
    'examples/api/lib/widgets/shortcuts/shortcuts.0.dart',
    'examples/api/lib/widgets/shortcuts/character_activator.0.dart',
    'examples/api/lib/widgets/shortcuts/shortcuts.1.dart',
    'examples/api/lib/widgets/shortcuts/callback_shortcuts.0.dart',
    'examples/api/lib/widgets/shortcuts/single_activator.0.dart',
    'examples/api/lib/widgets/shortcuts/logical_key_set.0.dart',
    'examples/api/lib/widgets/actions/action_listener.0.dart',
    'examples/api/lib/widgets/actions/action.action_overridable.0.dart',
    'examples/api/lib/widgets/actions/focusable_action_detector.0.dart',
    'examples/api/lib/widgets/actions/actions.0.dart',
    'examples/api/lib/widgets/widget_state/widget_state_property.0.dart',
    'examples/api/lib/widgets/widget_state/widget_state_border_side.0.dart',
    'examples/api/lib/widgets/widget_state/widget_state_outlined_border.0.dart',
    'examples/api/lib/widgets/widget_state/widget_state_mouse_cursor.0.dart',
    'examples/api/lib/widgets/magnifier/magnifier.0.dart',
    'examples/api/lib/widgets/navigator/restorable_route_future.0.dart',
    'examples/api/lib/widgets/navigator/navigator.restorable_push_and_remove_until.0.dart',
    'examples/api/lib/widgets/navigator/navigator_state.restorable_push.0.dart',
    'examples/api/lib/widgets/navigator/navigator.restorable_push_replacement.0.dart',
    'examples/api/lib/widgets/navigator/navigator_state.restorable_push_and_remove_until.0.dart',
    'examples/api/lib/widgets/navigator/navigator_state.restorable_push_replacement.0.dart',
    'examples/api/lib/widgets/navigator/navigator.0.dart',
    'examples/api/lib/widgets/navigator/navigator.restorable_push.0.dart',
    'examples/api/lib/widgets/system_context_menu/system_context_menu.0.dart',
    'examples/api/lib/widgets/system_context_menu/system_context_menu.1.dart',
    'examples/api/lib/widgets/tween_animation_builder/tween_animation_builder.0.dart',
    'examples/api/lib/widgets/page_view/page_view.0.dart',
    'examples/api/lib/widgets/page_view/page_view.1.dart',
    'examples/api/lib/widgets/hardware_keyboard/key_event_manager.0.dart',
    'examples/api/lib/widgets/sliver_fill/sliver_fill_remaining.2.dart',
    'examples/api/lib/widgets/sliver_fill/sliver_fill_remaining.3.dart',
    'examples/api/lib/widgets/sliver_fill/sliver_fill_remaining.0.dart',
    'examples/api/lib/widgets/sliver_fill/sliver_fill_remaining.1.dart',
    'examples/api/lib/widgets/interactive_viewer/interactive_viewer.builder.0.dart',
    'examples/api/lib/widgets/interactive_viewer/interactive_viewer.0.dart',
    'examples/api/lib/widgets/interactive_viewer/interactive_viewer.constrained.0.dart',
    'examples/api/lib/widgets/interactive_viewer/interactive_viewer.transformation_controller.0.dart',
    'examples/api/lib/widgets/text/ui_testing_with_text.dart',
    'examples/api/lib/widgets/text/text.0.dart',
    'examples/api/lib/widgets/nested_scroll_view/nested_scroll_view.1.dart',
    'examples/api/lib/widgets/nested_scroll_view/nested_scroll_view.0.dart',
    'examples/api/lib/widgets/nested_scroll_view/nested_scroll_view.2.dart',
    'examples/api/lib/widgets/nested_scroll_view/nested_scroll_view_state.0.dart',
    'examples/api/lib/widgets/overscroll_indicator/glowing_overscroll_indicator.1.dart',
    'examples/api/lib/widgets/overscroll_indicator/glowing_overscroll_indicator.0.dart',
    'examples/api/lib/widgets/transitions/positioned_transition.0.dart',
    'examples/api/lib/widgets/transitions/listenable_builder.3.dart',
    'examples/api/lib/widgets/transitions/matrix_transition.0.dart',
    'examples/api/lib/widgets/transitions/listenable_builder.2.dart',
    'examples/api/lib/widgets/transitions/size_transition.0.dart',
    'examples/api/lib/widgets/transitions/relative_positioned_transition.0.dart',
    'examples/api/lib/widgets/transitions/animated_builder.0.dart',
    'examples/api/lib/widgets/transitions/decorated_box_transition.0.dart',
    'examples/api/lib/widgets/transitions/rotation_transition.0.dart',
    'examples/api/lib/widgets/transitions/fade_transition.0.dart',
    'examples/api/lib/widgets/transitions/animated_widget.0.dart',
    'examples/api/lib/widgets/transitions/align_transition.0.dart',
    'examples/api/lib/widgets/transitions/listenable_builder.1.dart',
    'examples/api/lib/widgets/transitions/listenable_builder.0.dart',
    'examples/api/lib/widgets/transitions/default_text_style_transition.0.dart',
    'examples/api/lib/widgets/transitions/slide_transition.0.dart',
    'examples/api/lib/widgets/transitions/scale_transition.0.dart',
    'examples/api/lib/widgets/transitions/sliver_fade_transition.0.dart',
    'examples/api/lib/widgets/windows/popup.0.dart',
    'examples/api/lib/widgets/windows/tooltip.0.dart',
    'examples/api/lib/widgets/windows/satellite.0.dart',
    'examples/api/lib/widgets/text_editing_intents/editable_text_tap_up_outside_intent.0.dart',
    'examples/api/lib/widgets/overlay/overlay_portal.0.dart',
    'examples/api/lib/widgets/overlay/overlay.0.dart',
    'examples/api/lib/widgets/draggable_scrollable_sheet/draggable_scrollable_sheet.0.dart',
    'examples/api/lib/widgets/focus_manager/focus_node.unfocus.0.dart',
    'examples/api/lib/widgets/focus_manager/focus_node.0.dart',
    'examples/api/lib/widgets/restoration_properties/restorable_value.0.dart',
    'examples/api/lib/widgets/gesture_detector/gesture_detector.3.dart',
    'examples/api/lib/widgets/gesture_detector/gesture_detector.2.dart',
    'examples/api/lib/widgets/gesture_detector/gesture_detector.1.dart',
    'examples/api/lib/widgets/gesture_detector/gesture_detector.0.dart',
    'examples/api/lib/widgets/routes/show_general_dialog.0.dart',
    'examples/api/lib/widgets/routes/local_history_entry.0.dart',
    'examples/api/lib/widgets/routes/route_observer.0.dart',
    'examples/api/lib/widgets/routes/flexible_route_transitions.1.dart',
    'examples/api/lib/widgets/routes/flexible_route_transitions.0.dart',
    'examples/api/lib/widgets/routes/popup_route.0.dart',
    'examples/api/lib/widgets/repeating_animation_builder/repeating_animation_builder.0.dart',
    'examples/api/lib/widgets/scrollbar/raw_scrollbar.1.dart',
    'examples/api/lib/widgets/scrollbar/raw_scrollbar.shape.0.dart',
    'examples/api/lib/widgets/scrollbar/raw_scrollbar.0.dart',
    'examples/api/lib/widgets/scrollbar/raw_scrollbar.2.dart',
    'examples/api/lib/widgets/scrollbar/raw_scrollbar.desktop.0.dart',
    'examples/api/lib/widgets/inherited_notifier/inherited_notifier.0.dart',
    'examples/api/lib/widgets/text_magnifier/text_magnifier.0.dart',
    'examples/api/test/widgets/animated_grid/animated_grid.0_test.dart',
    'examples/api/test/widgets/animated_grid/sliver_animated_grid.0_test.dart',
    'examples/api/test/widgets/navigator_pop_handler/navigator_pop_handler.1_test.dart',
    'examples/api/test/widgets/navigator_pop_handler/navigator_pop_handler.0_test.dart',
    'examples/api/test/widgets/editable_text/editable_text.on_content_inserted.0_test.dart',
    'examples/api/test/widgets/editable_text/text_editing_controller.1_test.dart',
    'examples/api/test/widgets/editable_text/editable_text.on_changed.0_test.dart',
    'examples/api/test/widgets/editable_text/text_editing_controller.0_test.dart',
    'examples/api/test/widgets/undo_history/undo_history_controller.0_test.dart',
    'examples/api/test/widgets/raw_tooltip/raw_tooltip.0_test.dart',
    'examples/api/test/widgets/form/form.0_test.dart',
    'examples/api/test/widgets/form/form.1_test.dart',
    'examples/api/test/widgets/tap_region/text_field_tap_region.0_test.dart',
    'examples/api/test/widgets/restoration/restoration_mixin.0_test.dart',
    'examples/api/test/widgets/drag_target/draggable.0_test.dart',
    'examples/api/test/widgets/autocomplete/raw_autocomplete.1_test.dart',
    'examples/api/test/widgets/autocomplete/raw_autocomplete.focus_node.0_test.dart',
    'examples/api/test/widgets/autocomplete/raw_autocomplete.0_test.dart',
    'examples/api/test/widgets/autocomplete/raw_autocomplete.2_test.dart',
    'examples/api/test/widgets/keep_alive/automatic_keep_alive.0_test.dart',
    'examples/api/test/widgets/keep_alive/keep_alive.0_test.dart',
    'examples/api/test/widgets/keep_alive/automatic_keep_alive_client_mixin.0_test.dart',
    'examples/api/test/widgets/safe_area/safe_area.0_test.dart',
    'examples/api/test/widgets/scroll_notification_observer/scroll_notification_observer.0_test.dart',
    'examples/api/test/widgets/animated_size/animated_size.0_test.dart',
    'examples/api/test/widgets/framework/build_owner.0_test.dart',
    'examples/api/test/widgets/framework/error_widget.0_test.dart',
    'examples/api/test/widgets/sliver/pinned_header_sliver.1_test.dart',
    'examples/api/test/widgets/sliver/sliver_floating_header.0_test.dart',
    'examples/api/test/widgets/sliver/pinned_header_sliver.0_test.dart',
    'examples/api/test/widgets/sliver/sliver_opacity.1_test.dart',
    'examples/api/test/widgets/sliver/decorated_sliver.0_test.dart',
    'examples/api/test/widgets/sliver/sliver_cross_axis_group.0_test.dart',
    'examples/api/test/widgets/sliver/decorated_sliver.1_test.dart',
    'examples/api/test/widgets/sliver/sliver_main_axis_group.0_test.dart',
    'examples/api/test/widgets/sliver/sliver_constrained_cross_axis.0_test.dart',
    'examples/api/test/widgets/sliver/sliver_resizing_header.0_test.dart',
    'examples/api/test/widgets/heroes/hero.0_test.dart',
    'examples/api/test/widgets/heroes/hero.1_test.dart',
    'examples/api/test/widgets/dismissible/dismissible.0_test.dart',
    'examples/api/test/widgets/overflow_bar/overflow_bar.0_test.dart',
    'examples/api/test/widgets/preferred_size/preferred_size.0_test.dart',
    'examples/api/test/widgets/media_query/media_query_data.system_gesture_insets.0_test.dart',
    'examples/api/test/widgets/focus_traversal/focus_traversal_group.0_test.dart',
    'examples/api/test/widgets/focus_traversal/ordered_traversal_policy.0_test.dart',
    'examples/api/test/widgets/value_listenable_builder/value_listenable_builder.0_test.dart',
    'examples/api/test/widgets/raw_menu_anchor/raw_menu_anchor.3_test.dart',
    'examples/api/test/widgets/raw_menu_anchor/raw_menu_anchor.2_test.dart',
    'examples/api/test/widgets/raw_menu_anchor/raw_menu_anchor.0_test.dart',
    'examples/api/test/widgets/async/stream_builder.0_test.dart',
    'examples/api/test/widgets/async/future_builder.0_test.dart',
    'examples/api/test/widgets/shared_app_data/shared_app_data.0_test.dart',
    'examples/api/test/widgets/shared_app_data/shared_app_data.1_test.dart',
    'examples/api/test/widgets/animated_list/animated_list_separated.0_test.dart',
    'examples/api/test/widgets/animated_list/sliver_animated_list.0_test.dart',
    'examples/api/test/widgets/animated_list/animated_list.0_test.dart',
    'examples/api/test/widgets/basic/physical_shape.0_test.dart',
    'examples/api/test/widgets/basic/aspect_ratio.2_test.dart',
    'examples/api/test/widgets/basic/indexed_stack.0_test.dart',
    'examples/api/test/widgets/basic/clip_rrect.1_test.dart',
    'examples/api/test/widgets/basic/absorb_pointer.0_test.dart',
    'examples/api/test/widgets/basic/listener.0_test.dart',
    'examples/api/test/widgets/basic/clip_rrect.0_test.dart',
    'examples/api/test/widgets/basic/mouse_region.0_test.dart',
    'examples/api/test/widgets/basic/expanded.0_test.dart',
    'examples/api/test/widgets/basic/fitted_box.0_test.dart',
    'examples/api/test/widgets/basic/mouse_region.on_exit.0_test.dart',
    'examples/api/test/widgets/basic/aspect_ratio.0_test.dart',
    'examples/api/test/widgets/basic/fractionally_sized_box.0_test.dart',
    'examples/api/test/widgets/basic/expanded.1_test.dart',
    'examples/api/test/widgets/basic/mouse_region.on_exit.1_test.dart',
    'examples/api/test/widgets/basic/custom_multi_child_layout.0_test.dart',
    'examples/api/test/widgets/basic/aspect_ratio.1_test.dart',
    'examples/api/test/widgets/basic/flow.0_test.dart',
    'examples/api/test/widgets/basic/overflowbox.0_test.dart',
    'examples/api/test/widgets/scroll_end_notification/scroll_end_notification.0_test.dart',
    'examples/api/test/widgets/scroll_end_notification/scroll_end_notification.1_test.dart',
    'examples/api/test/widgets/autofill/autofill_group.0_test.dart',
    'examples/api/test/widgets/scroll_view/list_view.1_test.dart',
    'examples/api/test/widgets/scroll_view/custom_scroll_view.1_test.dart',
    'examples/api/test/widgets/scroll_view/list_view.0_test.dart',
    'examples/api/test/widgets/image/image.loading_builder.0_test.dart',
    'examples/api/test/widgets/image/image.error_builder.0_test.dart',
    'examples/api/test/widgets/image/image.frame_builder.0_test.dart',
    'examples/api/test/widgets/color_filter/color_filtered.0_test.dart',
    'examples/api/test/widgets/implicit_animations/animated_positioned.0_test.dart',
    'examples/api/test/widgets/implicit_animations/sliver_animated_opacity.0_test.dart',
    'examples/api/test/widgets/implicit_animations/animated_slide.0_test.dart',
    'examples/api/test/widgets/implicit_animations/animated_padding.0_test.dart',
    'examples/api/test/widgets/implicit_animations/animated_fractionally_sized_box.0_test.dart',
    'examples/api/test/widgets/implicit_animations/animated_align.0_test.dart',
    'examples/api/test/widgets/implicit_animations/animated_container.0_test.dart',
    'examples/api/test/widgets/radio_group/radio_group.0_test.dart',
    'examples/api/test/widgets/inherited_theme/inherited_theme.0_test.dart',
    'examples/api/test/widgets/scroll_position/scroll_metrics_notification.0_test.dart',
    'examples/api/test/widgets/scroll_position/scroll_controller_on_attach.0_test.dart',
    'examples/api/test/widgets/scroll_position/is_scrolling_listener.0_test.dart',
    'examples/api/test/widgets/scroll_position/scroll_controller_notification.0_test.dart',
    'examples/api/test/widgets/page_transitions_builder/page_transitions_builder.0_test.dart',
    'examples/api/test/widgets/page_storage/page_storage.0_test.dart',
    'examples/api/test/widgets/table/table.0_test.dart',
    'examples/api/test/widgets/notification_listener/notification.0_test.dart',
    'examples/api/test/widgets/inherited_model/inherited_model.0_test.dart',
    'examples/api/test/widgets/focus_scope/focus.0_test.dart',
    'examples/api/test/widgets/focus_scope/focus.1_test.dart',
    'examples/api/test/widgets/focus_scope/focus.2_test.dart',
    'examples/api/test/widgets/focus_scope/focus_scope.0_test.dart',
    'examples/api/test/widgets/pop_scope/pop_scope.1_test.dart',
    'examples/api/test/widgets/animated_switcher/animated_switcher.0_test.dart',
    'examples/api/test/widgets/shortcuts/character_activator.0_test.dart',
    'examples/api/test/widgets/actions/action_listener.0_test.dart',
    'examples/api/test/widgets/actions/focusable_action_detector.0_test.dart',
    'examples/api/test/widgets/actions/actions.0_test.dart',
    'examples/api/test/widgets/actions/action.action_overridable.0_test.dart',
    'examples/api/test/widgets/widget_state/widget_state_property.0_test.dart',
    'examples/api/test/widgets/widget_state/widget_state_border_side.0_test.dart',
    'examples/api/test/widgets/widget_state/widget_state_outlined_border.0_test.dart',
    'examples/api/test/widgets/widget_state/widget_state_mouse_cursor.0_test.dart',
    'examples/api/test/widgets/magnifier/magnifier.0_test.dart',
    'examples/api/test/widgets/navigator/navigator.restorable_push.0_test.dart',
    'examples/api/test/widgets/navigator/navigator_state.restorable_push_and_remove_until.0_test.dart',
    'examples/api/test/widgets/navigator/navigator_state.restorable_push.0_test.dart',
    'examples/api/test/widgets/navigator/navigator.restorable_push_and_remove_until.0_test.dart',
    'examples/api/test/widgets/navigator/restorable_route_future.0_test.dart',
    'examples/api/test/widgets/navigator/navigator_state.restorable_push_replacement.0_test.dart',
    'examples/api/test/widgets/navigator/navigator.restorable_push_replacement.0_test.dart',
    'examples/api/test/widgets/system_context_menu/system_context_menu.1_test.dart',
    'examples/api/test/widgets/system_context_menu/system_context_menu.0_test.dart',
    'examples/api/test/widgets/tween_animation_builder/tween_animation_builder.0_test.dart',
    'examples/api/test/widgets/page_view/page_view.0_test.dart',
    'examples/api/test/widgets/page_view/page_view.1_test.dart',
    'examples/api/test/widgets/hardware_keyboard/key_event_manager.0_test.dart',
    'examples/api/test/widgets/sliver_fill/sliver_fill_remaining.1_test.dart',
    'examples/api/test/widgets/sliver_fill/sliver_fill_remaining.0_test.dart',
    'examples/api/test/widgets/sliver_fill/sliver_fill_remaining.3_test.dart',
    'examples/api/test/widgets/sliver_fill/sliver_fill_remaining.2_test.dart',
    'examples/api/test/widgets/interactive_viewer/interactive_viewer.transformation_controller.0_test.dart',
    'examples/api/test/widgets/interactive_viewer/interactive_viewer.0_test.dart',
    'examples/api/test/widgets/interactive_viewer/interactive_viewer.constrained.0_test.dart',
    'examples/api/test/widgets/text/text.0_test.dart',
    'examples/api/test/widgets/nested_scroll_view/nested_scroll_view.2_test.dart',
    'examples/api/test/widgets/nested_scroll_view/nested_scroll_view_state.0_test.dart',
    'examples/api/test/widgets/nested_scroll_view/nested_scroll_view.0_test.dart',
    'examples/api/test/widgets/nested_scroll_view/nested_scroll_view.1_test.dart',
    'examples/api/test/widgets/overscroll_indicator/glowing_overscroll_indicator.0_test.dart',
    'examples/api/test/widgets/overscroll_indicator/glowing_overscroll_indicator.1_test.dart',
    'examples/api/test/widgets/transitions/listenable_builder.3_test.dart',
    'examples/api/test/widgets/transitions/sliver_fade_transition.0_test.dart',
    'examples/api/test/widgets/transitions/matrix_transition.0_test.dart',
    'examples/api/test/widgets/transitions/default_text_style_transition.0_test.dart',
    'examples/api/test/widgets/transitions/listenable_builder.2_test.dart',
    'examples/api/test/widgets/transitions/align_transition.0_test.dart',
    'examples/api/test/widgets/transitions/size_transition.0_test.dart',
    'examples/api/test/widgets/transitions/fade_transition.0_test.dart',
    'examples/api/test/widgets/transitions/listenable_builder.1_test.dart',
    'examples/api/test/widgets/transitions/relative_positioned_transition.0_test.dart',
    'examples/api/test/widgets/transitions/slide_transition.0_test.dart',
    'examples/api/test/widgets/transitions/positioned_transition.0_test.dart',
    'examples/api/test/widgets/transitions/decorated_box_transition.0_test.dart',
    'examples/api/test/widgets/transitions/animated_builder.0_test.dart',
    'examples/api/test/widgets/transitions/listenable_builder.0_test.dart',
    'examples/api/test/widgets/transitions/scale_transition.0_test.dart',
    'examples/api/test/widgets/transitions/animated_widget.0_test.dart',
    'examples/api/test/widgets/transitions/rotation_transition.0_test.dart',
    'examples/api/test/widgets/text_editing_intents/editable_text_tap_up_outside_intent.0_test.dart',
    'examples/api/test/widgets/overlay/overlay.0_test.dart',
    'examples/api/test/widgets/draggable_scrollable_sheet/draggable_scrollable_sheet.0_test.dart',
    'examples/api/test/widgets/focus_manager/focus_node.unfocus.0_test.dart',
    'examples/api/test/widgets/focus_manager/focus_node.0_test.dart',
    'examples/api/test/widgets/restoration_properties/restorable_value.0_test.dart',
    'examples/api/test/widgets/gesture_detector/gesture_detector.3_test.dart',
    'examples/api/test/widgets/gesture_detector/gesture_detector.2_test.dart',
    'examples/api/test/widgets/gesture_detector/gesture_detector.1_test.dart',
    'examples/api/test/widgets/gesture_detector/gesture_detector.0_test.dart',
    'examples/api/test/widgets/routes/popup_route.0_test.dart',
    'examples/api/test/widgets/routes/show_general_dialog.0_test.dart',
    'examples/api/test/widgets/repeating_animation_builder/repeating_animation_builder.0_test.dart',
    'examples/api/test/widgets/scrollbar/raw_scrollbar.2_test.dart',
    'examples/api/test/widgets/scrollbar/raw_scrollbar.desktop.0_test.dart',
    'examples/api/test/widgets/scrollbar/raw_scrollbar.0_test.dart',
    'examples/api/test/widgets/scrollbar/raw_scrollbar.shape.0_test.dart',
    'examples/api/test/widgets/scrollbar/raw_scrollbar.1_test.dart',
    'examples/api/test/widgets/inherited_notifier/inherited_notifier.0_test.dart',
    'examples/api/test/widgets/text_magnifier/text_magnifier.0_test.dart',
  };

  /// The known cross imports in the `examples/flutter_view` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesFlutterViewCrossImports = <String>{
    'examples/flutter_view/lib/main.dart',
  };

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
  static final Set<String> knownExamplesImageListCrossImports = <String>{
    'examples/image_list/lib/main.dart',
  };

  /// The known cross imports in the `examples/layers` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesLayersCrossImports = <String>{
    'examples/layers/rendering/touch_input.dart',
    'examples/layers/services/isolate.dart',
    'examples/layers/widgets/gestures.dart',
    'examples/layers/widgets/spinning_mixed.dart',
    'examples/layers/widgets/media_query.dart',
    'examples/layers/widgets/sectors.dart',
    'examples/layers/widgets/styled_text.dart',
    'examples/layers/test/gestures_test.dart',
  };

  /// The known cross imports in the `examples/multiple_windows` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesMultipleWindowsCrossImports = <String>{
    'examples/multiple_windows/lib/app/main_window.dart',
    'examples/multiple_windows/lib/app/tooltip_button.dart',
    'examples/multiple_windows/lib/app/tooltip_window_edit_dialog.dart',
    'examples/multiple_windows/lib/app/dialog_window_content.dart',
    'examples/multiple_windows/lib/app/dialog_window_edit_dialog.dart',
    'examples/multiple_windows/lib/app/popup_window_content.dart',
    'examples/multiple_windows/lib/app/regular_window_content.dart',
    'examples/multiple_windows/lib/app/rotated_wire_cube.dart',
    'examples/multiple_windows/lib/app/popup_window_edit_dialog.dart',
    'examples/multiple_windows/lib/app/regular_window_edit_dialog.dart',
    'examples/multiple_windows/lib/app/tooltip_window_content.dart',
    'examples/multiple_windows/lib/app/popup_button.dart',
    'examples/multiple_windows/lib/app/window_settings_dialog.dart',
    'examples/multiple_windows/lib/main.dart',
    'examples/multiple_windows/test/multiple_windows_test.dart',
  };

  /// The known cross imports in the `examples/platform_channel` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesPlatformChannelCrossImports = <String>{
    'examples/platform_channel/lib/main.dart',
  };

  /// The known cross imports in the `examples/platform_channel_swift` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesPlatformChannelSwiftCrossImports = <String>{
    'examples/platform_channel_swift/lib/main.dart',
  };

  /// The known cross imports in the `examples/platform_view` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesPlatformViewCrossImports = <String>{
    'examples/platform_view/lib/main.dart',
  };

  /// The known cross imports in the `examples/splash` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesSplashCrossImports = <String>{
    'examples/splash/lib/main.dart',
    'examples/splash/test/splash_test.dart',
  };

  /// The known cross imports in the `examples/texture` directory.
  ///
  /// These cross imports should all eventually be resolved, but until they are we allow them, so
  /// that we can catch any new cross imports that are added.
  // TODO(justinmc): Fix all of these tests so there are no cross imports.
  // See https://github.com/flutter/flutter/issues/187645.
  static final Set<String> knownExamplesTextureCrossImports = <String>{
    'examples/texture/lib/main.dart',
  };

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

          // Handle the other samples, which are divided per subfolder.
          mapping.addAll(
            _getExamplesSlashApiExamples(
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
  Map<_SampleTemplatesLibraryFile, Set<File>> _getExamplesSlashApiSampleTemplatesFiles({
    required Directory libDirectory,
    required Directory testDirectory,
    required Pattern dartFilePattern,
  }) {
    final Directory sampleTemplatesLibDirectory = libDirectory.childDirectory(
      _kSampleTemplatesDirectoryName,
    );
    final Directory sampleTemplatesTestDirectory = testDirectory.childDirectory(
      _kSampleTemplatesDirectoryName,
    );

    final Map<_SampleTemplatesLibraryFile, Set<File>> mapping = {};

    for (final File file
        in sampleTemplatesLibDirectory.listSync(recursive: true).whereType<File>()) {
      if (file.absolute.path.contains(dartFilePattern)) {
        mapping[_SampleTemplatesLibraryFile.fromFile(file)] = {file};
      }
    }

    for (final File file
        in sampleTemplatesTestDirectory.listSync(recursive: true).whereType<File>()) {
      if (file.absolute.path.contains(dartFilePattern)) {
        mapping[_SampleTemplatesLibraryFile.fromFile(file)] = {file};
      }
    }

    return mapping;
  }

  /// Get a list of all the filenames that end in ".dart", grouped by library,
  /// for the subdirectories of `examples/api`,
  /// except `examples/api/lib/sample_templates` and `examples/api/test/sample_templates`.
  Map<_ExamplesLibrary, Set<File>> _getExamplesSlashApiExamples({
    required Directory libDirectory,
    required Directory testDirectory,
    required Pattern dartFilePattern,
  }) {
    final Map<_ExamplesLibrary, Set<File>> mapping = {};

    for (final Directory directory in libDirectory.listSync().whereType<Directory>()) {
      // The sample templates directory is handled separately.
      if (path.basename(directory.absolute.path) == _kSampleTemplatesDirectoryName) {
        continue;
      }

      final library = _ExamplesLibrary.fromDirectory(directory, flutterRoot: flutterRoot);

      mapping.putIfAbsent(library, () => {});

      for (final File file in directory.listSync(recursive: true).whereType<File>()) {
        if (!file.absolute.path.contains(dartFilePattern)) {
          continue;
        }

        mapping[library]?.add(file);
      }
    }

    for (final Directory directory in testDirectory.listSync().whereType<Directory>()) {
      // The sample templates directory is handled separately.
      if (path.basename(directory.absolute.path) == _kSampleTemplatesDirectoryName) {
        continue;
      }

      final library = _ExamplesLibrary.fromDirectory(directory, flutterRoot: flutterRoot);

      mapping.putIfAbsent(library, () => {});

      for (final File file in directory.listSync(recursive: true).whereType<File>()) {
        if (!file.absolute.path.contains(dartFilePattern)) {
          continue;
        }

        mapping[library]?.add(file);
      }
    }

    return mapping;
  }

  /// Returns true if there are no errors, false otherwise.
  bool check() {
    filesystem.currentDirectory = flutterRoot;

    final Map<_ExamplesLibrary, Set<File>> filesByLibrary = _getExampleFiles();

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

      final Set<String> knownCrossImportsForLibrary = {
        for (final String element in entry.key.knownCrossImports)
          // The known cross imports include both /lib and /test entries, so handle both.
          if (element.startsWith('${entry.key.libraryName}/')) element,
      };

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

    // TODO(justinmc): The examples checker needs an exemption list for specific core widgets
    // For example the Material and Cupertino text magnifier or context menu builders.
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

    const genericExamples = {
      'examples',
      'examples/api',
      'examples/api/lib/animation',
      'examples/api/lib/foundation',
      'examples/api/lib/gestures',
      'examples/api/lib/painting',
      'examples/api/lib/rendering',
      'examples/api/lib/services',
      'examples/api/lib/ui',
      'examples/api/lib/widgets',
      'examples/api/test/animation',
      'examples/api/test/foundation',
      'examples/api/test/gestures',
      'examples/api/test/painting',
      'examples/api/test/rendering',
      'examples/api/test/services',
      'examples/api/test/ui',
      'examples/api/test/widgets',
      'examples/flutter_view',
      'examples/hello_world',
      'examples/image_list',
      'examples/layers',
      'examples/multiple_windows',
      'examples/platform_channel',
      'examples/platform_channel_swift',
      'examples/platform_view',
      'examples/splash',
      'examples/texture',
    };

    if (genericExamples.contains(relativePath)) {
      return _ApiExampleLibrary(relativePath);
    }

    return switch (relativePath) {
      'examples/api/lib/cupertino' ||
      'examples/api/test/cupertino' => _CupertinoApiExampleLibrary(relativePath),
      'examples/api/lib/material' ||
      'examples/api/test/material' => _MaterialApiExampleLibrary(relativePath),
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
  bool canImport(LibraryCrossImportStatementType import) => false;

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
///
/// For example `examples/api/lib/foundation` and `examples/api/test/foundation`.
final class _ApiExampleLibrary extends _ExamplesLibrary {
  const _ApiExampleLibrary(super.name);
}

/// The examples in `examples/api/lib/cupertino`
/// and their tests in `examples/api/test/cupertino`.
final class _CupertinoApiExampleLibrary extends _ExamplesLibrary {
  const _CupertinoApiExampleLibrary(super.name);

  @override
  bool canImport(LibraryCrossImportStatementType import) {
    return import == LibraryCrossImportStatementType.cupertino;
  }
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

  @override
  bool canImport(LibraryCrossImportStatementType import) {
    return import == LibraryCrossImportStatementType.material;
  }
}

/// The examples in `examples/api/lib/sample_templates`
/// and their tests in `examples/api/test/sample_templates`.
///
/// The sample templates are individual files, rather than directories.
final class _SampleTemplatesLibraryFile extends _ExamplesLibrary {
  const _SampleTemplatesLibraryFile._(super.name, this._filePath);

  factory _SampleTemplatesLibraryFile.fromFile(File file) {
    const examplesLibPrefix = 'examples/api/lib/sample_templates';
    const examplesTestPrefix = 'examples/api/test/sample_templates';
    final String filePath = file.absolute.path.replaceAll(Platform.pathSeparator, '/');

    final int libIndex = filePath.indexOf(examplesLibPrefix);

    if (libIndex != -1) {
      return _SampleTemplatesLibraryFile._(examplesLibPrefix, filePath);
    }

    final int testIndex = filePath.indexOf(examplesTestPrefix);

    if (testIndex != -1) {
      return _SampleTemplatesLibraryFile._(examplesTestPrefix, filePath);
    }

    throw ArgumentError('Invalid file path: $filePath');
  }

  /// The file path to the template file.
  final String _filePath;

  @override
  bool canImport(LibraryCrossImportStatementType import) {
    return switch (import) {
      LibraryCrossImportStatementType.material => _filePath.contains('material'),
      LibraryCrossImportStatementType.cupertino => _filePath.contains('cupertino'),
    };
  }
}
