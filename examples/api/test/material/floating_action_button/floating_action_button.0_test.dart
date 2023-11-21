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
      const example.FloatingActionButtonExampleApp(),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.navigation), findsOneWidget);

    final Material material = tester.widget<Material>(find.descendant(
      of: find.byType(ElevatedButton),
      matching: find.byType(Material),
    ));

    Color? getIconColor() {
      final RichText iconRichText = tester.widget<RichText>(
        find.descendant(of: find.byIcon(Icons.navigation), matching: find.byType(RichText)),
      );
      return iconRichText.text.style?.color;
    }

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle(); // Wait for the animation to finish.
    expect(material.color, const Color(0xffeaddff));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle(); // Wait for the animation to finish.
    expect(material.color, const Color(0xffeaddff));
    expect(getIconColor(), Colors.white);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle(); // Wait for the animation to finish.
    expect(material.color, const Color(0xffeaddff));
    expect(getIconColor(), Colors.white);
    expect(
      material.shape,
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    );
  });
}
