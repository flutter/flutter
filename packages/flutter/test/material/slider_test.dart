// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Slider can move when tapped (LTR)', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
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
      ),
    );

    expect(value, equals(0.0));
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(0.5));
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));

    final Offset topLeft = tester.getTopLeft(find.byKey(sliderKey));
    final Offset bottomRight = tester.getBottomRight(find.byKey(sliderKey));

    final Offset target = topLeft + (bottomRight - topLeft) / 4.0;
    await tester.tapAt(target);
    expect(value, closeTo(0.25, 0.05));
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });

  testWidgets('Slider can move when tapped (RTL)', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new StatefulBuilder(
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
      ),
    );

    expect(value, equals(0.0));
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(0.5));
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));

    final Offset topLeft = tester.getTopLeft(find.byKey(sliderKey));
    final Offset bottomRight = tester.getBottomRight(find.byKey(sliderKey));

    final Offset target = topLeft + (bottomRight - topLeft) / 4.0;
    await tester.tapAt(target);
    expect(value, closeTo(0.75, 0.05));
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });

  testWidgets('Slider take on discrete values', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new Material(
              child: new Center(
                child: new SizedBox(
                  width: 144.0 + 2 * 16.0, // _kPreferredTotalWidth
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
              ),
            );
          },
        ),
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
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Material(
        child: new Slider(
          value: 0.0,
          min: 0.0,
          max: 1.0,
          onChanged: (double newValue) { log.add(newValue); },
        ),
      ),
    ));

    await tester.tap(find.byType(Slider));
    expect(log, <double>[0.5]);
    log.clear();

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Material(
        child: new Slider(
          value: 0.0,
          min: 0.0,
          max: 0.0,
          onChanged: (double newValue) { log.add(newValue); },
        ),
      ),
    ));

    await tester.tap(find.byType(Slider));
    expect(log, <double>[]);
    log.clear();
  });

  testWidgets('Slider has a customizable active color',
      (WidgetTester tester) async {
    const Color customColor = const Color(0xFF4CD964);
    final ThemeData theme = new ThemeData(platform: TargetPlatform.android);
    Widget buildApp(Color activeColor) {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new Center(
            child: new Theme(
              data: theme,
              child: new Slider(
                value: 0.5,
                activeColor: activeColor,
                onChanged: (double newValue) {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(null));

    final RenderBox sliderBox =
        tester.firstRenderObject<RenderBox>(find.byType(Slider));

    expect(sliderBox, paints..rect(color: theme.accentColor)..rect(color: theme.unselectedWidgetColor));
    expect(sliderBox, paints..circle(color: theme.accentColor));
    expect(sliderBox, isNot(paints..circle(color: customColor)));
    expect(sliderBox, isNot(paints..circle(color: theme.unselectedWidgetColor)));
    await tester.pumpWidget(buildApp(customColor));
    expect(sliderBox, paints..rect(color: customColor)..rect(color: theme.unselectedWidgetColor));
    expect(sliderBox, paints..circle(color: customColor));
    expect(sliderBox, isNot(paints..circle(color: theme.accentColor)));
    expect(sliderBox, isNot(paints..circle(color: theme.unselectedWidgetColor)));
  });

  testWidgets('Slider has a customizable inactive color',
      (WidgetTester tester) async {
    const Color customColor = const Color(0xFF4CD964);
    final ThemeData theme = new ThemeData(platform: TargetPlatform.android);
    Widget buildApp(Color inactiveColor) {
      return new Directionality(
      textDirection: TextDirection.ltr,
        child: new Material(
          child: new Center(
            child: new Theme(
              data: theme,
              child: new Slider(
                value: 0.5,
                inactiveColor: inactiveColor,
                onChanged: (double newValue) {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(null));

    final RenderBox sliderBox =
        tester.firstRenderObject<RenderBox>(find.byType(Slider));

    expect(sliderBox, paints..rect(color: theme.accentColor)..rect(color: theme.unselectedWidgetColor));
    expect(sliderBox, paints..circle(color: theme.accentColor));
    await tester.pumpWidget(buildApp(customColor));
    expect(sliderBox, paints..rect(color: theme.accentColor)..rect(color: customColor));
    expect(sliderBox, paints..circle(color: theme.accentColor));
  });

  testWidgets('Slider can draw an open thumb at min (LTR)',
      (WidgetTester tester) async {
    Widget buildApp(bool thumbOpenAtMin) {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new Center(
            child: new Slider(
              value: 0.0,
              thumbOpenAtMin: thumbOpenAtMin,
              onChanged: (double newValue) {},
            ),
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

  testWidgets('Slider can draw an open thumb at min (RTL)',
      (WidgetTester tester) async {
    Widget buildApp(bool thumbOpenAtMin) {
      return new Directionality(
        textDirection: TextDirection.rtl,
        child: new Material(
          child: new Center(
            child: new Slider(
              value: 0.0,
              thumbOpenAtMin: thumbOpenAtMin,
              onChanged: (double newValue) {},
            ),
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
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Material(
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
      ),
    ));

    await tester.tap(find.byType(Slider));
    expect(value, equals(0.5));
  });

  testWidgets('Slider drags immediately (LTR)', (WidgetTester tester) async {
    double value = 0.0;
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Material(
        child: new Center(
          child: new Slider(
            value: value,
            onChanged: (double newValue) {
              value = newValue;
            },
          ),
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

  testWidgets('Slider drags immediately (RTL)', (WidgetTester tester) async {
    double value = 0.0;
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.rtl,
      child: new Material(
        child: new Center(
          child: new Slider(
            value: value,
            onChanged: (double newValue) {
              value = newValue;
            },
          ),
        ),
      ),
    ));

    final Offset center = tester.getCenter(find.byType(Slider));
    final TestGesture gesture = await tester.startGesture(center);

    expect(value, equals(0.5));

    await gesture.moveBy(const Offset(1.0, 0.0));

    expect(value, lessThan(0.5));

    await gesture.up();
  });

  testWidgets('Slider sizing', (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: const Material(
        child: const Center(
          child: const Slider(
            value: 0.5,
            onChanged: null,
          ),
        ),
      ),
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(800.0, 600.0));

    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: const Material(
        child: const Center(
          child: const IntrinsicWidth(
            child: const Slider(
              value: 0.5,
              onChanged: null,
            ),
          ),
        ),
      ),
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(144.0 + 2.0 * 16.0, 600.0));

    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: const Material(
        child: const Center(
          child: const OverflowBox(
            maxWidth: double.INFINITY,
            maxHeight: double.INFINITY,
            child: const Slider(
              value: 0.5,
              onChanged: null,
            ),
          ),
        ),
      ),
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(144.0 + 2.0 * 16.0, 32.0));
  });

  testWidgets('discrete Slider respects textScaleFactor', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;

    Widget buildSlider({ double textScaleFactor }) {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new MediaQuery(
              data: new MediaQueryData(textScaleFactor: textScaleFactor),
              child: new Material(
                child: new Center(
                  child: new OverflowBox(
                    maxWidth: double.INFINITY,
                    maxHeight: double.INFINITY,
                    child: new Slider(
                      key: sliderKey,
                      min: 0.0,
                      max: 100.0,
                      divisions: 10,
                      label: '${value.round()}',
                      value: value,
                      onChanged: (double newValue) {
                        setState(() {
                          value = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildSlider(textScaleFactor: 1.0));
    Offset center = tester.getCenter(find.byType(Slider));
    TestGesture gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(10.0, 0.0));

    expect(
      tester.renderObject(find.byType(Slider)),
      paints..circle(radius: 6.0, x: 16.0, y: 44.0)
    );

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(buildSlider(textScaleFactor: 2.0));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(10.0, 0.0));

    expect(
      tester.renderObject(find.byType(Slider)),
      paints..circle(radius: 12.0, x: 16.0, y: 44.0)
    );

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Slider Semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Material(
        child: new Slider(
          value: 0.5,
          onChanged: (double v) {},
        ),
      ),
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
          children: <TestSemantics>[
            new TestSemantics.rootChild(
              id: 1,
              actions: SemanticsAction.decrease.index | SemanticsAction.increase.index,
            ),
          ]
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    // Disable slider
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: const Material(
        child: const Slider(
          value: 0.5,
          onChanged: null,
        ),
      ),
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });
}
