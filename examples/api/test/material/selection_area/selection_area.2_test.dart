// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/selection_area/selection_area.2.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SelectionArea Color Text Red Example Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SelectionAreaColorTextRedExampleApp(),
    );
    expect(find.widgetWithIcon(FloatingActionButton, Icons.undo), findsOneWidget);
    expect(find.byType(Column), findsNWidgets(2));
    expect(find.textContaining('This is some bulleted list:\n'), findsOneWidget);
    for (int i = 1; i <= 7; i += 1) {
      expect(find.widgetWithText(Text, '• Bullet $i'), findsOneWidget);
    }
    expect(find.textContaining('This is some text in a text widget.'), findsOneWidget);
    expect(find.textContaining(' This is some more text in the same text widget.'), findsOneWidget);
    expect(find.textContaining('This is some text in another text widget.'), findsOneWidget);
  });
}
