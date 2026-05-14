// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/basic/absorb_pointer.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AbsorbPointer prevents taps on its subtree', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.AbsorbPointerApp());

    expect(find.text('Absorbing: false'), findsOneWidget);
    expect(find.text('Last button pressed: none'), findsOneWidget);

    await tester.tap(find.text('Button 1'));
    await tester.pump();
    expect(find.text('Last button pressed: Button 1'), findsOneWidget);

    await tester.tap(find.text('Button 2'));
    await tester.pump();
    expect(find.text('Last button pressed: Button 2'), findsOneWidget);

    await tester.tap(find.text('Set absorbing to true'));
    await tester.pump();
    expect(find.text('Absorbing: true'), findsOneWidget);

    await tester.tap(find.text('Button 1'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Last button pressed: Button 2'), findsOneWidget);

    await tester.tap(find.text('Set absorbing to false'));
    await tester.pump();
    expect(find.text('Absorbing: false'), findsOneWidget);

    await tester.tap(find.text('Button 1'));
    await tester.pump();
    expect(find.text('Last button pressed: Button 1'), findsOneWidget);
  });
}
