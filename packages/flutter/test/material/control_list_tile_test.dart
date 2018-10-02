// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/semantics_tester.dart';

Widget wrap({ Widget child }) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Material(child: child),
    ),
  );
}

void main() {
  testWidgets('CheckboxListTile control test', (WidgetTester tester) async {
    final List<dynamic> log = <dynamic>[];
    await tester.pumpWidget(wrap(
      child: CheckboxListTile(
        value: true,
        onChanged: (bool value) { log.add(value); },
        title: const Text('Hello'),
      ),
    ));
    await tester.tap(find.text('Hello'));
    log.add('-');
    await tester.tap(find.byType(Checkbox));
    expect(log, equals(<dynamic>[false, '-', false]));
  });

  testWidgets('RadioListTile control test', (WidgetTester tester) async {
    final List<dynamic> log = <dynamic>[];
    await tester.pumpWidget(wrap(
      child: RadioListTile<bool>(
        value: true,
        groupValue: false,
        onChanged: (bool value) { log.add(value); },
        title: const Text('Hello'),
      ),
    ));
    await tester.tap(find.text('Hello'));
    log.add('-');
    await tester.tap(find.byType(const Radio<bool>(value: false, groupValue: false, onChanged: null).runtimeType));
    expect(log, equals(<dynamic>[true, '-', true]));
  });

  testWidgets('SwitchListTile control test', (WidgetTester tester) async {
    final List<dynamic> log = <dynamic>[];
    await tester.pumpWidget(wrap(
      child: SwitchListTile(
        value: true,
        onChanged: (bool value) { log.add(value); },
        title: const Text('Hello'),
      ),
    ));
    await tester.tap(find.text('Hello'));
    log.add('-');
    await tester.tap(find.byType(Switch));
    expect(log, equals(<dynamic>[false, '-', false]));
  });

  testWidgets('SwitchListTile control test', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(wrap(
      child: Column(
        children: <Widget>[
          SwitchListTile(
            value: true,
            onChanged: (bool value) { },
            title: const Text('AAA'),
            secondary: const Text('aaa'),
          ),
          CheckboxListTile(
            value: true,
            onChanged: (bool value) { },
            title: const Text('BBB'),
            secondary: const Text('bbb'),
          ),
          RadioListTile<bool>(
            value: true,
            groupValue: false,
            onChanged: (bool value) { },
            title: const Text('CCC'),
            secondary: const Text('ccc'),
          ),
        ],
      ),
    ));

    // This test verifies that the label and the control get merged.
    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          rect: Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: null,
          flags: <SemanticsFlag>[
            SemanticsFlag.hasToggledState,
            SemanticsFlag.isToggled,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled
          ],
          actions: SemanticsAction.tap.index,
          label: 'aaa\nAAA',
        ),
        TestSemantics.rootChild(
          id: 3,
          rect: Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: Matrix4.translationValues(0.0, 56.0, 0.0),
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.isChecked,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled
          ],
          actions: SemanticsAction.tap.index,
          label: 'bbb\nBBB',
        ),
        TestSemantics.rootChild(
          id: 5,
          rect: Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: Matrix4.translationValues(0.0, 112.0, 0.0),
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isInMutuallyExclusiveGroup,
          ],
          actions: SemanticsAction.tap.index,
          label: 'CCC\nccc',
        ),
      ],
    )));

    semantics.dispose();
  });

}
