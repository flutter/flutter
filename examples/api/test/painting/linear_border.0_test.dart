// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/painting/linear_border/linear_border.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

// Just a smoke test for now.

void main() {
  testWidgets('Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ExampleApp(),
    );

    expect(find.byType(example.Home), findsOneWidget);
  });
}
