// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

void main() {
  test('tap-select an hour', () {
    testWidgets((WidgetTester tester) {
      Key _timePickerKey = new UniqueKey();
      TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);

      tester.pumpWidget(
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
      tester.tapAt(hour0);
      expect(_selectedTime.hour, equals(0));

      Point hour3 = new Point(center.x + 50.0, center.y);
      tester.tapAt(hour3);
      expect(_selectedTime.hour, equals(3));

      Point hour6 = new Point(center.x, center.y + 50.0);
      tester.tapAt(hour6);
      expect(_selectedTime.hour, equals(6));

      Point hour9 = new Point(center.x - 50.0, center.y);
      tester.tapAt(hour9);
      expect(_selectedTime.hour, equals(9));

      tester.pump(const Duration(seconds: 1)); // Finish gesture animation.
      tester.pump(const Duration(seconds: 1)); // Finish settling animation.
    });
  });

  test('drag-select an hour', () {
    testWidgets((WidgetTester tester) {
      Key _timePickerKey = new UniqueKey();
      TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);

      tester.pumpWidget(
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

      tester.startGesture(hour3)
        ..moveBy(hour0 - hour3)
        ..up();
      expect(_selectedTime.hour, equals(0));
      tester.pump(const Duration(seconds: 1)); // Finish gesture animation.
      tester.pump(const Duration(seconds: 1)); // Finish settling animation.

      tester.startGesture(hour0)
        ..moveBy(hour3 - hour0)
        ..up();
      expect(_selectedTime.hour, equals(3));
      tester.pump(const Duration(seconds: 1));
      tester.pump(const Duration(seconds: 1));

      tester.startGesture(hour3)
        ..moveBy(hour6 - hour3)
        ..up();
      expect(_selectedTime.hour, equals(6));
      tester.pump(const Duration(seconds: 1));
      tester.pump(const Duration(seconds: 1));

      tester.startGesture(hour6)
        ..moveBy(hour9 - hour6)
        ..up();
      expect(_selectedTime.hour, equals(9));
      tester.pump(const Duration(seconds: 1));
      tester.pump(const Duration(seconds: 1));
    });
  });
}
