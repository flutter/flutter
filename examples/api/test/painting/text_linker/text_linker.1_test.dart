// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/painting/text_linker/text_linker.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('can tap different link types with different results', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.TextLinkerApp(),
    );

    final Finder textFinder = find.descendant(
      of: find.byType(SelectionArea),
      matching: find.byType(Text),
    );
    expect(textFinder, findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tapAt(tester.getTopLeft(textFinder));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('You tapped: https://www.twitter.com/FlutterDev'), findsOneWidget);

    await tester.tapAt(tester.getTopLeft(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tapAt(tester.getCenter(textFinder));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('You tapped: www.flutter.dev'), findsOneWidget);
  });
}
