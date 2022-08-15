// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart';

import 'desktop_text_selection_toolbar.dart';
import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_buttons_builder.dart';

/// The default Cupertino context menu for text selection for the current
/// platform.
///
/// Builds the mobile Cupertino context menu for all mobile platforms, not just
/// iOS, and builds the desktop Cupertino context menu for all desktop
/// platforms, not just MacOS. For a widget that builds the native-looking
/// context menu for all platforms, see [AdaptiveTextSelectionToolbar].
///
/// {@template flutter.cupertino.AdaptiveTextSelectionToolbar.constructor.adaptiveButtons}
/// To adaptively generate the default buttons for the current platform, use
/// [CupertinoAdaptiveTextSelectionToolbar.adaptiveButtons].
/// {@endtemplate}
///
/// {@template flutter.cupertino.AdaptiveTextSelectionToolbar.constructor.buttonItems}
/// To specify the button labels and callbacks but still adaptively generate
/// the look of the buttons based on the current platform, use
/// [CupertinoAdaptiveTextSelectionToolbar.buttonItems].
/// {@endtemplate}
///
/// See also:
///
/// * [EditableTextContextMenuButtonItemsBuilder], which generates the default
///   [ContextMenuButtonItem]s for the current platform for a context menu
///   displaying inside of an [EditableText].
/// * [TextSelectionToolbarButtonsBuilder], which builds the native-looking
///   button Widgets for the current platform given [ContextMenuButtonItem]s.
/// * [AdaptiveTextSelectionToolbar], which does the same thing as this widget
///   but for all platforms, not just the Cupertino-styled platforms.
class CupertinoAdaptiveTextSelectionToolbar extends StatelessWidget {
  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] with the
  /// given [children].
  const CupertinoAdaptiveTextSelectionToolbar({
    super.key,
    required this.children,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : _targetPlatform = targetPlatform,
       buttonItems = null,
       editableTextState = null;

  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] and
  /// adaptively generate the buttons based on the current platform and the
  /// given [editableTextState].
  ///
  /// {@template flutter.cupertino.AdaptiveTextSelectionToolbar}
  /// To specify the [children] widgets directly, use the main constructor
  /// [CupertinoAdaptiveTextSelectionToolbar.CupertinoAdaptiveTextSelectionToolbar].
  /// {@endtemplate}
  ///
  /// {@macro flutter.cupertino.AdaptiveTextSelectionToolbar.constructor.buttonItems}
  const CupertinoAdaptiveTextSelectionToolbar.adaptiveButtons({
    super.key,
    required this.editableTextState,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : _targetPlatform = targetPlatform,
       buttonItems = null,
       children = null;

  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] and
  /// adaptively generate the buttons based on the current platform and
  /// [buttonItems].
  ///
  /// {@macro flutter.cupertino.AdaptiveTextSelectionToolbar}
  ///
  /// {@macro flutter.cupertino.AdaptiveTextSelectionToolbar.constructor.adaptiveButtons}
  const CupertinoAdaptiveTextSelectionToolbar.buttonItems({
    super.key,
    required this.buttonItems,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : _targetPlatform = targetPlatform,
       editableTextState = null,
       children = null;

  /// {@template flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  /// The main location on which to anchor the menu.
  ///
  /// Optionally, [secondaryAnchor] can be provided as an alternative anchor
  /// location if the menu doesn't fit here.
  /// {@endtemplate}
  final Offset primaryAnchor;

  /// {@template flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  /// The optional secondary location on which to anchor the menu, if it doesn't
  /// fit at [primaryAnchor].
  /// {@endtemplate}
  final Offset? secondaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  ///
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar}
  ///
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.constructor.adaptiveButtons}
  final List<ContextMenuButtonItem>? buttonItems;

  /// Used to generate the default buttons for the platform in the case that
  /// [children] and [buttonItems] are not provided.
  final EditableTextState? editableTextState;

  /// The platform to base the toolbar on.
  ///
  /// Defaults to [defaultTargetPlatform].
  TargetPlatform get targetPlatform => _targetPlatform ?? defaultTargetPlatform;

  final TargetPlatform? _targetPlatform;

  /// The children of the toolbar, typically buttons.
  ///
  /// If provided, [buttonItems] cannot also be provided.
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if ((children?.isEmpty ?? false) || (buttonItems?.isEmpty ?? false)) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    if (children?.isNotEmpty ?? false) {
      return _AdaptiveTextSelectionToolbarFromChildren(
        primaryAnchor: primaryAnchor,
        secondaryAnchor: secondaryAnchor,
        children: children!,
      );
    }

    if (buttonItems?.isNotEmpty ?? false) {
      return _AdaptiveTextSelectionToolbarFromButtonItems(
        primaryAnchor: primaryAnchor,
        secondaryAnchor: secondaryAnchor,
        buttonItems: buttonItems!,
      );
    }

    return EditableTextContextMenuButtonItemsBuilder(
      editableTextState: editableTextState!,
      targetPlatform: targetPlatform,
      builder: (BuildContext context, List<ContextMenuButtonItem> buttonItems) {
        return _AdaptiveTextSelectionToolbarFromButtonItems(
          primaryAnchor: primaryAnchor,
          secondaryAnchor: secondaryAnchor,
          buttonItems: buttonItems,
        );
      },
    );
  }
}

/// The default text selection toolbar by platform given the [children] for the
/// platform, for Cupertino.
class _AdaptiveTextSelectionToolbarFromChildren extends StatelessWidget {
  const _AdaptiveTextSelectionToolbarFromChildren({
    required this.primaryAnchor,
    this.secondaryAnchor,
    required this.children,
  }) : assert(children != null);

  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// The children of the toolbar, typically buttons.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (children.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return CupertinoTextSelectionToolbar(
          anchorAbove: primaryAnchor,
          anchorBelow: secondaryAnchor == null ? primaryAnchor : secondaryAnchor!,
          children: children,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return CupertinoDesktopTextSelectionToolbar(
          anchor: primaryAnchor,
          children: children,
        );
    }
  }
}

/// The default text selection toolbar by platform given [buttonItems]
/// representing the children for the platform.
class _AdaptiveTextSelectionToolbarFromButtonItems extends StatelessWidget {
  const _AdaptiveTextSelectionToolbarFromButtonItems({
    required this.primaryAnchor,
    this.secondaryAnchor,
    required this.buttonItems,
  }) : assert(buttonItems != null);

  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// The information needed to create each child button of the menu.
  final List<ContextMenuButtonItem> buttonItems;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (buttonItems.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return CupertinoTextSelectionToolbarButtonsBuilder(
      buttonItems: buttonItems,
      builder: (BuildContext context, List<Widget> children) {
        return _AdaptiveTextSelectionToolbarFromChildren(
          primaryAnchor: primaryAnchor,
          secondaryAnchor: secondaryAnchor,
          children: children,
        );
      },
    );
  }
}
