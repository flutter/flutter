// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Range Slider can move when tapped (continuous LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
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
              ),
            );
          },
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

    // The start thumb is selected when tapping the left inactive track.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.1;
    await tester.tapAt(leftTarget);
    expect(values.start, closeTo(0.1, 0.01));
    expect(values.end, equals(0.7));

    // The end thumb is selected when tapping the right inactive track.
    await tester.pump();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.9;
    await tester.tapAt(rightTarget);
    expect(values.start, closeTo(0.1, 0.01));
    expect(values.end, closeTo(0.9, 0.01));
  });

  testWidgets('Range Slider can move when tapped (continuous RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
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
              ),
            );
          },
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
    expect(values.end, closeTo(0.9, 0.01));

    // The start thumb is selected when tapping the right inactive track.
    await tester.pump();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.9;
    await tester.tapAt(rightTarget);
    expect(values.start, closeTo(0.1, 0.01));
    expect(values.end, closeTo(0.9, 0.01));
  });

  testWidgets('Range Slider can move when tapped (discrete LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    min: 0.0,
                    max: 100.0,
                    divisions: 10,
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
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    min: 0,
                    max: 100,
                    divisions: 10,
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

  testWidgets('Range Slider thumbs can be dragged to the min and max (continous LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
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
              ),
            );
          },
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

  testWidgets('Range Slider thumbs can be dragged to the min and max (continous RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
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
              ),
            );
          },
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    min: 0,
                    max: 100,
                    divisions: 10,
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
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    min: 0,
                    max: 100,
                    divisions: 10,
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

  testWidgets('Range Slider thumbs can be dragged together and the start thumb can be dragged apart (continous LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
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
              ),
            );
          },
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
    expect(values.start, closeTo(0.5, 0.05));

    // Drag the end thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.end, closeTo(0.5, 0.05));

    // Drag the start thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
    expect(values.start, closeTo(0.2, 0.05));
  });

  testWidgets('Range Slider thumbs can be dragged together and the start thumb can be dragged apart (continous RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
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
              ),
            );
          },
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
    expect(values.end, closeTo(0.5, 0.05));

    // Drag the start thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, closeTo(0.5, 0.05));

    // Drag the start thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
    expect(values.start, closeTo(0.2, 0.05));
  });

  testWidgets('Range Slider thumbs can be dragged together and the start thumb can be dragged apart (discrete LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    min: 0,
                    max: 100,
                    divisions: 10,
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
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the start thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.start, closeTo(50, 0.01));

    // Drag the end thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.end, closeTo(50, 0.01));

    // Drag the start thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
    expect(values.start, closeTo(20, 0.01));
  });

  testWidgets('Range Slider thumbs can be dragged together and the start thumb can be dragged apart (discrete RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    min: 0,
                    max: 100,
                    divisions: 10,
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
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the end thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.end, closeTo(50, 0.01));

    // Drag the start thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, closeTo(50, 0.01));

    // Drag the start thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
    expect(values.start, closeTo(20, 0.01));
  });

  testWidgets('Range Slider thumbs can be dragged together and the end thumb can be dragged apart (continous LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
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
              ),
            );
          },
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
    expect(values.start, closeTo(0.5, 0.05));

    // Drag the end thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.end, closeTo(0.5, 0.05));

    // Drag the end thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
    expect(values.end, closeTo(0.8, 0.05));
  });

  testWidgets('Range Slider thumbs can be dragged together and the end thumb can be dragged apart (continous RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
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
              ),
            );
          },
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
    expect(values.end, closeTo(0.5, 0.05));

    // Drag the start thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, closeTo(0.5, 0.05));

    // Drag the end thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
    expect(values.end, closeTo(0.8, 0.05));
  });

  testWidgets('Range Slider thumbs can be dragged together and the end thumb can be dragged apart (discrete LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    min: 0,
                    max: 100,
                    divisions: 10,
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
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the start thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.start, closeTo(50, 0.01));

    // Drag the end thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.end, closeTo(50, 0.01));

    // Drag the end thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
    expect(values.end, closeTo(80, 0.01));
  });

  testWidgets('Range Slider thumbs can be dragged together and the end thumb can be dragged apart (discrete RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    min: 0,
                    max: 100,
                    divisions: 10,
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
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the end thumb towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    expect(values.end, closeTo(50, 0.01));

    // Drag the start thumb towards the center.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, closeTo(50, 0.01));

    // Drag the end thumb apart.
    await tester.pumpAndSettle();
    await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
    expect(values.end, closeTo(80, 0.01));
  });

  testWidgets('Range Slider onChangeEnd and onChangeStart are called on an interaction initiated by tap', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);
    RangeValues startValues;
    RangeValues endValues;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    min: 0,
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
              ),
            );
          },
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
    expect(startValues.start, closeTo(30, 1));
    expect(startValues.end, closeTo(70, 1));
    expect(values.start, closeTo(50, 1));
    expect(values.end, closeTo(70, 1));
    expect(endValues.start, closeTo(50, 1));
    expect(endValues.end, closeTo(70, 1));
  });

  testWidgets('Range Slider onChangeEnd and onChangeStart are called on an interaction initiated by drag', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);
    RangeValues startValues;
    RangeValues endValues;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    min: 0,
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
              ),
            );
          },
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
    expect(values.start, closeTo(50, 1));
    expect(values.end, closeTo(51, 1));

    // Drag the end thumb to the right.
    final Offset middleTarget = topLeft + (bottomRight - topLeft) * 0.5;
    await tester.dragFrom(middleTarget, (bottomRight - topLeft) * 0.4);
    await tester.pumpAndSettle();
    expect(startValues.start, closeTo(50, 1));
    expect(startValues.end, closeTo(51, 1));
    expect(endValues.start, closeTo(50, 1));
    expect(endValues.end, closeTo(90, 1));
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
        )
    );
  }

  Widget _buildThemedApp({
    ThemeData theme,
    Color activeColor,
    Color inactiveColor,
    int divisions,
    bool enabled = true,
  }) {
    RangeValues values = const RangeValues(0.5, 0.75);
    final ValueChanged<RangeValues> onChanged = !enabled ? null : (RangeValues newValues) {
      values = newValues;
    };
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
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
    expect(sliderBox, paints
      ..rect(color: sliderTheme.inactiveTrackColor)
      ..rect(color: sliderTheme.activeTrackColor)
      ..rect(color: sliderTheme.inactiveTrackColor));
    expect(sliderBox, paints
      ..circle(color: sliderTheme.thumbColor)
      ..circle(color: sliderTheme.thumbColor));
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
          ..rect(color: sliderTheme.inactiveTrackColor)
          ..rect(color: activeColor)
          ..rect(color: sliderTheme.inactiveTrackColor));
    expect(
        sliderBox,
        paints
          ..circle(color: activeColor)
          ..circle(color: activeColor));
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
          ..rect(color: inactiveColor)
          ..rect(color: sliderTheme.activeTrackColor)
          ..rect(color: inactiveColor));
    expect(
        sliderBox,
        paints
          ..circle(color: sliderTheme.thumbColor)
          ..circle(color: sliderTheme.thumbColor));
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
          ..rect(color: inactiveColor)
          ..rect(color: activeColor)
          ..rect(color: inactiveColor));
    expect(
        sliderBox,
        paints
          ..circle(color: activeColor)
          ..circle(color: activeColor));
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
          ..rect(color: sliderTheme.inactiveTrackColor)
          ..rect(color: sliderTheme.activeTrackColor)
          ..rect(color: sliderTheme.inactiveTrackColor));
    expect(
        sliderBox,
        paints
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.activeTickMarkColor)
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.thumbColor)
          ..circle(color: sliderTheme.thumbColor));
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
          ..rect(color: inactiveColor)
          ..rect(color: activeColor)
          ..rect(color: inactiveColor));
    expect(
        sliderBox,
        paints
          ..circle(color: activeColor)
          ..circle(color: activeColor)
          ..circle(color: inactiveColor)
          ..circle(color: activeColor)
          ..circle(color: activeColor)
          ..circle(color: activeColor));
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
          ..rect(color: sliderTheme.disabledInactiveTrackColor)
          ..rect(color: sliderTheme.disabledActiveTrackColor)
          ..rect(color: sliderTheme.disabledInactiveTrackColor));
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
          ..rect(color: sliderTheme.disabledInactiveTrackColor)
          ..rect(color: sliderTheme.disabledActiveTrackColor)
          ..rect(color: sliderTheme.disabledInactiveTrackColor));
    expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.activeTrackColor)));
    expect(sliderBox, isNot(paints..rect(color: sliderTheme.inactiveTrackColor)));
  });

  testWidgets('Range Slider uses the right theme colors for the right shapes when the value indicators are showing', (WidgetTester tester) async {
    const Color customColor1 = Color(0xcafefeed);
    const Color customColor2 = Color(0xdeadbeef);
    final ThemeData theme = _buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;
    RangeValues values = const RangeValues(0.5, 0.75);

    Widget buildApp({
      Color activeColor,
      Color inactiveColor,
      int divisions,
      bool enabled = true,
    }) {
      final ValueChanged<RangeValues> onChanged = !enabled ? null : (RangeValues newValues) {
        values = newValues;
      };
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window),
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

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    final Offset topRight = tester.getTopRight(find.byType(RangeSlider)).translate(-24, 0);
    TestGesture gesture = await tester.startGesture(topRight);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(values.end, equals(1));
    expect(
      sliderBox,
      paints
        ..path(color: sliderTheme.valueIndicatorColor)
        ..path(color: sliderTheme.valueIndicatorColor)
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
    gesture = await tester.startGesture(topRight);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(values.end, equals(1));
    expect(
      sliderBox,
      paints
        ..path(color: customColor1)
        ..path(color: customColor1)
    );
    await gesture.up();
  });

  testWidgets('Range Slider top thumb gets stroked when overlapping', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    final ThemeData theme = ThemeData(
        platform: TargetPlatform.android,
        primarySwatch: Colors.blue,
        sliderTheme: const SliderThemeData(
          thumbColor: Color(0xff000001),
          overlappingShapeStrokeColor: Color(0xff000002)
        )
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
              child: Material(
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
              ),
            );
          },
        ),
      ),
    );

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the the thumbs towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, closeTo(0.5, 0.03));
    expect(values.end, closeTo(0.5, 0.03));
    await tester.pumpAndSettle();

    expect(
      sliderBox,
      paints
        ..circle(color: sliderTheme.thumbColor)
        ..circle(color: sliderTheme.overlappingShapeStrokeColor)
        ..circle(color: sliderTheme.thumbColor)
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
        )
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MediaQuery(
              data: MediaQueryData.fromWindow(window),
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
    );

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the the thumbs towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    await tester.pumpAndSettle();
    expect(values.start, closeTo(0.5, 0.03));
    expect(values.end, closeTo(0.5, 0.03));
    final TestGesture gesture = await tester.startGesture(middle);
    await tester.pumpAndSettle();

    expect(
        sliderBox,
        paints
          ..path(color: sliderTheme.valueIndicatorColor)
          ..path(color: sliderTheme.overlappingShapeStrokeColor)
          ..path(color: sliderTheme.valueIndicatorColor)
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
        )
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(
      Directionality(
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
    );

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the the thumbs towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    await tester.pumpAndSettle();
    expect(values.start, closeTo(0.5, 0.03));
    expect(values.end, closeTo(0.5, 0.03));
    final TestGesture gesture = await tester.startGesture(middle);
    await tester.pumpAndSettle();

    expect(
      sliderBox,
      paints
        ..path(color: sliderTheme.valueIndicatorColor)
        ..path(color: sliderTheme.overlappingShapeStrokeColor)
        ..path(color: sliderTheme.valueIndicatorColor),
    );

    await gesture.up();
  });
}

