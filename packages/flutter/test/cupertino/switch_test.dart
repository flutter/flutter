// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

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
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
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
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Using other widgets that rebuild the switch will not cause vibrations', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
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
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Haptic vibration triggers on drag', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
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
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('No haptic vibration triggers from a programmatic value change', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
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
    debugDefaultTargetPlatformOverride = null;
  });

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

    TestGesture gesture = await tester.startGesture(switchRect.center);
    // We have to execute the drag in two frames because the first update will
    // just set the start position.
    await gesture.moveBy(const Offset(20.0, 0.0));
    await gesture.moveBy(const Offset(20.0, 0.0));
    expect(value, isTrue);
    await gesture.up();
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
    expect(value, isFalse);
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
        )
      ),
    );

    expect(find.byType(Opacity), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.5);
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
        )
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
        )
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
        )
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
        )
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
        )
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
                )
              )
            );
          },
        ),
      ),
    );

    await expectLater(
      find.byKey(switchKey),
      matchesGoldenFile(
        'switch.tap.off.png',
        version: 0,
      ),
      skip: !isLinux,
    );

    await tester.tap(find.byKey(switchKey));
    expect(value, isTrue);

    // Kick off animation, then advance to intermediate frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await expectLater(
      find.byKey(switchKey),
      matchesGoldenFile(
        'switch.tap.turningOn.png',
        version: 0,
      ),
      skip: !isLinux,
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(switchKey),
      matchesGoldenFile(
        'switch.tap.on.png',
        version: 0,
      ),
      skip: !isLinux,
    );
  });

}
