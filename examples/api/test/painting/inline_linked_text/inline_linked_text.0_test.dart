// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/painting/inline_linked_text/inline_linked_text.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a link shows a dialog with the tapped uri', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.InlineLinkedTextApp(),
    );

    final Finder textFinder = find.descendant(
      of: find.byType(Column),
      matching: find.byType(Text),
    );
    expect(textFinder, findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tapAt(tester.getCenter(textFinder));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('You tapped: www.flutter.dev'), findsOneWidget);
  });
}
