// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/selection_area/selection_area.2.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SelectionArea Insert Content Example Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SelectionAreaInsertContentExampleApp(),
    );
    expect(find.byType(Text), findsNWidgets(5));
    expect(find.byType(Column), findsOneWidget);
  });
}
