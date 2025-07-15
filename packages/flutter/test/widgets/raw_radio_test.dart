// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RawRadio control test', (WidgetTester tester) async {
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);
    ToggleableStateMixin? actualState;
    final TestRegistry<int> registry = TestRegistry<int>();

    Widget buildWidget() {
      return RawRadio<int>(
        value: 0,
        mouseCursor: WidgetStateProperty.all<MouseCursor>(SystemMouseCursors.click),
        toggleable: true,
        focusNode: node,
        autofocus: false,
        enabled: true,
        groupRegistry: registry,
        builder: (BuildContext context, ToggleableStateMixin state) {
          actualState = state;
          return CustomPaint(size: const Size(40, 40), painter: TestPainter());
        },
      );
    }

    await tester.pumpWidget(buildWidget());
    expect(actualState!.tristate, isTrue);
    expect(actualState!.value, isFalse);
    expect(registry.groupValue, isNull);

    final State state = tester.state(find.byType(RawRadio<int>));
    expect(registry.clients.contains(state as RadioClient<int>), isTrue);

    await tester.tap(find.byType(RawRadio<int>));
    // Rebuilds with new group value
    await tester.pumpWidget(buildWidget());

    expect(registry.groupValue, 0);
    expect(actualState!.value, isTrue);
  });

  testWidgets('RawRadio disabled', (WidgetTester tester) async {
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);
    final TestRegistry<int> registry = TestRegistry<int>();

    Widget buildWidget() {
      return RawRadio<int>(
        value: 0,
        mouseCursor: WidgetStateProperty.all<MouseCursor>(SystemMouseCursors.click),
        toggleable: true,
        focusNode: node,
        autofocus: false,
        enabled: false,
        groupRegistry: registry,
        builder: (BuildContext context, ToggleableStateMixin state) {
          return CustomPaint(size: const Size(40, 40), painter: TestPainter());
        },
      );
    }

    await tester.pumpWidget(buildWidget());
    await tester.tap(find.byType(RawRadio<int>));
    // onChanged won't fire
    expect(registry.groupValue, isNull);
  });

  testWidgets('RawRadio enabled without registry throws', (WidgetTester tester) async {
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);

    Widget buildWidget() {
      return RawRadio<int>(
        value: 0,
        mouseCursor: WidgetStateProperty.all<MouseCursor>(SystemMouseCursors.click),
        toggleable: true,
        focusNode: node,
        autofocus: false,
        enabled: true,
        groupRegistry: null,
        builder: (BuildContext context, ToggleableStateMixin state) {
          return CustomPaint(size: const Size(40, 40), painter: TestPainter());
        },
      );
    }

    await expectLater(() => tester.pumpWidget(buildWidget()), throwsAssertionError);
  });
}

class TestRegistry<T> extends RadioGroupRegistry<T> {
  final Set<RadioClient<T>> clients = <RadioClient<T>>{};
  @override
  T? groupValue;

  @override
  ValueChanged<T?> get onChanged =>
      (T? newValue) => groupValue = newValue;

  @override
  void registerClient(RadioClient<T> radio) => clients.add(radio);

  @override
  void unregisterClient(RadioClient<T> radio) => clients.remove(radio);
}

class TestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
