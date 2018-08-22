// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('English translations exist for all CupertinoLocalization properties', (WidgetTester tester) async {
    const CupertinoLocalizations localizations = DefaultCupertinoLocalizations();

    for (int i = 0; i < 10; i++)
      expect(localizations.number(i), isNotNull);

    for (int i = 1; i <= 12; i++)
      expect(localizations.datePickerMonth(i), isNotNull);

    for (int i = 1; i <= 31; i++)
      expect(localizations.datePickerDayOfMonth(i), isNotNull);

    for (int i= 2000; i <= 2050; i++)
      expect(localizations.datePickerYear(i), isNotNull);

    expect(localizations.datePickerMediumDate(DateTime.now()), isNotNull);
    expect(localizations.datePickerDateOrder, isNotNull);
    expect(localizations.anteMeridiemAbbreviation, isNotNull);
    expect(localizations.postMeridiemAbbreviation, isNotNull);
    expect(localizations.timerPickerHourLabel(0), isNotNull);
    expect(localizations.timerPickerMinuteLabel(0), isNotNull);
    expect(localizations.timerPickerSecondLabel(0), isNotNull);
  });
}
