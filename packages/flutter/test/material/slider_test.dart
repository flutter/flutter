// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Slider can move when tapped', (WidgetTester tester) async {
    Key sliderKey = new UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Material(
            child: new Center(
              child: new Slider(
                key: sliderKey,
                value: value,
                onChanged: (double newValue) {
                  setState(() {
                    value = newValue;
                  });
                }
              )
            )
          );
        }
      )
    );

    expect(value, equals(0.0));
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(0.5));
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });

  testWidgets('Slider take on discrete values', (WidgetTester tester) async {
    Key sliderKey = new UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Material(
            child: new Center(
              child: new Slider(
                key: sliderKey,
                min: 0.0,
                max: 100.0,
                divisions: 10,
                value: value,
                onChanged: (double newValue) {
                  setState(() {
                    value = newValue;
                  });
                }
              )
            )
          );
        }
      )
    );

    expect(value, equals(0.0));
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(50.0));
    await tester.scroll(find.byKey(sliderKey), const Offset(5.0, 0.0));
    expect(value, equals(50.0));
    await tester.scroll(find.byKey(sliderKey), const Offset(40.0, 0.0));
    expect(value, equals(80.0));

    await tester.pump(); // Starts animation.
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    // Animation complete.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });
}
