// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Radio control test', (WidgetTester tester) async {
    final Key key = new UniqueKey();
    final List<int> log = <int>[];

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new Radio<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: log.add,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[1]));
    log.clear();

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new Radio<int>(
          key: key,
          value: 1,
          groupValue: 1,
          onChanged: log.add,
          activeColor: Colors.green[500],
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, isEmpty);

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new Radio<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: null,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, isEmpty);
  });

  testWidgets('Radio semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(new Material(
      child: new Radio<int>(
        value: 1,
        groupValue: 2,
        onChanged: (int i) { },
      ),
    ));

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.isInMutuallyExclusiveGroup,
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
          ],
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    await tester.pumpWidget(new Material(
      child: new Radio<int>(
        value: 2,
        groupValue: 2,
        onChanged: (int i) { },
      ),
    ));

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.isInMutuallyExclusiveGroup,
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.isChecked,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
          ],
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    await tester.pumpWidget(const Material(
      child: const Radio<int>(
        value: 1,
        groupValue: 2,
        onChanged: null,
      ),
    ));

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.isInMutuallyExclusiveGroup,
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    await tester.pumpWidget(const Material(
      child: const Radio<int>(
        value: 2,
        groupValue: 2,
        onChanged: null,
      ),
    ));

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.isInMutuallyExclusiveGroup,
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.isChecked,
            SemanticsFlag.hasEnabledState,
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    semantics.dispose();
  });
}
