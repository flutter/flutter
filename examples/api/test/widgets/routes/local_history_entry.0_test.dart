// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/routes/local_history_entry.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PanelDemo builds and the panel can open', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(example.PanelDemo());

    expect(find.text('Open Panel'), findsOneWidget);
    expect(find.text('Press back to close this panel'), findsNothing);

    await tester.tap(find.text('Open Panel'));
    await tester.pumpAndSettle();

    expect(find.text('Press back to close this panel'), findsOneWidget);
  });
}
