// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/draggable_scrollable_sheet/draggable_scrollable_sheet.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test DraggableScrollableSheet initial state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.DraggableScrollableSheetExampleApp());

    final Finder sheetFinder = find.byType(DraggableScrollableSheet);

    // Verify that DraggableScrollableSheet is initially present
    expect(sheetFinder, findsOneWidget);

    // Verify that DraggableScrollableSheet is shown initially at 50% height
    final DraggableScrollableSheet draggableSheet = tester.widget(sheetFinder);
    expect(draggableSheet.initialChildSize, 0.5);
  });

  testWidgets(
    'Test DraggableScrollableSheet drag behavior on mobile platforms',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.DraggableScrollableSheetExampleApp(),
      );

      // Verify that ListView is visible
      final Finder listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      // Get the initial size of the ListView
      final Size listViewInitialSize = tester.getSize(listViewFinder);

      // Drag the sheet from anywhere inside the sheet to change the sheet position
      await tester.drag(listViewFinder, const Offset(0.0, -100.0));
      await tester.pump();

      // Verify that the ListView is expanded
      final Size listViewCurrentSize = tester.getSize(listViewFinder);
      expect(
        listViewCurrentSize.height,
        greaterThan(listViewInitialSize.height),
      );
    },
    variant: TargetPlatformVariant.mobile(),
  );

  testWidgets(
    'Test DraggableScrollableSheet drag behavior on desktop platforms',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.DraggableScrollableSheetExampleApp(),
      );

      // Verify that Grabber is visible
      final Finder grabberFinder = find.byType(example.Grabber);
      expect(grabberFinder, findsOneWidget);

      // Drag the Grabber to change the sheet position
      await tester.drag(grabberFinder, const Offset(0.0, -100.0));
      await tester.pump();

      // Verify that the DraggableScrollableSheet's initialChildSize is updated
      final DraggableScrollableSheet draggableSheet = tester.widget(
        find.byType(DraggableScrollableSheet),
      );
      expect(draggableSheet.initialChildSize, isNot(0.5));
    },
    variant: TargetPlatformVariant.desktop(),
  );

  // Regression test for https://github.com/flutter/flutter/issues/179102.
  testWidgets(
    'Test DraggableScrollableSheet should move (with mouse pointer) proportionally to view height',
    (WidgetTester tester) async {
      // Simulate a viewport size with an exaggerated height.
      tester.view.physicalSize = const Size(800.0, 1000.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const example.DraggableScrollableSheetExampleApp(),
      );

      final Finder grabberFinder = find.byType(example.Grabber);
      expect(grabberFinder, findsOneWidget);

      // Get initial sheet size.
      final DraggableScrollableSheet initialSheet = tester.widget(
        find.byType(DraggableScrollableSheet),
      );
      expect(initialSheet.initialChildSize, 0.5);

      // Drag up by 100 pixels.
      // Since initial size is 0.5, dragging up should increase the sheet height.
      await tester.drag(grabberFinder, const Offset(0.0, -100.0));
      await tester.pump();

      final DraggableScrollableSheet draggedSheet = tester.widget(
        find.byType(DraggableScrollableSheet),
      );

      // Verify that the sheet moved proportionally.
      // It should be greater than initial (0.5).
      expect(draggedSheet.initialChildSize, greaterThan(0.5));
    },
    variant: TargetPlatformVariant.desktop(),
  );

  // Regression test for https://github.com/flutter/flutter/issues/179102.
  testWidgets(
    'Test DraggableScrollableSheet respects max bounds',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.DraggableScrollableSheetExampleApp(),
      );

      final Finder grabberFinder = find.byType(example.Grabber);
      expect(grabberFinder, findsOneWidget);

      // Drag far up to exceed max bounds (1.0).
      await tester.drag(grabberFinder, const Offset(0.0, -1000.0));
      await tester.pump();

      final DraggableScrollableSheet draggableSheet = tester.widget(
        find.byType(DraggableScrollableSheet),
      );

      // Verify that the sheet is clamped to max (1.0).
      expect(draggableSheet.initialChildSize, 1.0);
    },
    variant: TargetPlatformVariant.desktop(),
  );

  // Regression test for https://github.com/flutter/flutter/issues/179102.
  testWidgets(
    'Test DraggableScrollableSheet respects min bounds',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.DraggableScrollableSheetExampleApp(),
      );

      final Finder grabberFinder = find.byType(example.Grabber);
      expect(grabberFinder, findsOneWidget);

      // Drag far down to exceed min bounds (0.25).
      await tester.drag(grabberFinder, const Offset(0.0, 1000.0));
      await tester.pump();

      final DraggableScrollableSheet draggableSheet = tester.widget(
        find.byType(DraggableScrollableSheet),
      );

      // Verify that the sheet is clamped to min (0.25).
      expect(draggableSheet.initialChildSize, 0.25);
    },
    variant: TargetPlatformVariant.desktop(),
  );

  testWidgets('DraggableScrollableSheet does not crash at zero area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.shrink(
            child: DraggableScrollableSheet(builder: (_, _) => Text('X')),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DraggableScrollableSheet)), Size.zero);
  });
}
