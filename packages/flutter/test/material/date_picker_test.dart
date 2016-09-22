// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tap-select a day', (WidgetTester tester) async {
    Key _datePickerKey = new UniqueKey();
    DateTime _selectedDate = new DateTime(2016, DateTime.JULY, 26);

    await tester.pumpWidget(
      new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) => new StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return new Positioned(
                  width: 400.0,
                  child: new Block(
                    children: <Widget>[
                      new Material(
                        child: new DatePicker(
                          firstDate: new DateTime(0),
                          lastDate: new DateTime(9999),
                          key: _datePickerKey,
                          selectedDate: _selectedDate,
                          onChanged: (DateTime value) {
                            setState(() {
                              _selectedDate = value;
                            });
                          }
                        )
                      )
                    ]
                  )
                );
              }
            )
          )
        ]
      )
    );

    await tester.tapAt(const Point(50.0, 200.0));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.JULY, 26)));
    await tester.pump(const Duration(seconds: 2));

    await tester.tapAt(const Point(300.0, 200.0));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.JULY, 1)));
    await tester.pump(const Duration(seconds: 2));

    await tester.tapAt(const Point(380.0, 120.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.JULY, 1)));

    await tester.tapAt(const Point(300.0, 200.0));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.AUGUST, 5)));
    await tester.pump(const Duration(seconds: 2));

    await tester.scroll(find.byKey(_datePickerKey), const Offset(-300.0, 0.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.AUGUST, 5)));

    await tester.tapAt(const Point(45.0, 370.0));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.SEPTEMBER, 25)));
    await tester.pump(const Duration(seconds: 2));

    await tester.scroll(find.byKey(_datePickerKey), const Offset(300.0, 10.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.SEPTEMBER, 25)));

    await tester.tapAt(const Point(210.0, 280.0));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.AUGUST, 17)));
    await tester.pump(const Duration(seconds: 2));

  });

  testWidgets('render picker with intrinsic dimensions', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) => new StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return new IntrinsicWidth(
                  child: new IntrinsicHeight(
                    child: new Material(
                      child: new Block(
                        children: <Widget>[
                          new DatePicker(
                            firstDate: new DateTime(0),
                            lastDate: new DateTime(9999),
                            onChanged: null,
                            selectedDate: new DateTime(2000, DateTime.JANUARY, 1)
                          )
                        ]
                      )
                    )
                  )
                );
              }
            )
          )
        ]
      )
    );
    await tester.pump(const Duration(seconds: 5));
  });

}
