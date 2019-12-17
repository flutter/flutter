// Copyright 2014 The Flutter Authors. All rights reserved.
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
  testWidgets('RadioListTile should initialize according to groupValue', (WidgetTester tester) async {
    final List<int> values = <int>[0, 1, 2];
    int selectedValue;
    // Constructor parameters are required for [RadioListTile], but they are
    // irrelevant when searching with [find.byType].
    final Type radioListTileType = const RadioListTile<int>(
      value: 0,
      groupValue: 0,
      onChanged: null,
    ).runtimeType;

    List<RadioListTile<int>> generatedRadioListTiles;
    List<RadioListTile<int>> findTiles() => find
      .byType(radioListTileType)
      .evaluate()
      .map<Widget>((Element element) => element.widget)
      .cast<RadioListTile<int>>()
      .toList();

    Widget buildFrame() {
      return wrap(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: ListView.builder(
                itemCount: values.length,
                itemBuilder: (BuildContext context, int index) => RadioListTile<int>(
                  onChanged: (int value) {
                    setState(() { selectedValue = value; });
                  },
                  value: values[index],
                  groupValue: selectedValue,
                  title: Text(values[index].toString()),
                ),
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    generatedRadioListTiles = findTiles();

    expect(generatedRadioListTiles[0].checked, equals(false));
    expect(generatedRadioListTiles[1].checked, equals(false));
    expect(generatedRadioListTiles[2].checked, equals(false));

    selectedValue = 1;

    await tester.pumpWidget(buildFrame());
    generatedRadioListTiles = findTiles();

    expect(generatedRadioListTiles[0].checked, equals(false));
    expect(generatedRadioListTiles[1].checked, equals(true));
    expect(generatedRadioListTiles[2].checked, equals(false));
  });

  testWidgets('RadioListTile control tests', (WidgetTester tester) async {
    final List<int> values = <int>[0, 1, 2];
    int selectedValue;
    // Constructor parameters are required for [Radio], but they are irrelevant
    // when searching with [find.byType].
    final Type radioType = const Radio<int>(
      value: 0,
      groupValue: 0,
      onChanged: null,
    ).runtimeType;
    final List<dynamic> log = <dynamic>[];

    Widget buildFrame() {
      return wrap(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: ListView.builder(
                itemCount: values.length,
                itemBuilder: (BuildContext context, int index) => RadioListTile<int>(
                  onChanged: (int value) {
                    log.add(value);
                    setState(() { selectedValue = value; });
                  },
                  value: values[index],
                  groupValue: selectedValue,
                  title: Text(values[index].toString()),
                ),
              ),
            );
          },
        ),
      );
    }

    // Tests for tapping between [Radio] and [ListTile]
    await tester.pumpWidget(buildFrame());
    await tester.tap(find.text('1'));
    log.add('-');
    await tester.tap(find.byType(radioType).at(2));
    expect(log, equals(<dynamic>[1, '-', 2]));
    log.add('-');
    await tester.tap(find.text('1'));

    log.clear();
    selectedValue = null;

    // Tests for tapping across [Radio]s exclusively
    await tester.pumpWidget(buildFrame());
    await tester.tap(find.byType(radioType).at(1));
    log.add('-');
    await tester.tap(find.byType(radioType).at(2));
    expect(log, equals(<dynamic>[1, '-', 2]));

    log.clear();
    selectedValue = null;

    // Tests for tapping across [ListTile]s exclusively
    await tester.pumpWidget(buildFrame());
    await tester.tap(find.text('1'));
    log.add('-');
    await tester.tap(find.text('2'));
    expect(log, equals(<dynamic>[1, '-', 2]));
  });

  testWidgets('Selected RadioListTile should not trigger onChanged', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/30311
    final List<int> values = <int>[0, 1, 2];
    int selectedValue;
    // Constructor parameters are required for [Radio], but they are irrelevant
    // when searching with [find.byType].
    final Type radioType = const Radio<int>(
      value: 0,
      groupValue: 0,
      onChanged: null,
    ).runtimeType;
    final List<dynamic> log = <dynamic>[];

    Widget buildFrame() {
      return wrap(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: ListView.builder(
                itemCount: values.length,
                itemBuilder: (BuildContext context, int index) => RadioListTile<int>(
                  onChanged: (int value) {
                    log.add(value);
                    setState(() { selectedValue = value; });
                  },
                  value: values[index],
                  groupValue: selectedValue,
                  title: Text(values[index].toString()),
                ),
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    await tester.tap(find.text('0'));
    await tester.pump();
    expect(log, equals(<int>[0]));

    await tester.tap(find.text('0'));
    expect(log, equals(<int>[0]));

    await tester.tap(find.byType(radioType).at(0));
    await tester.pump();
    expect(log, equals(<int>[0]));
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
          rect: const Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: null,
          flags: <SemanticsFlag>[
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.hasToggledState,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isFocusable,
            SemanticsFlag.isToggled,
          ],
          actions: SemanticsAction.tap.index,
          label: 'aaa\nAAA',
        ),
        TestSemantics.rootChild(
          id: 3,
          rect: const Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: Matrix4.translationValues(0.0, 56.0, 0.0),
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isChecked,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isFocusable,
          ],
          actions: SemanticsAction.tap.index,
          label: 'bbb\nBBB',
        ),
        TestSemantics.rootChild(
          id: 5,
          rect: const Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: Matrix4.translationValues(0.0, 112.0, 0.0),
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isFocusable,
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
