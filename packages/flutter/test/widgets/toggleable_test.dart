// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Toggleable exists in widget layer', (WidgetTester tester) async {
    final testPainter = TestPainter();
    expect(testPainter, isA<ToggleablePainter>());
    expect(testPainter, isNot(throwsException));
  });

  testWidgets('Toggleable exists in widget layer', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TestToggleable()));
    final TestToggleableState state = tester.state<TestToggleableState>(
      find.byType(TestToggleable),
    );

    expect(find.text('child'), findsOneWidget);
    expect(state.value, isTrue);

    await tester.tap(find.byType(TestToggleable));
    await tester.pumpAndSettle();
    expect(state.value, isNull);

    await tester.tap(find.byType(TestToggleable));
    await tester.pumpAndSettle();
    expect(state.value, isFalse);
  });
}

class TestPainter extends ToggleablePainter {
  @override
  void paint(Canvas canvas, Size size) {}
}

class TestToggleable extends StatefulWidget {
  const TestToggleable({super.key});

  @override
  State<StatefulWidget> createState() => TestToggleableState();
}

class TestToggleableState extends State<TestToggleable>
    with TickerProviderStateMixin, ToggleableStateMixin {
  @override
  Widget build(BuildContext context) {
    return buildToggleableWithChild(child: const Text('child'));
  }

  @override
  ValueChanged<bool?>? get onChanged =>
      (bool? value) => this.value = value;

  @override
  bool tristate = true;

  @override
  bool? value = true;
}
