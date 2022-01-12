// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/physics/utils.dart' show nearEqual;
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
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    log.add(thumbCenter);
    final Paint thumbPaint = Paint()..color = Colors.red;
    context.canvas.drawCircle(thumbCenter, 5.0, thumbPaint);
  }
}

class TallSliderTickMarkShape extends SliderTickMarkShape {
  @override
  Size getPreferredSize({required SliderThemeData sliderTheme, required bool isEnabled}) {
    return const Size(10.0, 200.0);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required Offset thumbCenter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required bool isEnabled,
    required TextDirection textDirection,
  }) {
    final Paint paint = Paint()..color = Colors.red;
    context.canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, 10.0, 20.0), paint);
  }
}

void main() {
  testWidgets('Slider can move when tapped (LTR)', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    double? startValue;
    double? endValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
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
              );
            },
          ),
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
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));

    final Offset topLeft = tester.getTopLeft(find.byKey(sliderKey));
    final Offset bottomRight = tester.getBottomRight(find.byKey(sliderKey));

    final Offset target = topLeft + (bottomRight - topLeft) / 4.0;
    await tester.tapAt(target);
    expect(value, moreOrLessEquals(0.25, epsilon: 0.05));
    expect(startValue, equals(0.5));
    expect(endValue, moreOrLessEquals(0.25, epsilon: 0.05));
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));
  });

  testWidgets('Slider can move when tapped (RTL)', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
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
              );
            },
          ),
        ),
      ),
    );

    expect(value, equals(0.0));
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(0.5));
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));

    final Offset topLeft = tester.getTopLeft(find.byKey(sliderKey));
    final Offset bottomRight = tester.getBottomRight(find.byKey(sliderKey));

    final Offset target = topLeft + (bottomRight - topLeft) / 4.0;
    await tester.tapAt(target);
    expect(value, moreOrLessEquals(0.75, epsilon: 0.05));
    await tester.pump(); // No animation should start.
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));
  });

  testWidgets("Slider doesn't send duplicate change events if tapped on the same value", (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    late double startValue;
    late double endValue;
    int updates = 0;
    int startValueUpdates = 0;
    int endValueUpdates = 0;


    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
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
              );
            },
          ),
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
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
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
              );
            },
          ),
        ),
      ),
    );

    expect(value, equals(0.0));
    await tester.tap(find.byKey(sliderKey));
    expect(value, equals(0.5));
    await tester.pump(const Duration(milliseconds: 100));
    // Starts with the position animation and value indicator
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(2));
    await tester.pump(const Duration(milliseconds: 100));
    // Value indicator is longer than position.
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));
    await tester.pump(const Duration(milliseconds: 100));
    // Shown for long enough, value indicator is animated closed.
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(1));
    await tester.pump(const Duration(milliseconds: 101));
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));
  });

  testWidgets('Discrete Slider repaints and animates when dragged', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    final List<Offset> log = <Offset>[];
    final LoggingThumbShape loggingThumb = LoggingThumbShape(log);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final SliderThemeData sliderTheme = SliderTheme.of(context).copyWith(thumbShape: loggingThumb);
              return Material(
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
              );
            },
          ),
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
    expect(log.last.dx, moreOrLessEquals(386.6, epsilon: 0.1));
    // With no more gesture or value changes, the thumb position should still
    // be redrawn in the animated position.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(value, equals(0.0));
    expect(log.length, 7);
    expect(log.last.dx, moreOrLessEquals(344.5, epsilon: 0.1));
    // Final position.
    await tester.pump(const Duration(milliseconds: 80));
    expectedLog.add(const Offset(24.0, 300.0));
    expect(value, equals(0.0));
    expect(log.length, 8);
    expect(log.last.dx, moreOrLessEquals(24.0, epsilon: 0.1));
    await gesture.up();
  });

  testWidgets("Slider doesn't send duplicate change events if tapped on the same value", (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    int updates = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
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
              );
            },
          ),
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
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final SliderThemeData sliderTheme = SliderTheme.of(context).copyWith(thumbShape: loggingThumb);
              return Material(
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
              );
            },
          ),
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
    expect(log.last.dx, moreOrLessEquals(386.6, epsilon: 0.1));
    // With no more gesture or value changes, the thumb position should still
    // be redrawn in the animated position.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(value, equals(0.0));
    expect(log.length, 7);
    expect(log.last.dx, moreOrLessEquals(344.5, epsilon: 0.1));
    // Final position.
    await tester.pump(const Duration(milliseconds: 80));
    expectedLog.add(const Offset(24.0, 300.0));
    expect(value, equals(0.0));
    expect(log.length, 8);
    expect(log.last.dx, moreOrLessEquals(24.0, epsilon: 0.1));
    await gesture.up();
  });

  testWidgets('Slider take on discrete values', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: SizedBox(
                    width: 144.0 + 2 * 16.0, // _kPreferredTotalWidth
                    child: Slider(
                      key: sliderKey,
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
    expect(SchedulerBinding.instance!.transientCallbackCount, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    // Animation complete.
    expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));
  });

  testWidgets('Slider can be given zero values', (WidgetTester tester) async {
    final List<double> log = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Slider(
              value: 0.0,
              onChanged: (double newValue) {
                log.add(newValue);
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Slider));
    expect(log, <double>[0.5]);
    log.clear();

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Slider(
              value: 0.0,
              max: 0.0,
              onChanged: (double newValue) {
                log.add(newValue);
              },
            ),
          ),
        ),
      ),
    );

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
      ),
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;
    double value = 0.45;
    Widget buildApp({
      Color? activeColor,
      Color? inactiveColor,
      int? divisions,
      bool enabled = true,
    }) {
      final ValueChanged<double>? onChanged = !enabled
        ? null
        : (double d) {
            value = d;
          };
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
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

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;
    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

    // Check default theme for enabled widget.
    expect(material, paints..rrect(color: sliderTheme.activeTrackColor)..rrect(color: sliderTheme.inactiveTrackColor));
    expect(material, paints..shadow(color: const Color(0xff000000)));
    expect(material, paints..circle(color: sliderTheme.thumbColor));
    expect(material, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledActiveTrackColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledInactiveTrackColor)));
    expect(material, isNot(paints..circle(color: sliderTheme.activeTickMarkColor)));
    expect(material, isNot(paints..circle(color: sliderTheme.inactiveTickMarkColor)));

    // Test setting only the activeColor.
    await tester.pumpWidget(buildApp(activeColor: customColor1));
    expect(material, paints..rrect(color: customColor1)..rrect(color: sliderTheme.inactiveTrackColor));
    expect(material, paints..shadow(color: Colors.black));
    expect(material, paints..circle(color: customColor1));
    expect(material, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(material, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledActiveTrackColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledInactiveTrackColor)));

    // Test setting only the inactiveColor.
    await tester.pumpWidget(buildApp(inactiveColor: customColor1));
    expect(material, paints..rrect(color: sliderTheme.activeTrackColor)..rrect(color: customColor1));
    expect(material, paints..shadow(color: Colors.black));
    expect(material, paints..circle(color: sliderTheme.thumbColor));
    expect(material, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledActiveTrackColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledInactiveTrackColor)));

    // Test setting both activeColor and inactiveColor.
    await tester.pumpWidget(buildApp(activeColor: customColor1, inactiveColor: customColor2));
    expect(material, paints..rrect(color: customColor1)..rrect(color: customColor2));
    expect(material, paints..shadow(color: Colors.black));
    expect(material, paints..circle(color: customColor1));
    expect(material, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(material, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledActiveTrackColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledInactiveTrackColor)));

    // Test colors for discrete slider.
    await tester.pumpWidget(buildApp(divisions: 3));
    expect(material, paints..rrect(color: sliderTheme.activeTrackColor)..rrect(color: sliderTheme.inactiveTrackColor));
    expect(
      material,
      paints
        ..circle(color: sliderTheme.activeTickMarkColor)
        ..circle(color: sliderTheme.activeTickMarkColor)
        ..circle(color: sliderTheme.inactiveTickMarkColor)
        ..circle(color: sliderTheme.inactiveTickMarkColor)
        ..shadow(color: Colors.black)
        ..circle(color: sliderTheme.thumbColor),
    );
    expect(material, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledActiveTrackColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledInactiveTrackColor)));

    // Test colors for discrete slider with inactiveColor and activeColor set.
    await tester.pumpWidget(buildApp(
      activeColor: customColor1,
      inactiveColor: customColor2,
      divisions: 3,
    ));
    expect(material, paints..rrect(color: customColor1)..rrect(color: customColor2));
    expect(
      material,
      paints
        ..circle(color: customColor2)
        ..circle(color: customColor2)
        ..circle(color: customColor1)
        ..circle(color: customColor1)
        ..shadow(color: Colors.black)
        ..circle(color: customColor1),
    );
    expect(material, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(material, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledActiveTrackColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.disabledInactiveTrackColor)));
    expect(material, isNot(paints..circle(color: sliderTheme.activeTickMarkColor)));
    expect(material, isNot(paints..circle(color: sliderTheme.inactiveTickMarkColor)));

    // Test default theme for disabled widget.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(
      material,
      paints
        ..rrect(color: sliderTheme.disabledActiveTrackColor)
        ..rrect(color: sliderTheme.disabledInactiveTrackColor),
    );
    expect(material, paints..shadow(color: Colors.black)..circle(color: sliderTheme.disabledThumbColor));
    expect(material, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.activeTrackColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.inactiveTrackColor)));

    // Test setting the activeColor and inactiveColor for disabled widget.
    await tester.pumpWidget(buildApp(activeColor: customColor1, inactiveColor: customColor2, enabled: false));
    expect(
      material,
      paints
        ..rrect(color: sliderTheme.disabledActiveTrackColor)
        ..rrect(color: sliderTheme.disabledInactiveTrackColor),
    );
    expect(material, paints..circle(color: sliderTheme.disabledThumbColor));
    expect(material, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.activeTrackColor)));
    expect(material, isNot(paints..rrect(color: sliderTheme.inactiveTrackColor)));

    // Test that the default value indicator has the right colors.
    await tester.pumpWidget(buildApp(divisions: 3));
    Offset center = tester.getCenter(find.byType(Slider));
    TestGesture gesture = await tester.startGesture(center);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(value, equals(2.0 / 3.0));
    expect(
      valueIndicatorBox,
      paints
        ..path(color: sliderTheme.valueIndicatorColor)
        ..paragraph(),
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
      valueIndicatorBox,
      paints
        ..rrect(color: customColor1) // active track
        ..rrect(color: customColor2) // inactive track
        ..circle(color: customColor1.withOpacity(0.12)) // overlay
        ..circle(color: customColor2) // 1st tick mark
        ..circle(color: customColor2) // 2nd tick mark
        ..circle(color: customColor2) // 3rd tick mark
        ..circle(color: customColor1) // 4th tick mark
        ..shadow(color: Colors.black)
        ..circle(color: customColor1) // thumb
        ..path(color: sliderTheme.valueIndicatorColor), // indicator
    );
    await gesture.up();
  });

  testWidgets('Slider can tap in vertical scroller', (WidgetTester tester) async {
    double value = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
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
      ),
    );

    await tester.tap(find.byType(Slider));
    expect(value, equals(0.5));
  });

  testWidgets('Slider drags immediately (LTR)', (WidgetTester tester) async {
    double value = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
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
      ),
    );

    final Offset center = tester.getCenter(find.byType(Slider));
    final TestGesture gesture = await tester.startGesture(center);

    expect(value, equals(0.5));

    await gesture.moveBy(const Offset(1.0, 0.0));

    expect(value, greaterThan(0.5));

    await gesture.up();
  });

  testWidgets('Slider drags immediately (RTL)', (WidgetTester tester) async {
    double value = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
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
      ),
    );

    final Offset center = tester.getCenter(find.byType(Slider));
    final TestGesture gesture = await tester.startGesture(center);

    expect(value, equals(0.5));

    await gesture.moveBy(const Offset(1.0, 0.0));

    expect(value, lessThan(0.5));

    await gesture.up();
  });

  testWidgets('Slider onChangeStart and onChangeEnd fire once', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/28115

    int startFired = 0;
    int endFired = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: GestureDetector(
                onHorizontalDragUpdate: (_) { },
                child: Slider(
                  value: 0.0,
                  onChanged: (double newValue) { },
                  onChangeStart: (double value) {
                    startFired += 1;
                  },
                  onChangeEnd: (double value) {
                    endFired += 1;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.timedDrag(
      find.byType(Slider),
      const Offset(20.0, 0.0),
      const Duration(milliseconds: 100),
    );

    expect(startFired, equals(1));
    expect(endFired, equals(1));
  });

  testWidgets('Slider sizing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Slider(
                value: 0.5,
                onChanged: null,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(800.0, 600.0));

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
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
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(144.0 + 2.0 * 24.0, 600.0));

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
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
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Slider)).size, const Size(144.0 + 2.0 * 24.0, 48.0));
  });

  testWidgets('Slider respects textScaleFactor', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;

    Widget buildSlider({
      required double textScaleFactor,
      bool isDiscrete = true,
      ShowValueIndicator show = ShowValueIndicator.onlyForDiscrete,
    }) {
      return MaterialApp(
        home: Directionality(
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
        ),
      );
    }

    await tester.pumpWidget(buildSlider(textScaleFactor: 1.0));
    Offset center = tester.getCenter(find.byType(Slider));
    TestGesture gesture = await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(
      tester.renderObject(find.byType(Overlay)),
      paints
        ..path(
          includes: const <Offset>[
            Offset.zero,
            Offset(0.0, -8.0),
            Offset(-276.0, -16.0),
            Offset(-216.0, -16.0),
          ],
          color: const Color(0xf55f5f5f),
        )
        ..paragraph(),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    await tester.pumpWidget(buildSlider(textScaleFactor: 2.0));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(
      tester.renderObject(find.byType(Overlay)),
      paints
        ..path(
          includes: const <Offset>[
            Offset.zero,
            Offset(0.0, -8.0),
            Offset(-304.0, -16.0),
            Offset(-216.0, -16.0),
          ],
          color: const Color(0xf55f5f5f),
        )
        ..paragraph(),
    );

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

    expect(tester.renderObject(find.byType(Overlay)),
      paints
        ..path(
          includes: const <Offset>[
            Offset.zero,
            Offset(0.0, -8.0),
            Offset(-276.0, -16.0),
            Offset(-216.0, -16.0),
          ],
          color: const Color(0xf55f5f5f),
        )
        ..paragraph(),
    );

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

    expect(
      tester.renderObject(find.byType(Overlay)),
      paints
        ..path(
          includes: const <Offset>[
            Offset.zero,
            Offset(0.0, -8.0),
            Offset(-276.0, -16.0),
            Offset(-216.0, -16.0),
          ],
          color: const Color(0xf55f5f5f),
        )
        ..paragraph(),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Tick marks are skipped when they are too dense', (WidgetTester tester) async {
    Widget buildSlider({
      required int divisions,
    }) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Slider(
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

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    // 5 tick marks and a thumb.
    expect(material, paintsExactlyCountTimes(#drawCircle, 6));

    // 200 divisions will produce a tick interval off less than 6,
    // which would be too dense to draw.
    await tester.pumpWidget(
      buildSlider(
        divisions: 200,
      ),
    );

    // No tick marks are drawn because they are too dense, but the thumb is
    // still drawn.
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));
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

      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: createParents(parents, setState),
              );
            },
          ),
        ),
      );
    }

    Future<void> testReparenting(bool reparent) async {
      final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;
      final Offset center = tester.getCenter(find.byType(Slider));
      // Move to 0.0.
      TestGesture gesture = await tester.startGesture(Offset.zero);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));
      expect(
        material,
        paints
          ..circle(x: 26.0, y: 24.0, radius: 1.0)
          ..circle(x: 213.0, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 1.0)
          ..circle(x: 587.0, y: 24.0, radius: 1.0)
          ..circle(x: 774.0, y: 24.0, radius: 1.0)
          ..circle(x: 24.0, y: 24.0, radius: 10.0),
      );

      gesture = await tester.startGesture(center);
      await tester.pump();
      // Wait for animations to start.
      await tester.pump(const Duration(milliseconds: 25));
      expect(SchedulerBinding.instance!.transientCallbackCount, equals(2));
      expect(
        material,
        paints
          ..circle(x: 111.20703125, y: 24.0, radius: 5.687664985656738)
          ..circle(x: 26.0, y: 24.0, radius: 1.0)
          ..circle(x: 213.0, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 1.0)
          ..circle(x: 587.0, y: 24.0, radius: 1.0)
          ..circle(x: 774.0, y: 24.0, radius: 1.0)
          ..circle(x: 111.20703125, y: 24.0, radius: 10.0),
      );

      // Reparenting in the middle of an animation should do nothing.
      if (reparent) {
        await tester.pumpWidget(buildSlider(2));
      }

      // Move a little further in the animations.
      await tester.pump(const Duration(milliseconds: 10));
      expect(SchedulerBinding.instance!.transientCallbackCount, equals(2));
      expect(
        material,
        paints
          ..circle(x: 190.0135726928711, y: 24.0, radius: 12.0)
          ..circle(x: 26.0, y: 24.0, radius: 1.0)
          ..circle(x: 213.0, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 1.0)
          ..circle(x: 587.0, y: 24.0, radius: 1.0)
          ..circle(x: 774.0, y: 24.0, radius: 1.0)
          ..circle(x: 190.0135726928711, y: 24.0, radius: 10.0),
      );
      // Wait for animations to finish.
      await tester.pumpAndSettle();
      expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));
      expect(
        material,
        paints
          ..circle(x: 400.0, y: 24.0, radius: 24.0)
          ..circle(x: 26.0, y: 24.0, radius: 1.0)
          ..circle(x: 213.0, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 1.0)
          ..circle(x: 587.0, y: 24.0, radius: 1.0)
          ..circle(x: 774.0, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 10.0),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(SchedulerBinding.instance!.transientCallbackCount, equals(0));
      expect(
        material,
        paints
          ..circle(x: 26.0, y: 24.0, radius: 1.0)
          ..circle(x: 213.0, y: 24.0, radius: 1.0)
          ..circle(x: 400.0, y: 24.0, radius: 1.0)
          ..circle(x: 587.0, y: 24.0, radius: 1.0)
          ..circle(x: 774.0, y: 24.0, radius: 1.0)
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

    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Slider(
            value: 0.5,
            onChanged: (double v) { },
          ),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 3,
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 4,
                          flags: <SemanticsFlag>[
                            SemanticsFlag.hasEnabledState,
                            SemanticsFlag.isEnabled,
                            SemanticsFlag.isFocusable,
                            SemanticsFlag.isSlider,
                          ],
                          actions: <SemanticsAction>[
                            SemanticsAction.increase,
                            SemanticsAction.decrease,
                          ],
                          value: '50%',
                          increasedValue: '55%',
                          decreasedValue: '45%',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    // Disable slider
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
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
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 3,
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 4,
                          flags: <SemanticsFlag>[
                            SemanticsFlag.hasEnabledState,
                            // isFocusable is delayed by 1 frame.
                            SemanticsFlag.isFocusable,
                            SemanticsFlag.isSlider,
                          ],
                          value: '50%',
                          increasedValue: '55%',
                          decreasedValue: '45%',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    await tester.pump();
    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 3,
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 4,
                          flags: <SemanticsFlag>[
                            SemanticsFlag.hasEnabledState,
                            SemanticsFlag.isSlider,
                          ],
                          value: '50%',
                          increasedValue: '55%',
                          decreasedValue: '45%',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android,  TargetPlatform.fuchsia, TargetPlatform.linux }));

  testWidgets('Slider Semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: ThemeData.light(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: Slider(
                value: 100.0,
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
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 3,
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 4,
                          flags: <SemanticsFlag>[SemanticsFlag.hasEnabledState, SemanticsFlag.isEnabled, SemanticsFlag.isFocusable, SemanticsFlag.isSlider],
                          actions: <SemanticsAction>[SemanticsAction.increase, SemanticsAction.decrease],
                          value: '50%',
                          increasedValue: '60%',
                          decreasedValue: '40%',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    // Disable slider
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
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
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 3,
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 5,
                          flags: <SemanticsFlag>[SemanticsFlag.hasEnabledState, SemanticsFlag.isSlider],
                          value: '50%',
                          increasedValue: '60%',
                          decreasedValue: '40%',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );
    semantics.dispose();
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Slider Semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Slider(
            value: 0.5,
            onChanged: (double v) { },
          ),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 3,
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 4,
                          flags: <SemanticsFlag>[
                            SemanticsFlag.hasEnabledState,
                            SemanticsFlag.isEnabled,
                            SemanticsFlag.isFocusable,
                            SemanticsFlag.isSlider,
                          ],
                          actions: <SemanticsAction>[
                            SemanticsAction.increase,
                            SemanticsAction.decrease,
                            SemanticsAction.didGainAccessibilityFocus,
                          ],
                          value: '50%',
                          increasedValue: '55%',
                          decreasedValue: '45%',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    // Disable slider
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
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
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 3,
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 4,
                          flags: <SemanticsFlag>[
                            SemanticsFlag.hasEnabledState,
                            // isFocusable is delayed by 1 frame.
                            SemanticsFlag.isFocusable,
                            SemanticsFlag.isSlider,
                          ],
                          actions: <SemanticsAction>[
                            SemanticsAction.didGainAccessibilityFocus,
                          ],
                          value: '50%',
                          increasedValue: '55%',
                          decreasedValue: '45%',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    await tester.pump();
    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 3,
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 4,
                          flags: <SemanticsFlag>[
                            SemanticsFlag.hasEnabledState,
                            SemanticsFlag.isSlider,
                          ],
                          actions: <SemanticsAction>[
                            SemanticsAction.didGainAccessibilityFocus,
                          ],
                          value: '50%',
                          increasedValue: '55%',
                          decreasedValue: '45%',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.windows }));

  testWidgets('Slider semantics with custom formatter', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Slider(
            value: 40.0,
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
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 3,
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 4,
                          flags: <SemanticsFlag>[SemanticsFlag.hasEnabledState, SemanticsFlag.isEnabled, SemanticsFlag.isFocusable, SemanticsFlag.isSlider],
                          actions: <SemanticsAction>[SemanticsAction.increase, SemanticsAction.decrease],
                          value: '40',
                          increasedValue: '60',
                          decreasedValue: '20',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('Slider is focusable and has correct focus color', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'Slider');
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    double value = 0.5;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return SliderTheme(
                data: SliderThemeData(
                  overlayColor: Colors.orange[500],
                ),
                child: Slider(
                  value: value,
                  onChanged: enabled ? (double newValue) {
                    setState(() {
                      value = newValue;
                    });
                  } : null,
                  autofocus: true,
                  focusNode: focusNode,
                ),
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());

    // Check that the overlay shows when focused.
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      Material.of(tester.element(find.byType(Slider))),
      paints..circle(color: Colors.orange[500]),
    );

    // Check that the overlay does not show when focused and disabled.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isFalse);
    expect(
      Material.of(tester.element(find.byType(Slider))),
      isNot(paints..circle(color: Colors.orange[500])),
    );
  });

  testWidgets('Slider can be hovered and has correct hover color', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    double value = 0.5;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return SliderTheme(
                data: SliderThemeData(
                  overlayColor: Colors.orange[500],
                ),
                child: Slider(
                  value: value,
                  onChanged: enabled ? (double newValue) {
                    setState(() {
                      value = newValue;
                    });
                  } : null,
                ),
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());

    // Slider does not have overlay when enabled and not hovered.
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(Slider))),
      isNot(paints..circle(color: Colors.orange[500])),
    );

    // Start hovering.
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(Slider)));

    // Slider has overlay when enabled and hovering.
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(Slider))),
      paints..circle(color: Colors.orange[500]),
    );

    // Slider does not have an overlay when disabled and hovering.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(Slider))),
      isNot(paints..circle(color: Colors.orange[500])),
    );
  });

  testWidgets('Slider can be incremented and decremented by keyboard shortcuts - LTR', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    double value = 0.5;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Slider(
                value: value,
                onChanged: (double newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
                autofocus: true,
              );
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(value, 0.55);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(value, 0.5);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(value, 0.55);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(value, 0.5);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android,  TargetPlatform.fuchsia, TargetPlatform.linux, TargetPlatform.windows }));

  testWidgets('Slider can be incremented and decremented by keyboard shortcuts - LTR', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    double value = 0.5;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Slider(
                value: value,
                onChanged: (double newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
                autofocus: true,
              );
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(value, 0.6);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(value, 0.5);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(value, 0.6);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(value, 0.5);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Slider can be incremented and decremented by keyboard shortcuts - RTL', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    double value = 0.5;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Slider(
                  value: value,
                  onChanged: (double newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                  autofocus: true,
                ),
              );
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(value, 0.45);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(value, 0.5);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(value, 0.55);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(value, 0.5);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android,  TargetPlatform.fuchsia, TargetPlatform.linux, TargetPlatform.windows }));

  testWidgets('Slider can be incremented and decremented by keyboard shortcuts - RTL', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    double value = 0.5;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Slider(
                  value: value,
                  onChanged: (double newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                  autofocus: true,
                ),
              );
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(value, 0.4);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(value, 0.5);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(value, 0.6);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(value, 0.5);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Slider gains keyboard focus when it gains semantics focus on Windows', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner!;
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Slider(
            value: 0.5,
            onChanged: (double _) {},
            focusNode: focusNode,
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            id: 1,
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              TestSemantics(
                id: 2,
                children: <TestSemantics>[
                  TestSemantics(
                    id: 3,
                    flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                    children: <TestSemantics>[
                      TestSemantics(
                        id: 4,
                        flags: <SemanticsFlag>[
                          SemanticsFlag.hasEnabledState,
                          SemanticsFlag.isEnabled,
                          SemanticsFlag.isFocusable,
                          SemanticsFlag.isSlider,
                        ],
                        actions: <SemanticsAction>[
                          SemanticsAction.increase,
                          SemanticsAction.decrease,
                          SemanticsAction.didGainAccessibilityFocus,
                        ],
                        value: '50%',
                        increasedValue: '55%',
                        decreasedValue: '45%',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    expect(focusNode.hasFocus, isFalse);
    semanticsOwner.performAction(4, SemanticsAction.didGainAccessibilityFocus);
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);
    semantics.dispose();
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.windows }));

  testWidgets('Value indicator appears when it should', (WidgetTester tester) async {
    final ThemeData baseTheme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    SliderThemeData theme = baseTheme.sliderTheme;
    double value = 0.45;
    Widget buildApp({ required SliderThemeData sliderTheme, int? divisions, bool enabled = true }) {
      final ValueChanged<double>? onChanged = enabled ? (double d) => value = d : null;
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
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
      required bool isVisible,
      required SliderThemeData theme,
      int? divisions,
      bool enabled = true,
    }) async {
      // Discrete enabled widget.
      await tester.pumpWidget(buildApp(sliderTheme: theme, divisions: divisions, enabled: enabled));
      final Offset center = tester.getCenter(find.byType(Slider));
      final TestGesture gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();


      final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));
      expect(
        valueIndicatorBox,
        isVisible
            ? (paints..path(color: theme.valueIndicatorColor)..paragraph())
            : isNot(paints..path(color: theme.valueIndicatorColor)..paragraph()),
      );
      await gesture.up();
    }

    // Default (showValueIndicator set to onlyForDiscrete).
    await expectValueIndicator(isVisible: true, theme: theme, divisions: 3);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3, enabled: false);
    await expectValueIndicator(isVisible: false, theme: theme);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);

    // With showValueIndicator set to onlyForContinuous.
    theme = theme.copyWith(showValueIndicator: ShowValueIndicator.onlyForContinuous);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3, enabled: false);
    await expectValueIndicator(isVisible: true, theme: theme);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);

    // discrete enabled widget with showValueIndicator set to always.
    theme = theme.copyWith(showValueIndicator: ShowValueIndicator.always);
    await expectValueIndicator(isVisible: true, theme: theme, divisions: 3);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3, enabled: false);
    await expectValueIndicator(isVisible: true, theme: theme);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);

    // discrete enabled widget with showValueIndicator set to never.
    theme = theme.copyWith(showValueIndicator: ShowValueIndicator.never);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 3, enabled: false);
    await expectValueIndicator(isVisible: false, theme: theme);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);
  });

  testWidgets("Slider doesn't start any animations after dispose", (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
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
              );
            },
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(sliderKey)));
    await tester.pumpAndSettle();
    expect(value, equals(0.5));
    await gesture.moveBy(const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();
    // Change the tree to dispose the original widget.
    await tester.pumpWidget(Container());
    expect(await tester.pumpAndSettle(), equals(1));
    await gesture.up();
  });

  testWidgets('Slider removes value indicator from overlay if Slider gets disposed without value indicator animation completing.', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    const Color fillColor = Color(0xf55f5f5f);
    double value = 0.0;

    Widget buildApp({
      int? divisions,
      bool enabled = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            // The builder is used to pass the context from the MaterialApp widget
            // to the [Navigator]. This context is required in order for the
            // Navigator to work.
            builder: (BuildContext context) {
              return Column(
                children: <Widget>[
                  Slider(
                    key: sliderKey,
                    max: 100.0,
                    divisions: divisions,
                    label: '${value.round()}',
                    value: value,
                    onChanged: (double newValue) {
                      value = newValue;
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Next'),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) {
                            return ElevatedButton(
                              child: const Text('Inner page'),
                              onPressed: () { Navigator.of(context).pop(); },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(divisions: 3));

    final RenderObject valueIndicatorBox = tester.renderObject(find.byType(Overlay));
    final Offset topRight = tester.getTopRight(find.byType(Slider)).translate(-24, 0);
    final TestGesture gesture = await tester.startGesture(topRight);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();

    expect(find.byType(Slider), isNotNull);
    expect(
      valueIndicatorBox,
      paints
        // Represents the raised button with text, next.
        ..path(color: Colors.black)
        ..paragraph()
        // Represents the Slider.
        ..path(color: fillColor)
        ..paragraph(),
    );

    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 2));
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawParagraph, 2));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsNothing);
    expect(
      valueIndicatorBox,
      isNot(
        paints
          ..path(color: fillColor)
          ..paragraph(),
      ),
    );

    // Represents the ElevatedButton with inner Text, inner page.
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 1));
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawParagraph, 1));

    // Don't stop holding the value indicator.
    await gesture.up();
    await tester.pumpAndSettle();
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

    for (final TargetPlatform platform in <TargetPlatform>[TargetPlatform.iOS, TargetPlatform.macOS]) {
      value = 0.5;
      await tester.pumpWidget(buildFrame(platform));
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(CupertinoSlider), findsOneWidget);

      expect(value, 0.5, reason: 'on ${platform.name}');
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CupertinoSlider)));
      // Drag to the right end of the track.
      await gesture.moveBy(const Offset(600.0, 0.0));
      expect(value, 1.0, reason: 'on ${platform.name}');
      await gesture.up();
    }

    for (final TargetPlatform platform in <TargetPlatform>[TargetPlatform.android, TargetPlatform.fuchsia, TargetPlatform.linux, TargetPlatform.windows]) {
      value = 0.5;
      await tester.pumpWidget(buildFrame(platform));
      await tester.pumpAndSettle(); // Finish the theme change animation.
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(CupertinoSlider), findsNothing);

      expect(value, 0.5, reason: 'on ${platform.name}');
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Slider)));
      // Drag to the right end of the track.
      await gesture.moveBy(const Offset(600.0, 0.0));
      expect(value, 1.0, reason: 'on ${platform.name}');
      await gesture.up();
    }
  });

  testWidgets('Slider respects height from theme', (WidgetTester tester) async {
    final Key sliderKey = UniqueKey();
    double value = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final SliderThemeData sliderTheme = SliderTheme.of(context).copyWith(tickMarkShape: TallSliderTickMarkShape());
              return Material(
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
              );
            },
          ),
        ),
      ),
    );

    final RenderBox renderObject = tester.renderObject<RenderBox>(find.byType(Slider));
    expect(renderObject.size.height, 200);
  });

  testWidgets('Slider changes mouse cursor when hovered', (WidgetTester tester) async {
    // Test Slider() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Slider(
                  mouseCursor: SystemMouseCursors.text,
                  value: 0.5,
                  onChanged: (double newValue) { },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byType(Slider)));
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    // Test Slider.adaptive() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Slider.adaptive(
                  mouseCursor: SystemMouseCursors.text,
                  value: 0.5,
                  onChanged: (double newValue) { },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    // Test default cursor
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Slider(
                  value: 0.5,
                  onChanged: (double newValue) { },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);
  });

  testWidgets('Slider implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    const Slider(
      activeColor: Colors.blue,
      divisions: 10,
      inactiveColor: Colors.grey,
      label: 'Set a value',
      max: 100.0,
      onChanged: null,
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

  testWidgets('Slider track paints correctly when the shape is rectangular', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          sliderTheme: const SliderThemeData(
            trackShape: RectangularSliderTrackShape(),
          ),
        ),
        home: const Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Slider(
                value: 0.5,
                onChanged: null,
              ),
            ),
          ),
        ),
      ),
    );

    // _RenderSlider is the last render object in the tree.
    final RenderObject renderObject = tester.allRenderObjects.last;

    // The active track rect should start at 24.0 pixels,
    // and there should not have a gap between active and inactive track.
    expect(
      renderObject,
      paints
        ..rect(rect: const Rect.fromLTRB(24.0, 298.0, 400.0, 302.0)) // active track Rect.
        ..rect(rect: const Rect.fromLTRB(400.0, 298.0, 776.0, 302.0)), // inactive track Rect.
    );
  });

  testWidgets('Slider can be painted in a narrower constraint', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: SizedBox(
                height: 10.0,
                width: 10.0,
                child: Slider(
                  value: 0.5,
                  onChanged: null,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // _RenderSlider is the last render object in the tree.
    final RenderObject renderObject = tester.allRenderObjects.last;

    expect(
      renderObject,
      paints
        // active track RRect
        ..rrect(rrect: RRect.fromLTRBAndCorners(-14.0, 2.0, 5.0, 8.0, topLeft: const Radius.circular(3.0), bottomLeft: const Radius.circular(3.0)))
        // inactive track RRect
        ..rrect(rrect: RRect.fromLTRBAndCorners(5.0, 3.0, 24.0, 7.0, topRight: const Radius.circular(2.0), bottomRight: const Radius.circular(2.0)))
        // thumb
        ..circle(x: 5.0, y: 5.0, radius: 10.0, ),
    );
  });

  testWidgets('Update the divisions and value at the same time for Slider', (WidgetTester tester) async {
    // Regress test for https://github.com/flutter/flutter/issues/65943
    Widget buildFrame(double maxValue) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: Slider.adaptive(
              value: 5,
              max: maxValue,
              divisions: maxValue.toInt(),
              onChanged: (double newValue) {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(10));

    // _RenderSlider is the last render object in the tree.
    final RenderObject renderObject = tester.allRenderObjects.last;

    // Update the divisions from 10 to 15, the thumb should be paint at the correct position.
    await tester.pumpWidget(buildFrame(15));
    await tester.pumpAndSettle(); // Finish the animation.

    late RRect activeTrackRRect;
    expect(renderObject, paints..something((Symbol method, List<dynamic> arguments) {
      if (method != #drawRRect)
        return false;
      activeTrackRRect = arguments[0] as RRect;
      return true;
    }));

    // The thumb should at one-third(5 / 15) of the Slider.
    // The right of the active track shape is the position of the thumb.
    // 24.0 is the default margin, (800.0 - 24.0 - 24.0) is the slider's width.
    expect(nearEqual(activeTrackRRect.right, (800.0 - 24.0 - 24.0) * (5 / 15) + 24.0, 0.01), true);
  });


  testWidgets('Slider paints thumbColor', (WidgetTester tester) async {
    const Color color = Color(0xffffc107);

    final Widget sliderAdaptive = MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: Material(
        child: Slider(
          value: 0,
          onChanged: (double newValue) {},
          thumbColor: color,
        ),
      ),
    );

    await tester.pumpWidget(sliderAdaptive);
    await tester.pumpAndSettle();

    final MaterialInkController material =
        Material.of(tester.element(find.byType(Slider)))!;
    expect(material, paints..circle(color: color));
  });

  testWidgets('Slider.adaptive paints thumbColor on Android',
      (WidgetTester tester) async {
    const Color color = Color(0xffffc107);

    final Widget sliderAdaptive = MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: Material(
        child: Slider.adaptive(
          value: 0,
          onChanged: (double newValue) {},
          thumbColor: color,
        ),
      ),
    );

    await tester.pumpWidget(sliderAdaptive);
    await tester.pumpAndSettle();

    final MaterialInkController material =
        Material.of(tester.element(find.byType(Slider)))!;
    expect(material, paints..circle(color: color));
  });

  testWidgets('If thumbColor is null, it defaults to CupertinoColors.white',
      (WidgetTester tester) async {
    final Widget sliderAdaptive = MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: Material(
        child: Slider.adaptive(
          value: 0,
          onChanged: (double newValue) {},
        ),
      ),
    );

    await tester.pumpWidget(sliderAdaptive);
    await tester.pumpAndSettle();

    final MaterialInkController material =
        Material.of(tester.element(find.byType(CupertinoSlider)))!;
    expect(
      material,
      paints
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(color: CupertinoColors.white),
    );
  });

  testWidgets('Slider.adaptive passes thumbColor to CupertinoSlider',
      (WidgetTester tester) async {
    const Color color = Color(0xffffc107);

    final Widget sliderAdaptive = MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: Material(
        child: Slider.adaptive(
          value: 0,
          onChanged: (double newValue) {},
          thumbColor: color,
        ),
      ),
    );

    await tester.pumpWidget(sliderAdaptive);
    await tester.pumpAndSettle();

    final MaterialInkController material =
        Material.of(tester.element(find.byType(CupertinoSlider)))!;
    expect(
      material,
      paints..rrect()..rrect()..rrect()..rrect()..rrect()..rrect(color: color),
    );
  });
}
