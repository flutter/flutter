// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart';

import 'desktop_text_selection.dart';
import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_buttons_builder.dart';

/// The default Cupertino context menu for text selection for the current
/// platform.
///
/// Builds the mobile Cupertino context menu for all mobile platforms, not just
/// iOS, and builds the desktop Cupertino context menu for all desktop
/// platforms, not just MacOS. For a widget that builds all context menus, see
/// [DefaultTextSelectionToolbar].
///
/// The children can be customized using the [children] or [buttonDatas]
/// parameters. If neither is given, then the default buttons will be used.
///
/// See also:
///
/// * [TextSelectionToolbarButtonDatasBuilder], which builds the
///   [ContextMenuButtonData]s.
/// * [TextSelectionToolbarButtonsBuilder], which builds the button Widgets
///   given [ContextMenuButtonData]s.
/// * [DefaultTextSelectionToolbar], which does the same thing as this widget
///   but for all platforms.
class DefaultCupertinoTextSelectionToolbar extends StatelessWidget {
  /// Create an instance of [DefaultCupertinoTextSelectionToolbar].
  const DefaultCupertinoTextSelectionToolbar({
    super.key,
    required this.primaryAnchor,
    this.buttonDatas,
    this.children,
    this.editableTextState,
    TargetPlatform? targetPlatform,
    this.secondaryAnchor,
  }) : assert(
         buttonDatas == null || children == null,
         'No need for both buttonDatas and children, use one or the other, or neither.',
       ),
       assert(
         !(buttonDatas == null && children == null && editableTextState == null),
         'If not providing buttonDatas or children, provide editableTextState to generate them.',
       ),
       _targetPlatform = targetPlatform;

  /// The main location on which to anchor the menu.
  ///
  /// Optionally, [secondaryAnchor] can be provided as an alternative anchor
  /// location if the menu doesn't fit here.
  final Offset primaryAnchor;

  /// The optional secondary location on which to anchor the menu, if it doesn't
  /// fit at [primaryAnchor].
  final Offset? secondaryAnchor;

  /// The information needed to create each child button of the menu.
  ///
  /// If provided, [children] cannot also be provided.
  final List<ContextMenuButtonData>? buttonDatas;

  /// Used to generate the default buttons for the platform in the case that
  /// [children] and [buttonDatas] are not provided.
  final EditableTextState? editableTextState;

  /// The platform to base the toolbar on.
  ///
  /// If null, then [defaultTargetPlatform] will be used.
  TargetPlatform get targetPlatform => _targetPlatform ?? defaultTargetPlatform;

  final TargetPlatform? _targetPlatform;

  /// The children of the toolbar.
  ///
  /// If provided, buttonDatas cannot also be provided.
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if ((children?.isEmpty ?? false) || (buttonDatas?.isEmpty ?? false)) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    if (children?.isNotEmpty ?? false) {
      return _DefaultTextSelectionToolbarFromChildren(
        primaryAnchor: primaryAnchor,
        secondaryAnchor: secondaryAnchor,
        children: children!,
      );
    }

    if (buttonDatas?.isNotEmpty ?? false) {
      return _DefaultTextSelectionToolbarFromButtonDatas(
        primaryAnchor: primaryAnchor,
        secondaryAnchor: secondaryAnchor,
        buttonDatas: buttonDatas!,
      );
    }

    return TextSelectionToolbarButtonDatasBuilder(
      editableTextState: editableTextState!,
      targetPlatform: targetPlatform,
      builder: (BuildContext context, List<ContextMenuButtonData> buttonDatas) {
        return _DefaultTextSelectionToolbarFromButtonDatas(
          primaryAnchor: primaryAnchor,
          secondaryAnchor: secondaryAnchor,
          buttonDatas: buttonDatas,
        );
      },
    );
  }
}

/// The default text selection toolbar by platform given the [children] for the
/// platform, for Cupertino.
class _DefaultTextSelectionToolbarFromChildren extends StatelessWidget {
  const _DefaultTextSelectionToolbarFromChildren({
    required this.primaryAnchor,
    this.secondaryAnchor,
    required this.children,
  }) : assert(children != null);

  /// The main location on which to anchor the menu.
  ///
  /// Optionally, [secondaryAnchor] can be provided as an alternative anchor
  /// location if the menu doesn't fit here.
  final Offset primaryAnchor;

  /// The optional secondary location on which to anchor the menu, if it doesn't
  /// fit at [primaryAnchor].
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

/// The default text selection toolbar by platform given [buttonDatas]
/// representing the children for the platform.
class _DefaultTextSelectionToolbarFromButtonDatas extends StatelessWidget {
  const _DefaultTextSelectionToolbarFromButtonDatas({
    required this.primaryAnchor,
    this.secondaryAnchor,
    required this.buttonDatas,
  }) : assert(buttonDatas != null);

  /// The main location on which to anchor the menu.
  ///
  /// Optionally, [secondaryAnchor] can be provided as an alternative anchor
  /// location if the menu doesn't fit here.
  final Offset primaryAnchor;

  /// The optional secondary location on which to anchor the menu, if it doesn't
  /// fit at [primaryAnchor].
  final Offset? secondaryAnchor;

  /// The information needed to create each child button of the menu.
  final List<ContextMenuButtonData> buttonDatas;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (buttonDatas.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return CupertinoTextSelectionToolbarButtonsBuilder(
      buttonDatas: buttonDatas,
      builder: (BuildContext context, List<Widget> children) {
        return _DefaultTextSelectionToolbarFromChildren(
          primaryAnchor: primaryAnchor,
          secondaryAnchor: secondaryAnchor,
          children: children,
        );
      },
    );
  }
}
