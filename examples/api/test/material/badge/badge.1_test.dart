// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/badge/badge.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BadgeMaxCountExample shows overflow label', (WidgetTester tester) async {
    // Pump the demo app
    await tester.pumpWidget(const example.BadgeMaxCountExampleApp());

    // There should be exactly one Badge widget
    expect(find.byType(Badge), findsOneWidget);

    // The count is 1000 with maxCount=99, so it should display "99+"
    expect(find.text('99+'), findsOneWidget);

    // And no literal "1000" should appear
    expect(find.text('1000'), findsNothing);
  });
}
