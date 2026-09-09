// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:a11y_assessments/use_cases/toggle_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('toggle buttons can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, ToggleButtonsUseCase());
    expect(find.byType(ToggleButtons), findsOneWidget);
  });

  testWidgets('toggle buttons can toggle state', (WidgetTester tester) async {
    await pumpsUseCase(tester, ToggleButtonsUseCase());
    final Finder findBold = find.bySemanticsLabel('Bold');
    expect(findBold, findsOneWidget);

    final Finder findToggleButtons = find.byType(ToggleButtons);
    expect(findToggleButtons, findsOneWidget);

    ToggleButtons widget = tester.widget(findToggleButtons);
    expect(widget.isSelected[0], isTrue);

    await tester.tap(findBold);
    await tester.pumpAndSettle();

    widget = tester.widget(findToggleButtons);
    expect(widget.isSelected[0], isFalse);
  });

  // Verifies that the contrast ratio between the background of the selected state
  // and the background of the unselected/default state is at least 3:1.
  // This is required by WCAG 2.1 Success Criterion 1.4.11 (Non-text Contrast) to
  // ensure users can identify when a user interface component changes state:
  // https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html
  testWidgets('toggle buttons selected and unselected backgrounds have at least 3:1 contrast ratio', (
    WidgetTester tester,
  ) async {
    await pumpsUseCase(tester, ToggleButtonsUseCase());

    final Finder boldButton = find.ancestor(
      of: find.bySemanticsLabel('Bold'),
      matching: find.byType(TextButton),
    );

    final Color scaffoldBg = Theme.of(tester.element(boldButton)).scaffoldBackgroundColor;
    final Color selectedBg = _getButtonBg(tester, boldButton, scaffoldBg, isSelected: true);

    // Tap the button to deselect it.
    await tester.tap(boldButton);
    await tester.pumpAndSettle();

    final Color unselectedBg = _getButtonBg(tester, boldButton, scaffoldBg, isSelected: false);

    final double contrastRatio = _contrastRatio(selectedBg, unselectedBg);
    expect(
      contrastRatio,
      greaterThanOrEqualTo(3.0),
      reason:
          'Contrast ratio between selected background ($selectedBg) and unselected background ($unselectedBg) must be at least 3.0',
    );
  });
}

/// Resolves the background color of the button and blends it with the scaffold background.
Color _getButtonBg(
  WidgetTester tester,
  Finder buttonFinder,
  Color scaffoldBg, {
  required bool isSelected,
}) {
  final TextButton button = tester.widget<TextButton>(buttonFinder);
  final states = isSelected ? const <WidgetState>{WidgetState.selected} : const <WidgetState>{};
  final Color resolved = button.style?.backgroundColor?.resolve(states) ?? Colors.transparent;
  return Color.alphaBlend(resolved, scaffoldBg);
}

/// Computes the contrast ratio as defined by the WCAG.
///
/// Source: https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
double _contrastRatio(Color color1, Color color2) {
  final double l1 = color1.computeLuminance();
  final double l2 = color2.computeLuminance();
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}
