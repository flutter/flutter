// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../foundation/leak_tracking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithLeakTracking('position in the toolbar changes width', (WidgetTester tester) async {
    late StateSetter setState;
    int index = 1;
    int total = 3;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return TextSelectionToolbarTextButton(
                  padding: TextSelectionToolbarTextButton.getPadding(index, total),
                  child: const Text('button'),
                );
              },
            ),
          ),
        ),
      ),
    );

    final Size middleSize = tester.getSize(find.byType(TextSelectionToolbarTextButton));

    setState(() {
      index = 0;
      total = 3;
    });
    await tester.pump();
    final Size firstSize = tester.getSize(find.byType(TextSelectionToolbarTextButton));
    expect(firstSize.width, greaterThan(middleSize.width));

    setState(() {
      index = 2;
      total = 3;
    });
    await tester.pump();
    final Size lastSize = tester.getSize(find.byType(TextSelectionToolbarTextButton));
    expect(lastSize.width, greaterThan(middleSize.width));
    expect(lastSize.width, equals(firstSize.width));

    setState(() {
      index = 0;
      total = 1;
    });
    await tester.pump();
    final Size onlySize = tester.getSize(find.byType(TextSelectionToolbarTextButton));
    expect(onlySize.width, greaterThan(middleSize.width));
    expect(onlySize.width, greaterThan(firstSize.width));
    expect(onlySize.width, greaterThan(lastSize.width));
  });

  for (final ColorScheme colorScheme in <ColorScheme>[ThemeData.light().colorScheme, ThemeData.dark().colorScheme]) {
    testWidgetsWithLeakTracking('theme color by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: colorScheme,
          ),
          home: Scaffold(
            body: Center(
              child: TextSelectionToolbarTextButton(
                padding: TextSelectionToolbarTextButton.getPadding(0, 1),
                child: const Text('button'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);

      final TextButton textButton = tester.widget(find.byType(TextButton));
      expect(
        textButton.style!.foregroundColor!.resolve(<MaterialState>{}),
        colorScheme.onSurface,
      );
    });
  }

  for (final ColorScheme colorScheme in <ColorScheme>[ThemeData.light().colorScheme, ThemeData.dark().colorScheme]) {
    testWidgetsWithLeakTracking('custom theme foreground color', (WidgetTester tester) async {
      const Color foregroundColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: colorScheme.copyWith(
              onSurface: foregroundColor,
            ),
          ),
          home: Scaffold(
            body: Center(
              child: TextSelectionToolbarTextButton(
                padding: TextSelectionToolbarTextButton.getPadding(0, 1),
                child: const Text('button'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);

      final TextButton textButton = tester.widget(find.byType(TextButton));
      expect(
        textButton.style!.foregroundColor!.resolve(<MaterialState>{}),
        foregroundColor,
      );
    });
  }
}
