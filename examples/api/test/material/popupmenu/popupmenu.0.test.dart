// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/popupmenu/popupmenu.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can select a menu item', (WidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: example.MyStatefulWidget(
            key: popupButtonKey,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(popupButtonKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation
    await tester.tapAt(const Offset(1.0, 1.0));
    await tester.pumpAndSettle();
    expect(find.text('_selectedMenu: itemOne'), findsNothing);
  });
}
