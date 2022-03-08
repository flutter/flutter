// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/floating_action_button/floating_action_button.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FloatingActionButton', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.navigation), findsOneWidget);

    final Material material = tester.widget(find.descendant(
      of: find.byType(ElevatedButton),
      matching: find.byType(Material),
    ));
    expect(material.color, Colors.green);
    expect(material.shape, const CircleBorder());
  });
}
