// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/foundation/change_notifier/change_notifier.0.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Counter class listeners', () {
    Color currentColor = Colors.black;
    int currentCount = 0;

    final AppState counterNotifier = AppState();
    counterNotifier.addListener(() {
      if (counterNotifier.counter != currentCount) {
        currentCount = counterNotifier.counter;
      }

      if (counterNotifier.textColor != currentColor) {
        currentColor = counterNotifier.textColor;
      }
    });

    // Initial values
    expect(counterNotifier.counter, isZero);
    expect(currentCount, isZero);
    expect(counterNotifier.textColor, equals(Colors.black));
    expect(currentColor, equals(Colors.black));

    // Changing value
    counterNotifier.counter++;

    expect(counterNotifier.counter, equals(1));
    expect(currentCount, equals(1));
    expect(counterNotifier.textColor, equals(Colors.black));
    expect(currentColor, equals(Colors.black));

    // Changing color
    counterNotifier.textColor = Colors.green;

    expect(counterNotifier.counter, equals(1));
    expect(currentCount, equals(1));
    expect(counterNotifier.textColor, equals(Colors.green));
    expect(currentColor, equals(Colors.green));
  });

  testWidgets('Smoke test for CounterApp', (WidgetTester tester) async {
    await tester.pumpWidget(const CounterApp());

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(CounterBody), findsOneWidget);
    expect(find.byType(TextButton), findsNWidgets(2));
    expect(find.text('ChangeNotifier demo'), findsOneWidget);
  });

  testWidgets('Counter update', (WidgetTester tester) async {
    await tester.pumpWidget(const CounterApp());

    // Initial state of the counter
    expect(find.text('0'), findsOneWidget);

    // Tapping the increase button
    await tester.tap(find.text('Increase'));
    await tester.pumpAndSettle();

    // Counter should be at 1
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('Color change', (WidgetTester tester) async {
    await tester.pumpWidget(const CounterApp());

    // Initial state of the counter
    expect(find.text('Green text color'), findsOneWidget);

    // Tapping to for the green color
    await tester.tap(find.text('Green text color'));
    await tester.pumpAndSettle();

    expect(find.text('Black text color'), findsOneWidget);
    expect(find.text('Green text color'), findsNothing);

    // Tapping to get the black color back
    await tester.tap(find.text('Black text color'));
    await tester.pumpAndSettle();

    expect(find.text('Green text color'), findsOneWidget);
    expect(find.text('Black text color'), findsNothing);
  });
}
