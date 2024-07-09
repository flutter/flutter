// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/scrollbar/scrollbar.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('The scrollbar thumb should be visible', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ScrollbarExampleApp(),
    );

    expect(find.widgetWithText(AppBar, 'Scrollbar Sample'), findsOne);
    expect(find.text('item 0'), findsOne);
    expect(find.text('item 1'), findsOne);
    expect(find.text('item 2'), findsOne);

  });
}
