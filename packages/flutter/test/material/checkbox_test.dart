// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../widgets/semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('Checkbox size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Material(
            child: new Center(
              child: new Checkbox(
                value: true,
                onChanged: (bool newValue) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Checkbox)), const Size(48.0, 48.0));

    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Material(
            child: new Center(
              child: new Checkbox(
                value: true,
                onChanged: (bool newValue) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Checkbox)), const Size(40.0, 40.0));
  });

  testWidgets('CheckBox semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(new Material(
      child: new Checkbox(
        value: false,
        onChanged: (bool b) { },
      ),
    ));

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
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
      child: new Checkbox(
        value: true,
        onChanged: (bool b) { },
      ),
    ));

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
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
      child: const Checkbox(
        value: false,
        onChanged: null,
      ),
    ));

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    await tester.pumpWidget(const Material(
      child: const Checkbox(
        value: true,
        onChanged: null,
      ),
    ));

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.isChecked,
            SemanticsFlag.hasEnabledState,
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('Can wrap CheckBox with Semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(new Material(
      child: new Semantics(
        label: 'foo',
        textDirection: TextDirection.ltr,
        child: new Checkbox(
          value: false,
          onChanged: (bool b) { },
        ),
      ),
    ));

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          label: 'foo',
          textDirection: TextDirection.ltr,
          flags: <SemanticsFlag>[
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

    semantics.dispose();
  });

  testWidgets('CheckBox tristate: true', (WidgetTester tester) async {
    bool checkBoxValue;

    await tester.pumpWidget(
      new Material(
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new Checkbox(
              tristate: true,
              value: checkBoxValue,
              onChanged: (bool value) {
                setState(() {
                  checkBoxValue = value;
                });
              },
            );
          },
        ),
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, null);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(checkBoxValue, false);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(checkBoxValue, true);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(checkBoxValue, null);

    checkBoxValue = true;
    await tester.pumpAndSettle();
    expect(checkBoxValue, true);

    checkBoxValue = null;
    await tester.pumpAndSettle();
    expect(checkBoxValue, null);
  });

  testWidgets('has semantics for tristate', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new Material(
        child: new Checkbox(
          tristate: true,
          value: null,
          onChanged: (bool newValue) {},
        ),
      ),
    );

    expect(semantics.nodesWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.hasCheckedState,
        SemanticsFlag.hasEnabledState,
        SemanticsFlag.isEnabled
      ],
      actions: <SemanticsAction>[SemanticsAction.tap],
    ), hasLength(1));

    await tester.pumpWidget(
      new Material(
        child: new Checkbox(
          tristate: true,
          value: true,
          onChanged: (bool newValue) {},
        ),
      ),
    );

    expect(semantics.nodesWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.hasCheckedState,
        SemanticsFlag.hasEnabledState,
        SemanticsFlag.isEnabled,
        SemanticsFlag.isChecked,
      ],
      actions: <SemanticsAction>[SemanticsAction.tap],
    ), hasLength(1));

    await tester.pumpWidget(
      new Material(
        child: new Checkbox(
          tristate: true,
          value: false,
          onChanged: (bool newValue) {},
        ),
      ),
    );

    expect(semantics.nodesWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.hasCheckedState,
        SemanticsFlag.hasEnabledState,
        SemanticsFlag.isEnabled,
      ],
      actions: <SemanticsAction>[SemanticsAction.tap],
    ), hasLength(1));

    semantics.dispose();
  });

  testWidgets('has semantic events', (WidgetTester tester) async {
    dynamic semanticEvent;
    bool checkboxValue = false;
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) {
      semanticEvent = message;
    });
    final SemanticsTester semanticsTester = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Material(
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new Checkbox(
              value: checkboxValue,
              onChanged: (bool value) {
                setState(() {
                  checkboxValue = value;
                });
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    final RenderObject object = tester.firstRenderObject(find.byType(Checkbox));

    expect(checkboxValue, true);
    expect(semanticEvent, <String, dynamic>{
      'type': 'tap',
      'nodeId': object.debugSemantics.id,
      'data': <String, dynamic>{},
    });
    expect(object.debugSemantics.getSemanticsData().hasAction(SemanticsAction.tap), true);

    SystemChannels.accessibility.setMockMessageHandler(null);
    semanticsTester.dispose();
  });
}
