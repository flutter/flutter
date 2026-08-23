// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:widget_preview_scaffold/src/controls.dart';
import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  testWidgets('Search query updates and clears correctly', (
    WidgetTester tester,
  ) async {
    final controller = FakeWidgetPreviewScaffoldController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PreviewSearchControls(controller: controller)),
      ),
    );

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'My Awesome Widget');
    await tester.pumpAndSettle();

    expect(controller.searchQueryListenable.value, 'My Awesome Widget');

    final clearButton = find.byTooltip('Clear search');
    expect(clearButton, findsOneWidget);

    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(controller.searchQueryListenable.value, '');
  });
}
