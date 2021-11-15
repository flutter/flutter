// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/cupertino/date_picker/cupertino_timer_picker.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

const Offset _kRowOffset = Offset(0.0, -50.0);

void main() {
  testWidgets('Can pick a duration from CupertinoTimerPicker', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    // Open the timer picker.
    await tester.tap(find.text('1:23:42.000000'));
    await tester.pumpAndSettle();

    // Drag all three date wheels.
    await tester.drag(find.text('1'), _kRowOffset, touchSlopY: 0, warnIfMissed: false); // see top of file
    await tester.drag(find.text('23'), _kRowOffset, touchSlopY: 0, warnIfMissed: false); // see top of file
    await tester.drag(find.text('42'), _kRowOffset, touchSlopY: 0, warnIfMissed: false); // see top of file

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    //Close the date picker.
    await tester.tapAt(const Offset(1.0, 1.0));
    await tester.pumpAndSettle();

    expect(find.text('3:25:44.000000'), findsOneWidget);
  });
}
