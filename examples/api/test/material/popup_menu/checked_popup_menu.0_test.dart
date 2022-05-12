// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/popup_menu/checked_popup_menu.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can check menu item', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.CheckedMenuItemApp(),
    );

    final Finder containerFinder = find.byType(Container);
    expect(tester.getSize(containerFinder), const Size(75.0, 75.0));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.done), findsNothing);
    await tester.tap(find.text('Large'));
    await tester.pump();
    expect(find.byIcon(Icons.done), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.getSize(containerFinder), const Size(150.0, 150.0));
  });
}
