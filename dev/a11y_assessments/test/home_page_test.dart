// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('Has light and dark theme', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    final MaterialApp app = find.byType(MaterialApp).evaluate().first.widget as MaterialApp;
    expect(app.theme!.brightness, equals(Brightness.light));
    expect(app.darkTheme!.brightness, equals(Brightness.dark));
  });
}
