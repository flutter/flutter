// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
/// * [EditableText.getEditableButtonItems], which returns the default
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
  /// {@template flutter.material.AdaptiveTextSelectionToolbar.selectable}
  /// * [AdaptiveTextSelectionToolbar.selectable], which builds the default
  ///   children for content that is selectable but not editable.
  /// {@endtemplate}
  const AdaptiveTextSelectionToolbar({
    super.key,
    required this.children,
    required this.anchors,
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
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectable}
  const AdaptiveTextSelectionToolbar.buttonItems({
    super.key,
    required this.buttonItems,
    required this.anchors,
  }) : children = null;

  /// Create an instance of [AdaptiveTextSelectionToolbar] with the default
  /// children for an editable field.
  ///
  /// If a callback is null, then its corresponding button will not be built.
  ///
  /// See also:
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectable}
  AdaptiveTextSelectionToolbar.editable({
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

  /// Create an instance of [AdaptiveTextSelectionToolbar] with the default
  /// children for an [EditableText].
  ///
  /// See also:
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectable}
  AdaptiveTextSelectionToolbar.editableText({
    super.key,
    required EditableTextState editableTextState,
  }) : children = null,
       buttonItems = editableTextState.contextMenuButtonItems,
       anchors = getAnchorsEditable(editableTextState);

  /// Create an instance of [AdaptiveTextSelectionToolbar] with the default
  /// children for selectable, but not editable, content.
  ///
  /// See also:
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.editable}
  AdaptiveTextSelectionToolbar.selectable({
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

  /// Create an instance of [AdaptiveTextSelectionToolbar] with the default
  /// children for a [SelectableRegion].
  ///
  /// See also:
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.new}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.buttonItems}
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.selectable}
  AdaptiveTextSelectionToolbar.selectableRegion({
    super.key,
    required SelectableRegionState selectableRegionState,
  }) : children = null,
       buttonItems = selectableRegionState.contextMenuButtonItems,
       anchors = getAnchorsSelectable(selectableRegionState);

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
  //final Offset primaryAnchor;

  /// {@template flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  /// The optional secondary location on which to anchor the menu, if it doesn't
  /// fit at [primaryAnchor].
  /// {@endtemplate}
  //final Offset? secondaryAnchor;

  /// {@template flutter.material.AdaptiveTextSelectionToolbar.anchors}
  /// The location on which to anchor the menu.
  /// {@endtemplate}
  final TextSelectionToolbarAnchors anchors;

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
      case TargetPlatform.fuchsia:
      case TargetPlatform.android:
        return buttonItems.map((ContextMenuButtonItem buttonItem) {
          return TextSelectionToolbarTextButton(
            padding: TextSelectionToolbarTextButton.getPadding(buttonIndex++, buttonItems.length),
            onPressed: buttonItem.onPressed,
            child: Text(getButtonLabel(context, buttonItem)),
          );
        });
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

  // TODO(justinmc): Rename getEditableStartGlyphHeight?
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
    /*
    return Rect.fromPoints(
      Offset(
        selectionRect.left + selectionRect.width / 2,
        clampDouble(selectionRect.top, editingRegion.top, editingRegion.bottom),
      ),
      Offset(
        selectionRect.left + selectionRect.width / 2,
        clampDouble(selectionRect.bottom, editingRegion.top, editingRegion.bottom),
      ),
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if ((children != null && children!.isEmpty)
      || (buttonItems != null && buttonItems!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final List<Widget> resultChildren = children != null
        ? children!
        : getAdaptiveButtons(context, buttonItems!).toList();

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        return CupertinoTextSelectionToolbar(
          anchorAbove: anchors.primaryAnchor,
          anchorBelow: anchors.secondaryAnchor == null ? anchors.primaryAnchor : anchors.secondaryAnchor!,
          children: resultChildren,
        );
      case TargetPlatform.android:
        return TextSelectionToolbar(
          anchorAbove: anchors.primaryAnchor,
          anchorBelow: anchors.secondaryAnchor == null ? anchors.primaryAnchor : anchors.secondaryAnchor!,
          children: resultChildren,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return DesktopTextSelectionToolbar(
          anchor: anchors.primaryAnchor,
          children: resultChildren,
        );
      case TargetPlatform.macOS:
        return CupertinoDesktopTextSelectionToolbar(
          anchor: anchors.primaryAnchor,
          children: resultChildren,
        );
    }
  }
}

/// The position information for a text selection toolbar.
///
/// Typically, a menu will attempt to position itself at [primaryAnchor], and
/// if that's not possible, then it will use [secondaryAnchor] instead, if it
/// exists.
@immutable
class TextSelectionToolbarAnchors {
  /// Create an instance of [TextSelectionToolbarAnchors] directly from the
  /// anchor points.
  const TextSelectionToolbarAnchors({
    required this.primaryAnchor,
    this.secondaryAnchor,
  });

  // TODO(justinmc): No longer needed when we get rid of Rects altogether?
  TextSelectionToolbarAnchors.fromRect({
    required final Rect rect,
  }) : primaryAnchor = rect.topLeft,
       secondaryAnchor = rect.bottomRight;

  /// The location that the toolbar should attempt to position itself at.
  ///
  /// If the toolbar doesn't fit at this location, use [secondaryAnchor] if it
  /// exists.
  final Offset primaryAnchor;

  /// The fallback position that should be used if [primaryAnchor] doesn't work.
  final Offset? secondaryAnchor;
}
