// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(GlobalMaterialLocalizations, () {
    test('uses exact locale when exists', () async {
      final GlobalMaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('pt', 'PT'));
      expect(localizations.formatDecimal(10000), '10\u00A0000');
    });

    test('falls back to language code when exact locale is missing', () async {
      final GlobalMaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('pt', 'XX'));
      expect(localizations.formatDecimal(10000), '10.000');
    });

    test('fails when neither language code nor exact locale are available', () async {
      await expectLater(() async {
        await GlobalMaterialLocalizations.delegate.load(const Locale('xx', 'XX'));
      }, throwsAssertionError);
    });

    group('formatHour', () {
      Future<String> formatHour(WidgetTester tester, Locale locale, TimeOfDay timeOfDay) async {
        final Completer<String> completer = Completer<String>();
        await tester.pumpWidget(MaterialApp(
          supportedLocales: <Locale>[locale],
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
          ],
          home: Builder(builder: (BuildContext context) {
            completer.complete(MaterialLocalizations.of(context).formatHour(timeOfDay));
            return Container();
          }),
        ));
        return completer.future;
      }

      testWidgets('formats h', (WidgetTester tester) async {
        expect(await formatHour(tester, const Locale('en', 'US'), const TimeOfDay(hour: 10, minute: 0)), '10');
        expect(await formatHour(tester, const Locale('en', 'US'), const TimeOfDay(hour: 20, minute: 0)), '8');
      });

      testWidgets('formats HH', (WidgetTester tester) async {
        expect(await formatHour(tester, const Locale('de'), const TimeOfDay(hour: 9, minute: 0)), '09');
        expect(await formatHour(tester, const Locale('de'), const TimeOfDay(hour: 20, minute: 0)), '20');

        expect(await formatHour(tester, const Locale('en', 'GB'), const TimeOfDay(hour: 9, minute: 0)), '09');
        expect(await formatHour(tester, const Locale('en', 'GB'), const TimeOfDay(hour: 20, minute: 0)), '20');
      });

      testWidgets('formats H', (WidgetTester tester) async {
        expect(await formatHour(tester, const Locale('es'), const TimeOfDay(hour: 9, minute: 0)), '9');
        expect(await formatHour(tester, const Locale('es'), const TimeOfDay(hour: 20, minute: 0)), '20');

        expect(await formatHour(tester, const Locale('fa'), const TimeOfDay(hour: 9, minute: 0)), '۹');
        expect(await formatHour(tester, const Locale('fa'), const TimeOfDay(hour: 20, minute: 0)), '۲۰');
      });
    });

    group('formatMinute', () {
      test('formats English', () async {
        final GlobalMaterialLocalizations localizations = await GlobalMaterialLocalizations.delegate.load(const Locale('en', 'US'));
        expect(localizations.formatMinute(const TimeOfDay(hour: 1, minute: 32)), '32');
      });
    });

    group('formatTimeOfDay', () {
      Future<String> formatTimeOfDay(WidgetTester tester, Locale locale, TimeOfDay timeOfDay) async {
        final Completer<String> completer = Completer<String>();
        await tester.pumpWidget(MaterialApp(
          supportedLocales: <Locale>[locale],
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
          ],
          home: Builder(builder: (BuildContext context) {
            completer.complete(MaterialLocalizations.of(context).formatTimeOfDay(timeOfDay));
            return Container();
          }),
        ));
        return completer.future;
      }

      testWidgets('formats ${TimeOfDayFormat.h_colon_mm_space_a}', (WidgetTester tester) async {
        expect(await formatTimeOfDay(tester, const Locale('en'), const TimeOfDay(hour: 9, minute: 32)), '9:32 AM');
        expect(await formatTimeOfDay(tester, const Locale('en'), const TimeOfDay(hour: 20, minute: 32)), '8:32 PM');
      });

      testWidgets('formats ${TimeOfDayFormat.HH_colon_mm}', (WidgetTester tester) async {
        expect(await formatTimeOfDay(tester, const Locale('de'), const TimeOfDay(hour: 9, minute: 32)), '09:32');
        expect(await formatTimeOfDay(tester, const Locale('en', 'ZA'), const TimeOfDay(hour: 9, minute: 32)), '09:32');
      });

      testWidgets('formats ${TimeOfDayFormat.H_colon_mm}', (WidgetTester tester) async {
        expect(await formatTimeOfDay(tester, const Locale('es'), const TimeOfDay(hour: 9, minute: 32)), '9:32');
        expect(await formatTimeOfDay(tester, const Locale('es'), const TimeOfDay(hour: 20, minute: 32)), '20:32');

        expect(await formatTimeOfDay(tester, const Locale('ja'), const TimeOfDay(hour: 9, minute: 32)), '9:32');
        expect(await formatTimeOfDay(tester, const Locale('ja'), const TimeOfDay(hour: 20, minute: 32)), '20:32');
      });

      testWidgets('formats ${TimeOfDayFormat.frenchCanadian}', (WidgetTester tester) async {
        expect(await formatTimeOfDay(tester, const Locale('fr', 'CA'), const TimeOfDay(hour: 9, minute: 32)), '09 h 32');
      });

      testWidgets('formats ${TimeOfDayFormat.a_space_h_colon_mm}', (WidgetTester tester) async {
        expect(await formatTimeOfDay(tester, const Locale('zh'), const TimeOfDay(hour: 9, minute: 32)), '上午 9:32');
      });
    });

    group('date formatters', () {
      Future<Map<DateType, String>> formatDate(WidgetTester tester, Locale locale, DateTime dateTime) async {
        final Completer<Map<DateType, String>> completer = Completer<Map<DateType, String>>();
        await tester.pumpWidget(MaterialApp(
          supportedLocales: <Locale>[locale],
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
          ],
          home: Builder(builder: (BuildContext context) {
            final MaterialLocalizations localizations = MaterialLocalizations.of(context);
            completer.complete(<DateType, String>{
              DateType.year: localizations.formatYear(dateTime),
              DateType.medium: localizations.formatMediumDate(dateTime),
              DateType.full: localizations.formatFullDate(dateTime),
              DateType.monthYear: localizations.formatMonthYear(dateTime),
            });
            return Container();
          }),
        ));
        return completer.future;
      }

      testWidgets('formats dates in English', (WidgetTester tester) async {
       final Map<DateType, String> formatted = await formatDate(tester, const Locale('en'), DateTime(2018, 8, 1));
       expect(formatted[DateType.year], '2018');
       expect(formatted[DateType.medium], 'Wed, Aug 1');
       expect(formatted[DateType.full], 'Wednesday, August 1, 2018');
       expect(formatted[DateType.monthYear], 'August 2018');
      });

      testWidgets('formats dates in German', (WidgetTester tester) async {
        final Map<DateType, String> formatted = await formatDate(tester, const Locale('de'), DateTime(2018, 8, 1));
        expect(formatted[DateType.year], '2018');
        expect(formatted[DateType.medium], 'Mi., 1. Aug.');
        expect(formatted[DateType.full], 'Mittwoch, 1. August 2018');
        expect(formatted[DateType.monthYear], 'August 2018');
      });
    });
  });
}

enum DateType { year, medium, full, monthYear }
