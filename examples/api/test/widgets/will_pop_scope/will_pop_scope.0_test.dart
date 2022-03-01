// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/will_pop_scope/will_pop_scope.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pressing shouldPop button changes shouldPop', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    final Finder buttonFinder = find.text('shouldPop: true');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pump();
    expect(find.text('shouldPop: false'), findsOneWidget);
  });
  testWidgets('pressing Push button pushes route', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    final Finder buttonFinder = find.text('Push');
    expect(buttonFinder, findsOneWidget);
    expect(find.byType(example.MyStatefulWidget), findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    expect(find.byType(example.MyStatefulWidget, skipOffstage: false), findsNWidgets(2));
  });
}
