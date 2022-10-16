// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/menu_anchor/checkbox_menu_button.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can open menu and show message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MenuApp(),
    );

    await tester.tap(find.byType(TextButton));
    await tester.pump();

    expect(find.text('Show Message'), findsOneWidget);
    expect(find.text(example.MenuApp.kMessage), findsNothing);

    await tester.tap(find.text('Show Message'));
    await tester.pump();

    expect(find.text('Show Message'), findsNothing);
    expect(find.text(example.MenuApp.kMessage), findsOneWidget);
  });
}
