// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Switch can toggle on tap', (WidgetTester tester) async {
    final Key switchKey = UniqueKey();
    bool value = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: CupertinoSwitch(
                key: switchKey,
                value: value,
                dragStartBehavior: DragStartBehavior.down,
                onChanged: (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
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

  testWidgets('CupertinoSwitch can be toggled by keyboard shortcuts', (WidgetTester tester) async {
    bool value = true;
    Widget buildApp({bool enabled = true}) {
      return CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return CupertinoSwitch(
                value: value,
                onChanged: enabled ? (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                } : null,
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(value, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  testWidgets('Switch emits light haptic vibration on tap', (WidgetTester tester) async {
    final Key switchKey = UniqueKey();
    bool value = false;

    final List<MethodCall> log = <MethodCall>[];

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: CupertinoSwitch(
                key: switchKey,
                value: value,
                dragStartBehavior: DragStartBehavior.down,
                onChanged: (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(switchKey));
    await tester.pump();

    expect(log, hasLength(1));
    expect(log.single, isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Using other widgets that rebuild the switch will not cause vibrations', (WidgetTester tester) async {
    final Key switchKey = UniqueKey();
    final Key switchKey2 = UniqueKey();
    bool value = false;
    bool value2 = false;
    final List<MethodCall> log = <MethodCall>[];

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: Column(
                children: <Widget>[
                  CupertinoSwitch(
                    key: switchKey,
                    value: value,
                    onChanged: (bool newValue) {
                      setState(() {
                        value = newValue;
                      });
                    },
                  ),
                  CupertinoSwitch(
                    key: switchKey2,
                    value: value2,
                    onChanged: (bool newValue) {
                      setState(() {
                        value2 = newValue;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(switchKey));
    await tester.pump();

    expect(log, hasLength(1));
    expect(log[0], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));

    await tester.tap(find.byKey(switchKey2));
    await tester.pump();

    expect(log, hasLength(2));
    expect(log[1], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));

    await tester.tap(find.byKey(switchKey));
    await tester.pump();

    expect(log, hasLength(3));
    expect(log[2], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));

    await tester.tap(find.byKey(switchKey2));
    await tester.pump();

    expect(log, hasLength(4));
    expect(log[3], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Haptic vibration triggers on drag', (WidgetTester tester) async {
    bool value = false;
    final List<MethodCall> log = <MethodCall>[];

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: CupertinoSwitch(
                value: value,
                dragStartBehavior: DragStartBehavior.down,
                onChanged: (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.drag(find.byType(CupertinoSwitch), const Offset(30.0, 0.0));
    expect(value, isTrue);
    await tester.pump();

    expect(log, hasLength(1));
    expect(log[0], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('No haptic vibration triggers from a programmatic value change', (WidgetTester tester) async {
    final Key switchKey = UniqueKey();
    bool value = false;

    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: Column(
                children: <Widget>[
                  CupertinoButton(
                    child: const Text('Button'),
                    onPressed: () {
                      setState(() {
                        value = !value;
                      });
                    },
                  ),
                  CupertinoSwitch(
                    key: switchKey,
                    value: value,
                    onChanged: (bool newValue) {
                      setState(() {
                        value = newValue;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(value, isFalse);

    await tester.tap(find.byType(CupertinoButton));
    expect(value, isTrue);
    await tester.pump();

    expect(log, hasLength(0));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Switch can drag (LTR)', (WidgetTester tester) async {
    bool value = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: CupertinoSwitch(
                value: value,
                onChanged: (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    expect(value, isFalse);

    await tester.drag(find.byType(CupertinoSwitch), const Offset(-48.0, 0.0));

    expect(value, isFalse);

    await tester.drag(find.byType(CupertinoSwitch), const Offset(48.0, 0.0));

    expect(value, isTrue);

    await tester.pump();
    await tester.drag(find.byType(CupertinoSwitch), const Offset(48.0, 0.0));

    expect(value, isTrue);

    await tester.pump();
    await tester.drag(find.byType(CupertinoSwitch), const Offset(-48.0, 0.0));

    expect(value, isFalse);
  });

  testWidgets('Switch can drag with dragStartBehavior', (WidgetTester tester) async {
    bool value = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: CupertinoSwitch(
                value: value,
                dragStartBehavior: DragStartBehavior.down,
                onChanged: (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    expect(value, isFalse);
    await tester.drag(find.byType(CupertinoSwitch), const Offset(-30.0, 0.0));
    expect(value, isFalse);

    await tester.drag(find.byType(CupertinoSwitch), const Offset(30.0, 0.0));
    expect(value, isTrue);
    await tester.pump();
    await tester.drag(find.byType(CupertinoSwitch), const Offset(30.0, 0.0));
    expect(value, isTrue);
    await tester.pump();
    await tester.drag(find.byType(CupertinoSwitch), const Offset(-30.0, 0.0));
    expect(value, isFalse);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: CupertinoSwitch(
                value: value,
                onChanged: (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Rect switchRect = tester.getRect(find.byType(CupertinoSwitch));
    expect(value, isFalse);

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
    await tester.pump();

    gesture = await tester.startGesture(switchRect.center);
    await gesture.moveBy(const Offset(-20.0, 0.0));
    await gesture.moveBy(const Offset(-20.0, 0.0));
    expect(value, isTrue);
    await gesture.up();
    expect(value, isFalse);
    await tester.pump();
  });

  testWidgets('Switch can drag (RTL)', (WidgetTester tester) async {
    bool value = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: CupertinoSwitch(
                value: value,
                dragStartBehavior: DragStartBehavior.down,
                onChanged: (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    expect(value, isFalse);

    await tester.drag(find.byType(CupertinoSwitch), const Offset(30.0, 0.0));

    expect(value, isFalse);

    await tester.drag(find.byType(CupertinoSwitch), const Offset(-30.0, 0.0));

    expect(value, isTrue);

    await tester.pump();
    await tester.drag(find.byType(CupertinoSwitch), const Offset(-30.0, 0.0));

    expect(value, isTrue);

    await tester.pump();
    await tester.drag(find.byType(CupertinoSwitch), const Offset(30.0, 0.0));

    expect(value, isFalse);
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
                child: CupertinoSwitch(
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
    TestGesture gesture = await tester.startGesture(tester.getRect(find.byType(CupertinoSwitch)).center);
    await gesture.moveBy(const Offset(kTouchSlop + 0.1, 0.0));
    await tester.pump();
    await gesture.moveBy(const Offset(-kTouchSlop + 5.1, 0.0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(value, isFalse);
    // ignore: avoid_dynamic_calls
    final CurvedAnimation position = (tester.state(find.byType(CupertinoSwitch)) as dynamic).position as CurvedAnimation;
    expect(position.value, lessThan(0.5));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(position.value, 0);

    // Move past the middle.
    gesture = await tester.startGesture(tester.getRect(find.byType(CupertinoSwitch)).center);
    await gesture.moveBy(const Offset(kTouchSlop + 0.1, 0.0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(value, isTrue);
    expect(position.value, greaterThan(0.5));

    await tester.pump();
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(position.value, 1.0);

    // Now move back to the left, the revert animation should play.
    gesture = await tester.startGesture(tester.getRect(find.byType(CupertinoSwitch)).center);
    await gesture.moveBy(const Offset(-kTouchSlop - 0.1, 0.0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(value, isTrue);
    expect(position.value, lessThan(0.5));

    await tester.pump();
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(position.value, 1.0);
  });

  testWidgets('Switch is translucent when disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CupertinoSwitch(
            value: false,
            dragStartBehavior: DragStartBehavior.down,
            onChanged: null,
          ),
        ),
      ),
    );

    expect(find.byType(Opacity), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.5);
  });

  testWidgets('Switch is using track color when set', (WidgetTester tester) async {
    const Color trackColor = Color(0xFF00FF00);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CupertinoSwitch(
            value: false,
            trackColor: trackColor,
            dragStartBehavior: DragStartBehavior.down,
            onChanged: null,
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).trackColor, trackColor);
    expect(find.byType(CupertinoSwitch), paints..rrect(color: trackColor));
  });

  testWidgets('Switch is using default thumb color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CupertinoSwitch(
            value: false,
            onChanged: null,
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).thumbColor, null);
    expect(
      find.byType(CupertinoSwitch),
      paints
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(color: CupertinoColors.white),
    );
  });

  testWidgets('Switch is using thumb color when set', (WidgetTester tester) async {
    const Color thumbColor = Color(0xFF000000);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CupertinoSwitch(
            value: false,
            thumbColor: thumbColor,
            onChanged: null,
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).thumbColor, thumbColor);
    expect(
      find.byType(CupertinoSwitch),
      paints
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(color: thumbColor),
    );
  });

  testWidgets('Switch is opaque when enabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CupertinoSwitch(
            value: false,
            dragStartBehavior: DragStartBehavior.down,
            onChanged: (bool newValue) {},
          ),
        ),
      ),
    );

    expect(find.byType(Opacity), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1.0);
  });

  testWidgets('Switch turns translucent after becoming disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CupertinoSwitch(
            value: false,
            dragStartBehavior: DragStartBehavior.down,
            onChanged: (bool newValue) {},
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CupertinoSwitch(
            value: false,
            dragStartBehavior: DragStartBehavior.down,
            onChanged: null,
          ),
        ),
      ),
    );

    expect(find.byType(Opacity), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.5);
  });

  testWidgets('Switch turns opaque after becoming enabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CupertinoSwitch(
            value: false,
            dragStartBehavior: DragStartBehavior.down,
            onChanged: null,
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CupertinoSwitch(
            value: false,
            dragStartBehavior: DragStartBehavior.down,
            onChanged: (bool newValue) {},
          ),
        ),
      ),
    );

    expect(find.byType(Opacity), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1.0);
  });

  testWidgets('Switch renders correctly before, during, and after being tapped', (WidgetTester tester) async {
    final Key switchKey = UniqueKey();
    bool value = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: RepaintBoundary(
                child: CupertinoSwitch(
                  key: switchKey,
                  value: value,
                  dragStartBehavior: DragStartBehavior.down,
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

    await expectLater(
      find.byKey(switchKey),
      matchesGoldenFile('switch.tap.off.png'),
    );

    await tester.tap(find.byKey(switchKey));
    expect(value, isTrue);

    // Kick off animation, then advance to intermediate frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await expectLater(
      find.byKey(switchKey),
      matchesGoldenFile('switch.tap.turningOn.png'),
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(switchKey),
      matchesGoldenFile('switch.tap.on.png'),
    );
  });

  testWidgets('Switch renders correctly in dark mode', (WidgetTester tester) async {
    final Key switchKey = UniqueKey();
    bool value = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.dark),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Center(
                child: RepaintBoundary(
                  child: CupertinoSwitch(
                    key: switchKey,
                    value: value,
                    dragStartBehavior: DragStartBehavior.down,
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
      ),
    );

    await expectLater(
      find.byKey(switchKey),
      matchesGoldenFile('switch.tap.off.dark.png'),
    );

    await tester.tap(find.byKey(switchKey));
    expect(value, isTrue);

    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(switchKey),
      matchesGoldenFile('switch.tap.on.dark.png'),
    );
  });

  testWidgets('Switch can apply the ambient theme and be opted out', (WidgetTester tester) async {
    final Key switchKey = UniqueKey();
    bool value = false;
    await tester.pumpWidget(
      CupertinoTheme(
        data: const CupertinoThemeData(primaryColor: Colors.amber, applyThemeToAll: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Center(
                child: RepaintBoundary(
                  child: Column(
                    children: <Widget>[
                      CupertinoSwitch(
                        key: switchKey,
                        value: value,
                        dragStartBehavior: DragStartBehavior.down,
                        applyTheme: true,
                        onChanged: (bool newValue) {
                          setState(() {
                            value = newValue;
                          });
                        },
                      ),
                      CupertinoSwitch(
                        value: value,
                        dragStartBehavior: DragStartBehavior.down,
                        applyTheme: false,
                        onChanged: (bool newValue) {
                          setState(() {
                            value = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Column),
      matchesGoldenFile('switch.tap.off.themed.png'),
    );

    await tester.tap(find.byKey(switchKey));
    expect(value, isTrue);

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('switch.tap.on.themed.png'),
    );
  });

  testWidgets('Hovering over Cupertino switch updates cursor to clickable on Web', (WidgetTester tester) async {
    const bool value = false;
    // Disabled CupertinoSwitch does not update cursor on Web.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return const Center(
              child: CupertinoSwitch(
                value: value,
                dragStartBehavior: DragStartBehavior.down,
                onChanged: null,
              ),
            );
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    final Offset cupertinoSwitch = tester.getCenter(find.byType(CupertinoSwitch));
    await gesture.addPointer(location: cupertinoSwitch);
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);

    // Enabled CupertinoSwitch updates cursor when hovering on Web.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: CupertinoSwitch(
                value: value,
                dragStartBehavior: DragStartBehavior.down,
                onChanged: (bool newValue) { },
              ),
            );
          },
        ),
      ),
    );

    await gesture.moveTo(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);

    await gesture.moveTo(cupertinoSwitch);
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      kIsWeb ? SystemMouseCursors.click : SystemMouseCursors.basic,
    );
  });

  testWidgets('CupertinoSwitch is focusable and has correct focus color', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'CupertinoSwitch');
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    bool value = true;
    const Color focusColor = Color(0xffff0000);

    Widget buildApp({bool enabled = true}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: CupertinoSwitch(
                value: value,
                onChanged: enabled ? (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                } : null,
                focusColor: focusColor,
                focusNode: focusNode,
                autofocus: true,
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      find.byType(CupertinoSwitch),
      paints
        ..rrect(color: const Color(0xff34c759))
        ..rrect(color: focusColor)
        ..clipRRect()
        ..rrect(color: const Color(0x26000000))
        ..rrect(color: const Color(0x0f000000))
        ..rrect(color: const Color(0x0a000000))
        ..rrect(color: const Color(0xffffffff)),
    );

    // Check the false value.
    value = false;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      find.byType(CupertinoSwitch),
      paints
        ..rrect(color: const Color(0x28787880))
        ..rrect(color: focusColor)
        ..clipRRect()
        ..rrect(color: const Color(0x26000000))
        ..rrect(color: const Color(0x0f000000))
        ..rrect(color: const Color(0x0a000000))
        ..rrect(color: const Color(0xffffffff)),
    );

    // Check what happens when disabled.
    value = false;
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();

    expect(focusNode.hasPrimaryFocus, isFalse);
    expect(
      find.byType(CupertinoSwitch),
      paints
        ..rrect(color: const Color(0x28787880))
        ..clipRRect()
        ..rrect(color: const Color(0x26000000))
        ..rrect(color: const Color(0x0f000000))
        ..rrect(color: const Color(0x0a000000))
        ..rrect(color: const Color(0xffffffff)),
    );
  });

  testWidgets('CupertinoSwitch.onFocusChange callback', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'CupertinoSwitch');
    bool focused = false;
    await tester.pumpWidget(
      Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: CupertinoSwitch(
            value: true,
            focusNode: focusNode,
            onFocusChange: (bool value) {
              focused = value;
            },
            onChanged:(bool newValue) {},
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    expect(focused, isTrue);
    expect(focusNode.hasFocus, isTrue);

    focusNode.unfocus();
    await tester.pump();
    expect(focused, isFalse);
    expect(focusNode.hasFocus, isFalse);
  });
}
