// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/inherited_model/inherited_model.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Rebuild widget using InheritedModel', (WidgetTester tester) async {
    Color fooColor;

    BoxDecoration? getDecoration() {
      return tester.widget<AnimatedContainer>(
        find.widgetWithText(AnimatedContainer, 'Foo'),
      ).decoration as BoxDecoration?;
    }

    await tester.pumpWidget(
      const example.InheritedModelApp(),
    );

    BoxDecoration? decoration = getDecoration();
    fooColor = decoration!.color!;

    await tester.tap(find.text('Resize Foo'));
    await tester.pumpAndSettle();
    decoration = getDecoration();
    expect(fooColor, isNot(decoration!.color));
  });
}
