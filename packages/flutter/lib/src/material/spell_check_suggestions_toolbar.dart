// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/services.dart' show SuggestionSpan;
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'spell_check_suggestions_toolbar_layout_delegate.dart';
import 'text_selection_toolbar_text_button.dart';

// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;
const double _kHandleSize = 22.0;

// Padding between the toolbar and the anchor.
const double _kToolbarContentDistanceBelow = _kHandleSize - 3.0;

// The default height of the MaterialSpellCheckSuggestionsToolbar, which
// assumes there are the maximum number of spell check suggestions available, 3.
const double _kDefaultToolbarHeight = 193.0;

/// The default spell check suggestions toolbar for Android.
///
/// Tries to position itself below the [anchor], but if it doesn't fit, then it
/// readjusts to fit above bottom view insets.
class MaterialSpellCheckSuggestionsToolbar extends StatelessWidget {
  /// Constructs a [MaterialSpellCheckSuggestionsToolbar].
  const MaterialSpellCheckSuggestionsToolbar({
    super.key,
    required this.anchor,
    required this.buttonItems,
  }) : assert(buttonItems != null);

  /// {@template flutter.material.MaterialSpellCheckSuggestionsToolbar.anchor}
  /// The focal point below which the toolbar attempts to position itself.
  /// {@endtemplate}
  final Offset anchor;

  /// The buttons that will be displayed in the spell check suggestions toolbar.
  final List<ContextMenuButtonItem> buttonItems;

  /// Builds the default Android Material spell check suggestions toolbar.
  static Widget _spellCheckSuggestionsToolbarBuilder(BuildContext context, Widget child) {
    return _MaterialSpellCheckSuggestionsToolbarContainer(
      child: child,
    );
  }

  /// Builds the button items for the toolbar based on the available
  /// spell check suggestions.
  static List<ContextMenuButtonItem> buildButtonItems(
    BuildContext context,
    EditableTextState editableTextState,
    SuggestionSpan suggestionSpan,
  ) {
    final List<ContextMenuButtonItem> buttonItems = <ContextMenuButtonItem>[];

    // Build suggestion buttons.
    for (final String suggestion in suggestionSpan.suggestions) {
      buttonItems.add(ContextMenuButtonItem(
        onPressed: () {
          editableTextState
            .replaceSelection(
              SelectionChangedCause.toolbar,
              suggestion,
              suggestionSpan.range.start,
              suggestionSpan.range.end,
          );
        },
        label: suggestion,
      ));
    }

    // Build delete button.
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final ContextMenuButtonItem deleteButton =
      ContextMenuButtonItem(
        onPressed: () {
          editableTextState.replaceSelection(
            SelectionChangedCause.toolbar,
            '',
            suggestionSpan.range.start,
            suggestionSpan.range.end,
          );
        },
        type: ContextMenuButtonType.delete,
        label: localizations.deleteButtonTooltip.toUpperCase(),
    );
    buttonItems.add(deleteButton);

    return buttonItems;
  }

  /// Determines the Offset that the toolbar will be anchored to.
  static Offset getToolbarAnchor(TextSelectionToolbarAnchors anchors) {
    return anchors.secondaryAnchor == null ? anchors.primaryAnchor : anchors.secondaryAnchor!;
  }

  /// Builds the toolbar buttons based on the [buttonItems].
  List<Widget> _buildToolbarButtons() {
    return buttonItems.map((ContextMenuButtonItem buttonItem) {
      final TextSelectionToolbarTextButton button =
        TextSelectionToolbarTextButton(
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
          onPressed: buttonItem.onPressed,
          alignment: Alignment.centerLeft,
          child: Text(buttonItem.label!),
        );

      if (buttonItem.type == ContextMenuButtonType.delete) {
        return DecoratedBox(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.grey))),
          child: button.copyWith(
            child: Text(buttonItem.label!, style: const TextStyle(color: Colors.blue)),
          )
        );
      }
      return button;
    }).toList();
  }

  /// Calculates the height available to draw the toolbar below the anchor.
  @visibleForTesting
  double getAvailableHeightBelow(MediaQueryData mediaQueryData, Offset anchorPadded) {
    final double paddingBelow =
        math.max(mediaQueryData.viewPadding.bottom, mediaQueryData.viewInsets.bottom);
    return mediaQueryData.size.height - anchorPadded.dy - paddingBelow;
  }

  /// Calculates the height available to draw the toolbar above the anchor.
  @visibleForTesting
  double getAvailableHeightAbove(MediaQueryData mediaQueryData, Offset anchorPadded, double heightOffset) {
    final double paddingAbove =
        math.max(mediaQueryData.viewPadding.top, mediaQueryData.viewInsets.top);
    return anchorPadded.dy + heightOffset - paddingAbove;
  }

  @override
  Widget build(BuildContext context) {
    // Adjust toolbar height if needed.
    final double spellCheckSuggestionsToolbarHeight =
        _kDefaultToolbarHeight - (48.0 * (4 - buttonItems.length));
    // Incorporate the padding distance between the content and toolbar.
    final Offset anchorPadded =
        anchor + const Offset(0.0, _kToolbarContentDistanceBelow);
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    final double availableHeightBelow = getAvailableHeightBelow(mediaQueryData, anchorPadded);
    final double heightSlack = availableHeightBelow - spellCheckSuggestionsToolbarHeight;
    final bool fitsBelow = heightSlack >= 0;
    // Makes up for any cases where the toolbar may overlap bottom padding.
    final double heightOffset = fitsBelow? 0 : heightSlack;

    if (!fitsBelow && getAvailableHeightAbove(mediaQueryData, anchorPadded, heightOffset) < 0) {
        // Ensure that if toolbar is shifted up, it does not overlap top padding.
        return const SizedBox(width: 0.0, height: 0.0);
    }

    final double paddingAbove = mediaQueryData.padding.top + _kToolbarScreenPadding;
    // Makes up for the Padding above the Stack.
    final Offset localAdjustment = Offset(_kToolbarScreenPadding, paddingAbove);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kToolbarScreenPadding,
        _kToolbarContentDistanceBelow,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
      ),
      child: CustomSingleChildLayout(
        delegate: SpellCheckSuggestionsToolbarLayoutDelegate(
          anchor: anchorPadded - localAdjustment,
          heightOffset: heightOffset,
        ),
        child: AnimatedSize(
          // This duration was eyeballed on a Pixel 2 emulator running Android
          // API 28 for the Material TextSelectionToolbar.
          duration: const Duration(milliseconds: 140),
          child: _spellCheckSuggestionsToolbarBuilder(context, _SpellCheckSuggestsionsToolbarItemsLayout(
            height: spellCheckSuggestionsToolbarHeight,
            children: <Widget>[..._buildToolbarButtons()],
          )),
        ),
      ),
    );
  }
}

/// The Material-styled toolbar outline for the spell check suggestions
/// toolbar.
class _MaterialSpellCheckSuggestionsToolbarContainer extends StatelessWidget {
  const _MaterialSpellCheckSuggestionsToolbarContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      // This elevation was eyeballed on a Pixel 4 emulator running Android
      // API 31 for the MaterialSpellCheckSuggestionsToolbar.
      elevation: 2.0,
      type: MaterialType.card,
      child: child,
    );
  }
}

/// Renders the spell check suggestions toolbar items in the correct positions
/// in the menu.
class _SpellCheckSuggestsionsToolbarItemsLayout extends StatelessWidget {
  const _SpellCheckSuggestsionsToolbarItemsLayout({
    required this.height,
    required this.children,
  });

  final double height;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // This width was eyeballed on a Pixel 4 emulator running Android
      // API 31 for the MaterialSpellCheckSuggestionsToolbar.
      width: 165,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
