// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tap-select an hour', (WidgetTester tester) async {
    Key _timePickerKey = new UniqueKey();
    TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Material(
            child: new Center(
                child: new SizedBox(
                width: 200.0,
                height: 400.0,
                child: new TimePicker(
                  key: _timePickerKey,
                  selectedTime: _selectedTime,
                  onChanged: (TimeOfDay value) {
                    setState(() {
                      _selectedTime = value;
                    });
                  }
                )
              )
            )
          );
        }
      )
    );

    Point center = tester.getCenter(find.byKey(_timePickerKey));

    Point hour0 = new Point(center.x, center.y - 50.0); // 12:00 AM
    await tester.tapAt(hour0);
    expect(_selectedTime.hour, equals(0));

    Point hour3 = new Point(center.x + 50.0, center.y);
    await tester.tapAt(hour3);
    expect(_selectedTime.hour, equals(3));

    Point hour6 = new Point(center.x, center.y + 50.0);
    await tester.tapAt(hour6);
    expect(_selectedTime.hour, equals(6));

    Point hour9 = new Point(center.x - 50.0, center.y);
    await tester.tapAt(hour9);
    expect(_selectedTime.hour, equals(9));

    await tester.pump(const Duration(seconds: 1)); // Finish gesture animation.
    await tester.pump(const Duration(seconds: 1)); // Finish settling animation.
  });

  testWidgets('drag-select an hour', (WidgetTester tester) async {
    Key _timePickerKey = new UniqueKey();
    TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Material(
            child: new Center(
                child: new SizedBox(
                width: 200.0,
                height: 400.0,
                child: new TimePicker(
                  key: _timePickerKey,
                  selectedTime: _selectedTime,
                  onChanged: (TimeOfDay value) {
                    setState(() {
                      _selectedTime = value;
                    });
                  }
                )
              )
            )
          );
        }
      )
    );

    Point center = tester.getCenter(find.byKey(_timePickerKey));
    Point hour0 = new Point(center.x, center.y - 50.0); // 12:00 AM
    Point hour3 = new Point(center.x + 50.0, center.y);
    Point hour6 = new Point(center.x, center.y + 50.0);
    Point hour9 = new Point(center.x - 50.0, center.y);

    TestGesture gesture;

    gesture = await tester.startGesture(hour3);
    await gesture.moveBy(hour0 - hour3);
    await gesture.up();
    expect(_selectedTime.hour, equals(0));
    await tester.pump(const Duration(seconds: 1)); // Finish gesture animation.
    await tester.pump(const Duration(seconds: 1)); // Finish settling animation.

    gesture = await tester.startGesture(hour0);
    await gesture.moveBy(hour3 - hour0);
    await gesture.up();
    expect(_selectedTime.hour, equals(3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    gesture = await tester.startGesture(hour3);
    await gesture.moveBy(hour6 - hour3);
    await gesture.up();
    expect(_selectedTime.hour, equals(6));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    gesture = await tester.startGesture(hour6);
    await gesture.moveBy(hour9 - hour6);
    await gesture.up();
    expect(_selectedTime.hour, equals(9));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });
}
