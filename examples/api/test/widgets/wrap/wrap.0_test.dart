// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_api_samples/widgets/wrap/wrap.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

Iterable<double> _getXOffsets(WidgetTester tester) {
  final RenderWrap renderWrap = tester.renderObject<RenderWrap>(find.byType(Wrap));
  return renderWrap.getChildrenAsList().map(
    (RenderBox renderBox) => renderBox.localToGlobal(Offset.zero).dy,
  );
}

void main() {
  testWidgets(
    'Items can be added and deleted',
    (WidgetTester tester) async {
      await tester.pumpWidget(const example.WrapExampleApp());

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      _expectAllTheSame(_getXOffsets(tester));

      // Add an item
      const String itemText = 'A Very Very Long Item';
      await tester.enterText(find.byType(TextField), itemText);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text(itemText), findsNWidgets(2));
      _expectAllTheSame(_getXOffsets(tester).toList().take(3));

      // Clear TextField
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text(itemText), findsOneWidget);
      _expectAllTheSame(_getXOffsets(tester).toList().take(3));

      // Delete Item 1
      await tester.longPress(find.bySubtype<FilledButton>().at(1));
      await tester.pump();
      expect(find.text('Item 1'), findsNothing);

      _expectAllTheSame(_getXOffsets(tester));
    },
  );

  testWidgets(
    'Fits can be cycled',
    (WidgetTester tester) async {
      await tester.pumpWidget(const example.WrapExampleApp());

      expect(find.byType(Wrapped), findsOneWidget);
      expect(find.byTooltip(WrapFit.fillRun.name), findsNothing);

      await tester.tap(find.bySubtype<FilledButton>().first);
      await tester.pump();

      expect(find.byType(Wrapped), findsNWidgets(2));
      expect(find.byTooltip(WrapFit.fillRun.name), findsOneWidget);
    },
  );
}

void _expectAllTheSame(Iterable<dynamic> items) {
  expect(items, List<dynamic>.generate(items.length, (int index) => items.firstOrNull));
}
