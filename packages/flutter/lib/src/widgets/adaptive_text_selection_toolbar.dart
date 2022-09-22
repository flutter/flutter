// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'context_menu_button_item.dart';
import 'editable_text.dart';
import 'text_selection.dart';

/// Returns the [ContextMenuButtonItem]s representing the buttons in this
/// platform's default selection menu for an editable field.
///
/// See also:
///
/// * [AdaptiveTextSelectionToolbar], which builds the toolbar itself, and can
///   take a list of [ContextMenuButtonItem]s with
///   [AdaptiveTextSelectionToolbar.buttonItems].
/// * [getEditableTextButtonItems], which is like this function but specific to
///   [EditableText].
/// * [getSelectableButtonItems], which performs a similar role but for a
///   selection that is not editable.
/// * [AdaptiveTextSelectionToolbar.getAdaptiveButtons], which builds the button
///   Widgets for the current platform given [ContextMenuButtonItem]s.
List<ContextMenuButtonItem> getEditableButtonItems({
  required final bool readOnly,
  required final ClipboardStatus? clipboardStatus,
  required final VoidCallback? onCopy,
  required final VoidCallback? onCut,
  required final VoidCallback? onPaste,
  required final VoidCallback? onSelectAll,
}) {
  // If the paste button is enabled, don't render anything until the state
  // of the clipboard is known, since it's used to determine if paste is
  // shown.
  if (onPaste == null && clipboardStatus == ClipboardStatus.unknown) {
    return <ContextMenuButtonItem>[];
  }

  return <ContextMenuButtonItem>[
    if (onCut != null)
      ContextMenuButtonItem(
        onPressed: onCut,
        type: ContextMenuButtonType.cut,
      ),
    if (onCopy != null)
      ContextMenuButtonItem(
        onPressed: onCopy,
        type: ContextMenuButtonType.copy,
      ),
    if (onPaste != null)
      ContextMenuButtonItem(
        onPressed: onPaste,
        type: ContextMenuButtonType.paste,
      ),
    if (onSelectAll != null)
      ContextMenuButtonItem(
        onPressed: onSelectAll,
        type: ContextMenuButtonType.selectAll,
      ),
  ];
}

/// Returns the [ContextMenuButtonItem]s representing the buttons in this
/// platform's default selection menu for [EditableText].
///
/// See also:
///
/// * [AdaptiveTextSelectionToolbar], which builds the toolbar itself, and can
///   take a list of [ContextMenuButtonItem]s with
///   [AdaptiveTextSelectionToolbar.buttonItems].
/// * [getEditableButtonItems], which is like this function but generic to any
///   editable field.
/// * [SelectableRegionState.getSelectableRegionButtonItems], which is like
///   this function but for a [SelectableRegion] instead of an [EditableText].
/// * [AdaptiveTextSelectionToolbar.getAdaptiveButtons], which builds the button
///   Widgets for the current platform given [ContextMenuButtonItem]s.
List<ContextMenuButtonItem> getEditableTextButtonItems(
  EditableTextState editableTextState,
) {
  return getEditableButtonItems(
    readOnly: editableTextState.widget.readOnly,
    clipboardStatus: editableTextState.clipboardStatus?.value,
    onCopy: editableTextState.copyEnabled
        ? () => editableTextState.copySelection(SelectionChangedCause.toolbar)
        : null,
    onCut: editableTextState.cutEnabled
        ? () => editableTextState.cutSelection(SelectionChangedCause.toolbar)
        : null,
    onPaste: editableTextState.pasteEnabled
        ? () => editableTextState.pasteText(SelectionChangedCause.toolbar)
        : null,
    onSelectAll: editableTextState.selectAllEnabled
        ? () => editableTextState.selectAll(SelectionChangedCause.toolbar)
        : null,
  );
}

/// Returns the [ContextMenuButtonItem]s representing the buttons in this
/// platform's default selection menu.
///
/// See also:
///
/// * [AdaptiveTextSelectionToolbar], which builds the toolbar itself, and can
///   take a list of [ContextMenuButtonItem]s with
///   [AdaptiveTextSelectionToolbar.buttonItems].
/// * [SelectableRegionState.getSelectableRegionButtonItems], which is like
///   this function but specific to [SelectableRegion].
/// * [getEditableTextButtonItems], which performs a similar role but for
///   an editable field's context menu.
/// * [AdaptiveTextSelectionToolbar.getAdaptiveButtons], which builds the button
///   Widgets for the current platform given [ContextMenuButtonItem]s.
List<ContextMenuButtonItem> getSelectableButtonItems({
  required final SelectionGeometry selectionGeometry,
  required final VoidCallback onCopy,
  required final VoidCallback onHideToolbar,
  required final VoidCallback onSelectAll,
}) {
  final bool canCopy = selectionGeometry.hasSelection;
  final bool canSelectAll = selectionGeometry.hasContent;

  // Determine which buttons will appear so that the order and total number is
  // known. A button's position in the menu can slightly affect its
  // appearance.
  return <ContextMenuButtonItem>[
    if (canCopy)
      ContextMenuButtonItem(
        onPressed: () {
          onCopy();
          onHideToolbar();
        },
        type: ContextMenuButtonType.copy,
      ),
    if (canSelectAll)
      ContextMenuButtonItem(
        onPressed: () {
          onSelectAll();
          onHideToolbar();
        },
        type: ContextMenuButtonType.selectAll,
      ),
  ];
}
