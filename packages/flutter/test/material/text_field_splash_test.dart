// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

int confirmCount = 0;
int cancelCount = 0;

class TestInkSplash extends InkSplash {
  TestInkSplash({
    MaterialInkController controller,
    RenderBox referenceBox,
    Offset position,
    Color color,
    bool containedInkWell: false,
    RectCallback rectCallback,
    BorderRadius borderRadius,
    double radius,
    VoidCallback onRemoved,
  }) : super(
    controller: controller,
    referenceBox: referenceBox,
    position: position,
    color: color,
    containedInkWell: containedInkWell,
    rectCallback: rectCallback,
    borderRadius: borderRadius,
    radius: radius,
    onRemoved: onRemoved,
  );

  @override
  void confirm() {
    confirmCount += 1;
    super.confirm();
  }

  @override
  void cancel() {
    cancelCount += 1;
    super.cancel();
  }
}

class TestInkSplashFactory extends InteractiveInkFeatureFactory {
  const TestInkSplashFactory();

  @override
  InteractiveInkFeature create({
    MaterialInkController controller,
    RenderBox referenceBox,
    Offset position,
    Color color,
    bool containedInkWell: false,
    RectCallback rectCallback,
    BorderRadius borderRadius,
    double radius,
    VoidCallback onRemoved,
  }) {
    return new TestInkSplash(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}

void main() {
  testWidgets('Tap and no focus causes a splash', (WidgetTester tester) async {
    final Key textField1 = new UniqueKey();
    final Key textField2 = new UniqueKey();

    await tester.pumpWidget(
      new MaterialApp(
        home: new Theme(
          data: new ThemeData.light().copyWith(splashFactory: const TestInkSplashFactory()),
          child: new Material(
            child: new Container(
              alignment: Alignment.topLeft,
              child: new Column(
                children: <Widget>[
                  new TextField(
                    key: textField1,
                    decoration: const InputDecoration(
                      labelText: 'label',
                    ),
                  ),
                  new TextField(
                    key: textField2,
                    decoration: const InputDecoration(
                      labelText: 'label',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );

    confirmCount = 0;
    cancelCount = 0;

    await tester.tap(find.byKey(textField1));
    await tester.pumpAndSettle();
    expect(confirmCount, 1);
    expect(cancelCount, 0);

    // textField1 already has the focus, no new splash
    await tester.tap(find.byKey(textField1));
    await tester.pumpAndSettle();
    expect(confirmCount, 1);
    expect(cancelCount, 0);

    // textField2 gets the focus and a splash
    await tester.tap(find.byKey(textField2));
    await tester.pumpAndSettle();
    expect(confirmCount, 2);
    expect(cancelCount, 0);

    // Tap outside of textField1's editable. It still gets focus and splash.
    await tester.tapAt(tester.getTopLeft(find.byKey(textField1)));
    await tester.pumpAndSettle();
    expect(confirmCount, 3);
    expect(cancelCount, 0);

    // Tap in the center of textField2's editable. It still gets the focus
    // and the splash. There is no splash cancel.
    await tester.tap(find.byKey(textField2));
    await tester.pumpAndSettle();
    expect(confirmCount, 4);
    expect(cancelCount, 0);
  });

  testWidgets('Splash cancel', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Theme(
          data: new ThemeData.light().copyWith(splashFactory: const TestInkSplashFactory()),
          child: new Material(
            child: new ListView(
              children: <Widget>[
                const TextField(
                  decoration: const InputDecoration(
                    labelText: 'label1',
                  ),
                ),
                const TextField(
                  decoration: const InputDecoration(
                    labelText: 'label2',
                  ),
                ),
                new Container(
                  height: 1000.0,
                  color: const Color(0xFF00FF00),
                ),
              ],
            ),
          ),
        ),
      )
    );

    confirmCount = 0;
    cancelCount = 0;

    // Pointer is dragged below the textfield, splash is canceled.
    final TestGesture gesture1 = await tester.startGesture(tester.getCenter(find.text('label1')));

    // Splashes start on tapDown.
    // If the timeout is less than kPressTimeout the recognizer will just trigger
    // the onTapCancel callback. If the timeout is greater or equal to kPressTimeout
    // and less than kLongPressTimeout then onTapDown, onCancel will be called.
    await tester.pump(kPressTimeout);

    await gesture1.moveTo(const Offset(400.0, 300.0));
    await gesture1.up();
    expect(confirmCount, 0);
    expect(cancelCount, 1);

    // Pointer is dragged upwards causing a scroll, splash is canceled.
    final TestGesture gesture2 = await tester.startGesture(tester.getCenter(find.text('label2')));
    await tester.pump(kPressTimeout);
    await gesture2.moveBy(const Offset(0.0, -200.0));
    await gesture2.up();
    expect(confirmCount, 0);
    expect(cancelCount, 2);
  });
}
