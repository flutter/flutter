// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Slider can move when tapped', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
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
                },
              ),
            ),
          );
        },
      ),
    );

    expect(value, equals(0.0));
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(0.5));
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });

  testWidgets('Slider take on discrete values', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
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
                },
              ),
            ),
          );
        },
      ),
    );

    expect(value, equals(0.0));
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(50.0));
    await tester.drag(find.byKey(sliderKey), const Offset(5.0, 0.0));
    expect(value, equals(50.0));
    await tester.drag(find.byKey(sliderKey), const Offset(40.0, 0.0));
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

  testWidgets('Slider can be given zero values',
      (WidgetTester tester) async {
    final List<double> log = <double>[];
    await tester.pumpWidget(new Material(
      child: new Slider(
        value: 0.0,
        min: 0.0,
        max: 1.0,
        onChanged: (double newValue) { log.add(newValue); },
      ),
    ));

    await tester.tap(find.byType(Slider));
    expect(log, <double>[0.5]);
    log.clear();

    await tester.pumpWidget(new Material(
      child: new Slider(
        value: 0.0,
        min: 0.0,
        max: 0.0,
        onChanged: (double newValue) { log.add(newValue); },
      ),
    ));

    await tester.tap(find.byType(Slider));
    expect(log, <double>[]);
    log.clear();
  });

  testWidgets('Slider can draw an open thumb at min',
      (WidgetTester tester) async {
    Widget buildApp(bool thumbOpenAtMin) {
      return new Material(
        child: new Center(
          child: new Slider(
            value: 0.0,
            thumbOpenAtMin: thumbOpenAtMin,
            onChanged: (double newValue) {},
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(false));

    final RenderBox sliderBox =
        tester.firstRenderObject<RenderBox>(find.byType(Slider));

    expect(sliderBox, paints..circle(style: PaintingStyle.fill));
    expect(sliderBox, isNot(paints..circle()..circle()));
    await tester.pumpWidget(buildApp(true));
    expect(sliderBox, paints..circle(style: PaintingStyle.stroke));
    expect(sliderBox, isNot(paints..circle()..circle()));
  });

  testWidgets('Slider can tap in vertical scroller',
      (WidgetTester tester) async {
    double value = 0.0;
    await tester.pumpWidget(new Material(
      child: new ListView(
        children: <Widget>[
          new Slider(
            value: value,
            onChanged: (double newValue) {
              value = newValue;
            },
          ),
          new Container(
            height: 2000.0,
          ),
        ],
      ),
    ));

    await tester.tap(find.byType(Slider));
    expect(value, equals(0.5));
  });

  testWidgets('Slider drags immediately', (WidgetTester tester) async {
    double value = 0.0;
    await tester.pumpWidget(new Material(
      child: new Center(
        child: new Slider(
          value: value,
          onChanged: (double newValue) {
            value = newValue;
          },
        ),
      ),
    ));

    final Offset center = tester.getCenter(find.byType(Slider));
    final TestGesture gesture = await tester.startGesture(center);

    expect(value, equals(0.5));

    await gesture.moveBy(const Offset(1.0, 0.0));

    expect(value, greaterThan(0.5));

    await gesture.up();
  });
}
