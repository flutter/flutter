// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Radio control test', (WidgetTester tester) async {
    final Key key = UniqueKey();
    final List<int> log = <int>[];

    await tester.pumpWidget(Material(
      child: Center(
        child: Radio<int>(
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

    await tester.pumpWidget(Material(
      child: Center(
        child: Radio<int>(
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

    await tester.pumpWidget(Material(
      child: Center(
        child: Radio<int>(
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

  testWidgets('Radio can be toggled when toggleable is set', (WidgetTester tester) async {
    final Key key = UniqueKey();
    final List<int> log = <int>[];

    await tester.pumpWidget(Material(
      child: Center(
        child: Radio<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: log.add,
          toggleable: true,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[1]));
    log.clear();

    await tester.pumpWidget(Material(
      child: Center(
        child: Radio<int>(
          key: key,
          value: 1,
          groupValue: 1,
          onChanged: log.add,
          toggleable: true,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[null]));
    log.clear();

    await tester.pumpWidget(Material(
      child: Center(
        child: Radio<int>(
          key: key,
          value: 1,
          groupValue: null,
          onChanged: log.add,
          toggleable: true,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[1]));
  });

  testWidgets('Radio size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    final Key key1 = UniqueKey();
    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Radio<bool>(
                key: key1,
                groupValue: true,
                value: true,
                onChanged: (bool newValue) { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key1)), const Size(48.0, 48.0));

    final Key key2 = UniqueKey();
    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Radio<bool>(
                key: key2,
                groupValue: true,
                value: true,
                onChanged: (bool newValue) { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key2)), const Size(40.0, 40.0));
  });


  testWidgets('Radio semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(Material(
      child: Radio<int>(
        value: 1,
        groupValue: 2,
        onChanged: (int i) { },
      ),
    ));

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.isInMutuallyExclusiveGroup,
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isFocusable,
          ],
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    await tester.pumpWidget(Material(
      child: Radio<int>(
        value: 2,
        groupValue: 2,
        onChanged: (int i) { },
      ),
    ));

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.isInMutuallyExclusiveGroup,
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.isChecked,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isFocusable,
          ],
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    await tester.pumpWidget(const Material(
      child: Radio<int>(
        value: 1,
        groupValue: 2,
        onChanged: null,
      ),
    ));

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isInMutuallyExclusiveGroup,
            SemanticsFlag.isFocusable,  // This flag is delayed by 1 frame.
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    await tester.pump();

    // Now the isFocusable should be gone.
    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isInMutuallyExclusiveGroup,
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    await tester.pumpWidget(const Material(
      child: Radio<int>(
        value: 2,
        groupValue: 2,
        onChanged: null,
      ),
    ));

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.isChecked,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isInMutuallyExclusiveGroup,
          ],
        ),
      ],
    ), ignoreRect: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('has semantic events', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final Key key = UniqueKey();
    dynamic semanticEvent;
    int radioValue = 2;
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) async {
      semanticEvent = message;
    });

    await tester.pumpWidget(Material(
      child: Radio<int>(
        key: key,
        value: 1,
        groupValue: radioValue,
        onChanged: (int i) {
          radioValue = i;
        },
      ),
    ));

    await tester.tap(find.byKey(key));
    final RenderObject object = tester.firstRenderObject(find.byType(Focus));

    expect(radioValue, 1);
    expect(semanticEvent, <String, dynamic>{
      'type': 'tap',
      'nodeId': object.debugSemantics.id,
      'data': <String, dynamic>{},
    });
    expect(object.debugSemantics.getSemanticsData().hasAction(SemanticsAction.tap), true);

    semantics.dispose();
    SystemChannels.accessibility.setMockMessageHandler(null);
  });

  testWidgets('Radio ink ripple is displayed correctly', (WidgetTester tester) async {
    final Key painterKey = UniqueKey();
    const Key radioKey = Key('radio');

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(),
      home: Scaffold(
        body: RepaintBoundary(
          key: painterKey,
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              color: Colors.white,
              child: Radio<int>(
                key: radioKey,
                value: 1,
                groupValue: 1,
                onChanged: (int value) { },
              ),
            ),
          ),
        ),
      ),
    ));

    await tester.press(find.byKey(radioKey));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('radio.ink_ripple.png'),
    );
  });

  testWidgets('Radio is focusable and has correct focus color', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'Radio');
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    int groupValue = 0;
    const Key radioKey = Key('radio');
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.white,
                child: Radio<int>(
                  key: radioKey,
                  value: 0,
                  onChanged: enabled ? (int newValue) {
                    setState(() {
                      groupValue = newValue;
                    });
                  } : null,
                  focusColor: Colors.orange[500],
                  autofocus: true,
                  focusNode: focusNode,
                  groupValue: groupValue,
                ),
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());

    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      Material.of(tester.element(find.byKey(radioKey))),
      paints
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
        ..circle(color: Colors.orange[500])
        ..circle(color: const Color(0xff1e88e5))
        ..circle(color: const Color(0xff1e88e5)),
    );

    // Check when the radio isn't selected.
    groupValue = 1;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      Material.of(tester.element(find.byKey(radioKey))),
      paints
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
        ..circle(color: Colors.orange[500])
        ..circle(color: const Color(0x8a000000), style: PaintingStyle.stroke, strokeWidth: 2.0)
    );

    // Check when the radio is selected, but disabled.
    groupValue = 0;
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isFalse);
    expect(
      Material.of(tester.element(find.byKey(radioKey))),
      paints
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
        ..circle(color: const Color(0x61000000))
        ..circle(color: const Color(0x61000000)),
    );
  });

  testWidgets('Radio can be hovered and has correct hover color', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    int groupValue = 0;
    const Key radioKey = Key('radio');
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.white,
                child: Radio<int>(
                  key: radioKey,
                  value: 0,
                  onChanged: enabled ? (int newValue) {
                    setState(() {
                      groupValue = newValue;
                    });
                  } : null,
                  hoverColor: Colors.orange[500],
                  groupValue: groupValue,
                ),
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());

    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byKey(radioKey))),
      paints
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
        ..circle(color: const Color(0xff1e88e5))
        ..circle(color: const Color(0xff1e88e5)),
    );

    // Start hovering
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byKey(radioKey)));

    // Check when the radio isn't selected.
    groupValue = 1;
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
        Material.of(tester.element(find.byKey(radioKey))),
        paints
          ..rect(
              color: const Color(0xffffffff),
              rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
          ..circle(color: Colors.orange[500])
          ..circle(color: const Color(0x8a000000), style: PaintingStyle.stroke, strokeWidth: 2.0),
    );

    // Check when the radio is selected, but disabled.
    groupValue = 0;
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byKey(radioKey))),
      paints
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
        ..circle(color: const Color(0x61000000))
        ..circle(color: const Color(0x61000000)),
    );
  });

  testWidgets('Radio can be controlled by keyboard shortcuts', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    int groupValue = 1;
    const Key radioKey0 = Key('radio0');
    const Key radioKey1 = Key('radio1');
    const Key radioKey2 = Key('radio2');
    final FocusNode focusNode2 = FocusNode(debugLabel: 'radio2');
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 200,
                height: 100,
                color: Colors.white,
                child: Row(
                  children: <Widget>[
                    Radio<int>(
                      key: radioKey0,
                      value: 0,
                      onChanged: enabled ? (int newValue) {
                        setState(() {
                          groupValue = newValue;
                        });
                      } : null,
                      hoverColor: Colors.orange[500],
                      groupValue: groupValue,
                      autofocus: true,
                    ),
                    Radio<int>(
                      key: radioKey1,
                      value: 1,
                      onChanged: enabled ? (int newValue) {
                        setState(() {
                          groupValue = newValue;
                        });
                      } : null,
                      hoverColor: Colors.orange[500],
                      groupValue: groupValue,
                    ),
                    Radio<int>(
                      key: radioKey2,
                      value: 2,
                      onChanged: enabled ? (int newValue) {
                        setState(() {
                          groupValue = newValue;
                        });
                      } : null,
                      hoverColor: Colors.orange[500],
                      groupValue: groupValue,
                      focusNode: focusNode2,
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    // On web, radios don't respond to the enter key.
    expect(groupValue, kIsWeb ? equals(1) : equals(0));

    focusNode2.requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(groupValue, equals(2));
  });

  testWidgets('Radio responds to density changes.', (WidgetTester tester) async {
    const Key key = Key('test');
    Future<void> buildTest(VisualDensity visualDensity) async {
      return await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: Radio<int>(
                visualDensity: visualDensity,
                key: key,
                onChanged: (int value) {},
                value: 0,
                groupValue: 0,
              ),
            ),
          ),
        ),
      );
    }

    await buildTest(const VisualDensity());
    final RenderBox box = tester.renderObject(find.byKey(key));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(48, 48)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(60, 60)));

    await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(36, 36)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(60, 36)));
  });

  testWidgets('Radio changes mouse cursor when hovered', (WidgetTester tester) async {
    const Key key = ValueKey<int>(1);
    // Test Radio() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Radio<int>(
                  key: key,
                  mouseCursor: SystemMouseCursors.text,
                  value: 1,
                  onChanged: (int v) {},
                  groupValue: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byKey(key)));
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);


    // Test default cursor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Radio<int>(
                  value: 1,
                  onChanged: (int v) {},
                  groupValue: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);

    // Test default cursor when disabled
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Radio<int>(
                  value: 1,
                  onChanged: null,
                  groupValue: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);
  });
}
