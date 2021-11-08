// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;

void main() {
  group(CupertinoCalendarPicker, () {
    final intl.NumberFormat arabicNumbers = intl.NumberFormat('0', 'ar');
    final Map<Locale, Map<String, dynamic>> testLocales = <Locale, Map<String, dynamic>>{
      // Tests the default.
      const Locale('en', 'US'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
        'expectedDaysOfMonth': List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'September 2017',
      },
      // Tests a different first day of week.
      const Locale('ru', 'RU'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'],
        'expectedDaysOfMonth': List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'сентябрь 2017 г.',
      },
      const Locale('ro', 'RO'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['DUM.', 'LUN.', 'MAR.', 'MIE.', 'JOI', 'VIN.', 'SÂM.'],
        'expectedDaysOfMonth': List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'septembrie 2017',
      },
      // // Tests RTL.
      const Locale('ar', 'AR'): <String, dynamic>{
        'textDirection': TextDirection.rtl,
        'expectedDaysOfWeek': <String>['الجمعة', 'الخميس', 'الأربعاء', 'الثلاثاء', 'الاثنين', 'الأحد', 'السبت'],
        'expectedDaysOfMonth': List<String>.generate(30, (int i) => arabicNumbers.format(i + 1)),
        'expectedMonthYearHeader': 'سبتمبر ٢٠١٧',
      },
    };

    for (final Locale locale in testLocales.keys) {
      testWidgets('shows dates for $locale', (WidgetTester tester) async {
        final List<String> expectedDaysOfWeek = testLocales[locale]!['expectedDaysOfWeek'] as List<String>;
        final List<String> expectedDaysOfMonth = testLocales[locale]!['expectedDaysOfMonth'] as List<String>;
        final String expectedMonthYearHeader = testLocales[locale]!['expectedMonthYearHeader'] as String;
        final TextDirection textDirection = testLocales[locale]!['textDirection'] as TextDirection;
        final DateTime baseDate = DateTime(2017, 9, 27);

        await _pumpBoilerplate(tester, CupertinoCalendarPicker(
          initialDate: baseDate,
          onDateChanged: (DateTime newValue) {},
        ), locale: locale, textDirection: textDirection);

        expect(find.text(expectedMonthYearHeader), findsOneWidget);

        for (final String dayOfWeek in expectedDaysOfWeek) {
          expect(find.text(dayOfWeek), findsWidgets);
        }

        Offset? previousCellOffset;
        for (final String dayOfMonth in expectedDaysOfMonth) {
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

  testWidgets('textDirection parameter overrides ambient textDirection', (WidgetTester tester) async {
    await tester.pumpWidget(CupertinoApp(
      locale: const Locale('en', 'US'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
            builder: (BuildContext context) {
              return  CupertinoCalendarPicker(
                onDateChanged: (DateTime newValue) {},
              );
            },
          ),
      ),
    ));

    final Element picker = tester.element(find.byType(CupertinoCalendarPicker));
    expect(
      Directionality.of(picker),
      TextDirection.rtl,
    );
  });

group("locale fonts don't overflow layout", () {
    // Test screen layouts in various locales to ensure the fonts used
    // don't overflow the layout

    // Common screen size roughly based on a Pixel 1
    const Size kCommonScreenSizePortrait = Size(1070, 1770);
    const Size kCommonScreenSizeLandscape = Size(1770, 1070);

    Future<void> _showPicker(WidgetTester tester, Locale locale, Size size) async {
      tester.binding.window.physicalSizeTestValue = size;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (BuildContext context) {
              return Localizations(
                locale: locale,
                delegates: GlobalMaterialLocalizations.delegates,
                child: CupertinoCalendarPicker(
                  onDateChanged: (DateTime newValue) {},
                )
              );
            },
          ),
        )
      );
    }

    // Regression test for https://github.com/flutter/flutter/issues/20171
    testWidgets('common screen size - portrait - Chinese', (WidgetTester tester) async {
      await _showPicker(tester, const Locale('zh', 'CN'), kCommonScreenSizePortrait);
      expect(tester.takeException(), isNull);
    });

    testWidgets('common screen size - landscape - Chinese', (WidgetTester tester) async {
      await _showPicker(tester, const Locale('zh', 'CN'), kCommonScreenSizeLandscape);
      expect(tester.takeException(), isNull);
    });

    testWidgets('common screen size - portrait - Japanese', (WidgetTester tester) async {
      await _showPicker(tester, const Locale('ja', 'JA'), kCommonScreenSizePortrait);
      expect(tester.takeException(), isNull);
    });

    testWidgets('common screen size - landscape - Japanese', (WidgetTester tester) async {
      await _showPicker(tester, const Locale('ja', 'JA'), kCommonScreenSizeLandscape);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpBoilerplate(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en', 'US'),
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await tester.pumpWidget(CupertinoApp(
    home: Directionality(
      textDirection: TextDirection.ltr,
      child: Localizations(
        locale: locale,
        delegates: GlobalMaterialLocalizations.delegates,
        child: child,
      ),
    ),
  ));
}
