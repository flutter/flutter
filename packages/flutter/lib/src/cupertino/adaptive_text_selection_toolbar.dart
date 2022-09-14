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
/// * [getEditableTextButtonItems], which generates the default
///   [ContextMenuButtonItem]s for a context menu displaying inside of an
///   [EditableText] on the current platform.
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
  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editableText}
  /// * [CupertinoAdaptiveTextSelectionToolbar.editableText], which builds the
  ///   default Cupertino children for an [EditableText].
  /// {@endtemplate}
  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  /// * [CupertinoAdaptiveTextSelectionToolbar.selectable], which builds the
  ///   Cupertino children for content that is selectable but not editable.
  /// {@endtemplate}
  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectableRegion}
  /// * [CupertinoAdaptiveTextSelectionToolbar.selectableRegion], which builds
  ///   the default Cupertino children for a [SelectableRegion].
  /// {@endtemplate}
  const CupertinoAdaptiveTextSelectionToolbar({
    super.key,
    required this.children,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : buttonItems = null,
       _targetPlatform = targetPlatform;

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
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editableText}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectableRegion}
  const CupertinoAdaptiveTextSelectionToolbar.buttonItems({
    super.key,
    required this.buttonItems,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : children = null,
       _targetPlatform = targetPlatform;

  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] with the
  /// default children for an editable field.
  ///
  /// See also:
  ///
  /// * [AdaptiveTextSelectionToolbar.editable], which is similar to this but
  ///   includes Material and Cupertino toolbars.
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editableText}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectableRegion}
  CupertinoAdaptiveTextSelectionToolbar.editable({
    super.key,
    required bool readOnly,
    required ClipboardStatus clipboardStatus,
    required bool copyEnabled,
    required bool cutEnabled,
    required bool pasteEnabled,
    required bool selectAllEnabled,
    required VoidCallback onCopy,
    required VoidCallback onCut,
    required VoidCallback onPaste,
    required VoidCallback onSelectAll,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : children = null,
       _targetPlatform = targetPlatform,
       buttonItems = getEditableButtonItems(
         readOnly: readOnly,
         clipboardStatus: clipboardStatus,
         copyEnabled: copyEnabled,
         cutEnabled: cutEnabled,
         pasteEnabled: pasteEnabled,
         selectAllEnabled: selectAllEnabled,
         onCopy: onCopy,
         onCut: onCut,
         onPaste: onPaste,
         onSelectAll: onSelectAll,
       );

  /// Create an instance of [CupertinoAdaptiveTextSelectionToolbar] with the
  /// default children for an [EditableText].
  ///
  /// See also:
  ///
  /// * [AdaptiveTextSelectionToolbar.editableText], which is similar to this
  ///   but includes Material and Cupertino toolbars.
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editable}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectableRegion}
  CupertinoAdaptiveTextSelectionToolbar.editableText({
    super.key,
    required EditableTextState editableTextState,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : children = null,
       buttonItems = getEditableTextButtonItems(editableTextState),
       _targetPlatform = targetPlatform;

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
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editableText}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectableRegion}
  CupertinoAdaptiveTextSelectionToolbar.selectable({
    super.key,
    required VoidCallback onCopy,
    required VoidCallback onHideToolbar,
    required VoidCallback onSelectAll,
    required SelectionGeometry selectionGeometry,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : children = null,
       buttonItems = getSelectableButtonItems(
         selectionGeometry: selectionGeometry,
         onCopy: onCopy,
         onHideToolbar: onHideToolbar,
         onSelectAll: onSelectAll,
       ),
       _targetPlatform = targetPlatform;

  /// Create an instance of [AdaptiveTextSelectionToolbar] with the default
  /// children for a [SelectableRegion].
  ///
  /// See also:
  ///
  /// * [AdaptiveTextSelectionToolbar.selectableRegion], which is similar to
  ///   this but includes Material and Cupertino toolbars.
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editable}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editableText}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  CupertinoAdaptiveTextSelectionToolbar.selectableRegion({
    super.key,
    required SelectableRegionState selectableRegionState,
    required this.primaryAnchor,
    this.secondaryAnchor,
    final TargetPlatform? targetPlatform,
  }) : children = null,
       buttonItems = selectableRegionState.getSelectableRegionButtonItems(),
       _targetPlatform = targetPlatform;

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
    if ((children != null && children!.isEmpty)
      || (buttonItems != null && buttonItems!.isEmpty)) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    final List<Widget> resultChildren = children != null
        ? children!
        : getAdaptiveButtons(context, buttonItems!).toList();

    return _AdaptiveTextSelectionToolbarFromChildren(
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor,
      targetPlatform: targetPlatform,
      children: resultChildren,
      /*
      children: <Widget>[
        CupertinoTextSelectionToolbarButton.text(
          text: 'one',
          onPressed: () {},
        ),
        const Text('two'),
        const Text('three'),
        const Text('four'),
      ],
      */
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
      case TargetPlatform.fuchsia:
        return CupertinoTextSelectionToolbar(
          anchorAbove: primaryAnchor,
          anchorBelow: secondaryAnchor == null ? primaryAnchor : secondaryAnchor!,
          children: children,
        );
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
