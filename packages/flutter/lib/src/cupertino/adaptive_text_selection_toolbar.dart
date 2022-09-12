// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/src/material/adaptive_text_selection_toolbar.dart';
import 'package:flutter/widgets.dart';

import 'desktop_text_selection_toolbar.dart';
import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_buttons_builder.dart';

// TODO(justinmc): Refactor this similar to the material one.
/// The default Cupertino context menu for text selection for the current
/// platform with the given children.
///
/// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.platforms}
/// Builds the mobile Cupertino context menu on all mobile platforms, not just
/// iOS, and builds the desktop Cupertino context menu on all desktop platforms,
/// not just MacOS. For a widget that builds the native-looking context menu for
/// all platforms, see [AdaptiveTextSelectionToolbar].
/// {@endtemplate}
///
/// See also:
///
/// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.seeAlso}
/// * [CupertinoAdaptiveTextSelectionToolbarButtonItems], which is like this
///   widget but creates its children from a list of [ContextMenuButtonItem]s.
/// * [CupertinoAdaptiveTextSelectionToolbarEditableText], which is like this
///   widget but uses the default children for an editable text field.
/// {@endtemplate}
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
  }) : _targetPlatform = targetPlatform;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.targetPlatform}
  /// The platform to base the toolbar on.
  ///
  /// Defaults to [defaultTargetPlatform].
  /// {@endtemplate}
  TargetPlatform get targetPlatform => _targetPlatform ?? defaultTargetPlatform;

  final TargetPlatform? _targetPlatform;

  /// The children of the toolbar, typically buttons.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (children.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }
    return _AdaptiveTextSelectionToolbarFromChildren(
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor,
      targetPlatform: targetPlatform,
      children: children,
    );
  }
}

/// The default Cupertino context menu for text selection for the current
/// platform for an editable text field.
///
/// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.platforms}
///
/// See also:
///
/// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.seeAlso}
/// * [EditableTextContextMenuButtonItemsBuilder], which generates the default
///   [ContextMenuButtonItem]s for the current platform for a context menu
///   displaying inside of an [EditableText].
/// * [TextSelectionToolbarButtonsBuilder], which builds the native-looking
///   button Widgets for the current platform given [ContextMenuButtonItem]s.
/// * [AdaptiveTextSelectionToolbar], which does the same thing as this widget
///   but for all platforms, not just the Cupertino-styled platforms.
class CupertinoAdaptiveTextSelectionToolbarEditableText extends StatelessWidget {
  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] and
  /// adaptively generate the buttons based on the current platform and the
  /// given [editableTextState].
  const CupertinoAdaptiveTextSelectionToolbarEditableText({
    super.key,
    required this.editableTextState,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : _targetPlatform = targetPlatform;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// Used to generate the default buttons for the field.
  final EditableTextState editableTextState;

  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.targetPlatform}
  TargetPlatform get targetPlatform => _targetPlatform ?? defaultTargetPlatform;

  final TargetPlatform? _targetPlatform;

  @override
  Widget build(BuildContext context) {
    return _AdaptiveTextSelectionToolbarFromButtonItems(
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor,
      buttonItems: AdaptiveTextSelectionToolbar.getEditableTextButtonItems(
        editableTextState,
      ),
    );
  }
}

/// The default Cupertino context menu for text selection for the current
/// platform with children generated from the given [ContextMenuButtonItem]s.
///
/// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.platforms}
///
/// See also:
///
/// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.seeAlso}
/// * [EditableTextContextMenuButtonItemsBuilder], which generates the default
///   [ContextMenuButtonItem]s for the current platform for a context menu
///   displaying inside of an [EditableText].
/// * [TextSelectionToolbarButtonsBuilder], which builds the native-looking
///   button Widgets for the current platform given [ContextMenuButtonItem]s.
/// * [AdaptiveTextSelectionToolbar], which does the same thing as this widget
///   but for all platforms, not just the Cupertino-styled platforms.
class CupertinoAdaptiveTextSelectionToolbarButtonItems extends StatelessWidget {
  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] and
  /// adaptively generate the buttons based on the current platform and
  /// [buttonItems].
  const CupertinoAdaptiveTextSelectionToolbarButtonItems({
    super.key,
    required this.buttonItems,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : _targetPlatform = targetPlatform;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  final List<ContextMenuButtonItem> buttonItems;

  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.targetPlatform}
  TargetPlatform get targetPlatform => _targetPlatform ?? defaultTargetPlatform;

  final TargetPlatform? _targetPlatform;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (buttonItems.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return _AdaptiveTextSelectionToolbarFromButtonItems(
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor,
      targetPlatform: targetPlatform,
      buttonItems: buttonItems,
    );
  }
}

/// The default text selection toolbar by platform given the [children] for the
/// platform, for Cupertino.
class _AdaptiveTextSelectionToolbarFromChildren extends StatelessWidget {
  _AdaptiveTextSelectionToolbarFromChildren({
    required this.primaryAnchor,
    this.secondaryAnchor,
    required this.children,
    final TargetPlatform? targetPlatform,
  }) : assert(children != null),
       _targetPlatform = targetPlatform ?? defaultTargetPlatform;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// The children of the toolbar, typically buttons.
  final List<Widget> children;

  /// The platform to use to adaptively generate the toolbar.
  final TargetPlatform _targetPlatform;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (children.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    switch (_targetPlatform) {
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
  _AdaptiveTextSelectionToolbarFromButtonItems({
    required this.primaryAnchor,
    this.secondaryAnchor,
    required this.buttonItems,
    final TargetPlatform? targetPlatform,
  }) : assert(buttonItems != null),
       _targetPlatform = targetPlatform ?? defaultTargetPlatform;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// The information needed to create each child button of the menu.
  final List<ContextMenuButtonItem> buttonItems;

  /// The platform to use to adaptively generate the toolbar.
  final TargetPlatform _targetPlatform;

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
          targetPlatform: _targetPlatform,
          children: children,
        );
      },
    );
  }
}
