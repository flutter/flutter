// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/routes/flexible_route_transitions.1.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../navigator_utils.dart';

void main() {
  testWidgets('Flexible Transitions App is able to build', (WidgetTester tester) async {
    await tester.pumpWidget(
      FlexibleRouteTransitionsApp(),
    );

    expect(find.text('Zoom Transition'), findsOneWidget);
    expect(find.text('Crazy Vertical Transition'), findsOneWidget);
    expect(find.text('Cupertino Transition'), findsOneWidget);
  });

  testWidgets('on Pop the correct page shows', (WidgetTester tester) async {
    await tester.pumpWidget(
      FlexibleRouteTransitionsApp(),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Cupertino Route'), findsNothing);
    expect(find.text('Zoom Route'), findsNothing);

    await tester.tap(find.text('Zoom Transition'));

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Cupertino Route'), findsNothing);
    expect(find.text('Zoom Route'), findsOneWidget);

    await tester.tap(find.text('Cupertino Transition'));

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Cupertino Route'), findsOneWidget);
    expect(find.text('Zoom Route'), findsNothing);

    expect(find.byType(MyPageScaffold), findsOneWidget);

    await simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Cupertino Route'), findsNothing);
    expect(find.text('Zoom Route'), findsOneWidget);

    await simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Cupertino Route'), findsNothing);
    expect(find.text('Zoom Route'), findsNothing);

    // await tester.tap(find.text('Crazy Vertical Transition'));

    // print(tester.getTopLeft(find.text('Cupertino Route')).dy);

    // await tester.pumpAndSettle();

    // print(tester.getTopLeft(find.text('Cupertino Route')).dy);
    // print(tester.getTopLeft(find.text('Vertical Route')).dy);

    // print(find.byType(MyPageScaffold));
  });
}
