// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/popup_menu/popup_menu_button.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can select a menu item', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.PopupMenuButtonApp(),
    );

    expect(find.text('Select an item'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item 3'));
    await tester.pumpAndSettle();
    expect(find.text('Select an item'), findsNothing);
    expect(find.text('Selected item: itemThree'), findsOneWidget);
  });
}
