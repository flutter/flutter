// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Radio group control test', (WidgetTester tester) async {
    final UniqueKey key0 = UniqueKey();
    final UniqueKey key1 = UniqueKey();

    await tester.pumpWidget(
      Material(
        child: TestRadioGroup<int>(
          child: Column(
            children: <Widget>[
              Radio<int>(key: key0, value: 0),
              Radio<int>(key: key1, value: 1),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key0)),
      containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: true),
    );
    expect(
      tester.getSemantics(find.byKey(key1)),
      containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: true),
    );

    await tester.tap(find.byKey(key0));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(key0)),
      containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: true, isEnabled: true),
    );
    expect(
      tester.getSemantics(find.byKey(key1)),
      containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: true),
    );

    await tester.tap(find.byKey(key1));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(key0)),
      containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: true),
    );
    expect(
      tester.getSemantics(find.byKey(key1)),
      containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: true, isEnabled: true),
    );
  });

  testWidgets('Radio group can have disabled radio', (WidgetTester tester) async {
    final UniqueKey key0 = UniqueKey();
    final UniqueKey key1 = UniqueKey();

    await tester.pumpWidget(
      Material(
        child: TestRadioGroup<int>(
          child: Column(
            children: <Widget>[
              Radio<int>(key: key0, value: 0, enabled: false),
              Radio<int>(key: key1, value: 1),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key0)),
      containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: false),
    );
    expect(
      tester.getSemantics(find.byKey(key1)),
      containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: true),
    );

    await tester.tap(find.byKey(key0));
    await tester.pumpAndSettle();
    // Can't be select because the radio is disabled.
    expect(
      tester.getSemantics(find.byKey(key0)),
      containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: false),
    );
    expect(
      tester.getSemantics(find.byKey(key1)),
      containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: false, isEnabled: true),
    );
  });

  testWidgets('Radio group will not merge up', (WidgetTester tester) async {
    await tester.pumpWidget(
      Material(
        child: Semantics(
          container: true,
          child: Column(
            children: <Widget>[
              Checkbox(value: true, onChanged: (bool? value) {}),
              const TestRadioGroup<int>(
                child: Column(children: <Widget>[Radio<int>(value: 0), Radio<int>(value: 1)]),
              ),
              Checkbox(value: true, onChanged: (bool? value) {}),
            ],
          ),
        ),
      ),
    );
    final SemanticsNode radioGroup = tester.getSemantics(find.byType(RadioGroup<int>));
    expect(radioGroup.childrenCount, 2);
  });

  testWidgets('Radio group can use arrow key', (WidgetTester tester) async {
    final UniqueKey key0 = UniqueKey();
    final UniqueKey key1 = UniqueKey();
    final UniqueKey key2 = UniqueKey();
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TestRadioGroup<int>(
            child: Column(
              children: <Widget>[
                Radio<int>(key: key0, focusNode: focusNode, value: 0),
                Radio<int>(key: key1, value: 1),
                Radio<int>(key: key2, value: 2),
              ],
            ),
          ),
        ),
      ),
    );

    final TestRadioGroupState<int> state = tester.state<TestRadioGroupState<int>>(
      find.byType(TestRadioGroup<int>),
    );

    await tester.tap(find.byKey(key0));
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);
    expect(focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(state.groupValue, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(state.groupValue, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    // Wrap around
    expect(state.groupValue, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    // Wrap around
    expect(state.groupValue, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    // Wrap around
    expect(state.groupValue, 1);
  });

  testWidgets('Radio group arrow key skips disabled radio', (WidgetTester tester) async {
    final UniqueKey key0 = UniqueKey();
    final UniqueKey key1 = UniqueKey();
    final UniqueKey key2 = UniqueKey();
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TestRadioGroup<int>(
            child: Column(
              children: <Widget>[
                Radio<int>(key: key0, focusNode: focusNode, value: 0),
                Radio<int>(key: key1, enabled: false, value: 1),
                Radio<int>(key: key2, value: 2),
              ],
            ),
          ),
        ),
      ),
    );

    final TestRadioGroupState<int> state = tester.state<TestRadioGroupState<int>>(
      find.byType(TestRadioGroup<int>),
    );

    await tester.tap(find.byKey(key0));
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);
    expect(focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(state.groupValue, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    // Wrap around
    expect(state.groupValue, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(state.groupValue, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    // Wrap around
    expect(state.groupValue, 2);
  });

  testWidgets('Radio group can tab in and out', (WidgetTester tester) async {
    final UniqueKey key0 = UniqueKey();
    final UniqueKey key1 = UniqueKey();
    final UniqueKey key2 = UniqueKey();
    final FocusNode radio0 = FocusNode();
    addTearDown(radio0.dispose);
    final FocusNode radio1 = FocusNode();
    addTearDown(radio1.dispose);
    final FocusNode textFieldBefore = FocusNode();
    addTearDown(textFieldBefore.dispose);
    final FocusNode textFieldAfter = FocusNode();
    addTearDown(textFieldAfter.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: <Widget>[
              TextField(focusNode: textFieldBefore),
              TestRadioGroup<int>(
                child: Column(
                  children: <Widget>[
                    Radio<int>(key: key0, focusNode: radio0, value: 0),
                    Radio<int>(key: key1, focusNode: radio1, value: 1),
                    Radio<int>(key: key2, value: 2),
                  ],
                ),
              ),
              TextField(focusNode: textFieldAfter),
            ],
          ),
        ),
      ),
    );

    textFieldBefore.requestFocus();
    await tester.pump();
    expect(textFieldBefore.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    // If no selected radio, focus the first.
    expect(textFieldBefore.hasFocus, isFalse);
    expect(radio0.hasFocus, isTrue);

    // tab out the radio group.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(radio0.hasFocus, isFalse);
    expect(radio1.hasFocus, isFalse);
    expect(textFieldAfter.hasFocus, isTrue);

    // Select the radio 1
    await tester.tap(find.byKey(key1));
    await tester.pump();
    final TestRadioGroupState<int> state = tester.state<TestRadioGroupState<int>>(
      find.byType(TestRadioGroup<int>),
    );
    expect(state.groupValue, 1);
    // focus textFieldAfter again.
    textFieldAfter.requestFocus();
    await tester.pump();
    expect(textFieldAfter.hasFocus, isTrue);

    // shift+tab in the radio again.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();
    // Should focus selected radio
    expect(radio0.hasFocus, isFalse);
    expect(radio1.hasFocus, isTrue);
    expect(textFieldAfter.hasFocus, isFalse);
  });

  // Regression test for https://github.com/flutter/flutter/issues/175258.
  testWidgets('Radio group throws on multiple selection', (WidgetTester tester) async {
    final UniqueKey key1 = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TestRadioGroup<int>(
            child: Column(
              children: <Widget>[
                const Radio<int>(value: 0),
                Radio<int>(key: key1, value: 1),
                const Radio<int>(value: 1),
                const Radio<int>(value: 2),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(key1));
    await tester.pump();

    expect(
      tester.takeException(),
      isA<FlutterError>().having(
        (FlutterError e) => e.message,
        'message',
        "RadioGroupPolicy can't be used for a radio group that allows multiple selection.",
      ),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/175258.
  testWidgets('Radio group does not throw when number of children decreases', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RadioGroup<int>(
            onChanged: (_) {},
            groupValue: 4,
            child: const Column(
              children: <Widget>[
                Radio<int>(value: 0),
                Radio<int>(value: 1),
                Radio<int>(value: 2),
                Radio<int>(value: 3),
                Radio<int>(value: 4),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RadioGroup<int>(
            onChanged: (_) {},
            groupValue: 4,
            child: const Column(
              children: <Widget>[
                Radio<int>(value: 1),
                Radio<int>(value: 2),
                Radio<int>(value: 3),
                Radio<int>(value: 4),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  // Regression test for https://github.com/flutter/flutter/issues/175511.
  testWidgets('Radio group does not intercept key events when no radio is focused', (
    WidgetTester tester,
  ) async {
    final List<String> log = <String>[];
    late final Map<ShortcutActivator, Intent> shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.arrowLeft): VoidCallbackIntent(() => log.add('←')),
      const SingleActivator(LogicalKeyboardKey.arrowRight): VoidCallbackIntent(() => log.add('→')),
      const SingleActivator(LogicalKeyboardKey.arrowDown): VoidCallbackIntent(() => log.add('↓')),
      const SingleActivator(LogicalKeyboardKey.arrowUp): VoidCallbackIntent(() => log.add('↑')),
      const SingleActivator(LogicalKeyboardKey.space): VoidCallbackIntent(() => log.add('_')),
    };

    final FocusNode firstRadioFocusNode = FocusNode();
    addTearDown(firstRadioFocusNode.dispose);
    final FocusNode textFieldFocusNode = FocusNode();
    addTearDown(textFieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Shortcuts(
            shortcuts: shortcuts,
            child: TestRadioGroup<int>(
              child: Column(
                children: <Widget>[
                  Radio<int>(focusNode: firstRadioFocusNode, value: 0),
                  const RadioListTile<int>(value: 1),
                  const Radio<int>(value: 2),
                  TextField(focusNode: textFieldFocusNode),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final TestRadioGroupState<int> state = tester.state<TestRadioGroupState<int>>(
      find.byType(TestRadioGroup<int>),
    );

    // Focus on the first radio and toggle it.
    firstRadioFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);
    expect(firstRadioFocusNode.hasFocus, isTrue);

    // Toggle the second radio with shortcut.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(state.groupValue, 1);
    // Log is empty because radio group handles shortcuts.
    expect(log, isEmpty);

    // Toggle the first radio with shortcut.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);
    expect(log, isEmpty);

    // Move focus to the text field.
    // Now radio group will ignore shortcuts as there are no focused radios.
    textFieldFocusNode.requestFocus();
    await tester.pumpAndSettle();

    // Verify that shortcuts are not intercepted by the radio group.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);
    expect(log, <String>['←']);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);
    expect(log, <String>['←', '→']);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);
    expect(log, <String>['←', '→', '↓']);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);
    expect(log, <String>['←', '→', '↓', '↑']);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);
    expect(log, <String>['←', '→', '↓', '↑', '_']);

    log.clear();
    expect(log, isEmpty);

    // Focus on the first radio.
    firstRadioFocusNode.requestFocus();
    await tester.pump();
    expect(state.groupValue, 0);
    expect(firstRadioFocusNode.hasFocus, isTrue);

    // Verify that radio group handles shortcuts again.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(state.groupValue, 1);
    expect(log, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(state.groupValue, 0);
    expect(log, isEmpty);
  });
}

class TestRadioGroup<T> extends StatefulWidget {
  const TestRadioGroup({super.key, required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() => TestRadioGroupState<T>();
}

class TestRadioGroupState<T> extends State<TestRadioGroup<T>> {
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
