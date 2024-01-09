// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/navigator_pop_handler/navigator_pop_handler.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

import '../navigator_utils.dart';

void main() {
  testWidgets('Can go back with system back gesture', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.NavigatorPopHandlerApp(),
    );

    expect(find.text('Nested Navigators Example'), findsOneWidget);
    expect(find.text('Nested Navigators Page One'), findsNothing);
    expect(find.text('Nested Navigators Page Two'), findsNothing);

    await tester.tap(find.text('Nested Navigator route'));
    await tester.pumpAndSettle();

    expect(find.text('Nested Navigators Example'), findsNothing);
    expect(find.text('Nested Navigators Page One'), findsOneWidget);
    expect(find.text('Nested Navigators Page Two'), findsNothing);

    await tester.tap(find.text('Go to another route in this nested Navigator'));
    await tester.pumpAndSettle();

    expect(find.text('Nested Navigators Example'), findsNothing);
    expect(find.text('Nested Navigators Page One'), findsNothing);
    expect(find.text('Nested Navigators Page Two'), findsOneWidget);

    await simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text('Nested Navigators Example'), findsNothing);
    expect(find.text('Nested Navigators Page One'), findsOneWidget);
    expect(find.text('Nested Navigators Page Two'), findsNothing);

    await simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text('Nested Navigators Example'), findsOneWidget);
    expect(find.text('Nested Navigators Page One'), findsNothing);
    expect(find.text('Nested Navigators Page Two'), findsNothing);
  });
}
