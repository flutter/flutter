// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/selection_area/selection_area.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Texts are descendant of the SelectionArea',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SelectionAreaExampleApp(),
    );

    expect(find.byType(SelectionArea), findsExactly(1));

    Finder finder = find.descendant(
      of: find.byType(SelectionArea),
      matching: find.descendant(
        of: find.byType(AppBar),
        matching: find.text('SelectionArea Sample'),
      ),
    );

    expect(finder, findsExactly(1));

    finder = find.descendant(
      of: find.byType(Column),
      matching: find.byType(Text),
    );

    expect(finder, findsExactly(3));
  });
}
