// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'material.dart';
import 'text_selection_toolbar_text_button.dart';
import 'theme.dart';

// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;
const double _kHandleSize = 22.0;

// Padding between the toolbar and the anchor.
const double _kToolbarContentDistanceBelow = _kHandleSize - 5.0;
const double _kToolbarContentDistance = 8.0;

const double _spellCheckSuggestionsToolbarHeight = 193;

/// The default context menu for displaying spell check suggestions for the
/// current platform.
///
/// Typically, this widget would be set as
/// `spellCheckSuggestionsToolbarBuilder` in a [SpellCheckConfiguration] that
/// would be passed to a supported parent widget, such as:
///
/// * [TextField.spellCheckConfiguration]
/// * [CupertinoTextField.spellCheckConfiguration]
///
/// See also:
/// * [MaterialSpellCheckSuggestionsToolbar], the default spell check
///   suggestions toolbar for Android.
class AdaptiveSpellCheckSuggestionsToolbar extends StatelessWidget {
  const AdaptiveSpellCheckSuggestionsToolbar({
    super.key,
    required this.anchors,
    required this.buttonItems,
  });

  /// {@template flutter.material.AdaptiveSpellCheckSuggestionsToolbar.anchors}
  /// The location on which to anchor the menu.
  /// {@endtemplate}
  final TextSelectionToolbarAnchors anchors;

  /// {@template flutter.material.AdaptiveSpellCheckSuggestionsToolbar.buttonItems}
  /// The data that will be used to adaptively generate each child button
  /// containing a click-and-replace replacement suggestion or an action related
  /// to a misspelled word of the toolbar.
  /// {@endtemplate}
  final List<ContextMenuButtonItem>? buttonItems;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (buttonItems?.isEmpty ?? false) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
        return MaterialSpellCheckSuggestionsToolbar(
          anchorBelow: anchors.secondaryAnchor == null ? anchors.primaryAnchor : anchors.secondaryAnchor!,
          buttonItems: buttonItems!,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
        return const SizedBox(width: 0.0, height: 0.0);
    }
  }
}

/// The default spell check suggestsions toolbar for Android.
///
/// Tries to position itself below [anchorBelow], but if it doesn't fit, then it
/// readjusts to fit above bottom view insets.
///
/// See also:
///
///  * [AdaptiveSpellCheckSuggestionsToolbar], which builds the toolbar for the
///    current platform.
class MaterialSpellCheckSuggestionsToolbar extends StatelessWidget {
  const MaterialSpellCheckSuggestionsToolbar({
    super.key,
    required this.anchorBelow,
    required this.buttonItems,
  }) : assert(buttonItems != null);

  /// The focal point below which the toolbar attempts to position itself.
  final Offset anchorBelow;

  /// The buttons that will be displayed in the spell check suggestions toolbar.
  final List<ContextMenuButtonItem> buttonItems;

  /// Build the default Android Material spell check suggestions toolbar.
  static Widget _spellCheckSuggestionsToolbarBuilder(BuildContext context, Widget child) {
    return _MaterialSpellCheckSuggestionsToolbarContainer(
      child: child,
    );
  }

  /// Creates the buttons corresponding the spell check suggestions of a
  /// misspelled word or any applicable actions to take.
  List<Widget> _buildToolbarButtons() {
    int buttonIndex = 0;

    List<Widget> buttons = buttonItems.map((ContextMenuButtonItem buttonItem) {
      TextSelectionToolbarTextButton button = TextSelectionToolbarTextButton(
        padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
        onPressed: buttonItem.onPressed,
        alignment: Alignment.centerLeft,
        child: Text(buttonItem.label!),
      );

      if (buttonItem.type! == ContextMenuButtonType.delete) {
        return Container(
          decoration: BoxDecoration(border: Border(top: BorderSide (color: Colors.grey))),
          child: button.copyWith(
            child: Text(buttonItem.label!, style: TextStyle(color: Colors.blue))
          )
        );
      }
      return button;
    }).toList();
    return buttons;
  }

  /// Calculates the height available to draw the toolbar below the anchor.
  double getAvailableHeightBelow(BuildContext context, Offset anchorPadded) {
    final double paddingBelow =
      math.max(MediaQuery.of(context).viewPadding.bottom, MediaQuery.of(context).viewInsets.bottom);
    return MediaQuery.of(context).size.height - anchorPadded.dy - paddingBelow;
  } 

  @override
  Widget build(BuildContext context) {
    // Incorporate the padding distance between the content and toolbar.
    final Offset anchorBelowPadded =
        anchorBelow + const Offset(0.0, _kToolbarContentDistanceBelow);
    final double availableHeightBelow = getAvailableHeightBelow(context, anchorBelowPadded);
    final double heightSlack = availableHeightBelow - _spellCheckSuggestionsToolbarHeight;
    final double heightOffset = heightSlack >= 0 ? 0 : heightSlack;

    final double paddingAbove = MediaQuery.of(context).padding.top + _kToolbarScreenPadding;
    // Makes up for the Padding above the Stack.
    final Offset localAdjustment = Offset(_kToolbarScreenPadding, paddingAbove);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _kToolbarScreenPadding,
        _kToolbarContentDistanceBelow,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
      ),
      child: CustomSingleChildLayout(
        delegate: SpellCheckSuggestionsToolbarLayoutDelegate(
          anchorBelow: anchorBelowPadded - localAdjustment,
          heightOffset: heightOffset,  
        ),
        child: AnimatedSize(
        // This duration was eyeballed on a Pixel 2 emulator running Android
        // API 28 for the Material TextSelectionToolbar.
          duration: const Duration(milliseconds: 140),
          child: _spellCheckSuggestionsToolbarBuilder(context, _SpellCheckSuggestsionsToolbarItemsLayout(
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
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      height: _spellCheckSuggestionsToolbarHeight,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[...children],
    ),
    );
  }
}
