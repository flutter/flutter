// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/choice_chip/choice_chip.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can choose an item using ChoiceChip', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ChipApp(),
    );

    ChoiceChip chosenChip = tester.widget(find.byType(ChoiceChip).at(1));
    expect(chosenChip.selected, true);

    await tester.tap(find.byType(ChoiceChip).at(0));
    await tester.pumpAndSettle();

    chosenChip = tester.widget(find.byType(ChoiceChip).at(0));
    expect(chosenChip.selected, true);
  });

  testWidgets('should show checkmark and set correct color',
      (WidgetTester tester) async {
    final checkmarkColor = Colors.green;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ChoiceChip(
              label: const Text('Choice Chip'),
              selected: true,
              showCheckmark: true,
              checkmarkColor: checkmarkColor,
              onSelected: (value) {},
            ),
          ),
        ),
      ),
    );

    final checkmarkFinder = find.byIcon(Icons.check);
    final checkmarkIcon = checkmarkFinder.evaluate().first.widget as Icon;
    final checkmarkOpacity = (checkmarkIcon.color?.opacity ?? 0).toDouble();

    expect(checkmarkFinder, findsOneWidget);
    expect(checkmarkOpacity, equals(1.0));
    expect(checkmarkIcon.color, equals(checkmarkColor));
  });

  testWidgets('should hide checkmark', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ChoiceChip(
              label: const Text('Choice Chip'),
              selected: true,
              showCheckmark: false,
              onSelected: (value) {},
            ),
          ),
        ),
      ),
    );

    final checkmarkFinder = find.byIcon(Icons.check);

    expect(checkmarkFinder, findsNothing);
  });
}
