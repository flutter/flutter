// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/floating_action_button/floating_action_button.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FloatingActionButton.extended', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.FloatingActionButtonExampleApp(),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up), findsOneWidget);

    final Finder materialButtonFinder = find.byType(RawMaterialButton);
    RawMaterialButton getRawMaterialButtonWidget() {
      return tester.widget<RawMaterialButton>(materialButtonFinder);
    }
    expect(getRawMaterialButtonWidget().fillColor, Colors.pink);
    expect(getRawMaterialButtonWidget().shape, const StadiumBorder());
  });
}
