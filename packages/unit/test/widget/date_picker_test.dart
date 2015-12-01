// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  test('Can select a day', () {
    testWidgets((WidgetTester tester) {
      DateTime currentValue;

      Widget widget = new Material(
        child: new Block(<Widget>[
          new DatePicker(
            selectedDate: new DateTime.utc(2015, 6, 9, 7, 12),
            firstDate: new DateTime.utc(2013),
            lastDate: new DateTime.utc(2018),
            onChanged: (DateTime dateTime) {
              currentValue = dateTime;
            }
          )
        ])
      );

      tester.pumpWidget(widget);

      expect(currentValue, isNull);
      tester.tap(tester.findText('2015'));
      tester.pumpWidget(widget);
      tester.tap(tester.findText('2014'));
      tester.pumpWidget(widget);
      expect(currentValue, equals(new DateTime(2014, 6, 9)));
      tester.tap(tester.findText('30'));
      expect(currentValue, equals(new DateTime(2013, 1, 30)));
    });
  });
}
