// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeOfDay.format', () {
    testWidgets('respects alwaysUse24HourFormat option', (WidgetTester tester) async {
      Future<String> pumpTest(bool alwaysUse24HourFormat) async {
        String formattedValue;
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(alwaysUse24HourFormat: alwaysUse24HourFormat),
            child: Builder(builder: (BuildContext context) {
              formattedValue = const TimeOfDay(hour: 7, minute: 0).format(context);
              return Container();
            }),
          ),
        ));
        return formattedValue;
      }

      expect(await pumpTest(false), '7:00 AM');
      expect(await pumpTest(true), '07:00');
    });
  });
}
