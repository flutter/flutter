// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/physics/utils.dart' show nearEqual;
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Range Slider can move when tapped (continuous LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // No thumbs get select when tapping between the thumbs outside the touch
    // boundaries
    expect(values, equals(const RangeValues(0.3, 0.7)));
    //  taps at 0.5
    await tester.tap(find.byType(RangeSlider));
    await tester.pump();
    expect(values, equals(const RangeValues(0.3, 0.7)));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // The start thumb is selected when tapping the left inactive track.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.1;
    await tester.tapAt(leftTarget);
    expect(values.start, moreOrLessEquals(0.1, epsilon: 0.01));
    expect(values.end, equals(0.7));

    // The end thumb is selected when tapping the right inactive track.
    await tester.pump();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.9;
    await tester.tapAt(rightTarget);
    expect(values.start, moreOrLessEquals(0.1, epsilon: 0.01));
    expect(values.end, moreOrLessEquals(0.9, epsilon: 0.01));
  });

  testWidgets('Range Slider can move when tapped (continuous RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // No thumbs get select when tapping between the thumbs outside the touch
    // boundaries
    expect(values, equals(const RangeValues(0.3, 0.7)));
    // taps at 0.5
    await tester.tap(find.byType(RangeSlider));
    await tester.pump();
    expect(values, equals(const RangeValues(0.3, 0.7)));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // The end thumb is selected when tapping the left inactive track.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.1;
    await tester.tapAt(leftTarget);
    expect(values.start, 0.3);
    expect(values.end, moreOrLessEquals(0.9, epsilon: 0.01));

    // The start thumb is selected when tapping the right inactive track.
    await tester.pump();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.9;
    await tester.tapAt(rightTarget);
    expect(values.start, moreOrLessEquals(0.1, epsilon: 0.01));
    expect(values.end, moreOrLessEquals(0.9, epsilon: 0.01));
  });

  testWidgets('Range Slider can move when tapped (discrete LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100.0,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // No thumbs get select when tapping between the thumbs outside the touch
    // boundaries
    expect(values, equals(const RangeValues(30, 70)));
    // taps at 0.5
    await tester.tap(find.byType(RangeSlider));
    await tester.pumpAndSettle();
    expect(values, equals(const RangeValues(30, 70)));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // The start thumb is selected when tapping the left inactive track.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.1;
    await tester.tapAt(leftTarget);
    await tester.pumpAndSettle();
    expect(values.start.round(), equals(10));
    expect(values.end.round(), equals(70));

    // The end thumb is selected when tapping the right inactive track.
    await tester.pump();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.9;
    await tester.tapAt(rightTarget);
    await tester.pumpAndSettle();
    expect(values.start.round(), equals(10));
    expect(values.end.round(), equals(90));
  });

  testWidgets('Range Slider can move when tapped (discrete RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // No thumbs get select when tapping between the thumbs outside the touch
    // boundaries
    expect(values, equals(const RangeValues(30, 70)));
    // taps at 0.5
    await tester.tap(find.byType(RangeSlider));
    await tester.pumpAndSettle();
    expect(values, equals(const RangeValues(30, 70)));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // The start thumb is selected when tapping the left inactive track.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.1;
    await tester.tapAt(leftTarget);
    await tester.pumpAndSettle();
    expect(values.start.round(), equals(30));
    expect(values.end.round(), equals(90));

    // The end thumb is selected when tapping the right inactive track.
    await tester.pump();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.9;
    await tester.tapAt(rightTarget);
    await tester.pumpAndSettle();
    expect(values.start.round(), equals(10));
    expect(values.end.round(), equals(90));
  });

  testWidgets('Range Slider thumbs can be dragged to the min and max (continuous LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // Drag the start thumb to the min.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, topLeft + (bottomRight - topLeft) * -0.4);
    expect(values.start, equals(0));

    // Drag the end thumb to the max.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, topLeft + (bottomRight - topLeft) * 0.4);
    expect(values.end, equals(1));
  });

  testWidgets('Range Slider thumbs can be dragged to the min and max (continuous RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // Drag the end thumb to the max.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, topLeft + (bottomRight - topLeft) * -0.4);
    expect(values.end, equals(1));

    // Drag the start thumb to the min.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, topLeft + (bottomRight - topLeft) * 0.4);
    expect(values.start, equals(0));
  });

  testWidgets('Range Slider thumbs can be dragged to the min and max (discrete LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // Drag the start thumb to the min.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, topLeft + (bottomRight - topLeft) * -0.4);
    expect(values.start, equals(0));

    // Drag the end thumb to the max.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, topLeft + (bottomRight - topLeft) * 0.4);
    expect(values.end, equals(100));
  });

  testWidgets('Range Slider thumbs can be dragged to the min and max (discrete RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // Drag the end thumb to the max.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, topLeft + (bottomRight - topLeft) * -0.4);
    expect(values.end, equals(100));

    // Drag the start thumb to the min.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, topLeft + (bottomRight - topLeft) * 0.4);
    expect(values.start, equals(0));
  });

  testWidgets('Range Slider thumbs can be dragged together and the start thumb can be dragged apart (continuous LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the start thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.05));

    // Drag the end thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.05));

    // Drag the start thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
    expect(values.start, moreOrLessEquals(0.2, epsilon: 0.05));
  });

  testWidgets('Range Slider thumbs can be dragged together and the start thumb can be dragged apart (continuous RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the end thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.05));

    // Drag the start thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.05));

    // Drag the start thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
    expect(values.start, moreOrLessEquals(0.2, epsilon: 0.05));
  });

  testWidgets('Range Slider thumbs can be dragged together and the start thumb can be dragged apart (discrete LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the start thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.start, moreOrLessEquals(50, epsilon: 0.01));

    // Drag the end thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.end, moreOrLessEquals(50, epsilon: 0.01));

    // Drag the start thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
    expect(values.start, moreOrLessEquals(20, epsilon: 0.01));
  });

  testWidgets('Range Slider thumbs can be dragged together and the start thumb can be dragged apart (discrete RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the end thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.end, moreOrLessEquals(50, epsilon: 0.01));

    // Drag the start thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, moreOrLessEquals(50, epsilon: 0.01));

    // Drag the start thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
    expect(values.start, moreOrLessEquals(20, epsilon: 0.01));
  });

  testWidgets('Range Slider thumbs can be dragged together and the end thumb can be dragged apart (continuous LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the start thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.05));

    // Drag the end thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.05));

    // Drag the end thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
    expect(values.end, moreOrLessEquals(0.8, epsilon: 0.05));
  });

  testWidgets('Range Slider thumbs can be dragged together and the end thumb can be dragged apart (continuous RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the end thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.05));

    // Drag the start thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.05));

    // Drag the end thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
    expect(values.end, moreOrLessEquals(0.8, epsilon: 0.05));
  });

  testWidgets('Range Slider thumbs can be dragged together and the end thumb can be dragged apart (discrete LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the start thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.start, moreOrLessEquals(50, epsilon: 0.01));

    // Drag the end thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.end, moreOrLessEquals(50, epsilon: 0.01));

    // Drag the end thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
    expect(values.end, moreOrLessEquals(80, epsilon: 0.01));
  });

  testWidgets('Range Slider thumbs can be dragged together and the end thumb can be dragged apart (discrete RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the end thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.end, moreOrLessEquals(50, epsilon: 0.01));

    // Drag the start thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, moreOrLessEquals(50, epsilon: 0.01));

    // Drag the end thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
    expect(values.end, moreOrLessEquals(80, epsilon: 0.01));
  });

  testWidgets('Range Slider onChangeEnd and onChangeStart are called on an interaction initiated by tap', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);
    RangeValues? startValues;
    RangeValues? endValues;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                    onChangeStart: (RangeValues newValues) {
                      startValues = newValues;
                    },
                    onChangeEnd: (RangeValues newValues) {
                      endValues = newValues;
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // Drag the start thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    expect(startValues, null);
    expect(endValues, null);
    await tester.dragFrom(leftTarget, (bottomRight - topLeft) * 0.2);
    expect(startValues!.start, moreOrLessEquals(30, epsilon: 1));
    expect(startValues!.end, moreOrLessEquals(70, epsilon: 1));
    expect(values.start, moreOrLessEquals(50, epsilon: 1));
    expect(values.end, moreOrLessEquals(70, epsilon: 1));
    expect(endValues!.start, moreOrLessEquals(50, epsilon: 1));
    expect(endValues!.end, moreOrLessEquals(70, epsilon: 1));
  });

  testWidgets('Range Slider onChangeEnd and onChangeStart are called on an interaction initiated by drag', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);
    late RangeValues startValues;
    late RangeValues endValues;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                    onChangeStart: (RangeValues newValues) {
                      startValues = newValues;
                    },
                    onChangeEnd: (RangeValues newValues) {
                      endValues = newValues;
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // Drag the thumbs together.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, (bottomRight - topLeft) * 0.2);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, (bottomRight - topLeft) * -0.2);
    await tester.pumpAndSettle();
    expect(values.start, moreOrLessEquals(50, epsilon: 1));
    expect(values.end, moreOrLessEquals(51, epsilon: 1));

    // Drag the end thumb to the right.
    final Offset middleTarget = topLeft + (bottomRight - topLeft) * 0.5;
    await tester.dragFrom(middleTarget, (bottomRight - topLeft) * 0.4);
    await tester.pumpAndSettle();
    expect(startValues.start, moreOrLessEquals(50, epsilon: 1));
    expect(startValues.end, moreOrLessEquals(51, epsilon: 1));
    expect(endValues.start, moreOrLessEquals(50, epsilon: 1));
    expect(endValues.end, moreOrLessEquals(90, epsilon: 1));
  });

  ThemeData _buildTheme() {
    return ThemeData(
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
  }

  Widget _buildThemedApp({
    required ThemeData theme,
    Color? activeColor,
    Color? inactiveColor,
    int? divisions,
    bool enabled = true,
  }) {
    RangeValues values = const RangeValues(0.5, 0.75);
    final ValueChanged<RangeValues>? onChanged = !enabled ? null : (RangeValues newValues) {
      values = newValues;
    };
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: Theme(
              data: theme,
              child: RangeSlider(
                values: values,
                labels: RangeLabels(values.start.toStringAsFixed(2), values.end.toStringAsFixed(2)),
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

  testWidgets('Range Slider uses the right theme colors for the right shapes for a default enabled slider', (WidgetTester tester) async {
    final ThemeData theme = _buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(_buildThemedApp(theme: theme));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    // Check default theme for enabled widget.
    expect(
      sliderBox,
      paints
        ..rrect(color: sliderTheme.inactiveTrackColor)
        ..rect(color: sliderTheme.activeTrackColor)
        ..rrect(color: sliderTheme.inactiveTrackColor),
    );
    expect(
      sliderBox,
      paints
        ..circle(color: sliderTheme.thumbColor)
        ..circle(color: sliderTheme.thumbColor),
    );
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.activeTickMarkColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.inactiveTickMarkColor)));
  });

  testWidgets('Range Slider uses the right theme colors for the right shapes when setting the active color', (WidgetTester tester) async {
    const Color activeColor = Color(0xcafefeed);
    final ThemeData theme = _buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(_buildThemedApp(theme: theme, activeColor: activeColor));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    expect(
      sliderBox,
      paints
        ..rrect(color: sliderTheme.inactiveTrackColor)
        ..rect(color: activeColor)
        ..rrect(color: sliderTheme.inactiveTrackColor),
    );
    expect(
      sliderBox,
      paints
        ..circle(color: activeColor)
        ..circle(color: activeColor),
    );
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
  });

  testWidgets('Range Slider uses the right theme colors for the right shapes when setting the inactive color', (WidgetTester tester) async {
    const Color inactiveColor = Color(0xdeadbeef);
    final ThemeData theme = _buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(_buildThemedApp(theme: theme, inactiveColor: inactiveColor));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    expect(
      sliderBox,
      paints
        ..rrect(color: inactiveColor)
        ..rect(color: sliderTheme.activeTrackColor)
        ..rrect(color: inactiveColor),
    );
    expect(
      sliderBox,
      paints
        ..circle(color: sliderTheme.thumbColor)
        ..circle(color: sliderTheme.thumbColor),
    );
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
  });

  testWidgets('Range Slider uses the right theme colors for the right shapes with active and inactive colors', (WidgetTester tester) async {
    const Color activeColor = Color(0xcafefeed);
    const Color inactiveColor = Color(0xdeadbeef);
    final ThemeData theme = _buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(_buildThemedApp(
      theme: theme,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
    ));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    expect(
      sliderBox,
      paints
        ..rrect(color: inactiveColor)
        ..rect(color: activeColor)
        ..rrect(color: inactiveColor),
    );
    expect(
      sliderBox,
      paints
        ..circle(color: activeColor)
        ..circle(color: activeColor),
    );
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
  });

  testWidgets('Range Slider uses the right theme colors for the right shapes for a discrete slider', (WidgetTester tester) async {
    final ThemeData theme = _buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(_buildThemedApp(theme: theme, divisions: 3));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    expect(
      sliderBox,
      paints
        ..rrect(color: sliderTheme.inactiveTrackColor)
        ..rect(color: sliderTheme.activeTrackColor)
        ..rrect(color: sliderTheme.inactiveTrackColor),
    );
    expect(
      sliderBox,
      paints
        ..circle(color: sliderTheme.inactiveTickMarkColor)
        ..circle(color: sliderTheme.inactiveTickMarkColor)
        ..circle(color: sliderTheme.activeTickMarkColor)
        ..circle(color: sliderTheme.inactiveTickMarkColor)
        ..circle(color: sliderTheme.thumbColor)
        ..circle(color: sliderTheme.thumbColor),
    );
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
  });

  testWidgets('Range Slider uses the right theme colors for the right shapes for a discrete slider with active and inactive colors', (WidgetTester tester) async {
    const Color activeColor = Color(0xcafefeed);
    const Color inactiveColor = Color(0xdeadbeef);
    final ThemeData theme = _buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;


    await tester.pumpWidget(_buildThemedApp(
      theme: theme,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      divisions: 3,
    ));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    expect(
      sliderBox,
      paints
        ..rrect(color: inactiveColor)
        ..rect(color: activeColor)
        ..rrect(color: inactiveColor),
    );
    expect(
      sliderBox,
      paints
        ..circle(color: activeColor)
        ..circle(color: activeColor)
        ..circle(color: inactiveColor)
        ..circle(color: activeColor)
        ..circle(color: activeColor)
        ..circle(color: activeColor),
    );
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.activeTickMarkColor)));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.inactiveTickMarkColor)));
  });

  testWidgets('Range Slider uses the right theme colors for the right shapes for a default disabled slider', (WidgetTester tester) async {
    final ThemeData theme = _buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(_buildThemedApp(theme: theme, enabled: false));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    expect(
      sliderBox,
      paints
        ..rrect(color: sliderTheme.disabledInactiveTrackColor)
        ..rect(color: sliderTheme.disabledActiveTrackColor)
        ..rrect(color: sliderTheme.disabledInactiveTrackColor),
    );
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.activeTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.inactiveTrackColor)));
  });

  testWidgets('Range Slider uses the right theme colors for the right shapes for a disabled slider with active and inactive colors', (WidgetTester tester) async {
    const Color activeColor = Color(0xcafefeed);
    const Color inactiveColor = Color(0xdeadbeef);
    final ThemeData theme = _buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(_buildThemedApp(
      theme: theme,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      enabled: false,
    ));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    expect(
      sliderBox,
      paints
        ..rrect(color: sliderTheme.disabledInactiveTrackColor)
        ..rect(color: sliderTheme.disabledActiveTrackColor)
        ..rrect(color: sliderTheme.disabledInactiveTrackColor),
    );
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.activeTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.inactiveTrackColor)));
  });

  testWidgets('Range Slider uses the right theme colors for the right shapes when the value indicators are showing', (WidgetTester tester) async {
    final ThemeData theme = _buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;
    RangeValues values = const RangeValues(0.5, 0.75);

    Widget buildApp({
      Color? activeColor,
      Color? inactiveColor,
      int? divisions,
      bool enabled = true,
    }) {
      final ValueChanged<RangeValues>? onChanged = !enabled ? null : (RangeValues newValues) {
        values = newValues;
      };
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Theme(
                data: theme,
                child: RangeSlider(
                  values: values,
                  labels: RangeLabels(values.start.toStringAsFixed(2), values.end.toStringAsFixed(2)),
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

    await tester.pumpWidget(buildApp(divisions: 3));

    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

    final Offset topRight = tester.getTopRight(find.byType(RangeSlider)).translate(-24, 0);
    final TestGesture gesture = await tester.startGesture(topRight);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(values.end, equals(1));
    expect(
      valueIndicatorBox,
      paints
        ..path(color: sliderTheme.valueIndicatorColor)
        ..paragraph(),
    );
    await gesture.up();
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
  });

  testWidgets('Range Slider removes value indicator from overlay if Slider gets disposed without value indicator animation completing.', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.5, 0.75);
    const Color fillColor = Color(0xf55f5f5f);

    Widget buildApp({
      Color? activeColor,
      Color? inactiveColor,
      int? divisions,
      bool enabled = true,
    }) {
      void onChanged(RangeValues newValues) {
        values = newValues;
      }
      return MaterialApp(
        home: Scaffold(
          // The builder is used to pass the context from the MaterialApp widget
          // to the [Navigator]. This context is required in order for the
          // Navigator to work.
          body: Builder(
            builder: (BuildContext context) {
              return Column(
                children: <Widget>[
                  RangeSlider(
                    values: values,
                    labels: RangeLabels(
                      values.start.toStringAsFixed(2),
                      values.end.toStringAsFixed(2),
                    ),
                    divisions: divisions,
                    onChanged: onChanged,
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
    final Offset topRight = tester.getTopRight(find.byType(RangeSlider)).translate(-24, 0);
    final TestGesture gesture = await tester.startGesture(topRight);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();

    expect(
      valueIndicatorBox,
      paints
      // Represents the raised button wth next text.
      ..path(color: Colors.black)
      ..paragraph()
      // Represents the range slider.
      ..path(color: fillColor)
      ..paragraph()
      ..path(color: fillColor)
      ..paragraph(),
    );

    // Represents the Raised Button and Range Slider.
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 3));
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawParagraph, 3));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.byType(RangeSlider), findsNothing);
    expect(
      valueIndicatorBox,
      isNot(
       paints
         ..path(color: fillColor)
         ..paragraph()
         ..path(color: fillColor)
         ..paragraph(),
      ),
    );

    // Represents the raised button with inner page text.
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 1));
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawParagraph, 1));

    // Don't stop holding the value indicator.
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Range Slider top thumb gets stroked when overlapping', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
      sliderTheme: const SliderThemeData(
        thumbColor: Color(0xff000001),
        overlappingShapeStrokeColor: Color(0xff000002),
      ),
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: Theme(
                    data: theme,
                    child: RangeSlider(
                      values: values,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
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

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the thumbs towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.03));
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.03));
    await tester.pumpAndSettle();

    expect(
      sliderBox,
      paints
        ..circle(color: sliderTheme.thumbColor)
        ..circle(color: sliderTheme.overlappingShapeStrokeColor)
        ..circle(color: sliderTheme.thumbColor),
    );
  });

  testWidgets('Range Slider top value indicator gets stroked when overlapping', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
      sliderTheme: const SliderThemeData(
        valueIndicatorColor: Color(0xff000001),
        overlappingShapeStrokeColor: Color(0xff000002),
        showValueIndicator: ShowValueIndicator.always,
      ),
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: Theme(
                    data: theme,
                    child: RangeSlider(
                      values: values,
                      labels: RangeLabels(values.start.toStringAsFixed(2), values.end.toStringAsFixed(2)),
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
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

    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the thumbs towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    await tester.pumpAndSettle();
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.03));
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.03));
    final TestGesture gesture = await tester.startGesture(middle);
    await tester.pumpAndSettle();

    expect(
      valueIndicatorBox,
      paints
        ..path(color: sliderTheme.valueIndicatorColor)
        ..paragraph(),
    );

    await gesture.up();
  });

  testWidgets('Range Slider top value indicator gets stroked when overlapping with large text scale', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
      sliderTheme: const SliderThemeData(
        valueIndicatorColor: Color(0xff000001),
        overlappingShapeStrokeColor: Color(0xff000002),
        showValueIndicator: ShowValueIndicator.always,
      ),
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MediaQuery(
                data: MediaQueryData.fromWindow(window).copyWith(textScaleFactor: 2.0),
                child: Material(
                  child: Center(
                    child: Theme(
                      data: theme,
                      child: RangeSlider(
                        values: values,
                        labels: RangeLabels(values.start.toStringAsFixed(2), values.end.toStringAsFixed(2)),
                        onChanged: (RangeValues newValues) {
                          setState(() {
                            values = newValues;
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

    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the thumbs towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    await tester.pumpAndSettle();
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.03));
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.03));
    final TestGesture gesture = await tester.startGesture(middle);
    await tester.pumpAndSettle();

    expect(
      valueIndicatorBox,
      paints
        ..path(color: sliderTheme.valueIndicatorColor)
        ..paragraph(),
    );

    await gesture.up();
  });

  testWidgets('Range Slider thumb gets stroked when overlapping', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
      sliderTheme: const SliderThemeData(
        valueIndicatorColor: Color(0xff000001),
        showValueIndicator: ShowValueIndicator.onlyForContinuous,
      ),
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: Theme(
                    data: theme,
                    child: RangeSlider(
                      values: values,
                      labels: RangeLabels(values.start.toStringAsFixed(2), values.end.toStringAsFixed(2)),
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
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

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the thumbs towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    await tester.pumpAndSettle();
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.03));
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.03));
    final TestGesture gesture = await tester.startGesture(middle);
    await tester.pumpAndSettle();

    /// The first circle is the thumb, the second one is the overlapping shape
    /// circle, and the last one is the second thumb.
    expect(
      find.byType(RangeSlider),
      paints
        ..circle()
        ..circle(color: sliderTheme.overlappingShapeStrokeColor)
        ..circle(),
    );

    await gesture.up();

    expect(
      find.byType(RangeSlider),
      paints
        ..circle()
        ..circle(color: sliderTheme.overlappingShapeStrokeColor)
        ..circle(),
    );
  });

  testWidgets('Range Slider Semantics', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: ThemeData.light(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: RangeSlider(
                values: const RangeValues(10.0, 12.0),
                max: 100.0,
                onChanged: (RangeValues v) { },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(RangeSlider)),
      matchesSemantics(
        scopesRoute: true,
        children:<Matcher>[
          matchesSemantics(
            children:  <Matcher>[
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '10%',
                increasedValue: '10%',
                decreasedValue: '5%',
              ),
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '12%',
                increasedValue: '17%',
                decreasedValue: '12%',
              ),
            ],
          ),
        ],
      ),
    );
  });

  testWidgets('Range Slider implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    RangeSlider(
      activeColor: Colors.blue,
      divisions: 4,
      inactiveColor: Colors.grey,
      labels: const RangeLabels('lowerValue', 'upperValue'),
      max: 100.0,
      onChanged: null,
      values: const RangeValues(25.0, 75.0),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      'valueStart: 25.0',
      'valueEnd: 75.0',
      'disabled',
      'min: 0.0',
      'max: 100.0',
      'divisions: 4',
      'labelStart: "lowerValue"',
      'labelEnd: "upperValue"',
      'activeColor: MaterialColor(primary value: Color(0xff2196f3))',
      'inactiveColor: MaterialColor(primary value: Color(0xff9e9e9e))',
    ]);
  });

  testWidgets('Range Slider can be painted in a narrower constraint when track shape is RoundedRectRange', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: SizedBox(
                height: 10.0,
                width: 0.0,
                child: RangeSlider(
                  values: const RangeValues(0.25, 0.5),
                  onChanged: null,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // _RenderRangeSlider is the last render object in the tree.
    final RenderObject renderObject = tester.allRenderObjects.last;

    expect(
      renderObject,
      paints
        // left inactive track RRect
        ..rrect(rrect: RRect.fromLTRBAndCorners(-24.0, 3.0, -12.0, 7.0, topLeft: const Radius.circular(2.0), bottomLeft: const Radius.circular(2.0)))
        // active track RRect
        ..rect(rect: const Rect.fromLTRB(-12.0, 2.0, 0.0, 8.0))
        // right inactive track RRect
        ..rrect(rrect: RRect.fromLTRBAndCorners(0.0, 3.0, 24.0, 7.0, topRight: const Radius.circular(2.0), bottomRight: const Radius.circular(2.0)))
        // thumbs
        ..circle(x: -12.0, y: 5.0, radius: 10.0)
        ..circle(x: 0.0, y: 5.0, radius: 10.0),
    );
  });

  testWidgets('Range Slider can be painted in a narrower constraint when track shape is Rectangular', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          sliderTheme: const SliderThemeData(
            rangeTrackShape: RectangularRangeSliderTrackShape(),
          ),
        ),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: SizedBox(
                height: 10.0,
                width: 0.0,
                child: RangeSlider(
                  values: const RangeValues(0.25, 0.5),
                  onChanged: null,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // _RenderRangeSlider is the last render object in the tree.
    final RenderObject renderObject = tester.allRenderObjects.last;

    //There should no gap between the inactive track and active track.
    expect(
      renderObject,
      paints
        // left inactive track RRect
        ..rect(rect: const Rect.fromLTRB(-24.0, 3.0, -12.0, 7.0))
        // active track RRect
        ..rect(rect: const Rect.fromLTRB(-12.0, 3.0, 0.0, 7.0))
        // right inactive track RRect
        ..rect(rect: const Rect.fromLTRB(0.0, 3.0, 24.0, 7.0))
        // thumbs
        ..circle(x: -12.0, y: 5.0, radius: 10.0)
        ..circle(x: 0.0, y: 5.0, radius: 10.0),
    );
  });

  testWidgets('Update the divisions and values at the same time for RangeSlider', (WidgetTester tester) async {
    // Regress test for https://github.com/flutter/flutter/issues/65943
    Widget buildFrame(double maxValue) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: RangeSlider(
              values: const RangeValues(5, 8),
              max: maxValue,
              divisions: maxValue.toInt(),
              onChanged: (RangeValues newValue) {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(10));

    // _RenderRangeSlider is the last render object in the tree.
    final RenderObject renderObject = tester.allRenderObjects.last;

    // Update the divisions from 10 to 15, the thumbs should be paint at the correct position.
    await tester.pumpWidget(buildFrame(15));
    await tester.pumpAndSettle(); // Finish the animation.

    late Rect activeTrackRect;
    expect(renderObject, paints..something((Symbol method, List<dynamic> arguments) {
      if (method != #drawRect)
        return false;
      activeTrackRect = arguments[0] as Rect;
      return true;
    }));

    // The 1st thumb should at one-third(5 / 15) of the Slider.
    // The 2nd thumb should at (8 / 15) of the Slider.
    // The left of the active track shape is the position of the 1st thumb.
    // The right of the active track shape is the position of the 2nd thumb.
    // 24.0 is the default margin, (800.0 - 24.0 - 24.0) is the slider's width.
    expect(nearEqual(activeTrackRect.left, (800.0 - 24.0 - 24.0) * (5 / 15) + 24.0, 0.01), true);
    expect(nearEqual(activeTrackRect.right, (800.0 - 24.0 - 24.0) * (8 / 15) + 24.0, 0.01), true);
  });
}
