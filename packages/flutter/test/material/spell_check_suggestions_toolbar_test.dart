// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double anchorBelow = 200;
const double _toolbarContentDistanceBelow = 17;
const double _toolbarScreenPadding = 8;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Finds the container of the [MaterialSpellCheckSuggestionsToolbar] to
  /// determine the toolbar's position.
  Finder findMaterialSpellCheckSuggestionsToolbar() {
    return find.descendant(
      of: find.byType(MaterialApp),
      matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_MaterialSpellCheckSuggestionsToolbarContainer'),
    );
  }

  testWidgets('positions toolbar below anchor when it fits above bottom view padding', (WidgetTester tester) async {
    final double expectedToolbarY = anchorBelow + (2 * _toolbarContentDistanceBelow) - _toolbarScreenPadding;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body:
              _FitsBelowAnchorMaterialSpellCheckSuggestionsToolbar(
                anchorBelow: const Offset(0.0, anchorBelow),
                buttonItems: buildSuggestionButtons(<String>['hello', 'yellow', 'yell']),
              ),
          ),
        ),
      );

    double toolbarY = tester.getTopLeft(findMaterialSpellCheckSuggestionsToolbar()).dy;
    expect(toolbarY, equals(expectedToolbarY));
  });

  testWidgets('re-positions toolbar higher below anchor when it does not fit above bottom view padding', (WidgetTester tester) async {
    final double expectedToolbarY = anchorBelow + (2 * _toolbarContentDistanceBelow) - _toolbarScreenPadding - 10;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body:
              _DoesNotFitBelowAnchorMaterialSpellCheckSuggestionsToolbar(
                anchorBelow: const Offset(0.0, anchorBelow),
                buttonItems: buildSuggestionButtons(<String>['hello', 'yellow', 'yell']),
              ),
          ),
        ),
      );

    double toolbarY = tester.getTopLeft(findMaterialSpellCheckSuggestionsToolbar()).dy;
    expect(toolbarY, equals(expectedToolbarY));
  });
}

List<ContextMenuButtonItem> buildSuggestionButtons(List<String> suggestions) {
  final List<ContextMenuButtonItem> buttonItems = <ContextMenuButtonItem>[];

  for (final String suggestion in suggestions) {
    buttonItems.add(ContextMenuButtonItem(
      onPressed: () {},
      type: ContextMenuButtonType.suggestion,
      label: suggestion,
    ));
  }

  ContextMenuButtonItem deleteButton =
    ContextMenuButtonItem(
      onPressed: () {},
      type: ContextMenuButtonType.delete,
      label: 'DELETE',
  );

  buttonItems.add(deleteButton);
  return buttonItems;
}

class _FitsBelowAnchorMaterialSpellCheckSuggestionsToolbar extends MaterialSpellCheckSuggestionsToolbar {
  const _FitsBelowAnchorMaterialSpellCheckSuggestionsToolbar({
    super.key,
    required super.anchorBelow,
    required super.buttonItems,
  });

  @override
  double getAvailableHeightBelow(BuildContext context, Offset anchorPadded) {
    // The toolbar will perfectly fit in the space available.
    return 193;
  }

  @override
  Widget build(BuildContext context) {
    return super.build(context);
  }
}

class _DoesNotFitBelowAnchorMaterialSpellCheckSuggestionsToolbar extends MaterialSpellCheckSuggestionsToolbar {
  const _DoesNotFitBelowAnchorMaterialSpellCheckSuggestionsToolbar({
    super.key,
    required super.anchorBelow,
    required super.buttonItems,
  });

  @override
  double getAvailableHeightBelow(BuildContext context, Offset anchorPadded) {
    // The toolbar overlaps the bottom view padding by 10 pixels.
    return 183;
  } 

  @override
  Widget build(BuildContext context) {
    return super.build(context);
  }
}
