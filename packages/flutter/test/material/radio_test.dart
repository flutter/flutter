// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    final List<int?> log = <int?>[];

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
    final List<int?> log = <int?>[];

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

    expect(log, equals(<int?>[null]));
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
                onChanged: (bool? newValue) { },
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
                onChanged: (bool? newValue) { },
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
        onChanged: (int? i) { },
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
        onChanged: (int? i) { },
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
    int? radioValue = 2;
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) async {
      semanticEvent = message;
    });

    await tester.pumpWidget(Material(
      child: Radio<int>(
        key: key,
        value: 1,
        groupValue: radioValue,
        onChanged: (int? i) {
          radioValue = i;
        },
      ),
    ));

    await tester.tap(find.byKey(key));
    final RenderObject object = tester.firstRenderObject(find.byKey(key));

    expect(radioValue, 1);
    expect(semanticEvent, <String, dynamic>{
      'type': 'tap',
      'nodeId': object.debugSemantics!.id,
      'data': <String, dynamic>{},
    });
    expect(object.debugSemantics!.getSemanticsData().hasAction(SemanticsAction.tap), true);

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
                onChanged: (int? value) { },
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

  testWidgets('Radio with splash radius set', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    const double splashRadius = 30;
    Widget buildApp() {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.white,
                child: Radio<int>(
                  value: 0,
                  onChanged: (int? newValue) {},
                  focusColor: Colors.orange[500],
                  autofocus: true,
                  groupValue: 0,
                  splashRadius: splashRadius,
                ),
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(
        find.byWidgetPredicate((Widget widget) => widget is Radio<int>),
      )),
      paints..circle(color: Colors.orange[500], radius: splashRadius)
    );
  });

  testWidgets('Radio is focusable and has correct focus color', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'Radio');
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    int? groupValue = 0;
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
                  onChanged: enabled ? (int? newValue) {
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
    int? groupValue = 0;
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
                  onChanged: enabled ? (int? newValue) {
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
    int? groupValue = 1;
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
                      onChanged: enabled ? (int? newValue) {
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
                      onChanged: enabled ? (int? newValue) {
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
                      onChanged: enabled ? (int? newValue) {
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
      return tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: Radio<int>(
                visualDensity: visualDensity,
                key: key,
                onChanged: (int? value) {},
                value: 0,
                groupValue: 0,
              ),
            ),
          ),
        ),
      );
    }

    await buildTest(VisualDensity.standard);
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
                  onChanged: (int? v) {},
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

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);


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
                  onChanged: (int? v) {},
                  groupValue: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);

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

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);
  });

  testWidgets('Radio button fill color resolves in enabled/disabled states', (WidgetTester tester) async {
    const Color activeEnabledFillColor = Color(0xFF000001);
    const Color activeDisabledFillColor = Color(0xFF000002);
    const Color inactiveEnabledFillColor = Color(0xFF000003);
    const Color inactiveDisabledFillColor = Color(0xFF000004);

    Color getFillColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        if (states.contains(MaterialState.selected)) {
          return activeDisabledFillColor;
        }
        return inactiveDisabledFillColor;
      }
      if (states.contains(MaterialState.selected)) {
        return activeEnabledFillColor;
      }
      return inactiveEnabledFillColor;
    }

    final MaterialStateProperty<Color> fillColor =
      MaterialStateColor.resolveWith(getFillColor);

    int? groupValue = 0;
    const Key radioKey = Key('radio');
    Widget buildApp({required bool enabled}) {
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
                  fillColor: fillColor,
                  onChanged: enabled ? (int? newValue) {
                    setState(() {
                      groupValue = newValue;
                    });
                  } : null,
                  groupValue: groupValue,
                ),
              );
            }),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(enabled: true));

    // Selected and enabled.
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byKey(radioKey))),
      paints
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
        ..circle(color: activeEnabledFillColor)
        ..circle(color: activeEnabledFillColor),
    );

    // Check when the radio isn't selected.
    groupValue = 1;
    await tester.pumpWidget(buildApp(enabled: true));
    await tester.pumpAndSettle();
    expect(
        Material.of(tester.element(find.byKey(radioKey))),
        paints
          ..rect(
              color: const Color(0xffffffff),
              rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
          ..circle(color: inactiveEnabledFillColor, style: PaintingStyle.stroke, strokeWidth: 2.0)
    );

    // Check when the radio is selected, but disabled.
    groupValue = 0;
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byKey(radioKey))),
      paints
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
        ..circle(color: activeDisabledFillColor)
        ..circle(color: activeDisabledFillColor),
    );

    // Check when the radio is unselected and disabled.
    groupValue = 1;
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byKey(radioKey))),
      paints
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
        ..circle(color: inactiveDisabledFillColor, style: PaintingStyle.stroke, strokeWidth: 2.0),
    );
  });

  testWidgets('Radio fill color resolves in hovered/focused states', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'radio');
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    const Color hoveredFillColor = Color(0xFF000001);
    const Color focusedFillColor = Color(0xFF000002);

    Color getFillColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered)) {
        return hoveredFillColor;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedFillColor;
      }
      return Colors.transparent;
    }

    final MaterialStateProperty<Color> fillColor =
      MaterialStateColor.resolveWith(getFillColor);

    int? groupValue = 0;
    const Key radioKey = Key('radio');
    Widget buildApp() {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.white,
                child: Radio<int>(
                  autofocus: true,
                  focusNode: focusNode,
                  key: radioKey,
                  value: 0,
                  fillColor: fillColor,
                  onChanged: (int? newValue) {
                    setState(() {
                      groupValue = newValue;
                    });
                  },
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
        ..circle(color: Colors.black12)
        ..circle(color: focusedFillColor),
    );

    // Start hovering
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byKey(radioKey)));
    await tester.pumpAndSettle();

    expect(
      Material.of(tester.element(find.byKey(radioKey))),
      paints
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0))
        ..circle(color: Colors.black12)
        ..circle(color: hoveredFillColor),
    );
  });

  testWidgets('Radio overlay color resolves in active/pressed/focused/hovered states', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'Radio');
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const Color fillColor = Color(0xFF000000);
    const Color activePressedOverlayColor = Color(0xFF000001);
    const Color inactivePressedOverlayColor = Color(0xFF000002);
    const Color hoverOverlayColor = Color(0xFF000003);
    const Color focusOverlayColor = Color(0xFF000004);
    const Color hoverColor = Color(0xFF000005);
    const Color focusColor = Color(0xFF000006);

    Color? getOverlayColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        if (states.contains(MaterialState.selected)) {
          return activePressedOverlayColor;
        }
        return inactivePressedOverlayColor;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoverOverlayColor;
      }
      if (states.contains(MaterialState.focused)) {
        return focusOverlayColor;
      }
      return null;
    }
    const double splashRadius = 24.0;

    Finder _findRadio() {
      return find.byWidgetPredicate((Widget widget) => widget is Radio<bool>);
    }

    MaterialInkController? _getRadioMaterial(WidgetTester tester) {
      return Material.of(tester.element(_findRadio()));
    }

    Widget buildRadio({bool active = false, bool focused = false, bool useOverlay = true}) {
      return MaterialApp(
        home: Scaffold(
          body: Radio<bool>(
            focusNode: focusNode,
            autofocus: focused,
            value: active,
            groupValue: true,
            onChanged: (_) { },
            fillColor: MaterialStateProperty.all(fillColor),
            overlayColor: useOverlay ? MaterialStateProperty.resolveWith(getOverlayColor) : null,
            hoverColor: hoverColor,
            focusColor: focusColor,
            splashRadius: splashRadius,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildRadio(active: false, useOverlay: false));
    await tester.press(_findRadio());
    await tester.pumpAndSettle();

    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(
          color: fillColor.withAlpha(kRadialReactionAlpha),
          radius: splashRadius,
        ),
      reason: 'Default inactive pressed Radio should have overlay color from fillColor',
    );

    await tester.pumpWidget(buildRadio(active: true, useOverlay: false));
    await tester.press(_findRadio());
    await tester.pumpAndSettle();

    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(
          color: fillColor.withAlpha(kRadialReactionAlpha),
          radius: splashRadius,
        ),
      reason: 'Default active pressed Radio should have overlay color from fillColor',
    );

    await tester.pumpWidget(buildRadio(active: false));
    await tester.press(_findRadio());
    await tester.pumpAndSettle();

    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(
          color: inactivePressedOverlayColor,
          radius: splashRadius,
        ),
      reason: 'Inactive pressed Radio should have overlay color: $inactivePressedOverlayColor',
    );

    await tester.pumpWidget(buildRadio(active: true));
    await tester.press(_findRadio());
    await tester.pumpAndSettle();

    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(
          color: activePressedOverlayColor,
          radius: splashRadius,
        ),
      reason: 'Active pressed Radio should have overlay color: $activePressedOverlayColor',
    );

    await tester.pumpWidget(buildRadio(focused: true));
    await tester.pumpAndSettle();

    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(
          color: focusOverlayColor,
          radius: splashRadius,
        ),
      reason: 'Focused Radio should use overlay color $focusOverlayColor over $focusColor',
    );

    // Start hovering
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(_findRadio()));
    await tester.pumpAndSettle();

    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(
          color: hoverOverlayColor,
          radius: splashRadius,
        ),
      reason: 'Hovered Radio should use overlay color $hoverOverlayColor over $hoverColor',
    );
  });

  testWidgets('Do not crash when widget disappears while pointer is down', (WidgetTester tester) async {
    final Key key = UniqueKey();

    Widget buildRadio(bool show) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: show ? Radio<bool>(key: key, value: true, groupValue: false, onChanged: (_) { }) : Container(),
          )
        ),
      );
    }

    await tester.pumpWidget(buildRadio(true));
    final Offset center = tester.getCenter(find.byKey(key));
    // Put a pointer down on the screen.
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump();
    // While the pointer is down, the widget disappears.
    await tester.pumpWidget(buildRadio(false));
    expect(find.byKey(key), findsNothing);
    // Release pointer after widget disappeared.
    await gesture.up();
  });
}
