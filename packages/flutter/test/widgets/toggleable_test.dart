// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Toggleable exists in widget layer', (WidgetTester tester) async {
    final testPainter = TestPainter();
    expect(testPainter, isA<ToggleablePainter>());
    expect(testPainter, isNot(throwsException));
  });

  testWidgets('Toggleable can be toggled by tap', (WidgetTester tester) async {
    await tester.pumpWidget(const TestWidgetsApp(home: TestToggleable()));
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

  testWidgets('reactionController defaults to a 100ms duration', (WidgetTester tester) async {
    await tester.pumpWidget(const TestWidgetsApp(home: TestToggleable()));
    final TestToggleableState state = tester.state<TestToggleableState>(
      find.byType(TestToggleable),
    );

    expect(state.reactionController.duration, const Duration(milliseconds: 100));
  });

  testWidgets('null reactionAnimationDuration override falls back to the 100ms default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TestWidgetsApp(home: TestToggleable()));
    final TestToggleableState state = tester.state<TestToggleableState>(
      find.byType(TestToggleable),
    );

    expect(state.reactionController.duration, const Duration(milliseconds: 100));
  });

  testWidgets('reactionAnimationDuration override is used by the reactionController', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: TestToggleable(reactionAnimationDuration: Duration(milliseconds: 250)),
      ),
    );
    final TestToggleableState state = tester.state<TestToggleableState>(
      find.byType(TestToggleable),
    );

    expect(state.reactionController.duration, const Duration(milliseconds: 250));
  });

  testWidgets('reactionAnimationDuration is only read when the state initializes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: TestToggleable(reactionAnimationDuration: Duration(milliseconds: 250)),
      ),
    );
    final TestToggleableState state = tester.state<TestToggleableState>(
      find.byType(TestToggleable),
    );

    // Pump again with a different reactionAnimationDuration but without
    // re-initializing state.
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: TestToggleable(reactionAnimationDuration: Duration(milliseconds: 400)),
      ),
    );

    expect(state.reactionController.duration, const Duration(milliseconds: 250));
  });
}

class TestPainter extends ToggleablePainter {
  @override
  void paint(Canvas canvas, Size size) {}
}

class TestToggleable extends StatefulWidget {
  const TestToggleable({super.key, this.reactionAnimationDuration});

  final Duration? reactionAnimationDuration;

  @override
  State<StatefulWidget> createState() => TestToggleableState();
}

class TestToggleableState extends State<TestToggleable>
    with TickerProviderStateMixin, ToggleableStateMixin {
  @override
  Duration? get reactionAnimationDuration => widget.reactionAnimationDuration;
  
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
