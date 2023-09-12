// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/dialog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('dialog can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, DialogUseCase());
    expect(find.text('Show Dialog'), findsOneWidget);

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
    expect(find.text('This is a typical dialog.'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Show Dialog'), findsOneWidget);
  });
}
