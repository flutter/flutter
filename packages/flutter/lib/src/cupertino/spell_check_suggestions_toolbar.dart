// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show SelectionChangedCause, SuggestionSpan;
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'localizations.dart';
import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_button.dart';

/// iOS only shows 3 spell check suggestions in the toolbar.
const int _maxSuggestions = 3;

/// The default spell check suggestions toolbar for iOS.
///
/// Tries to position itself below the [anchors], but if it doesn't fit, then it
/// readjusts to fit above bottom view insets.
class CupertinoSpellCheckSuggestionsToolbar extends StatelessWidget {
  /// Constructs a [CupertinoSpellCheckSuggestionsToolbar].
  const CupertinoSpellCheckSuggestionsToolbar({
    super.key,
    required this.anchors,
    required this.buttonItems,
  });

  /// The location on which to anchor the menu.
  final TextSelectionToolbarAnchors anchors;

  /// The [ContextMenuButtonItem]s that will be turned into the correct button
  /// widgets and displayed in the spell check suggestions toolbar.
  ///
  /// See also:
  ///
  ///  * [AdaptiveTextSelectionToolbar.buttonItems], the list of
  ///    [ContextMenuButtonItem]s that are used to build the buttons of the
  ///    text selection toolbar.
  ///  * [SpellCheckSuggestionsToolbar.buttonItems], the list of
  ///    [ContextMenuButtonItem]s used to build the Material style spell check
  ///    suggestions toolbar.
  final List<ContextMenuButtonItem> buttonItems;

  /// Builds the button items for the toolbar based on the available
  /// spell check suggestions.
  static List<ContextMenuButtonItem>? buildButtonItems(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    // Determine if composing region is misspelled.
    final SuggestionSpan? spanAtCursorIndex =
      editableTextState.findSuggestionSpanAtCursorIndex(
        editableTextState.currentTextEditingValue.selection.baseOffset,
      );

    if (spanAtCursorIndex == null) {
      return null;
    }
    if (spanAtCursorIndex.suggestions.isEmpty) {
      assert(debugCheckHasCupertinoLocalizations(context));
      final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
      return <ContextMenuButtonItem>[
        ContextMenuButtonItem(
          onPressed: () {},
          label: localizations.noSpellCheckReplacementsLabel,
        )
      ];
    }

    final List<ContextMenuButtonItem> buttonItems = <ContextMenuButtonItem>[];

    // Build suggestion buttons.
    int suggestionCount = 0;
    for (final String suggestion in spanAtCursorIndex.suggestions) {
      if (suggestionCount >= _maxSuggestions) {
        break;
      }
      buttonItems.add(ContextMenuButtonItem(
        onPressed: () {
          if (!editableTextState.mounted) {
            return;
          }
          _replaceText(
            editableTextState,
            suggestion,
            spanAtCursorIndex.range,
          );
        },
        label: suggestion,
      ));
      suggestionCount += 1;
    }
    return buttonItems;
  }

  static void _replaceText(EditableTextState editableTextState, String text, TextRange replacementRange) {
    // Replacement cannot be performed if the text is read only or obscured.
    assert(!editableTextState.widget.readOnly && !editableTextState.widget.obscureText);

    final TextEditingValue newValue = editableTextState.textEditingValue.replaced(
      replacementRange,
      text,
    );
    editableTextState.userUpdateTextEditingValue(newValue,SelectionChangedCause.toolbar);

    // Schedule a call to bringIntoView() after renderEditable updates.
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
      if (editableTextState.mounted) {
        editableTextState.bringIntoView(editableTextState.textEditingValue.selection.extent);
      }
    });
    editableTextState.hideToolbar();
    editableTextState.renderEditable.selectWordEdge(cause: SelectionChangedCause.toolbar);
  }

  /// Builds the toolbar buttons based on the [buttonItems].
  List<Widget> _buildToolbarButtons(BuildContext context) {
    return buttonItems.map((ContextMenuButtonItem buttonItem) {
      return CupertinoTextSelectionToolbarButton.buttonItem(
        buttonItem: buttonItem,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = _buildToolbarButtons(context);
    return CupertinoTextSelectionToolbar(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor == null ? anchors.primaryAnchor : anchors.secondaryAnchor!,
      children: children,
    );
  }
}
