// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/material/expansible/expansible.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Expansible can be expanded', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ExpansibleApp());

    // Verify that the expanded content is not visible initially.
    expect(find.text('Hidden content revealed!'), findsNothing);

    // Tap the header to expand.
    await tester.tap(find.text('Tap to Expand'));
    await tester.pumpAndSettle();

    // Verify that the expanded content is now visible.
    expect(find.text('Hidden content revealed!'), findsOneWidget);
  });
}
