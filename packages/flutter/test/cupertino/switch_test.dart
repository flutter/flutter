// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../rendering/mock_canvas.dart';

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

  testWidgets('Switch emits light haptic vibration on tap', (WidgetTester tester) async {
    final Key switchKey = UniqueKey();
    bool value = false;

    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
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

    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
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

    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
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
    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
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
                dragStartBehavior: DragStartBehavior.start,
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
}
