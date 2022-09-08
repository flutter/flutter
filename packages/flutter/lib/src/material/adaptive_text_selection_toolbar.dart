// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

import 'desktop_text_selection_toolbar.dart';
import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_buttons_builder.dart';
import 'theme.dart';

/// The default context menu for text selection for the current platform.
///
/// {@template flutter.material.AdaptiveTextSelectionToolbar.contextMenuBuilders}
/// Typically, this widget would be passed to `contextMenuBuilder` in a
/// supported parent widget, such as:
///
/// * [EditableText.contextMenuBuilder]
/// * [TextField.contextMenuBuilder]
/// * [CupertinoTextField.contextMenuBuilder]
/// * [SelectionArea.contextMenuBuilder]
/// * [SelectableText.contextMenuBuilder]
/// {@endtemplate}
///
/// See also:
///
/// * [AdaptiveTextSelectionToolbarButtonItems], which is the same as this
///   widget but takes a list of [ContextMenuButtonItem]s instead of widgets.
/// * [AdaptiveTextSelectionToolbarEditableText], which is the same as this
///   widget but automatically builds the children for an editable text field.
/// * [AdaptiveTextSelectionToolbarSelectableRegion], which is the same as this
///   widget but automatically builds the children for some selectable, non-
///   editable content.
/// {@template flutter.material.AdaptiveTextSelectionToolbar.seeAlso}
/// * [EditableTextContextMenuButtonItemsBuilder], which builds the
///   [ContextMenuButtonItem]s.
/// * [TextSelectionToolbarButtonsBuilder], which builds the button Widgets
///   given [ContextMenuButtonItem]s.
/// * [CupertinoAdaptiveTextSelectionToolbar], which does the same thing as this
///   widget but only for Cupertino context menus.
/// * [TextSelectionToolbar], the default toolbar for Android.
/// * [DesktopTextSelectionToolbar], the default toolbar for desktop platforms
///    other than MacOS.
/// * [CupertinoTextSelectionToolbar], the default toolbar for iOS.
/// * [CupertinoDesktopTextSelectionToolbar], the default toolbar for MacOS.
/// {@endtemplate}
class AdaptiveTextSelectionToolbar extends StatelessWidget {
  /// Create an instance of [AdaptiveTextSelectionToolbar] with the
  /// given [children].
  const AdaptiveTextSelectionToolbar({
    super.key,
    required this.children,
    required this.primaryAnchor,
    this.secondaryAnchor,
  });

  /// The children of the toolbar, typically buttons.
  final List<Widget> children;

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

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (children.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return _AdaptiveTextSelectionToolbarFromChildren(
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor,
      children: children,
    );
  }
}

/// The default context menu for text selection for the current platform with
/// children defined by the given [buttonItems].
///
/// {@macro flutter.material.AdaptiveTextSelectionToolbar.contextMenuBuilders}
///
/// See also:
///
/// * [AdaptiveTextSelectionToolbar], which is the same as this widget but takes
///   a list of children widgets directly.
/// * [AdaptiveTextSelectionToolbarEditableText], which is the same as this
///   widget but automatically builds the children for an editable text field.
/// * [AdaptiveTextSelectionToolbarSelectableRegion], which is the same as this
///   widget but automatically builds the children for some selectable, non-
///   editable content.
/// * [SelectableRegionContextMenuButtonItemsBuilder], which can be used to
///   build the default [ContextMenuButtonType]s for a [SelectableRegion].
/// * [EditableTextContextMenuButtonItemsBuilder], which can be used to
///   build the default [ContextMenuButtonType]s for an [EditableText].
/// {@macro flutter.material.AdaptiveTextSelectionToolbar.seeAlso}
class AdaptiveTextSelectionToolbarButtonItems extends StatelessWidget {
  /// Create an instance of [AdaptiveTextSelectionToolbar] and
  /// adaptively generate the buttons based on the current platform and
  /// [buttonItems].
  const AdaptiveTextSelectionToolbarButtonItems({
    super.key,
    required this.buttonItems,
    required this.primaryAnchor,
    this.secondaryAnchor,
  });

  /// {@template flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// The data that will be used to adaptively generate each child button of the
  /// menu.
  /// {@endtemplate}
  final List<ContextMenuButtonItem> buttonItems;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (buttonItems.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return _AdaptiveTextSelectionToolbarFromButtonItems(
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor,
      buttonItems: buttonItems,
    );
  }
}

/// The default context menu for text selection for the current platform for an
/// editable text field.
///
/// {@macro flutter.material.AdaptiveTextSelectionToolbar.contextMenuBuilders}
///
/// See also:
///
/// * [AdaptiveTextSelectionToolbar], which is the same as this widget but takes
///   a list of children widgets directly.
/// * [AdaptiveTextSelectionToolbarButtonItems], which is the same as this
///   widget but takes a list of [ContextMenuButtonItem]s instead of widgets.
/// * [AdaptiveTextSelectionToolbarSelectableRegion], which is the same as this
///   widget but automatically builds the children for some selectable, non-
///   editable content.
///  * [EditableTextContextMenuButtonItemsBuilder], which builds the default
///    [ContextMenuButtonItem]s for [EditableText] on the platform.
/// {@macro flutter.material.AdaptiveTextSelectionToolbar.seeAlso}
class AdaptiveTextSelectionToolbarEditableText extends StatelessWidget {
  /// Create an instance of [AdaptiveTextSelectionToolbar] and
  /// adaptively generate the buttons based on the current platform and the
  /// given [editableTextState].
  const AdaptiveTextSelectionToolbarEditableText({
    super.key,
    required this.editableTextState,
    required this.primaryAnchor,
    this.secondaryAnchor,
  });

  /// Used to adaptively generate the default buttons for this
  /// [EditableTextState] on the current platform.
  final EditableTextState editableTextState;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  @override
  Widget build(BuildContext context) {
    return EditableTextContextMenuButtonItemsBuilder(
      editableTextState: editableTextState,
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

/// The default context menu for text selection for the current platform for a
/// [SelectableRegion].
///
/// {@macro flutter.material.AdaptiveTextSelectionToolbar.contextMenuBuilders}
///
/// See also:
///
/// * [AdaptiveTextSelectionToolbar], which is the same as this widget but takes
///   a list of children widgets directly.
/// * [AdaptiveTextSelectionToolbarButtonItems], which is the same as this
///   widget but takes a list of [ContextMenuButtonItem]s instead of widgets.
/// * [AdaptiveTextSelectionToolbarEditableText], which is the same as this
///   widget but automatically builds the children for an editable text field.
/// * [SelectableRegionContextMenuButtonItemsBuilder], which builds the
///   default [ContextMenuButtonItem]s for [SelectableRegion] on the
///   current platform.
/// {@macro flutter.material.AdaptiveTextSelectionToolbar.seeAlso}
class AdaptiveTextSelectionToolbarSelectableRegion extends StatelessWidget {
  /// Create an instance of [AdaptiveTextSelectionToolbarSelectableRegion] and
  /// adaptively generate the buttons based on the current platform and the
  /// given [selectableRegionState].
  const AdaptiveTextSelectionToolbarSelectableRegion({
    super.key,
    required this.selectableRegionState,
    required this.primaryAnchor,
    this.secondaryAnchor,
  });

  /// Used to adaptively generate the default buttons for this
  /// [SelectableRegionState] on the current platform.
  final SelectableRegionState selectableRegionState;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  @override
  Widget build(BuildContext context) {
    return SelectableRegionContextMenuButtonItemsBuilder(
      selectableRegionState: selectableRegionState,
      builder: (BuildContext context, List<ContextMenuButtonItem> buttonItems) {
        return AdaptiveTextSelectionToolbarButtonItems(
          primaryAnchor: primaryAnchor,
          secondaryAnchor: secondaryAnchor,
          buttonItems: buttonItems,
        );
      },
    );
  }
}

/// The default text selection toolbar by platform given the [children] for the
/// platform.
class _AdaptiveTextSelectionToolbarFromChildren extends StatelessWidget {
  const _AdaptiveTextSelectionToolbarFromChildren({
    required this.primaryAnchor,
    this.secondaryAnchor,
    required this.children,
  }) : assert(children != null);

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// The children of the toolbar, typically buttons.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (children.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        return CupertinoTextSelectionToolbar(
          anchorAbove: primaryAnchor,
          anchorBelow: secondaryAnchor == null ? primaryAnchor : secondaryAnchor!,
          children: children,
        );
      case TargetPlatform.android:
        return TextSelectionToolbar(
          anchorAbove: primaryAnchor,
          anchorBelow: secondaryAnchor == null ? primaryAnchor : secondaryAnchor!,
          children: children,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return DesktopTextSelectionToolbar(
          anchor: primaryAnchor,
          children: children,
        );
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

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// The information needed to create each child button of the menu.
  final List<ContextMenuButtonItem> buttonItems;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (buttonItems.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return TextSelectionToolbarButtonsBuilder(
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
