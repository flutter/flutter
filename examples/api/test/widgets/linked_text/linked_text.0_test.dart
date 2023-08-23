// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/linked_text/linked_text.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a link shows a dialog with the tapped uri', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.LinkedTextApp(),
    );

    final Finder textFinder = find.descendant(
      of: find.byType(LinkedText),
      matching: find.byType(RichText),
    );
    expect(textFinder, findsOneWidget);

    await tester.tapAt(tester.getCenter(textFinder));
    await tester.pumpAndSettle();
    expect(find.text('You tapped: www.flutter.dev'), findsOneWidget);
  });
}
