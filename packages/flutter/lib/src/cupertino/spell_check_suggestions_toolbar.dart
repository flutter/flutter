// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart' show SuggestionSpan;
import 'package:flutter/widgets.dart';

import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_button.dart';

/// The default spell check suggestions toolbar for Android.
///
/// Tries to position itself below the [anchor], but if it doesn't fit, then it
/// readjusts to fit above bottom view insets.
class CupertinoSpellCheckSuggestionsToolbar extends StatelessWidget {
  /// Constructs a [SpellCheckSuggestionsToolbar].
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
      return <ContextMenuButtonItem>[
        ContextMenuButtonItem(
          onPressed: () {},
          label: 'No Replacements Found',
        )
      ];
    }

    final List<ContextMenuButtonItem> buttonItems = <ContextMenuButtonItem>[];

    // Build suggestion buttons.
    int suggestionCount = 0;
    for (final String suggestion in spanAtCursorIndex.suggestions) {
      // iOS only shows 3 spell check suggestions in the toolbar.
      if (suggestionCount < 3) {
        buttonItems.add(ContextMenuButtonItem(
          onPressed: () {
            editableTextState
              .replaceComposingRegion(
                cause: SelectionChangedCause.toolbar,
                text: suggestion,
                composingRegionRange: spanAtCursorIndex.range,
                shouldSelectWordEdgeAfterReplacement: true,
            );
          },
          label: suggestion,
        ));
      }
      suggestionCount += 1;
    }

    return buttonItems;
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
