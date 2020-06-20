// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

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

  group('TimeOfDay', () {
    test('assertions', () {
      expect(() => TimeOfDay(hour: null, minute: null), throwsAssertionError);
      expect(() => TimeOfDay(hour: null, minute: 0), throwsAssertionError);
      expect(() => TimeOfDay(hour: 0, minute: null), throwsAssertionError);
      expect(() => TimeOfDay(hour: -1, minute: -1), throwsAssertionError);
      expect(() => TimeOfDay(hour: 0, minute: -1), throwsAssertionError);
      expect(() => TimeOfDay(hour: -1, minute: 0), throwsAssertionError);
      expect(() => TimeOfDay(hour: 24, minute: 0), throwsAssertionError);
      expect(() => TimeOfDay(hour: 0, minute: 60), throwsAssertionError);
    });

    test('.==', () {
      expect(const TimeOfDay(hour: 0 , minute: 0)
          == (const TimeOfDay(hour: 0 , minute: 0)), true);
    });

    test('.replacing', () {
      expect(
        const TimeOfDay(hour: 23 , minute: 59).replacing(hour: 0),
        const TimeOfDay(hour: 0 , minute: 59),
      );
      expect(
        const TimeOfDay(hour: 23 , minute: 59).replacing(minute: 0),
        const TimeOfDay(hour: 23 , minute: 0),
      );
    });

    test('.compareTo', () {
      expect(
          <TimeOfDay>[
            const TimeOfDay(hour: 12 , minute: 0),
            const TimeOfDay(hour: 23 , minute: 59),
            const TimeOfDay(hour: 0 , minute: 0),
          ]..sort(),
          <TimeOfDay>[
            const TimeOfDay(hour: 0 , minute: 0),
            const TimeOfDay(hour: 12 , minute: 0),
            const TimeOfDay(hour: 23 , minute: 59),
          ]
      );

      expect(const TimeOfDay(hour: 0 , minute: 0).compareTo(null) > 0, true);

      const TimeOfDay zero = TimeOfDay(hour: 0 , minute: 0);
      expect(zero.compareTo(zero), 0);

      expect(const TimeOfDay(hour: 0 , minute: 0)
          .compareTo(const TimeOfDay(hour: 0 , minute: 0)), 0);

      expect(
          <TimeOfDay>[
            const TimeOfDay(hour: 0 , minute: 0),
            const TimeOfDay(hour: 23 , minute: 59),
            const TimeOfDay(hour: 12 , minute: 0),
          ]..sort(),
          <TimeOfDay>[
            const TimeOfDay(hour: 0 , minute: 0),
            const TimeOfDay(hour: 12 , minute: 0),
            const TimeOfDay(hour: 23 , minute: 59),
          ]
      );
    });
  });
}
