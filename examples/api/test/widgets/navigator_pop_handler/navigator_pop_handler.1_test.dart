// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/navigator_pop_handler/navigator_pop_handler.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

import '../navigator_utils.dart';

void main() {
  testWidgets("System back gesture operates on current tab's nested Navigator", (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.NavigatorPopHandlerApp(),
    );

    expect(find.text('Bottom nav - tab Home Tab - route _TabPage.home'), findsOneWidget);

    // Go to the next route in this tab.
    await tester.tap(find.text('Go to another route in this nested Navigator'));
    await tester.pumpAndSettle();
    expect(find.text('Bottom nav - tab Home Tab - route _TabPage.one'), findsOneWidget);

    // Go to another tab.
    await tester.tap(find.text('Go to One'));
    await tester.pumpAndSettle();
    expect(find.text('Bottom nav - tab Tab One - route _TabPage.home'), findsOneWidget);

    // Return to the home tab. The navigation state is preserved.
    await tester.tap(find.text('Go to Home'));
    await tester.pumpAndSettle();
    expect(find.text('Bottom nav - tab Home Tab - route _TabPage.one'), findsOneWidget);

    // A back pops the navigation stack of the current tab's nested Navigator.
    await simulateSystemBack();
    await tester.pumpAndSettle();
    expect(find.text('Bottom nav - tab Home Tab - route _TabPage.home'), findsOneWidget);
  });
}
