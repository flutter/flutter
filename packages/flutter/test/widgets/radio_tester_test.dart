// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'radio_tester.dart';
import 'widgets_app_tester.dart';

/// A stateful wrapper that hosts a [RadioGroup] with a mutable [groupValue],
/// making it easy to pump and interact with [TestRadio] buttons in tests.
class _TestRadioGroup<T> extends StatefulWidget {
  const _TestRadioGroup({super.key, required this.child});

  final Widget child;

  @override
  State<_TestRadioGroup<T>> createState() => _TestRadioGroupState<T>();
}

class _TestRadioGroupState<T> extends State<_TestRadioGroup<T>> {
  T? groupValue;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      onChanged: (T? newValue) {
        setState(() {
          groupValue = newValue;
        });
      },
      groupValue: groupValue,
      child: widget.child,
    );
  }
}

void main() {
  testWidgets('TestRadio renders and can be selected', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: _TestRadioGroup<int>(
          child: Column(children: <Widget>[TestRadio<int>(value: 0), TestRadio<int>(value: 1)]),
        ),
      ),
    );

    final _TestRadioGroupState<int> state = tester.state<_TestRadioGroupState<int>>(
      find.byType(_TestRadioGroup<int>),
    );

    expect(state.groupValue, isNull);

    await tester.tap(find.byType(TestRadio<int>).first);
    await tester.pump();
    expect(state.groupValue, 0);

    await tester.tap(find.byType(TestRadio<int>).last);
    await tester.pump();
    expect(state.groupValue, 1);
  });

  testWidgets('TestRadio disabled cannot be selected', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: _TestRadioGroup<int>(
          child: Column(
            children: <Widget>[TestRadio<int>(value: 0, enabled: false), TestRadio<int>(value: 1)],
          ),
        ),
      ),
    );

    final _TestRadioGroupState<int> state = tester.state<_TestRadioGroupState<int>>(
      find.byType(_TestRadioGroup<int>),
    );

    await tester.tap(find.byType(TestRadio<int>).first);
    await tester.pump();
    // Disabled radio must not update the group value.
    expect(state.groupValue, isNull);

    await tester.tap(find.byType(TestRadio<int>).last);
    await tester.pump();
    expect(state.groupValue, 1);
  });

  testWidgets('TestRadio provides correct semantics', (WidgetTester tester) async {
    final key0 = UniqueKey();
    final key1 = UniqueKey();

    await tester.pumpWidget(
      TestWidgetsApp(
        home: _TestRadioGroup<int>(
          child: Column(
            children: <Widget>[
              TestRadio<int>(key: key0, value: 0),
              TestRadio<int>(key: key1, value: 1),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byKey(key0)),
      isSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: true),
    );
    expect(
      tester.getSemantics(find.byKey(key1)),
      isSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: true),
    );

    await tester.tap(find.byKey(key0));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byKey(key0)),
      isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true, isEnabled: true),
    );
    expect(
      tester.getSemantics(find.byKey(key1)),
      isSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: true),
    );
  });

  testWidgets('TestRadio disabled provides correct semantics', (WidgetTester tester) async {
    final key = UniqueKey();

    await tester.pumpWidget(
      TestWidgetsApp(
        home: _TestRadioGroup<int>(
          child: Column(children: <Widget>[TestRadio<int>(key: key, value: 0, enabled: false)]),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byKey(key)),
      isSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: false),
    );
  });

  testWidgets('TestRadio has correct size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: _TestRadioGroup<int>(child: Column(children: <Widget>[TestRadio<int>(value: 0)])),
      ),
    );

    final Size size = tester.getSize(find.byType(SizedBox).last);
    expect(size, const Size(18.0, 18.0));
  });

  testWidgets('TestRadio accepts an external FocusNode', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      TestWidgetsApp(
        home: _TestRadioGroup<int>(
          child: Column(children: <Widget>[TestRadio<int>(value: 0, focusNode: focusNode)]),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('TestRegistry registers and unregisters clients', (WidgetTester tester) async {
    final registry = TestRegistry<int>();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RawRadio<int>(
          value: 0,
          mouseCursor: WidgetStateProperty.all<MouseCursor>(SystemMouseCursors.click),
          toggleable: false,
          focusNode: focusNode,
          autofocus: false,
          groupRegistry: registry,
          enabled: true,
          builder: (BuildContext context, ToggleableStateMixin state) =>
              const SizedBox(width: 18, height: 18),
        ),
      ),
    );

    expect(registry.clients, hasLength(1));

    // Pumping an empty widget removes the RawRadio, which should unregister.
    await tester.pumpWidget(const SizedBox());
    expect(registry.clients, isEmpty);
  });
}
