// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
      PaintingContext context,
      Offset thumbCenter, {
      Animation<double> activationAnimation,
      Animation<double> enableAnimation,
      bool isEnabled,
      bool isDiscrete,
      bool onActiveTrack,
      TextPainter labelPainter,
      RenderBox parentBox,
      SliderThemeData sliderTheme,
      TextDirection textDirection,
      double value,
    }) {
    log.add(thumbCenter);
    final Paint thumbPaint = Paint()..color = Colors.red;
    context.canvas.drawCircle(thumbCenter, 5.0, thumbPaint);
  }
}

class TallSliderTickMarkShape extends SliderTickMarkShape {
  @override
  Size getPreferredSize({SliderThemeData sliderTheme, bool isEnabled}) {
    return const Size(10.0, 200.0);
  }

  @override
  void paint(
      PaintingContext context,
      Offset offset, {
      Offset thumbCenter,
      RenderBox parentBox,
      SliderThemeData sliderTheme,
      Animation<double> enableAnimation,
      bool isEnabled,
      TextDirection textDirection,
    }) {
    final Paint paint = Paint()..color = Colors.red;
    context.canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, 10.0, 20.0), paint);
  }
}

void main() {
  testWidgets('Slider can move when tapped (LTR)', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    double startValue;
    double endValue;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: Slider(
                    key: sliderKey,
                    value: value,
                    onChanged: (double newValue) {
                      setState(() {
                        value = newValue;
                      });
                    },
                    onChangeStart: (double value) {
                      startValue = value;
                    },
                    onChangeEnd: (double value) {
                      endValue = value;
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
    expect(startValue, equals(0.0));
    expect(endValue, equals(0.5));
    startValue = null;
    endValue = null;
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));

    final Offset topLeft = tester.getTopLeft(find.byKey(sliderKey));
    final Offset bottomRight = tester.getBottomRight(find.byKey(sliderKey));

    final Offset target = topLeft + (bottomRight - topLeft) / 4.0;
    await tester.tapAt(target);
    expect(value, closeTo(0.25, 0.05));
    expect(startValue, equals(0.5));
    expect(endValue, closeTo(0.25, 0.05));
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });

  testWidgets('Slider can move when tapped (RTL)', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: Slider(
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
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    double startValue;
    double endValue;
    int updates = 0;
    int startValueUpdates = 0;
    int endValueUpdates = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: Slider(
                    key: sliderKey,
                    value: value,
                    onChanged: (double newValue) {
                      setState(() {
                        updates++;
                        value = newValue;
                      });
                    },
                    onChangeStart: (double value) {
                      startValueUpdates++;
                      startValue = value;
                    },
                    onChangeEnd: (double value) {
                      endValueUpdates++;
                      endValue = value;
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
    expect(startValue, equals(0.0));
    expect(endValue, equals(0.5));
    await tester.pump();
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(0.5));
    await tester.pump();
    expect(updates, equals(1));
    expect(startValueUpdates, equals(2));
    expect(endValueUpdates, equals(2));
  });

  testWidgets('Value indicator shows for a bit after being tapped', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: Slider(
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
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    final List<Offset> log = <Offset>[];
    final LoggingThumbShape loggingThumb = LoggingThumbShape(log);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final SliderThemeData sliderTheme = SliderTheme.of(context).copyWith(thumbShape: loggingThumb);
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: SliderTheme(
                    data: sliderTheme,
                    child: Slider(
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
      const Offset(24.0, 300.0),
      const Offset(24.0, 300.0),
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
    expect(log.last.dx, closeTo(386.6, 0.1));
    // With no more gesture or value changes, the thumb position should still
    // be redrawn in the animated position.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(value, equals(0.0));
    expect(log.length, 7);
    expect(log.last.dx, closeTo(344.5, 0.1));
    // Final position.
    await tester.pump(const Duration(milliseconds: 80));
    expectedLog.add(const Offset(24.0, 300.0));
    expect(value, equals(0.0));
    expect(log.length, 8);
    expect(log.last.dx, closeTo(24.0, 0.1));
    await gesture.up();
  });

  testWidgets("Slider doesn't send duplicate change events if tapped on the same value", (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    int updates = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: Slider(
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
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    final List<Offset> log = <Offset>[];
    final LoggingThumbShape loggingThumb = LoggingThumbShape(log);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final SliderThemeData sliderTheme = SliderTheme.of(context).copyWith(thumbShape: loggingThumb);
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: SliderTheme(
                    data: sliderTheme,
                    child: Slider(
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
      const Offset(24.0, 300.0),
      const Offset(24.0, 300.0),
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
    expect(log.last.dx, closeTo(386.6, 0.1));
    // With no more gesture or value changes, the thumb position should still
    // be redrawn in the animated position.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(value, equals(0.0));
    expect(log.length, 7);
    expect(log.last.dx, closeTo(344.5, 0.1));
    // Final position.
    await tester.pump(const Duration(milliseconds: 80));
    expectedLog.add(const Offset(24.0, 300.0));
    expect(value, equals(0.0));
    expect(log.length, 8);
    expect(log.last.dx, closeTo(24.0, 0.1));
    await gesture.up();
  });

  testWidgets('Slider take on discrete values', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: SizedBox(
                    width: 144.0 + 2 * 16.0, // _kPreferredTotalWidth
                    child: Slider(
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
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: Material(
          child: Slider(
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

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: Material(
          child: Slider(
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
    const Color customColor1 = Color(0xcafefeed);
    const Color customColor2 = Color(0xdeadbeef);
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
      sliderTheme: const SliderThemeData(
        disabledThumbColor: Color(0xff000001),
        disabledActiveTickMarkColor: Color(0xff000002),
        disabledActiveTrackColor: Color(0xff000003),
        disabledInactiveTickMarkColor: Color(0xff000004),
        disabledInactiveTrackColor: Color(0xff000005),
        activeTrackColor: Color(0xff000006),
        activeTickMarkColor: Color(0xff000007),
        inactiveTrackColor: Color(0xff000008),
        inactiveTickMarkColor: Color(0xff000009),
        overlayColor: Color(0xff000010),
        thumbColor: Color(0xff000011),
        valueIndicatorColor: Color(0xff000012),
      )
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;
    double value = 0.45;
    Widget buildApp({
      Color activeColor,
      Color inactiveColor,
      int divisions,
      bool enabled = true,
    }) {
      final ValueChanged<double> onChanged = !enabled
        ? null
        : (double d) {
            value = d;
          };
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window),
          child: Material(
            child: Center(
              child: Theme(
                data: theme,
                child: Slider(
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
    expect(sliderBox, paints..rect(color: sliderTheme.activeTrackColor)..rect(color: sliderTheme.inactiveTrackColor));
    expect(sliderBox, paints..circle(color: sliderTheme.thumbColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.activeTickMarkColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.inactiveTickMarkColor)));

    // Test setting only the activeColor.
    await tester.pumpWidget(buildApp(activeColor: customColor1));
    expect(sliderBox, paints..rect(color: customColor1)..rect(color: sliderTheme.inactiveTrackColor));
    expect(sliderBox, paints..circle(color: customColor1));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));

    // Test setting only the inactiveColor.
    await tester.pumpWidget(buildApp(inactiveColor: customColor1));
    expect(sliderBox, paints..rect(color: sliderTheme.activeTrackColor)..rect(color: customColor1));
    expect(sliderBox, paints..circle(color: sliderTheme.thumbColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));

    // Test setting both activeColor and inactiveColor.
    await tester.pumpWidget(buildApp(activeColor: customColor1, inactiveColor: customColor2));
    expect(sliderBox, paints..rect(color: customColor1)..rect(color: customColor2));
    expect(sliderBox, paints..circle(color: customColor1));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));

    // Test colors for discrete slider.
    await tester.pumpWidget(buildApp(divisions: 3));
    expect(sliderBox, paints..rect(color: sliderTheme.activeTrackColor)..rect(color: sliderTheme.inactiveTrackColor));
    expect(
        sliderBox,
        paints
          ..circle(color: sliderTheme.activeTickMarkColor)
          ..circle(color: sliderTheme.activeTickMarkColor)
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.thumbColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));

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
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.activeTickMarkColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.inactiveTickMarkColor)));

    // Test default theme for disabled widget.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(
        sliderBox,
        paints
          ..rect(color: sliderTheme.disabledActiveTrackColor)
          ..rect(color: sliderTheme.disabledInactiveTrackColor));
    expect(sliderBox, paints..circle(color: sliderTheme.disabledThumbColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.activeTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.inactiveTrackColor)));

    // Test setting the activeColor and inactiveColor for disabled widget.
    await tester.pumpWidget(buildApp(activeColor: customColor1, inactiveColor: customColor2, enabled: false));
    expect(
        sliderBox,
        paints
          ..rect(color: sliderTheme.disabledActiveTrackColor)
          ..rect(color: sliderTheme.disabledInactiveTrackColor));
    expect(sliderBox, paints..circle(color: sliderTheme.disabledThumbColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.activeTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.inactiveTrackColor)));

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
        ..rect(color: sliderTheme.activeTrackColor)
        ..rect(color: sliderTheme.inactiveTrackColor)
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
        ..rect(color: customColor1) // active track
        ..rect(color: customColor2) // inactive track
        ..circle(color: customColor1.withOpacity(0.12)) // overlay
        ..circle(color: customColor2) // 1st tick mark
        ..circle(color: customColor2) // 2nd tick mark
        ..circle(color: customColor2) // 3rd tick mark
        ..circle(color: customColor1) // 4th tick mark
        ..path(color: customColor1) // indicator
        ..circle(color: customColor1), // thumb
    );
    await gesture.up();
  });

  testWidgets('Slider can tap in vertical scroller', (WidgetTester tester) async {
    double value = 0.0;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: Material(
          child: ListView(
            children: <Widget>[
              Slider(
                value: value,
                onChanged: (double newValue) {
                  value = newValue;
                },
              ),
              Container(
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
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: Material(
          child: Center(
            child: Slider(
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
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: Material(
          child: Center(
            child: Slider(
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
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: const Material(
          child: Center(
            child: Slider(
              value: 0.5,
              onChanged: null,
            ),
          ),
        ),
      ),
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(800.0, 600.0));

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: const Material(
          child: Center(
            child: IntrinsicWidth(
              child: Slider(
                value: 0.5,
                onChanged: null,
              ),
            ),
          ),
        ),
      ),
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(144.0 + 2.0 * 24.0, 600.0));

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: const Material(
          child: Center(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Slider(
                value: 0.5,
                onChanged: null,
              ),
            ),
          ),
        ),
      ),
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(144.0 + 2.0 * 24.0, 48.0));
  });

  testWidgets('Slider respects textScaleFactor', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;

    Widget buildSlider({
      double textScaleFactor,
      bool isDiscrete = true,
      ShowValueIndicator show = ShowValueIndicator.onlyForDiscrete,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData(textScaleFactor: textScaleFactor),
              child: Material(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    sliderTheme: Theme.of(context).sliderTheme.copyWith(showValueIndicator: show),
                  ),
                  child: Center(
                    child: OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: Slider(
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
  }, skip: isBrowser);

  testWidgets('Tick marks are skipped when they are too dense', (WidgetTester tester) async {
    Widget buildSlider({
      int divisions,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window),
          child: Material(
            child: Center(
              child: Slider(
                min: 0.0,
                max: 100.0,
                divisions: divisions,
                value: 0.25,
                onChanged: (double newValue) { },
              ),
            ),
          ),
        ),
      );
    }

    // Pump a slider with a reasonable amount of divisions to verify that the
    // tick marks are drawn when the number of tick marks is not too dense.
    await tester.pumpWidget(
      buildSlider(
        divisions: 4,
      ),
    );

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(Slider));

    // 5 tick marks and a thumb.
    expect(sliderBox, paintsExactlyCountTimes(#drawCircle, 6));

    // 200 divisions will produce a tick interval off less than 6,
    // which would be too dense to draw.
    await tester.pumpWidget(
      buildSlider(
        divisions: 200,
      ),
    );

    // No tick marks are drawn because they are too dense, but the thumb is
    // still drawn.
    expect(sliderBox, paintsExactlyCountTimes(#drawCircle, 1));
  });

  testWidgets('Slider has correct animations when reparented', (WidgetTester tester) async {
    final Key sliderKey = GlobalKey(debugLabel: 'A');
    double value = 0.0;

    Widget buildSlider(int parents) {
      Widget createParents(int parents, StateSetter setState) {
        Widget slider = Slider(
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
          slider = Column(children: <Widget>[slider]);
        }
        return slider;
      }

      return Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: createParents(parents, setState),
              ),
            );
          },
        ),
      );
    }

    Future<void> testReparenting(bool reparent) async {
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
          ..circle(x: 25.0, y: 24.0, radius: 1.0)
          ..circle(x: 212.5, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 1.0)
          ..circle(x: 587.5, y: 24.0, radius: 1.0)
          ..circle(x: 775.0, y: 24.0, radius: 1.0)
          ..circle(x: 24.0, y: 24.0, radius: 10.0),
      );

      gesture = await tester.startGesture(center);
      await tester.pump();
      // Wait for animations to start.
      await tester.pump(const Duration(milliseconds: 25));
      expect(SchedulerBinding.instance.transientCallbackCount, equals(2));
      expect(
        sliderBox,
        paints
          ..circle(x: 111.20703125, y: 24.0, radius: 5.687664985656738)
          ..circle(x: 25.0, y: 24.0, radius: 1.0)
          ..circle(x: 212.5, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 1.0)
          ..circle(x: 587.5, y: 24.0, radius: 1.0)
          ..circle(x: 775.0, y: 24.0, radius: 1.0)
          ..circle(x: 111.20703125, y: 24.0, radius: 10.0),
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
          ..circle(x: 190.0135726928711, y: 24.0, radius: 12.0)
          ..circle(x: 25.0, y: 24.0, radius: 1.0)
          ..circle(x: 212.5, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 1.0)
          ..circle(x: 587.5, y: 24.0, radius: 1.0)
          ..circle(x: 775.0, y: 24.0, radius: 1.0)
          ..circle(x: 190.0135726928711, y: 24.0, radius: 10.0),
      );
      // Wait for animations to finish.
      await tester.pumpAndSettle();
      expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
      expect(
        sliderBox,
        paints
          ..circle(x: 400.0, y: 24.0, radius: 24.0)
          ..circle(x: 25.0, y: 24.0, radius: 1.0)
          ..circle(x: 212.5, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 1.0)
          ..circle(x: 587.5, y: 24.0, radius: 1.0)
          ..circle(x: 775.0, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 10.0),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
      expect(
        sliderBox,
        paints
          ..circle(x: 25.0, y: 24.0, radius: 1.0)
          ..circle(x: 212.5, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 1.0)
          ..circle(x: 587.5, y: 24.0, radius: 1.0)
          ..circle(x: 775.0, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 10.0),
      );
    }

    await tester.pumpWidget(buildSlider(1));
    // Do it once without reparenting in the middle of an animation
    await testReparenting(false);
    // Now do it again with reparenting in the middle of an animation.
    await testReparenting(true);
  });

  testWidgets('Slider Semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: Material(
          child: Slider(
            value: 0.5,
            onChanged: (double v) { },
          ),
        ),
      ),
    ));

    expect(
        semantics,
        hasSemantics(
          TestSemantics.root(children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              value: '50%',
              increasedValue: '55%',
              decreasedValue: '45%',
              textDirection: TextDirection.ltr,
              actions: SemanticsAction.decrease.index | SemanticsAction.increase.index,
            ),
          ]),
          ignoreRect: true,
          ignoreTransform: true,
        ));

    // Disable slider
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: const Material(
          child: Slider(
            value: 0.5,
            onChanged: null,
          ),
        ),
      ),
    ));

    expect(
        semantics,
        hasSemantics(
          TestSemantics.root(),
          ignoreRect: true,
          ignoreTransform: true,
        ));

    semantics.dispose();
  });

  testWidgets('Slider Semantics - iOS', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Theme(
        data: ThemeData.light().copyWith(
          platform: TargetPlatform.iOS,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData.fromWindow(window),
            child: Material(
              child: Slider(
                value: 100.0,
                min: 0.0,
                max: 200.0,
                onChanged: (double v) { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(children: <TestSemantics>[
          TestSemantics.rootChild(
            id: 1,
            value: '50%',
            increasedValue: '60%',
            decreasedValue: '40%',
            textDirection: TextDirection.ltr,
            actions: SemanticsAction.decrease.index | SemanticsAction.increase.index,
          ),
        ]),
        ignoreRect: true,
        ignoreTransform: true,
      ));
    semantics.dispose();
  });

  testWidgets('Slider semantics with custom formatter', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: Material(
          child: Slider(
            value: 40.0,
            min: 0.0,
            max: 200.0,
            divisions: 10,
            semanticFormatterCallback: (double value) => value.round().toString(),
            onChanged: (double v) { },
          ),
        ),
      ),
    ));

    expect(
        semantics,
        hasSemantics(
          TestSemantics.root(children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              value: '40',
              increasedValue: '60',
              decreasedValue: '20',
              textDirection: TextDirection.ltr,
              actions: SemanticsAction.decrease.index | SemanticsAction.increase.index,
            ),
          ]),
          ignoreRect: true,
          ignoreTransform: true,
        ));
    semantics.dispose();
  });

  testWidgets('Value indicator appears when it should', (WidgetTester tester) async {
    final ThemeData baseTheme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    SliderThemeData theme = baseTheme.sliderTheme;
    double value = 0.45;
    Widget buildApp({ SliderThemeData sliderTheme, int divisions, bool enabled = true }) {
      final ValueChanged<double> onChanged = enabled ? (double d) => value = d : null;
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window),
          child: Material(
            child: Center(
              child: Theme(
                data: baseTheme,
                child: SliderTheme(
                  data: sliderTheme,
                  child: Slider(
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

    Future<void> expectValueIndicator({
      bool isVisible,
      SliderThemeData theme,
      int divisions,
      bool enabled = true,
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

  testWidgets("Slider doesn't start any animations after dispose", (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: Slider(
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

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(sliderKey)));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(value, equals(0.5));
    await gesture.moveBy(const Offset(-500.0, 0.0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    // Change the tree to dispose the original widget.
    await tester.pumpWidget(Container());
    expect(await tester.pumpAndSettle(const Duration(milliseconds: 100)), equals(1));
    await gesture.up();
  });

  testWidgets('Slider.adaptive', (WidgetTester tester) async {
    double value = 0.5;

    Widget buildFrame(TargetPlatform platform) {
      return MaterialApp(
        theme: ThemeData(platform: platform),
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: Slider.adaptive(
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
    }

    await tester.pumpWidget(buildFrame(TargetPlatform.iOS));
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byType(CupertinoSlider), findsOneWidget);

    expect(value, 0.5);
    TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CupertinoSlider)));
    // Drag to the right end of the track.
    await gesture.moveBy(const Offset(600.0, 0.0));
    expect(value, 1.0);

    value = 0.5;
    await tester.pumpWidget(buildFrame(TargetPlatform.android));
    await tester.pumpAndSettle(); // Finish the theme change animation.
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byType(CupertinoSlider), findsNothing);

    expect(value, 0.5);
    gesture = await tester.startGesture(tester.getCenter(find.byType(Slider)));
    // Drag to the right end of the track.
    await gesture.moveBy(const Offset(600.0, 0.0));
    expect(value, 1.0);
  });

  testWidgets('Slider respects height from theme', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final SliderThemeData sliderTheme = SliderTheme.of(context).copyWith(tickMarkShape: TallSliderTickMarkShape());
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: IntrinsicHeight(
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
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
              ),
            );
          },
        ),
      ),
    );

    final RenderBox renderObject = tester.renderObject<RenderBox>(find.byType(Slider));
    expect(renderObject.size.height, 200);
  });

  testWidgets(
      'Slider implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    const Slider(
      activeColor: Colors.blue,
      divisions: 10,
      inactiveColor: Colors.grey,
      label: 'Set a value',
      max: 100.0,
      min: 0.0,
      onChanged: null,
      onChangeEnd: null,
      onChangeStart: null,
      semanticFormatterCallback: null,
      value: 50.0,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      'value: 50.0',
      'disabled',
      'min: 0.0',
      'max: 100.0',
      'divisions: 10',
      'label: "Set a value"',
      'activeColor: MaterialColor(primary value: Color(0xff2196f3))',
      'inactiveColor: MaterialColor(primary value: Color(0xff9e9e9e))',
    ]);
  });
}
