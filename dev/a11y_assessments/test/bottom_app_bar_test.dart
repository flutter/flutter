// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/bottom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('bottom app bar test', (WidgetTester tester) async {
    await pumpsUseCase(tester, BottomAppBarUseCase());
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.text('Selected: None'), findsOneWidget);

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();

    expect(find.text('Selected: Menu'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
