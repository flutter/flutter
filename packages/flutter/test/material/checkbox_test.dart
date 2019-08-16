// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('Checkbox size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Checkbox(
                value: true,
                onChanged: (bool newValue) { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Checkbox)), const Size(48.0, 48.0));

    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Checkbox(
                value: true,
                onChanged: (bool newValue) { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Checkbox)), const Size(40.0, 40.0));
  });

  testWidgets('CheckBox semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(Material(
      child: Checkbox(
        value: false,
        onChanged: (bool b) { },
      ),
    ));

    expect(tester.getSemantics(find.byType(Checkbox)), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
    ));

    await tester.pumpWidget(Material(
      child: Checkbox(
        value: true,
        onChanged: (bool b) { },
      ),
    ));

    expect(tester.getSemantics(find.byType(Checkbox)), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isChecked: true,
      isEnabled: true,
      hasTapAction: true,
    ));

    await tester.pumpWidget(const Material(
      child: Checkbox(
        value: false,
        onChanged: null,
      ),
    ));

    expect(tester.getSemantics(find.byType(Checkbox)), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
    ));

    await tester.pumpWidget(const Material(
      child: Checkbox(
        value: true,
        onChanged: null,
      ),
    ));

    expect(tester.getSemantics(find.byType(Checkbox)), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isChecked: true,
    ));
    handle.dispose();
  });

  testWidgets('Can wrap CheckBox with Semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(Material(
      child: Semantics(
        label: 'foo',
        textDirection: TextDirection.ltr,
        child: Checkbox(
          value: false,
          onChanged: (bool b) { },
        ),
      ),
    ));

    expect(tester.getSemantics(find.byType(Checkbox)), matchesSemantics(
      label: 'foo',
      textDirection: TextDirection.ltr,
      hasCheckedState: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
    ));
    handle.dispose();
  });

  testWidgets('CheckBox tristate: true', (WidgetTester tester) async {
    bool checkBoxValue;

    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Checkbox(
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
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Material(
        child: Checkbox(
          tristate: true,
          value: null,
          onChanged: (bool newValue) { },
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

    await tester.pumpWidget(
      Material(
        child: Checkbox(
          tristate: true,
          value: true,
          onChanged: (bool newValue) { },
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
      Material(
        child: Checkbox(
          tristate: true,
          value: false,
          onChanged: (bool newValue) { },
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
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) async {
      semanticEvent = message;
    });
    final SemanticsTester semanticsTester = SemanticsTester(tester);

    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Checkbox(
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

  testWidgets('CheckBox tristate rendering, programmatic transitions', (WidgetTester tester) async {
    Widget buildFrame(bool checkboxValue) {
      return Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Checkbox(
              tristate: true,
              value: checkboxValue,
              onChanged: (bool value) { },
            );
          },
        ),
      );
    }

    RenderToggleable getCheckboxRenderer() {
      return tester.renderObject<RenderToggleable>(find.byType(Checkbox));
    }

    await tester.pumpWidget(buildFrame(false));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), isNot(paints..path())); // checkmark is rendered as a path
    expect(getCheckboxRenderer(), isNot(paints..line())); // null is rendered as a line (a "dash")
    expect(getCheckboxRenderer(), paints..drrect()); // empty checkbox

    await tester.pumpWidget(buildFrame(true));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..path()); // checkmark is rendered as a path

    await tester.pumpWidget(buildFrame(false));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), isNot(paints..path())); // checkmark is rendered as a path
    expect(getCheckboxRenderer(), isNot(paints..line())); // null is rendered as a line (a "dash")
    expect(getCheckboxRenderer(), paints..drrect()); // empty checkbox

    await tester.pumpWidget(buildFrame(null));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..line()); // null is rendered as a line (a "dash")

    await tester.pumpWidget(buildFrame(true));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..path()); // checkmark is rendered as a path

    await tester.pumpWidget(buildFrame(null));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..line()); // null is rendered as a line (a "dash")
  });

  testWidgets('CheckBox color rendering', (WidgetTester tester) async {
    Widget buildFrame({Color activeColor, Color checkColor, ThemeData themeData}) {
      return Material(
        child: Theme(
          data: themeData ?? ThemeData(),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Checkbox(
                value: true,
                activeColor: activeColor,
                checkColor: checkColor,
                onChanged: (bool value) { },
              );
            },
          ),
        ),
      );
    }

    RenderToggleable getCheckboxRenderer() {
      return tester.renderObject<RenderToggleable>(find.byType(Checkbox));
    }

    await tester.pumpWidget(buildFrame(checkColor: const Color(0xFFFFFFFF)));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..path(color: const Color(0xFFFFFFFF))); // paints's color is 0xFFFFFFFF (default color)

    await tester.pumpWidget(buildFrame(checkColor: const Color(0xFF000000)));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..path(color: const Color(0xFF000000))); // paints's color is 0xFF000000 (params)

    await tester.pumpWidget(buildFrame(themeData: ThemeData(toggleableActiveColor: const Color(0xFF00FF00))));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..rrect(color: const Color(0xFF00FF00))); // paints's color is 0xFF00FF00 (theme)

    await tester.pumpWidget(buildFrame(activeColor: const Color(0xFF000000)));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..rrect(color: const Color(0xFF000000))); // paints's color is 0xFF000000 (params)
  });

}
