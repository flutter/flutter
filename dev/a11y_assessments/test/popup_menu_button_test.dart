// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/popup_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('popup menu button can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, PopupMenuButtonUseCase());
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
  });

  testWidgets('popup menu button can select item', (WidgetTester tester) async {
    await pumpsUseCase(tester, PopupMenuButtonUseCase());

    expect(find.text('Selected: None'), findsOneWidget);

    final Finder findButton = find.byType(PopupMenuButton<String>);
    expect(findButton, findsOneWidget);
    await tester.tap(findButton);
    await tester.pumpAndSettle();

    final Finder findItem1 = find.text('Item 1');
    expect(findItem1, findsOneWidget);
    await tester.tap(findItem1);
    await tester.pumpAndSettle();

    expect(find.text('Selected: Item 1'), findsOneWidget);
  });
}
