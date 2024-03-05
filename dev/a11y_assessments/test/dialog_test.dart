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

    Future<void> invokeDialog() async {
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('This is a typical dialog.'), findsOneWidget);
    }

    await invokeDialog();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('This is a typical dialog.'), findsNothing);

    await invokeDialog();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('This is a typical dialog.'), findsNothing);
  });
}
