// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Can select a day', (WidgetTester tester) async {
    DateTime currentValue;

    final Widget widget = new Directionality(
      textDirection: TextDirection.ltr,
      child: new Material(
        child: new ListView(
          children: <Widget>[
            new MonthPicker(
              selectedDate: new DateTime.utc(2015, 6, 9, 7, 12),
              firstDate: new DateTime.utc(2013),
              lastDate: new DateTime.utc(2018),
              onChanged: (DateTime dateTime) {
                currentValue = dateTime;
              },
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(widget);

    expect(currentValue, isNull);
    await tester.tap(find.text('2015'));
    await tester.pumpWidget(widget);
    await tester.tap(find.text('2014'));
    await tester.pumpWidget(widget);
    expect(currentValue, equals(new DateTime(2014, 6, 9)));
    await tester.tap(find.text('30'));
    expect(currentValue, equals(new DateTime(2013, 1, 30)));
  }, skip: true);
}
