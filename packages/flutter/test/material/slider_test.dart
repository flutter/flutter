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

// A thumb shape that also logs its repaint center.
class LoggingThumbShape extends SliderComponentShape {
  LoggingThumbShape(this.log);

  final List<Offset> log;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(10.0, 10.0);
  }

  @override
  void paint(
    RenderBox parentBox,
    PaintingContext context,
    bool isDiscrete,
    Offset thumbCenter,
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    TextPainter labelPainter,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  ) {
    log.add(thumbCenter);
    final Paint thumbPaint = new Paint()..color = Colors.red;
    context.canvas.drawCircle(thumbCenter, 5.0, thumbPaint);
  }
}

void main() {
  testWidgets('Slider can move when tapped (LTR)', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new MediaQuery(
              data: new MediaQueryData.fromWindow(window),
              child: new Material(
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
            return new MediaQuery(
              data: new MediaQueryData.fromWindow(window),
              child: new Material(
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

  testWidgets("Slider doesn't send duplicate change events if tapped on the same value", (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;
    int updates = 0;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new MediaQuery(
              data: new MediaQueryData.fromWindow(window),
              child: new Material(
                child: new Center(
                  child: new Slider(
                    key: sliderKey,
                    value: value,
                    onChanged: (double newValue) {
                      setState(() {
                        updates++;
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
    expect(value, equals(0.5));
    await tester.pump();
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(0.5));
    await tester.pump();
    expect(updates, equals(1));
  });

  testWidgets('Value indicator shows for a bit after being tapped', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new MediaQuery(
              data: new MediaQueryData.fromWindow(window),
              child: new Material(
                child: new Center(
                  child: new Slider(
                    key: sliderKey,
                    value: value,
                    divisions: 4,
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
    expect(value, equals(0.5));
    await tester.pump(const Duration(milliseconds: 100));
    // Starts with the position animation and value indicator
    expect(SchedulerBinding.instance.transientCallbackCount, equals(2));
    await tester.pump(const Duration(milliseconds: 100));
    // Value indicator is longer than position.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
    await tester.pump(const Duration(milliseconds: 100));
    // Shown for long enough, value indicator is animated closed.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(1));
    await tester.pump(const Duration(milliseconds: 101));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });

  testWidgets('Discrete Slider repaints and animates when dragged', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;
    final List<Offset> log = <Offset>[];
    final LoggingThumbShape loggingThumb = new LoggingThumbShape(log);
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final SliderThemeData sliderTheme = SliderTheme.of(context).copyWith(thumbShape: loggingThumb);
            return new MediaQuery(
              data: new MediaQueryData.fromWindow(window),
              child: new Material(
                child: new Center(
                  child: new SliderTheme(
                    data: sliderTheme,
                    child: new Slider(
                      key: sliderKey,
                      value: value,
                      divisions: 4,
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
      ),
    );

    final List<Offset> expectedLog = <Offset>[
      const Offset(16.0, 300.0),
      const Offset(16.0, 300.0),
      const Offset(400.0, 300.0),
    ];
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(sliderKey)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(value, equals(0.5));
    expect(log.length, 3);
    expect(log, orderedEquals(expectedLog));
    await gesture.moveBy(const Offset(-500.0, 0.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(value, equals(0.0));
    expect(log.length, 5);
    expect(log.last.dx, closeTo(386.3, 0.1));
    // With no more gesture or value changes, the thumb position should still
    // be redrawn in the animated position.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(value, equals(0.0));
    expect(log.length, 7);
    expect(log.last.dx, closeTo(343.3, 0.1));
    // Final position.
    await tester.pump(const Duration(milliseconds: 80));
    expectedLog.add(const Offset(16.0, 300.0));
    expect(value, equals(0.0));
    expect(log.length, 8);
    expect(log.last.dx, closeTo(16.0, 0.1));
    await gesture.up();
  });

  testWidgets("Slider doesn't send duplicate change events if tapped on the same value", (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;
    int updates = 0;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new MediaQuery(
              data: new MediaQueryData.fromWindow(window),
              child: new Material(
                child: new Center(
                  child: new Slider(
                    key: sliderKey,
                    value: value,
                    onChanged: (double newValue) {
                      setState(() {
                        updates++;
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
    expect(value, equals(0.5));
    await tester.pump();
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(0.5));
    await tester.pump();
    expect(updates, equals(1));
  });

  testWidgets('discrete Slider repaints when dragged', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;
    final List<Offset> log = <Offset>[];
    final LoggingThumbShape loggingThumb = new LoggingThumbShape(log);
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final SliderThemeData sliderTheme = SliderTheme.of(context).copyWith(thumbShape: loggingThumb);
            return new MediaQuery(
              data: new MediaQueryData.fromWindow(window),
              child: new Material(
                child: new Center(
                  child: new SliderTheme(
                    data: sliderTheme,
                    child: new Slider(
                      key: sliderKey,
                      value: value,
                      divisions: 4,
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
      ),
    );

    final List<Offset> expectedLog = <Offset>[
      const Offset(16.0, 300.0),
      const Offset(16.0, 300.0),
      const Offset(400.0, 300.0),
    ];
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(sliderKey)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(value, equals(0.5));
    expect(log.length, 3);
    expect(log, orderedEquals(expectedLog));
    await gesture.moveBy(const Offset(-500.0, 0.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(value, equals(0.0));
    expect(log.length, 5);
    expect(log.last.dx, closeTo(386.3, 0.1));
    // With no more gesture or value changes, the thumb position should still
    // be redrawn in the animated position.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(value, equals(0.0));
    expect(log.length, 7);
    expect(log.last.dx, closeTo(343.3, 0.1));
    // Final position.
    await tester.pump(const Duration(milliseconds: 80));
    expectedLog.add(const Offset(16.0, 300.0));
    expect(value, equals(0.0));
    expect(log.length, 8);
    expect(log.last.dx, closeTo(16.0, 0.1));
    await gesture.up();
  });

  testWidgets('Slider take on discrete values', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new MediaQuery(
              data: new MediaQueryData.fromWindow(window),
              child: new Material(
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

  testWidgets('Slider can be given zero values', (WidgetTester tester) async {
    final List<double> log = <double>[];
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
        child: new Material(
          child: new Slider(
            value: 0.0,
            min: 0.0,
            max: 1.0,
            onChanged: (double newValue) {
              log.add(newValue);
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(Slider));
    expect(log, <double>[0.5]);
    log.clear();

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
        child: new Material(
          child: new Slider(
            value: 0.0,
            min: 0.0,
            max: 0.0,
            onChanged: (double newValue) {
              log.add(newValue);
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(Slider));
    expect(log, <double>[]);
    log.clear();
  });

  testWidgets('Slider uses the right theme colors for the right components', (WidgetTester tester) async {
    const Color customColor1 = const Color(0xcafefeed);
    const Color customColor2 = const Color(0xdeadbeef);
    final ThemeData theme = new ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;
    double value = 0.45;
    Widget buildApp({
      Color activeColor,
      Color inactiveColor,
      int divisions,
      bool enabled: true,
    }) {
      final ValueChanged<double> onChanged = !enabled
          ? null
          : (double d) {
              value = d;
            };
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: new MediaQueryData.fromWindow(window),
          child: new Material(
            child: new Center(
              child: new Theme(
                data: theme,
                child: new Slider(
                  value: value,
                  label: '$value',
                  divisions: divisions,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(Slider));

    // Check default theme for enabled widget.
    expect(sliderBox, paints..rect(color: sliderTheme.activeRailColor)..rect(color: sliderTheme.inactiveRailColor));
    expect(sliderBox, paints..circle(color: sliderTheme.thumbColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveRailColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveRailColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.activeTickMarkColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.inactiveTickMarkColor)));

    // Test setting only the activeColor.
    await tester.pumpWidget(buildApp(activeColor: customColor1));
    expect(sliderBox, paints..rect(color: customColor1)..rect(color: sliderTheme.inactiveRailColor));
    expect(sliderBox, paints..circle(color: customColor1));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveRailColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveRailColor)));

    // Test setting only the inactiveColor.
    await tester.pumpWidget(buildApp(inactiveColor: customColor1));
    expect(sliderBox, paints..rect(color: sliderTheme.activeRailColor)..rect(color: customColor1));
    expect(sliderBox, paints..circle(color: sliderTheme.thumbColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveRailColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveRailColor)));

    // Test setting both activeColor and inactiveColor.
    await tester.pumpWidget(buildApp(activeColor: customColor1, inactiveColor: customColor2));
    expect(sliderBox, paints..rect(color: customColor1)..rect(color: customColor2));
    expect(sliderBox, paints..circle(color: customColor1));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveRailColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveRailColor)));

    // Test colors for discrete slider.
    await tester.pumpWidget(buildApp(divisions: 3));
    expect(sliderBox, paints..rect(color: sliderTheme.activeRailColor)..rect(color: sliderTheme.inactiveRailColor));
    expect(
        sliderBox,
        paints
          ..circle(color: sliderTheme.activeTickMarkColor)
          ..circle(color: sliderTheme.activeTickMarkColor)
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.thumbColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveRailColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveRailColor)));

    // Test colors for discrete slider with inactiveColor and activeColor set.
    await tester.pumpWidget(buildApp(
      activeColor: customColor1,
      inactiveColor: customColor2,
      divisions: 3,
    ));
    expect(sliderBox, paints..rect(color: customColor1)..rect(color: customColor2));
    expect(
        sliderBox,
        paints
          ..circle(color: customColor2)
          ..circle(color: customColor2)
          ..circle(color: customColor1)
          ..circle(color: customColor1)
          ..circle(color: customColor1));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveRailColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveRailColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.activeTickMarkColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.inactiveTickMarkColor)));

    // Test default theme for disabled widget.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(
        sliderBox,
        paints
          ..rect(color: sliderTheme.disabledActiveRailColor)
          ..rect(color: sliderTheme.disabledInactiveRailColor));
    expect(sliderBox, paints..circle(color: sliderTheme.disabledThumbColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.activeRailColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.inactiveRailColor)));

    // Test setting the activeColor and inactiveColor for disabled widget.
    await tester.pumpWidget(buildApp(activeColor: customColor1, inactiveColor: customColor2, enabled: false));
    expect(
        sliderBox,
        paints
          ..rect(color: sliderTheme.disabledActiveRailColor)
          ..rect(color: sliderTheme.disabledInactiveRailColor));
    expect(sliderBox, paints..circle(color: sliderTheme.disabledThumbColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.activeRailColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.inactiveRailColor)));

    // Test that the default value indicator has the right colors.
    await tester.pumpWidget(buildApp(divisions: 3));
    Offset center = tester.getCenter(find.byType(Slider));
    TestGesture gesture = await tester.startGesture(center);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(value, equals(2.0 / 3.0));
    expect(
      sliderBox,
      paints
        ..rect(color: sliderTheme.activeRailColor)
        ..rect(color: sliderTheme.inactiveRailColor)
        ..circle(color: sliderTheme.overlayColor)
        ..circle(color: sliderTheme.activeTickMarkColor)
        ..circle(color: sliderTheme.activeTickMarkColor)
        ..circle(color: sliderTheme.inactiveTickMarkColor)
        ..circle(color: sliderTheme.inactiveTickMarkColor)
        ..path(color: sliderTheme.valueIndicatorColor)
        ..circle(color: sliderTheme.thumbColor),
    );
    await gesture.up();
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();

    // Testing the custom colors are used for the indicator.
    await tester.pumpWidget(buildApp(
      divisions: 3,
      activeColor: customColor1,
      inactiveColor: customColor2,
    ));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(value, equals(2.0 / 3.0));
    expect(
      sliderBox,
      paints
        ..rect(color: customColor1)
        ..rect(color: customColor2)
        ..circle(color: customColor1.withAlpha(0x29))
        ..circle(color: customColor2)
        ..circle(color: customColor2)
        ..circle(color: customColor1)
        ..path(color: customColor1)
        ..circle(color: customColor1),
    );
    await gesture.up();
  });

  testWidgets('Slider can tap in vertical scroller', (WidgetTester tester) async {
    double value = 0.0;
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
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
      ),
    ));

    await tester.tap(find.byType(Slider));
    expect(value, equals(0.5));
  });

  testWidgets('Slider drags immediately (LTR)', (WidgetTester tester) async {
    double value = 0.0;
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
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
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
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
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
        child: const Material(
          child: const Center(
            child: const Slider(
              value: 0.5,
              onChanged: null,
            ),
          ),
        ),
      ),
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(800.0, 600.0));

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
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
      ),
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(144.0 + 2.0 * 16.0, 600.0));

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
        child: const Material(
          child: const Center(
            child: const OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: const Slider(
                value: 0.5,
                onChanged: null,
              ),
            ),
          ),
        ),
      ),
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(144.0 + 2.0 * 16.0, 32.0));
  });

  testWidgets('Slider respects textScaleFactor', (WidgetTester tester) async {
    final Key sliderKey = new UniqueKey();
    double value = 0.0;

    Widget buildSlider({
      double textScaleFactor,
      bool isDiscrete: true,
      ShowValueIndicator show: ShowValueIndicator.onlyForDiscrete,
    }) {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new MediaQuery(
              data: new MediaQueryData(textScaleFactor: textScaleFactor),
              child: new Material(
                child: new Theme(
                  data: Theme.of(context).copyWith(
                        sliderTheme: Theme.of(context).sliderTheme.copyWith(showValueIndicator: show),
                      ),
                  child: new Center(
                    child: new OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: new Slider(
                        key: sliderKey,
                        min: 0.0,
                        max: 100.0,
                        divisions: isDiscrete ? 10 : null,
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
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildSlider(textScaleFactor: 1.0));
    Offset center = tester.getCenter(find.byType(Slider));
    TestGesture gesture = await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(tester.renderObject(find.byType(Slider)), paints..scale(x: 1.0, y: 1.0));

    await gesture.up();
    await tester.pumpAndSettle();

    await tester.pumpWidget(buildSlider(textScaleFactor: 2.0));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(tester.renderObject(find.byType(Slider)), paints..scale(x: 2.0, y: 2.0));

    await gesture.up();
    await tester.pumpAndSettle();

    // Check continuous
    await tester.pumpWidget(buildSlider(
      textScaleFactor: 1.0,
      isDiscrete: false,
      show: ShowValueIndicator.onlyForContinuous,
    ));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(tester.renderObject(find.byType(Slider)), paints..scale(x: 1.0, y: 1.0));

    await gesture.up();
    await tester.pumpAndSettle();

    await tester.pumpWidget(buildSlider(
      textScaleFactor: 2.0,
      isDiscrete: false,
      show: ShowValueIndicator.onlyForContinuous,
    ));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(tester.renderObject(find.byType(Slider)), paints..scale(x: 2.0, y: 2.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Slider has correct animations when reparented', (WidgetTester tester) async {
    final Key sliderKey = new GlobalKey(debugLabel: 'A');
    double value = 0.0;

    Widget buildSlider(int parents) {
      Widget createParents(int parents, StateSetter setState) {
        Widget slider = new Slider(
          key: sliderKey,
          value: value,
          divisions: 4,
          onChanged: (double newValue) {
            setState(() {
              value = newValue;
            });
          },
        );

        for (int i = 0; i < parents; ++i) {
          slider = new Column(children: <Widget>[slider]);
        }
        return slider;
      }

      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new MediaQuery(
              data: new MediaQueryData.fromWindow(window),
              child: new Material(
                child: createParents(parents, setState),
              ),
            );
          },
        ),
      );
    }

    Future<Null> testReparenting(bool reparent) async {
      final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(Slider));
      final Offset center = tester.getCenter(find.byType(Slider));
      // Move to 0.0.
      TestGesture gesture = await tester.startGesture(Offset.zero);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
      expect(
        sliderBox,
        paints
          ..circle(x: 208.5, y: 16.0, radius: 1.0)
          ..circle(x: 400.0, y: 16.0, radius: 1.0)
          ..circle(x: 591.5, y: 16.0, radius: 1.0)
          ..circle(x: 783.0, y: 16.0, radius: 1.0)
          ..circle(x: 16.0, y: 16.0, radius: 6.0),
      );

      gesture = await tester.startGesture(center);
      await tester.pump();
      // Wait for animations to start.
      await tester.pump(const Duration(milliseconds: 25));
      expect(SchedulerBinding.instance.transientCallbackCount, equals(2));
      expect(
        sliderBox,
        paints
          ..circle(x: 105.0625, y: 16.0, radius: 3.791776657104492)
          ..circle(x: 17.0, y: 16.0, radius: 1.0)
          ..circle(x: 208.5, y: 16.0, radius: 1.0)
          ..circle(x: 400.0, y: 16.0, radius: 1.0)
          ..circle(x: 591.5, y: 16.0, radius: 1.0)
          ..circle(x: 783.0, y: 16.0, radius: 1.0)
          ..circle(x: 105.0625, y: 16.0, radius: 6.0),
      );

      // Reparenting in the middle of an animation should do nothing.
      if (reparent) {
        await tester.pumpWidget(buildSlider(2));
      }

      // Move a little further in the animations.
      await tester.pump(const Duration(milliseconds: 10));
      expect(SchedulerBinding.instance.transientCallbackCount, equals(2));
      expect(
        sliderBox,
        paints
          ..circle(x: 185.5457763671875, y: 16.0, radius: 8.0)
          ..circle(x: 17.0, y: 16.0, radius: 1.0)
          ..circle(x: 208.5, y: 16.0, radius: 1.0)
          ..circle(x: 400.0, y: 16.0, radius: 1.0)
          ..circle(x: 591.5, y: 16.0, radius: 1.0)
          ..circle(x: 783.0, y: 16.0, radius: 1.0)
          ..circle(x: 185.5457763671875, y: 16.0, radius: 6.0),
      );
      // Wait for animations to finish.
      await tester.pumpAndSettle();
      expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
      expect(
        sliderBox,
        paints
          ..circle(x: 400.0, y: 16.0, radius: 16.0)
          ..circle(x: 17.0, y: 16.0, radius: 1.0)
          ..circle(x: 208.5, y: 16.0, radius: 1.0)
          ..circle(x: 591.5, y: 16.0, radius: 1.0)
          ..circle(x: 783.0, y: 16.0, radius: 1.0)
          ..circle(x: 400.0, y: 16.0, radius: 6.0),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
      expect(
        sliderBox,
        paints
          ..circle(x: 17.0, y: 16.0, radius: 1.0)
          ..circle(x: 208.5, y: 16.0, radius: 1.0)
          ..circle(x: 591.5, y: 16.0, radius: 1.0)
          ..circle(x: 783.0, y: 16.0, radius: 1.0)
          ..circle(x: 400.0, y: 16.0, radius: 6.0),
      );
    }

    await tester.pumpWidget(buildSlider(1));
    // Do it once without reparenting in the middle of an animation
    await testReparenting(false);
    // Now do it again with reparenting in the middle of an animation.
    await testReparenting(true);
  });

  testWidgets('Slider Semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
        child: new Material(
          child: new Slider(
            value: 0.5,
            onChanged: (double v) {},
          ),
        ),
      ),
    ));

    expect(
        semantics,
        hasSemantics(
          new TestSemantics.root(children: <TestSemantics>[
            new TestSemantics.rootChild(
              id: 1,
              actions: SemanticsAction.decrease.index | SemanticsAction.increase.index,
            ),
          ]),
          ignoreRect: true,
          ignoreTransform: true,
        ));

    // Disable slider
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
        child: const Material(
          child: const Slider(
            value: 0.5,
            onChanged: null,
          ),
        ),
      ),
    ));

    expect(
        semantics,
        hasSemantics(
          new TestSemantics.root(),
          ignoreRect: true,
          ignoreTransform: true,
        ));

    semantics.dispose();
  });

  testWidgets('Value indicator appears when it should', (WidgetTester tester) async {
    final ThemeData baseTheme = new ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    SliderThemeData theme = baseTheme.sliderTheme;
    double value = 0.45;
    Widget buildApp({SliderThemeData sliderTheme, int divisions, bool enabled: true}) {
      final ValueChanged<double> onChanged = enabled ? (double d) => value = d : null;
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: new MediaQueryData.fromWindow(window),
          child: new Material(
            child: new Center(
              child: new Theme(
                data: baseTheme,
                child: new SliderTheme(
                  data: sliderTheme,
                  child: new Slider(
                    value: value,
                    label: '$value',
                    divisions: divisions,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<Null> expectValueIndicator({
      bool isVisible,
      SliderThemeData theme,
      int divisions,
      bool enabled: true,
    }) async {
      // Discrete enabled widget.
      await tester.pumpWidget(buildApp(sliderTheme: theme, divisions: divisions, enabled: enabled));
      final Offset center = tester.getCenter(find.byType(Slider));
      final TestGesture gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();

      final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(Slider));
      expect(
        sliderBox,
        isVisible
            ? (paints..path(color: theme.valueIndicatorColor))
            : isNot(paints..path(color: theme.valueIndicatorColor)),
      );
      await gesture.up();
    }

    // Default (showValueIndicator set to onlyForDiscrete).
    await expectValueIndicator(isVisible: true, theme: theme, divisions: 3, enabled: true);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3, enabled: false);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: true);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);

    // With showValueIndicator set to onlyForContinuous.
    theme = theme.copyWith(showValueIndicator: ShowValueIndicator.onlyForContinuous);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3, enabled: true);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3, enabled: false);
    await expectValueIndicator(isVisible: true, theme: theme, enabled: true);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);

    // discrete enabled widget with showValueIndicator set to always.
    theme = theme.copyWith(showValueIndicator: ShowValueIndicator.always);
    await expectValueIndicator(isVisible: true, theme: theme, divisions: 3, enabled: true);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3, enabled: false);
    await expectValueIndicator(isVisible: true, theme: theme, enabled: true);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);

    // discrete enabled widget with showValueIndicator set to never.
    theme = theme.copyWith(showValueIndicator: ShowValueIndicator.never);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3, enabled: true);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3, enabled: false);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: true);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);
  });
}
