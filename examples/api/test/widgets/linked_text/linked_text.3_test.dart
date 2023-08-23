// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/linked_text/linked_text.3.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('can tap links generated from TextSpans', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.LinkedTextApp(),
    );

    final Finder textFinder = find.descendant(
      of: find.byType(LinkedText),
      matching: find.byType(RichText),
    );
    expect(textFinder, findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tapAt(tester.getCenter(textFinder));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('You tapped: https://www.flutter.dev'), findsOneWidget);
  });
}
