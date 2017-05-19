// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlags;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('CheckboxListTile control test', (WidgetTester tester) async {
    final List<dynamic> log = <dynamic>[];
    await tester.pumpWidget(new Material(
      child: new CheckboxListTile(
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
    await tester.pumpWidget(new Material(
      child: new RadioListTile<bool>(
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
    await tester.pumpWidget(new Material(
      child: new SwitchListTile(
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
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(new Material(
      child: new Column(
        children: <Widget>[
          new SwitchListTile(
            value: true,
            onChanged: (bool value) { },
            title: const Text('AAA'),
            secondary: const Text('aaa'),
          ),
          new CheckboxListTile(
            value: true,
            onChanged: (bool value) { },
            title: const Text('BBB'),
            secondary: const Text('bbb'),
          ),
          new RadioListTile<bool>(
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
    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          rect: new Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: null,
          flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
          actions: SemanticsAction.tap.index,
          label: 'aaa\nAAA',
        ),
        new TestSemantics.rootChild(
          id: 6,
          rect: new Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: new Matrix4.translationValues(0.0, 56.0, 0.0),
          flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
          actions: SemanticsAction.tap.index,
          label: 'bbb\nBBB',
        ),
        new TestSemantics.rootChild(
          id: 11,
          rect: new Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: new Matrix4.translationValues(0.0, 112.0, 0.0),
          flags: SemanticsFlags.hasCheckedState.index,
          actions: SemanticsAction.tap.index,
          label: 'CCC\nccc',
        ),
      ],
    )));
  });

}
