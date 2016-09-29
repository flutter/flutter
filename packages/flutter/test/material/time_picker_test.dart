// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TimePickerLauncher extends StatelessWidget {
  _TimePickerLauncher({ Key key, this.onChanged }) : super(key: key);

  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Material(
        child: new Center(
          child: new Builder(
            builder: (BuildContext context) {
              return new RaisedButton(
                child: new Text('X'),
                onPressed: () async {
                  onChanged(await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 7, minute: 0)
                  ));
                }
              );
            }
          )
        )
      )
    );
  }
}

Future<Point> startPicker(WidgetTester tester, ValueChanged<TimeOfDay> onChanged) async {
  await tester.pumpWidget(new _TimePickerLauncher(onChanged: onChanged));
  await tester.tap(find.text('X'));

  await tester.pump(); // start animation
  await tester.pump(const Duration(seconds: 1));

  return tester.getCenter(find.byKey(new Key('time-picker-dial')));
}

Future<Null> finishPicker(WidgetTester tester) async {
  await tester.tap(find.text('OK'));

  await tester.pump(); // start animation
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('tap-select an hour', (WidgetTester tester) async {
    TimeOfDay result;

    Point center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(new Point(center.x, center.y - 50.0)); // 12:00 AM
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 0, minute: 0)));

    center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(new Point(center.x + 50.0, center.y));
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 3, minute: 0)));

    center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(new Point(center.x, center.y + 50.0));
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 6, minute: 0)));

    center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(new Point(center.x, center.y + 50.0));
    await tester.tapAt(new Point(center.x - 50, center.y));
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 9, minute: 0)));
  });

  testWidgets('drag-select an hour', (WidgetTester tester) async {
    TimeOfDay result;

    Point center = await startPicker(tester, (TimeOfDay time) { result = time; });
    Point hour0 = new Point(center.x, center.y - 50.0); // 12:00 AM
    Point hour3 = new Point(center.x + 50.0, center.y);
    Point hour6 = new Point(center.x, center.y + 50.0);
    Point hour9 = new Point(center.x - 50.0, center.y);

    TestGesture gesture;

    gesture = await tester.startGesture(hour3);
    await gesture.moveBy(hour0 - hour3);
    await gesture.up();
    await finishPicker(tester);
    expect(result.hour, 0);

    expect(await startPicker(tester, (TimeOfDay time) { result = time; }), equals(center));
    gesture = await tester.startGesture(hour0);
    await gesture.moveBy(hour3 - hour0);
    await gesture.up();
    await finishPicker(tester);
    expect(result.hour, 3);

    expect(await startPicker(tester, (TimeOfDay time) { result = time; }), equals(center));
    gesture = await tester.startGesture(hour3);
    await gesture.moveBy(hour6 - hour3);
    await gesture.up();
    await finishPicker(tester);
    expect(result.hour, equals(6));

    expect(await startPicker(tester, (TimeOfDay time) { result = time; }), equals(center));
    gesture = await tester.startGesture(hour6);
    await gesture.moveBy(hour9 - hour6);
    await gesture.up();
    await finishPicker(tester);
    expect(result.hour, equals(9));
  });
}
