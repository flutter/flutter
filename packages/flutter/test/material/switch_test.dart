// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Switch can toggle on tap', (WidgetTester tester) async {
    final Key switchKey = UniqueKey();
    bool value = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch(
                  dragStartBehavior: DragStartBehavior.down,
                  key: switchKey,
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(value, isFalse);
    await tester.tap(find.byKey(switchKey));
    expect(value, isTrue);
  });

  testWidgets('Switch size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Switch(
                dragStartBehavior: DragStartBehavior.down,
                value: true,
                onChanged: (bool newValue) { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Switch)), const Size(59.0, 48.0));

    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Switch(
                dragStartBehavior: DragStartBehavior.down,
                value: true,
                onChanged: (bool newValue) { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Switch)), const Size(59.0, 40.0));
  });

  testWidgets('Switch can drag (LTR)', (WidgetTester tester) async {
    bool value = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch(
                  dragStartBehavior: DragStartBehavior.down,
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(value, isFalse);

    await tester.drag(find.byType(Switch), const Offset(-30.0, 0.0));

    expect(value, isFalse);

    await tester.drag(find.byType(Switch), const Offset(30.0, 0.0));

    expect(value, isTrue);

    await tester.pump();
    await tester.drag(find.byType(Switch), const Offset(30.0, 0.0));

    expect(value, isTrue);

    await tester.pump();
    await tester.drag(find.byType(Switch), const Offset(-30.0, 0.0));

    expect(value, isFalse);
  });

  testWidgets('Switch can drag with dragStartBehavior', (WidgetTester tester) async {
    bool value = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch(
                  dragStartBehavior: DragStartBehavior.down,
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(value, isFalse);
    await tester.drag(find.byType(Switch), const Offset(-30.0, 0.0));
    expect(value, isFalse);

    await tester.drag(find.byType(Switch), const Offset(30.0, 0.0));
    expect(value, isTrue);
    await tester.pump();
    await tester.drag(find.byType(Switch), const Offset(30.0, 0.0));
    expect(value, isTrue);
    await tester.pump();
    await tester.drag(find.byType(Switch), const Offset(-30.0, 0.0));
    expect(value, isFalse);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch(
                    dragStartBehavior: DragStartBehavior.start,
                    value: value,
                    onChanged: (bool newValue) {
                      setState(() {
                        value = newValue;
                      });
                    },
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Rect switchRect = tester.getRect(find.byType(Switch));

    TestGesture gesture = await tester.startGesture(switchRect.center);
    // We have to execute the drag in two frames because the first update will
    // just set the start position.
    await gesture.moveBy(const Offset(20.0, 0.0));
    await gesture.moveBy(const Offset(20.0, 0.0));
    expect(value, isFalse);
    await gesture.up();
    expect(value, isTrue);
    await tester.pump();

    gesture = await tester.startGesture(switchRect.center);
    await gesture.moveBy(const Offset(20.0, 0.0));
    await gesture.moveBy(const Offset(20.0, 0.0));
    expect(value, isTrue);
    await gesture.up();
    expect(value, isTrue);
    await tester.pump();

    gesture = await tester.startGesture(switchRect.center);
    await gesture.moveBy(const Offset(-20.0, 0.0));
    await gesture.moveBy(const Offset(-20.0, 0.0));
    expect(value, isTrue);
    await gesture.up();
    expect(value, isFalse);
  });

  testWidgets('Switch can drag (RTL)', (WidgetTester tester) async {
    bool value = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch(
                  dragStartBehavior: DragStartBehavior.down,
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.drag(find.byType(Switch), const Offset(30.0, 0.0));

    expect(value, isFalse);

    await tester.drag(find.byType(Switch), const Offset(-30.0, 0.0));

    expect(value, isTrue);

    await tester.pump();
    await tester.drag(find.byType(Switch), const Offset(-30.0, 0.0));

    expect(value, isTrue);

    await tester.pump();
    await tester.drag(find.byType(Switch), const Offset(30.0, 0.0));

    expect(value, isFalse);
  });

  testWidgets('Switch has default colors when enabled', (WidgetTester tester) async {
    bool value = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch(
                  dragStartBehavior: DragStartBehavior.down,
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(
        Material.of(tester.element(find.byType(Switch))),
        paints
          ..rrect(
              color: const Color(0x52000000), // Black with 32% opacity
              rrect: RRect.fromLTRBR(
                  383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
          ..circle(color: const Color(0x33000000))
          ..circle(color: const Color(0x24000000))
          ..circle(color: const Color(0x1f000000))
          ..circle(color: Colors.grey.shade50),
      reason: 'Inactive enabled switch should match these colors',
    );
    await tester.drag(find.byType(Switch), const Offset(-30.0, 0.0));
    await tester.pump();

    expect(
        Material.of(tester.element(find.byType(Switch))),
        paints
          ..rrect(
              color: Colors.blue[600].withAlpha(0x80),
              rrect: RRect.fromLTRBR(
                  383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
          ..circle(color: const Color(0x33000000))
          ..circle(color: const Color(0x24000000))
          ..circle(color: const Color(0x1f000000))
          ..circle(color: Colors.blue[600]),
      reason: 'Active enabled switch should match these colors',
    );
  });

  testWidgets('Switch has default colors when disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return const Material(
              child: Center(
                child: Switch(
                  value: false,
                  onChanged: null,
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(
            color: Colors.black12,
            rrect: RRect.fromLTRBR(
                383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: Colors.grey.shade400),
      reason: 'Inactive disabled switch should match these colors',
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return const Material(
              child: Center(
                child: Switch(
                  value: true,
                  onChanged: null,
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(
            color: Colors.black12,
            rrect: RRect.fromLTRBR(
                383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: Colors.grey.shade400),
      reason: 'Active disabled switch should match these colors',
    );
  });

  testWidgets('Switch can be set color', (WidgetTester tester) async {
    bool value = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch(
                  dragStartBehavior: DragStartBehavior.down,
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                  activeColor: Colors.red[500],
                  activeTrackColor: Colors.green[500],
                  inactiveThumbColor: Colors.yellow[500],
                  inactiveTrackColor: Colors.blue[500],
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(
            color: Colors.blue[500],
            rrect: RRect.fromLTRBR(
                383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: Colors.yellow[500]),
    );
    await tester.drag(find.byType(Switch), const Offset(-30.0, 0.0));
    await tester.pump();

    expect(
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(
            color: Colors.green[500],
            rrect: RRect.fromLTRBR(
                383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: Colors.red[500]),
    );
  });

  testWidgets('Drag ends after animation completes', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17773

    bool value = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch(
                  dragStartBehavior: DragStartBehavior.down,
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(value, isFalse);

    final Rect switchRect = tester.getRect(find.byType(Switch));
    final TestGesture gesture = await tester.startGesture(switchRect.centerLeft);
    await tester.pump();
    await gesture.moveBy(Offset(switchRect.width, 0.0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(value, isTrue);
    expect(tester.hasRunningAnimations, false);
  });

  testWidgets('can veto switch dragging result', (WidgetTester tester) async {
    bool value = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch(
                  dragStartBehavior: DragStartBehavior.down,
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = value || newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    // Move a little to the right, not past the middle.
    TestGesture gesture = await tester.startGesture(tester.getRect(find.byType(Switch)).center);
    await gesture.moveBy(const Offset(kTouchSlop + 0.1, 0.0));
    await tester.pump();
    await gesture.moveBy(const Offset(-kTouchSlop + 5.1, 0.0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(value, isFalse);
    final RenderToggleable renderObject = tester.renderObject<RenderToggleable>(
      find.descendant(
        of: find.byType(Switch),
        matching: find.byWidgetPredicate(
          (Widget widget) => widget.runtimeType.toString() == '_SwitchRenderObjectWidget',
        ),
      ),
    );
    expect(renderObject.position.value, lessThan(0.5));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(renderObject.position.value, 0);

    // Move past the middle.
    gesture = await tester.startGesture(tester.getRect(find.byType(Switch)).center);
    await gesture.moveBy(const Offset(kTouchSlop + 0.1, 0.0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(value, isTrue);
    expect(renderObject.position.value, greaterThan(0.5));

    await tester.pump();
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(renderObject.position.value, 1.0);

    // Now move back to the left, the revert animation should play.
    gesture = await tester.startGesture(tester.getRect(find.byType(Switch)).center);
    await gesture.moveBy(const Offset(-kTouchSlop - 0.1, 0.0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(value, isTrue);
    expect(renderObject.position.value, lessThan(0.5));

    await tester.pump();
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(renderObject.position.value, 1.0);
  });

  testWidgets('switch has semantic events', (WidgetTester tester) async {
    dynamic semanticEvent;
    bool value = false;
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) async {
      semanticEvent = message;
    });
    final SemanticsTester semanticsTester = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch(
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byType(Switch));
    final RenderObject object = tester.firstRenderObject(find.byType(Focus));

    expect(value, true);
    expect(semanticEvent, <String, dynamic>{
      'type': 'tap',
      'nodeId': object.debugSemantics.id,
      'data': <String, dynamic>{},
    });
    expect(object.debugSemantics.getSemanticsData().hasAction(SemanticsAction.tap), true);

    semanticsTester.dispose();
    SystemChannels.accessibility.setMockMessageHandler(null);
  });

  testWidgets('switch sends semantic events from parent if fully merged', (WidgetTester tester) async {
    dynamic semanticEvent;
    bool value = false;
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) async {
      semanticEvent = message;
    });
    final SemanticsTester semanticsTester = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void onChanged(bool newValue) {
              setState(() {
                value = newValue;
              });
            }
            return Material(
              child: MergeSemantics(
                child: ListTile(
                  leading: const Text('test'),
                  onTap: () {
                    onChanged(!value);
                  },
                  trailing: Switch(
                    value: value,
                    onChanged: onChanged,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byType(MergeSemantics));
    final RenderObject object = tester.firstRenderObject(find.byType(MergeSemantics));

    expect(value, true);
    expect(semanticEvent, <String, dynamic>{
      'type': 'tap',
      'nodeId': object.debugSemantics.id,
      'data': <String, dynamic>{},
    });
    expect(object.debugSemantics.getSemanticsData().hasAction(SemanticsAction.tap), true);

    semanticsTester.dispose();
    SystemChannels.accessibility.setMockMessageHandler(null);
  });

  testWidgets('Switch.adaptive', (WidgetTester tester) async {
    bool value = false;
    const Color inactiveTrackColor = Colors.pink;

    Widget buildFrame(TargetPlatform platform) {
      return MaterialApp(
        theme: ThemeData(platform: platform),
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Switch.adaptive(
                  value: value,
                  inactiveTrackColor: inactiveTrackColor,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );
    }

    for (final TargetPlatform platform in <TargetPlatform>[ TargetPlatform.iOS, TargetPlatform.macOS ]) {
      value = false;
      await tester.pumpWidget(buildFrame(platform));
      expect(find.byType(CupertinoSwitch), findsOneWidget, reason: 'on ${describeEnum(platform)}');

      final CupertinoSwitch adaptiveSwitch = tester.widget(find.byType(CupertinoSwitch));
      expect(adaptiveSwitch.trackColor, inactiveTrackColor, reason: 'on ${describeEnum(platform)}');

      expect(value, isFalse, reason: 'on ${describeEnum(platform)}');
      await tester.tap(find.byType(Switch));
      expect(value, isTrue, reason: 'on ${describeEnum(platform)}');
    }

    for (final TargetPlatform platform in <TargetPlatform>[ TargetPlatform.android, TargetPlatform.fuchsia, TargetPlatform.linux, TargetPlatform.windows ]) {
      value = false;
      await tester.pumpWidget(buildFrame(platform));
      await tester.pumpAndSettle(); // Finish the theme change animation.
      expect(find.byType(CupertinoSwitch), findsNothing);
      expect(value, isFalse, reason: 'on ${describeEnum(platform)}');
      await tester.tap(find.byType(Switch));
      expect(value, isTrue, reason: 'on ${describeEnum(platform)}');
    }
  });

  testWidgets('Switch is focusable and has correct focus color', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'Switch');
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    bool value = true;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Switch(
                value: value,
                onChanged: enabled ? (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                } : null,
                focusColor: Colors.orange[500],
                autofocus: true,
                focusNode: focusNode,
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
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(
            color: const Color(0x801e88e5),
            rrect: RRect.fromLTRBR(
                383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
        ..circle(color: Colors.orange[500])
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: const Color(0xff1e88e5)),
    );

    // Check the false value.
    value = false;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(
            color: const Color(0x52000000),
            rrect: RRect.fromLTRBR(
                383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
        ..circle(color: Colors.orange[500])
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: const Color(0xfffafafa)),
    );

    // Check what happens when disabled.
    value = false;
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isFalse);
    expect(
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(
            color: const Color(0x1f000000),
            rrect: RRect.fromLTRBR(
                383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: const Color(0xffbdbdbd)),
    );
  });

  testWidgets('Switch can be hovered and has correct hover color', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    bool value = true;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Switch(
                value: value,
                onChanged: enabled ? (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                } : null,
                hoverColor: Colors.orange[500],
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(
            color: const Color(0x801e88e5),
            rrect: RRect.fromLTRBR(
                383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: const Color(0xff1e88e5)),
    );

    // Start hovering
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(Switch)));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(
            color: const Color(0x801e88e5),
            rrect: RRect.fromLTRBR(
                383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
        ..circle(color: Colors.orange[500])
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: const Color(0xff1e88e5)),
    );

    // Check what happens when disabled.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(
            color: const Color(0x1f000000),
            rrect: RRect.fromLTRBR(
                383.5, 293.0, 416.5, 307.0, const Radius.circular(7.0)))
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: const Color(0xffbdbdbd)),
    );
  });

  testWidgets('Switch can be toggled by keyboard shortcuts', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    bool value = true;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Switch(
                value: value,
                onChanged: enabled ? (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                } : null,
                focusColor: Colors.orange[500],
                autofocus: true,
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
    // On web, switches don't respond to the enter key.
    expect(value, kIsWeb ? isTrue : isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  testWidgets('Switch changes mouse cursor when hovered', (WidgetTester tester) async {
    // Test Switch.adaptive() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Switch.adaptive(
                  mouseCursor: SystemMouseCursors.text,
                  value: true,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byType(Switch)));
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    // Test Switch() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Switch(
                  mouseCursor: SystemMouseCursors.text,
                  value: true,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await gesture.moveTo(tester.getCenter(find.byType(Switch)));
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
                child: Switch(
                  value: true,
                  onChanged: (_) {},
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
                child: Switch(
                  value: true,
                  onChanged: null,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);

    await tester.pumpAndSettle();
  });

  testWidgets('Material switch should not recreate its render object when disabled', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/61247.
    bool value = true;
    bool enabled = true;
    StateSetter stateSetter;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            stateSetter = setState;
            return Material(
              child: Center(
                child: Switch(
                  value: value,
                  onChanged: !enabled ? null : (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    final RenderToggleable oldSwitchRenderObject = tester
      .renderObject(find.byWidgetPredicate((Widget widget) => widget is LeafRenderObjectWidget));

    stateSetter(() { value = false; });
    await tester.pump();
    // Disable the switch when the implicit animation begins.
    stateSetter(() { enabled = false; });
    await tester.pump();

    final RenderToggleable updatedSwitchRenderObject = tester
      .renderObject(find.byWidgetPredicate((Widget widget) => widget is LeafRenderObjectWidget));


    expect(updatedSwitchRenderObject.isInteractive, false);
    expect(updatedSwitchRenderObject, oldSwitchRenderObject);
    expect(updatedSwitchRenderObject.position.isCompleted, false);
    expect(updatedSwitchRenderObject.position.isDismissed, false);
  });
}
