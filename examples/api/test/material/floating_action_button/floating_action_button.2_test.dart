// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/floating_action_button/floating_action_button.2.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FloatingActionButton - Material 3', (WidgetTester tester) async {
    RawMaterialButton getRawMaterialButtonWidget(Finder finder) {
      return tester.widget<RawMaterialButton>(finder);
    }
    await tester.pumpWidget(
      const example.FloatingActionButtonExampleApp(),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    final ThemeData theme = ThemeData(colorSchemeSeed: const Color(0xff6750a4), useMaterial3: true);
    final Finder materialButtonFinder = find.byType(RawMaterialButton);
    expect(getRawMaterialButtonWidget(materialButtonFinder).fillColor, theme.colorScheme.primaryContainer);
    expect(getRawMaterialButtonWidget(materialButtonFinder).shape, RoundedRectangleBorder(borderRadius:  BorderRadius.circular(16.0)));
  });
}
