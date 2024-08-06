// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/routes/flexible_route_transitions.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flexible Transitions App is able to build', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.FlexibleRouteTransitionsApp(),
    );

    expect(find.text('Zoom Transition'), findsExactly(2));
    expect(find.text('Crazy Vertical Transition'), findsOneWidget);
    expect(find.text('Cupertino Transition'), findsOneWidget);
  });
}
