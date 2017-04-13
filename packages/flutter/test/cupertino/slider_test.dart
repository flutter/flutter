// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Slider does not move when tapped', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Material(
            child: new Center(
              child: new CupertinoSlider(
                key: sliderKey,
                value: value,
                onChanged: (double newValue) {
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

    expect(value, equals(0.0));
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(0.0));
    await tester.pump(); // No animation should start.
    // Check the transientCallbackCount before tearing down the widget to ensure
    // that no animation is running.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });

  testWidgets('Slider moves when dragged', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Material(
            child: new Center(
              child: new CupertinoSlider(
                key: sliderKey,
                value: value,
                onChanged: (double newValue) {
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

    expect(value, equals(0.0));
    final Offset topLeft = tester.getTopLeft(find.byKey(sliderKey));
    const double unit = CupertinoThumbPainter.radius;
    const double delta = 3.0 * unit;
    await tester.dragFrom(topLeft + const Offset(unit, unit), const Offset(delta, 0.0));
    final Size size = tester.getSize(find.byKey(sliderKey));
    expect(value, equals(delta / (size.width - 2.0 * (8.0 + CupertinoThumbPainter.radius))));
    await tester.pump(); // No animation should start.
    // Check the transientCallbackCount before tearing down the widget to ensure
    // that no animation is running.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });
}
