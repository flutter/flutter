// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/transitions/listenable_builder.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Changing focus changes border', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ListenableBuilderExample());

    Finder findContainer() => find.descendant(of: find.byType(example.FocusListenerContainer), matching: find.byType(Container)).first;
    bool containerHasFocus() => Focus.of(tester.element(findContainer())).hasFocus;
    Container getContainer() => tester.widget(findContainer()) as Container;
    ShapeDecoration getDecoration() => getContainer().decoration! as ShapeDecoration;
    OutlinedBorder getBorder() => getDecoration().shape as OutlinedBorder;

    expect(find.text('Company'), findsOneWidget);
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    expect(containerHasFocus(), isFalse);
    expect(getBorder().side.width, equals(1));
    expect(getContainer().color, isNull);
    expect(getDecoration().color, isNull);

    await tester.tap(find.byType(TextField).at(1));
    await tester.pumpAndSettle();
    expect(containerHasFocus(), isTrue);
    expect(getBorder().side.width, equals(4));
    expect(getDecoration().color, equals(Colors.blue.shade50));

    await tester.tap(find.byType(TextField).at(2));
    await tester.pumpAndSettle();
    expect(containerHasFocus(), isTrue);
    expect(getBorder().side.width, equals(4));
    expect(getDecoration().color, equals(Colors.blue.shade50));
  });
}
