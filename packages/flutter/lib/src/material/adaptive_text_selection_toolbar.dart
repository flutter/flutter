// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'debug.dart';
import 'desktop_text_selection_toolbar.dart';
import 'desktop_text_selection_toolbar_button.dart';
import 'material_localizations.dart';
import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_text_button.dart';
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
/// * [getEditableButtonItems], which returns the default
///   [ContextMenuButtonItem]s for [EditableText] on the platform.
/// * [AdaptiveTextSelectionToolbar.getAdaptiveButtons], which builds the button
///   Widgets for the current platform given [ContextMenuButtonItem]s.
/// * [CupertinoAdaptiveTextSelectionToolbar], which does the same thing as this
///   widget but only for Cupertino context menus.
/// * [TextSelectionToolbar], the default toolbar for Android.
/// * [DesktopTextSelectionToolbar], the default toolbar for desktop platforms
///    other than MacOS.
/// * [CupertinoTextSelectionToolbar], the default toolbar for iOS.
/// * [CupertinoDesktopTextSelectionToolbar], the default toolbar for MacOS.
class AdaptiveTextSelectionToolbar extends StatelessWidget {
  /// Create an instance of [AdaptiveTextSelectionToolbar] with the
  /// given [children].
  ///
  /// See also:
  ///
  /// {@template flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// * [AdaptiveTextSelectionToolbar.buttonItems], which takes a list of
  ///   [ContextMenuButtonItem]s instead of [children] widgets.
  /// {@endtemplate}
  /// {@template flutter.material.AdaptiveTextSelectionToolbar.editable}
  /// * [AdaptiveTextSelectionToolbar.editable], which builds the default
  ///   children for an editable field.
  /// {@endtemplate}
  /// {@template flutter.material.AdaptiveTextSelectionToolbar.editableText}
  /// * [AdaptiveTextSelectionToolbar.editableText], which builds the default
  ///   children for an [EditableText].
  /// {@endtemplate}
  /// {@template flutter.material.AdaptiveTextSelectionToolbar.selectable}
  /// * [AdaptiveTextSelectionToolbar.selectable], which builds the default
  ///   children for content that is selectable but not editable.
  /// {@endtemplate}
  /// {@template flutter.material.AdaptiveTextSelectionToolbar.selectableRegion}
  /// * [AdaptiveTextSelectionToolbar.selectableRegion], which builds the default
  ///   children for a [SelectableRegion].
  /// {@endtemplate}
  const AdaptiveTextSelectionToolbar({
    super.key,
    required this.children,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : buttonItems = null;

  /// Create an instance of [AdaptiveTextSelectionToolbar] whose children will
  /// be built from the given [buttonItems].
  ///
  /// See also:
  ///
  /// {@template flutter.material.AdaptiveTextSelectionToolbar.new}
  /// * [AdaptiveTextSelectionToolbar.new], which takes the children directly as
  ///   a list of widgets.
  /// {@endtemplate}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.editable}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.editableText}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectable}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectableRegion}
  const AdaptiveTextSelectionToolbar.buttonItems({
    super.key,
    required this.buttonItems,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : children = null;

  /// Create an instance of [AdaptiveTextSelectionToolbar] with the default
  /// children for an editable field.
  ///
  /// See also:
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.editableText}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectable}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectableRegion}
  AdaptiveTextSelectionToolbar.editable({
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
  }) : children = null,
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

  /// Create an instance of [AdaptiveTextSelectionToolbar] with the default
  /// children for an [EditableText].
  ///
  /// See also:
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.editable}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectable}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectableRegion}
  AdaptiveTextSelectionToolbar.editableText({
    super.key,
    required EditableTextState editableTextState,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : children = null,
       buttonItems = getEditableTextButtonItems(editableTextState);

  /// Create an instance of [AdaptiveTextSelectionToolbar] with the default
  /// children for selectable, but not editable, content.
  ///
  /// See also:
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.editable}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.editableText}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectableRegion}
  AdaptiveTextSelectionToolbar.selectable({
    super.key,
    required VoidCallback onCopy,
    required VoidCallback onHideToolbar,
    required VoidCallback onSelectAll,
    required SelectionGeometry selectionGeometry,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : children = null,
       buttonItems = getSelectableButtonItems(
         selectionGeometry: selectionGeometry,
         onCopy: onCopy,
         onHideToolbar: onHideToolbar,
         onSelectAll: onSelectAll,
       );

  /// Create an instance of [AdaptiveTextSelectionToolbar] with the default
  /// children for a [SelectableRegion].
  ///
  /// See also:
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.editable}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.editableText}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectable}
  AdaptiveTextSelectionToolbar.selectableRegion({
    super.key,
    required SelectableRegionState selectableRegionState,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : children = null,
       buttonItems = selectableRegionState.getSelectableRegionButtonItems();

  /// {@template flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// The [ContextMenuButtonItem]s that will be turned into the correct button
  /// widgets for the current platform.
  /// {@endtemplate}
  final List<ContextMenuButtonItem>? buttonItems;

  /// The children of the toolbar, typically buttons.
  final List<Widget>? children;

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

  /// Returns the default button label String for the button of the given
  /// [ContextMenuButtonType] on any platform.
  static String getButtonLabel(BuildContext context, ContextMenuButtonItem buttonItem) {
    if (buttonItem.label != null) {
      return buttonItem.label!;
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoAdaptiveTextSelectionToolbar.getButtonLabel(
          context,
          buttonItem,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        assert(debugCheckHasMaterialLocalizations(context));
        final MaterialLocalizations localizations = MaterialLocalizations.of(context);
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
  }

  /// Returns a List of Widgets generated by turning [buttonItems] into the
  /// the default context menu buttons for the current platform.
  ///
  /// This is useful when building a text selection toolbar with the default
  /// button appearance for the given platform, but where the toolbar and/or the
  /// button actions and labels may be custom.
  ///
  /// See also:
  ///
  /// * [CupertinoAdaptiveTextSelectionToolbar.getAdaptiveButtons], which is the
  ///   Cupertino equivalent of this class and builds only the Cupertino
  ///   buttons.
  static Iterable<Widget> getAdaptiveButtons(BuildContext context, List<ContextMenuButtonItem> buttonItems) {
    int buttonIndex = 0;
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        return buttonItems.map((ContextMenuButtonItem buttonItem) {
            return CupertinoTextSelectionToolbarButton.text(
              onPressed: buttonItem.onPressed,
              text: getButtonLabel(context, buttonItem),
            );
          });
      case TargetPlatform.android:
        return buttonItems.map((ContextMenuButtonItem buttonItem) {
          return TextSelectionToolbarTextButton(
            padding: TextSelectionToolbarTextButton.getPadding(buttonIndex++, buttonItems.length),
            onPressed: buttonItem.onPressed,
            child: Text(getButtonLabel(context, buttonItem)),
          );
        });
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return buttonItems.map((ContextMenuButtonItem buttonItem) {
          return DesktopTextSelectionToolbarButton.text(
            context: context,
            onPressed: buttonItem.onPressed,
            text: getButtonLabel(context, buttonItem),
          );
        });
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
      children: resultChildren,
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
