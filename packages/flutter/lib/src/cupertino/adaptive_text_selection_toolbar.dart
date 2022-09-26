// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'desktop_text_selection_toolbar.dart';
import 'desktop_text_selection_toolbar_button.dart';
import 'localizations.dart';
import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_button.dart';

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
/// * [AdaptiveTextSelectionToolbar], which does the same thing as this widget
///   but for all platforms, not just the Cupertino-styled platforms.
/// * [CupertinoAdaptiveTextSelectionToolbar.getAdaptiveButtons], which builds
///   the Cupertino button Widgets for the current platform given
///   [ContextMenuButtonItem]s.
class CupertinoAdaptiveTextSelectionToolbar extends StatelessWidget {
  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] with the
  /// given [children].
  ///
  /// See also:
  ///
  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.buttonItems}
  /// * [CupertinoAdaptiveTextSelectionToolbar.buttonItems], which takes a list
  ///   of [ContextMenuButtonItem]s instead of [children] widgets.
  /// {@endtemplate}
  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editable}
  /// * [CupertinoAdaptiveTextSelectionToolbar.editable], which builds the
  ///   default Cupertino children for an editable field.
  /// {@endtemplate}
  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  /// * [CupertinoAdaptiveTextSelectionToolbar.selectable], which builds the
  ///   Cupertino children for content that is selectable but not editable.
  /// {@endtemplate}
  const CupertinoAdaptiveTextSelectionToolbar({
    super.key,
    required this.children,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : buttonItems = null;

  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] whose
  /// children will be built from the given [buttonItems].
  ///
  /// See also:
  ///
  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.new}
  /// * [CupertinoAdaptiveTextSelectionToolbar.new], which takes the children
  ///   directly as a list of widgets.
  /// {@endtemplate}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editable}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  const CupertinoAdaptiveTextSelectionToolbar.buttonItems({
    super.key,
    required this.buttonItems,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : children = null;

  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] with the
  /// default children for an editable field.
  ///
  /// If a callback is null, then its corresponding button will not be built.
  ///
  /// See also:
  ///
  /// * [AdaptiveTextSelectionToolbar.editable], which is similar to this but
  ///   includes Material and Cupertino toolbars.
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  CupertinoAdaptiveTextSelectionToolbar.editable({
    super.key,
    required ClipboardStatus clipboardStatus,
    required VoidCallback? onCopy,
    required VoidCallback? onCut,
    required VoidCallback? onPaste,
    required VoidCallback? onSelectAll,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : children = null,
       buttonItems = getEditableButtonItems(
         clipboardStatus: clipboardStatus,
         onCopy: onCopy,
         onCut: onCut,
         onPaste: onPaste,
         onSelectAll: onSelectAll,
       );

  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] with the
  /// default children for selectable, but not editable, content.
  ///
  /// See also:
  ///
  /// * [AdaptiveTextSelectionToolbar.selectable], which is similar to this but
  ///   includes Material and Cupertino toolbars.
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editable}
  CupertinoAdaptiveTextSelectionToolbar.selectable({
    super.key,
    required VoidCallback onCopy,
    required VoidCallback onSelectAll,
    required SelectionGeometry selectionGeometry,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : children = null,
       buttonItems = getSelectableButtonItems(
         selectionGeometry: selectionGeometry,
         onCopy: onCopy,
         onSelectAll: onSelectAll,
       );

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// The children of the toolbar, typically buttons.
  final List<Widget>? children;

  /// The [ContextMenuButtonItem]s that will be turned into the correct button
  /// widgets for the current platform.
  final List<ContextMenuButtonItem>? buttonItems;

  /// Returns the default button label String for the button of the given
  /// [ContextMenuButtonItem]'s [ContextMenuButtonType].
  static String getButtonLabel(BuildContext context, ContextMenuButtonItem buttonItem) {
    if (buttonItem.label != null) {
      return buttonItem.label!;
    }

    assert(debugCheckHasCupertinoLocalizations(context));
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
    switch (buttonItem.type) {
      case ContextMenuButtonType.cut:
        return localizations.cutButtonLabel;
      case ContextMenuButtonType.copy:
        return localizations.copyButtonLabel;
      case ContextMenuButtonType.paste:
        return localizations.pasteButtonLabel;
      case ContextMenuButtonType.selectAll:
        return localizations.selectAllButtonLabel;
      case ContextMenuButtonType.custom:
        return '';
    }
  }

  /// Returns a List of Widgets generated by turning [buttonItems] into the
  /// the default context menu buttons for Cupertino on the current platform.
  ///
  /// This is useful when building a text selection toolbar with the default
  /// button appearance for the given platform, but where the toolbar and/or the
  /// button actions and labels may be custom.
  ///
  /// Does not build Material buttons. On non-Apple platforms, Cupertino buttons
  /// will still be used, because the Cupertino library does not access the
  /// Material library. To get the native-looking buttons on every platform, use
  /// use [AdaptiveTextSelectionToolbar.getAdaptiveButtons] in the Material
  /// library.
  ///
  /// See also:
  ///
  /// * [AdaptiveTextSelectionToolbar.getAdaptiveButtons], which is the Material
  ///   equivalent of this class and builds only the Material buttons.
  static Iterable<Widget> getAdaptiveButtons(BuildContext context, List<ContextMenuButtonItem> buttonItems) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return buttonItems.map((ContextMenuButtonItem buttonItem) {
          return CupertinoTextSelectionToolbarButton.text(
            onPressed: buttonItem.onPressed,
            text: getButtonLabel(context, buttonItem),
          );
        });
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return buttonItems.map((ContextMenuButtonItem buttonItem) {
          return CupertinoDesktopTextSelectionToolbarButton.text(
            context: context,
            onPressed: buttonItem.onPressed,
            text: getButtonLabel(context, buttonItem),
          );
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if ((children?.isEmpty ?? false) || (buttonItems?.isEmpty ?? false)) {
      return const SizedBox.shrink();
    }

    final List<Widget> resultChildren = children != null
        ? children!
        : getAdaptiveButtons(context, buttonItems!).toList();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return CupertinoTextSelectionToolbar(
          anchorAbove: primaryAnchor,
          anchorBelow: secondaryAnchor == null ? primaryAnchor : secondaryAnchor!,
          children: resultChildren,
        );
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return CupertinoDesktopTextSelectionToolbar(
          anchor: primaryAnchor,
          children: resultChildren,
        );
    }
  }
}
