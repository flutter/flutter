// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart' as intl;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime firstDate;
  DateTime lastDate;
  DateTime initialDate;

  setUp(() {
    firstDate = new DateTime(2001, DateTime.january, 1);
    lastDate = new DateTime(2031, DateTime.december, 31);
    initialDate = new DateTime(2016, DateTime.january, 15);
  });

  group(DayPicker, () {
    final intl.NumberFormat arabicNumbers = new intl.NumberFormat('0', 'ar');
    final Map<Locale, Map<String, dynamic>> testLocales = <Locale, Map<String, dynamic>>{
      // Tests the default.
      const Locale('en', 'US'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'],
        'expectedDaysOfMonth': new List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'September 2017',
      },
      // Tests a different first day of week.
      const Locale('ru', 'RU'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'],
        'expectedDaysOfMonth': new List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'сентябрь 2017 г.',
      },
      const Locale('ro', 'RO'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['D', 'L', 'M', 'M', 'J', 'V', 'S'],
        'expectedDaysOfMonth': new List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'septembrie 2017',
      },
      // Tests RTL.
      const Locale('ar', 'AR'): <String, dynamic>{
        'textDirection': TextDirection.rtl,
        'expectedDaysOfWeek': <String>['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'],
        'expectedDaysOfMonth': new List<String>.generate(30, (int i) => '${arabicNumbers.format(i + 1)}'),
        'expectedMonthYearHeader': 'سبتمبر ٢٠١٧',
      },
    };

    for (Locale locale in testLocales.keys) {
      testWidgets('shows dates for $locale', (WidgetTester tester) async {
        final List<String> expectedDaysOfWeek = testLocales[locale]['expectedDaysOfWeek'];
        final List<String> expectedDaysOfMonth = testLocales[locale]['expectedDaysOfMonth'];
        final String expectedMonthYearHeader = testLocales[locale]['expectedMonthYearHeader'];
        final TextDirection textDirection = testLocales[locale]['textDirection'];
        final DateTime baseDate = new DateTime(2017, 9, 27);

        await _pumpBoilerplate(tester, new DayPicker(
          selectedDate: baseDate,
          currentDate: baseDate,
          onChanged: (DateTime newValue) {},
          firstDate: baseDate.subtract(const Duration(days: 90)),
          lastDate: baseDate.add(const Duration(days: 90)),
          displayedMonth: baseDate,
        ), locale: locale, textDirection: textDirection);

        expect(find.text(expectedMonthYearHeader), findsOneWidget);

        for (String dayOfWeek in expectedDaysOfWeek) {
          expect(find.text(dayOfWeek), findsWidgets);
        }

        Offset previousCellOffset;
        for (String dayOfMonth in expectedDaysOfMonth) {
          final Finder dayCell = find.descendant(of: find.byType(GridView), matching: find.text(dayOfMonth));
          expect(dayCell, findsOneWidget);

          // Check that cells are correctly positioned relative to each other,
          // taking text direction into account.
          final Offset offset = tester.getCenter(dayCell);
          if (previousCellOffset != null) {
            if (textDirection == TextDirection.ltr) {
              expect(offset.dx > previousCellOffset.dx && offset.dy == previousCellOffset.dy || offset.dy > previousCellOffset.dy, true);
            } else {
              expect(offset.dx < previousCellOffset.dx && offset.dy == previousCellOffset.dy || offset.dy > previousCellOffset.dy, true);
            }
          }
          previousCellOffset = offset;
        }
      });
    }
  });

  testWidgets('locale parameter overrides ambient locale', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      locale: const Locale('en', 'US'),
      supportedLocales: const <Locale>[
        const Locale('en', 'US'),
        const Locale('fr', 'CA'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: new Material(
        child: new Builder(
          builder: (BuildContext context) {
            return new FlatButton(
              onPressed: () async {
                await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  locale: const Locale('fr', 'CA'),
                );
              },
              child: const Text('X'),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final Element dayPicker = tester.element(find.byType(DayPicker));
    expect(
      Localizations.localeOf(dayPicker),
      const Locale('fr', 'CA'),
    );

    expect(
      Directionality.of(dayPicker),
      TextDirection.ltr,
    );

    await tester.tap(find.text('ANNULER'));
  });

  testWidgets('textDirection parameter overrides ambient textDirection', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      locale: const Locale('en', 'US'),
      supportedLocales: const <Locale>[
        const Locale('en', 'US'),
      ],
      home: new Material(
        child: new Builder(
          builder: (BuildContext context) {
            return new FlatButton(
              onPressed: () async {
                await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  textDirection: TextDirection.rtl,
                );
              },
              child: const Text('X'),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final Element dayPicker = tester.element(find.byType(DayPicker));
    expect(
      Directionality.of(dayPicker),
      TextDirection.rtl,
    );

    await tester.tap(find.text('CANCEL'));
  });

  testWidgets('textDirection parameter takes precedence over locale parameter', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      locale: const Locale('en', 'US'),
      supportedLocales: const <Locale>[
        const Locale('en', 'US'),
        const Locale('fr', 'CA'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: new Material(
        child: new Builder(
          builder: (BuildContext context) {
            return new FlatButton(
              onPressed: () async {
                await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  locale: const Locale('fr', 'CA'),
                  textDirection: TextDirection.rtl,
                );
              },
              child: const Text('X'),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final Element dayPicker = tester.element(find.byType(DayPicker));
    expect(
      Localizations.localeOf(dayPicker),
      const Locale('fr', 'CA'),
    );

    expect(
      Directionality.of(dayPicker),
      TextDirection.rtl,
    );

    await tester.tap(find.text('ANNULER'));
  });
}

Future<Null> _pumpBoilerplate(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en', 'US'),
  TextDirection textDirection: TextDirection.ltr
}) async {
  await tester.pumpWidget(new Directionality(
    textDirection: TextDirection.ltr,
    child: new Localizations(
      locale: locale,
      delegates: GlobalMaterialLocalizations.delegates,
      child: child,
    ),
  ));
}
