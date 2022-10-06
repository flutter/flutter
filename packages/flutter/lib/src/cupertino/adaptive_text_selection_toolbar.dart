// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show clampDouble, defaultTargetPlatform;
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
  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editableText}
  /// * [CupertinoAdaptiveTextSelectionToolbar.editableText], which builds the
  ///   default Cupertino children for an [EditableText].
  /// {@endtemplate}
  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  /// * [CupertinoAdaptiveTextSelectionToolbar.selectable], which builds the
  ///   Cupertino children for content that is selectable but not editable.
  /// {@endtemplate}
  const CupertinoAdaptiveTextSelectionToolbar({
    super.key,
    required this.children,
    required this.anchors,
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
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editableText}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  const CupertinoAdaptiveTextSelectionToolbar.buttonItems({
    super.key,
    required this.buttonItems,
    required this.anchors,
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
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editableText}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  CupertinoAdaptiveTextSelectionToolbar.editable({
    super.key,
    required ClipboardStatus clipboardStatus,
    required VoidCallback? onCopy,
    required VoidCallback? onCut,
    required VoidCallback? onPaste,
    required VoidCallback? onSelectAll,
    required this.anchors,
  }) : children = null,
       buttonItems = EditableText.getEditableButtonItems(
         clipboardStatus: clipboardStatus,
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
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.editable}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.selectable}
  CupertinoAdaptiveTextSelectionToolbar.editableText({
    super.key,
    required EditableTextState editableTextState,
  }) : children = null,
       buttonItems = editableTextState.contextMenuButtonItems,
       anchors = getAnchorsEditable(editableTextState);

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
  CupertinoAdaptiveTextSelectionToolbar.selectable({
    super.key,
    required VoidCallback onCopy,
    required VoidCallback onSelectAll,
    required SelectionGeometry selectionGeometry,
    required this.anchors,
  }) : children = null,
       buttonItems = SelectableRegion.getSelectableButtonItems(
         selectionGeometry: selectionGeometry,
         onCopy: onCopy,
         onSelectAll: onSelectAll,
       );

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.anchors}
  final TextSelectionToolbarAnchors anchors;

  /// The children of the toolbar, typically buttons.
  final List<Widget>? children;

  /// The [ContextMenuButtonItem]s that will be turned into the correct button
  /// widgets for the current platform.
  final List<ContextMenuButtonItem>? buttonItems;

  /// Gets the line height at the start of the selection for the given
  /// [EditableTextState].
  static double _getStartGlyphHeight(EditableTextState editableTextState) {
    final RenderEditable renderEditable = editableTextState.renderEditable;
    final InlineSpan span = renderEditable.text!;
    final String prevText = span.toPlainText();
    final String currText = editableTextState.textEditingValue.text;
    final TextSelection selection = editableTextState.textEditingValue.selection;
    final int firstSelectedGraphemeExtent;
    Rect? startHandleRect;
    // Only calculate handle rects if the text in the previous frame
    // is the same as the text in the current frame. This is done because
    // widget.renderObject contains the renderEditable from the previous frame.
    // If the text changed between the current and previous frames then
    // widget.renderObject.getRectForComposingRange might fail. In cases where
    // the current frame is different from the previous we fall back to
    // renderObject.preferredLineHeight.
    if (prevText == currText && selection != null && selection.isValid && !selection.isCollapsed) {
      final String selectedGraphemes = selection.textInside(currText);
      firstSelectedGraphemeExtent = selectedGraphemes.characters.first.length;
      startHandleRect = renderEditable.getRectForComposingRange(TextRange(start: selection.start, end: selection.start + firstSelectedGraphemeExtent));
    }
    return startHandleRect?.height ?? renderEditable.preferredLineHeight;
  }

  /// Gets the line height at the end of the selection for the given
  /// [EditableTextState].
  static double _getEndGlyphHeight(EditableTextState editableTextState) {
    final RenderEditable renderEditable = editableTextState.renderEditable;
    final TextSelection selection = editableTextState.textEditingValue.selection;
    final InlineSpan span = renderEditable.text!;
    final String prevText = span.toPlainText();
    final String currText = editableTextState.textEditingValue.text;
    final int lastSelectedGraphemeExtent;
    Rect? endHandleRect;
    // See the explanation in _getStartGlyphHeight.
    if (prevText == currText && selection != null && selection.isValid && !selection.isCollapsed) {
      final String selectedGraphemes = selection.textInside(currText);
      lastSelectedGraphemeExtent = selectedGraphemes.characters.last.length;
      endHandleRect = renderEditable.getRectForComposingRange(TextRange(start: selection.end - lastSelectedGraphemeExtent, end: selection.end));
    }
    return endHandleRect?.height ?? renderEditable.preferredLineHeight;
  }

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

  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.getAnchorsEditable}
  /// Returns the location anchors for the text selection toolbar for the given
  /// [EditableTextState].
  /// {@endtemplate}
  static TextSelectionToolbarAnchors getAnchorsEditable(EditableTextState editableTextState) {
    if (editableTextState.renderEditable.lastSecondaryTapDownPosition != null) {
      return TextSelectionToolbarAnchors(
        primaryAnchor: editableTextState.renderEditable.lastSecondaryTapDownPosition!,
      );
    }
    final RenderBox renderBox = editableTextState.renderEditable;
    final double startGlyphHeight = _getStartGlyphHeight(editableTextState);
    final double endGlyphHeight = _getEndGlyphHeight(editableTextState);
    final TextSelection selection = editableTextState.textEditingValue.selection;
    final List<TextSelectionPoint> points =
        editableTextState.renderEditable.getEndpointsForSelection(selection);
    return _getAnchors(renderBox, startGlyphHeight, endGlyphHeight, points);
  }

  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.getAnchorsSelectable}
  /// Returns the location anchors for the text selection toolbar for the given
  /// [EditableTextState].
  /// {@endtemplate}
  static TextSelectionToolbarAnchors getAnchorsSelectable(SelectableRegionState selectableRegionState) {
    if (selectableRegionState.lastSecondaryTapDownPosition != null) {
      return TextSelectionToolbarAnchors(
        primaryAnchor: selectableRegionState.lastSecondaryTapDownPosition!,
      );
    }
    final RenderBox renderBox = selectableRegionState.context.findRenderObject()! as RenderBox;
    return _getAnchors(
      renderBox,
      selectableRegionState.startGlyphHeight,
      selectableRegionState.endGlyphHeight,
      selectableRegionState.selectionEndpoints,
    );
  }

  /// Gets the anchor locations generically for [EditableTextState] or
  /// [SelectableTextState].
  static TextSelectionToolbarAnchors _getAnchors(RenderBox renderBox, double startGlyphHeight, double endGlyphHeight, List<TextSelectionPoint> selectionEndpoints) {
    final Rect editingRegion = Rect.fromPoints(
      renderBox.localToGlobal(Offset.zero),
      renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero)),
    );
    final bool isMultiline = selectionEndpoints.last.point.dy - selectionEndpoints.first.point.dy >
        endGlyphHeight / 2;

    final Rect selectionRect = Rect.fromLTRB(
      isMultiline
          ? editingRegion.left
          : editingRegion.left + selectionEndpoints.first.point.dx,
      editingRegion.top + selectionEndpoints.first.point.dy - startGlyphHeight,
      isMultiline
          ? editingRegion.right
          : editingRegion.left + selectionEndpoints.last.point.dx,
      editingRegion.top + selectionEndpoints.last.point.dy,
    );

    return TextSelectionToolbarAnchors(
      primaryAnchor: Offset(
        selectionRect.left + selectionRect.width / 2,
        clampDouble(selectionRect.top, editingRegion.top, editingRegion.bottom),
      ),
      secondaryAnchor: Offset(
        selectionRect.left + selectionRect.width / 2,
        clampDouble(selectionRect.bottom, editingRegion.top, editingRegion.bottom),
      ),
    );
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
          anchorAbove: anchors.primaryAnchor,
          anchorBelow: anchors.secondaryAnchor == null ? anchors.primaryAnchor : anchors.secondaryAnchor!,
          children: resultChildren,
        );
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return CupertinoDesktopTextSelectionToolbar(
          anchor: anchors.primaryAnchor,
          children: resultChildren,
        );
    }
  }
}
