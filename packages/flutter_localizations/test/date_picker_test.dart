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
    firstDate = DateTime(2001, DateTime.january, 1);
    lastDate = DateTime(2031, DateTime.december, 31);
    initialDate = DateTime(2016, DateTime.january, 15);
  });

  group(DayPicker, () {
    final intl.NumberFormat arabicNumbers = intl.NumberFormat('0', 'ar');
    final Map<Locale, Map<String, dynamic>> testLocales = <Locale, Map<String, dynamic>>{
      // Tests the default.
      const Locale('en', 'US'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'],
        'expectedDaysOfMonth': List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'September 2017',
      },
      // Tests a different first day of week.
      const Locale('ru', 'RU'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'],
        'expectedDaysOfMonth': List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'сентябрь 2017 г.',
      },
      const Locale('ro', 'RO'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['D', 'L', 'M', 'M', 'J', 'V', 'S'],
        'expectedDaysOfMonth': List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'septembrie 2017',
      },
      // Tests RTL.
      const Locale('ar', 'AR'): <String, dynamic>{
        'textDirection': TextDirection.rtl,
        'expectedDaysOfWeek': <String>['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'],
        'expectedDaysOfMonth': List<String>.generate(30, (int i) => '${arabicNumbers.format(i + 1)}'),
        'expectedMonthYearHeader': 'سبتمبر ٢٠١٧',
      },
    };

    for (Locale locale in testLocales.keys) {
      testWidgets('shows dates for $locale', (WidgetTester tester) async {
        final List<String> expectedDaysOfWeek = testLocales[locale]['expectedDaysOfWeek'];
        final List<String> expectedDaysOfMonth = testLocales[locale]['expectedDaysOfMonth'];
        final String expectedMonthYearHeader = testLocales[locale]['expectedMonthYearHeader'];
        final TextDirection textDirection = testLocales[locale]['textDirection'];
        final DateTime baseDate = DateTime(2017, 9, 27);

        await _pumpBoilerplate(tester, DayPicker(
          selectedDate: baseDate,
          currentDate: baseDate,
          onChanged: (DateTime newValue) { },
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
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en', 'US'),
      supportedLocales: const <Locale>[
        Locale('en', 'US'),
        Locale('fr', 'CA'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Material(
        child: Builder(
          builder: (BuildContext context) {
            return FlatButton(
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
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en', 'US'),
      supportedLocales: const <Locale>[
        Locale('en', 'US'),
      ],
      home: Material(
        child: Builder(
          builder: (BuildContext context) {
            return FlatButton(
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
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en', 'US'),
      supportedLocales: const <Locale>[
        Locale('en', 'US'),
        Locale('fr', 'CA'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Material(
        child: Builder(
          builder: (BuildContext context) {
            return FlatButton(
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

  group('device configurations', () {

    Future<void> _showPicker(WidgetTester tester, Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Localizations(
                locale: locale,
                delegates: GlobalMaterialLocalizations.delegates,
                child: RaisedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                    );
                  },
                ),
              );
            },
          ),
        )
      );
      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();
    }

    testWidgets('should display on Pixel portrait, Chinese', (WidgetTester tester) async {
      _applyConfig(tester, _TestDeviceConfigs.Pixel);
      await _showPicker(tester, const Locale('zh', 'CN'));
    });

    testWidgets('should display on Pixel landscape, Chinese', (WidgetTester tester) async {
      _applyConfig(tester, _TestDeviceConfigs.Pixel.copyWith(
        orientation: Orientation.landscape,
      ));
      await _showPicker(tester, const Locale('zh', 'CN'));
    });

    testWidgets('should display on Pixel portrait, Japanese', (WidgetTester tester) async {
      _applyConfig(tester, _TestDeviceConfigs.Pixel);
      await _showPicker(tester, const Locale('ja', 'JA'));
    });

    testWidgets('should display on Pixel landcape, Japanese', (WidgetTester tester) async {
      _applyConfig(tester, _TestDeviceConfigs.Pixel.copyWith(
        orientation: Orientation.landscape,
      ));
      await _showPicker(tester, const Locale('ja', 'JA'));
    });

  });

}

Future<void> _pumpBoilerplate(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en', 'US'),
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Localizations(
      locale: locale,
      delegates: GlobalMaterialLocalizations.delegates,
      child: child,
    ),
  ));
}

class _TestDeviceConfig {

  const _TestDeviceConfig({
    this.size = Size.zero,
    this.devicePixelRatio = 1.0,
    this.orientation = Orientation.portrait,
    this.textScaleFactor = 1.0,
    this.locale,
  });

  final Size size;
  final double devicePixelRatio;
  final Orientation orientation;
  final double textScaleFactor;
  final Locale locale;

  _TestDeviceConfig copyWith({
    Size size,
    double devicePixelRatio,
    Orientation orientation,
    double textScaleFactor,
  }) {
    return _TestDeviceConfig(
      size: size ?? this.size,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      orientation: orientation ?? this.orientation,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }

  Size get orientedSize {
    final Orientation sizeOrientation = size.width <= size.height
        ? Orientation.portrait
        : Orientation.landscape;
    if (sizeOrientation != orientation) {
      return Size(size.height, size.width);
    }
    return size;
  }
}

class _TestDeviceConfigs {
  _TestDeviceConfigs._();

  static const _TestDeviceConfig Pixel = _TestDeviceConfig(
    size: Size(411.4, 683.4),
    devicePixelRatio: 2.6,
  );

  static const _TestDeviceConfig SmallDisplay = _TestDeviceConfig(
    size: Size(320, 521),
    devicePixelRatio: 1.0,
  );
}

void _applyConfig(WidgetTester tester, _TestDeviceConfig config) {
  tester.binding.window.physicalSizeTestValue = config.orientedSize * config.devicePixelRatio;
  tester.binding.window.devicePixelRatioTestValue = config.devicePixelRatio;
  tester.binding.window.textScaleFactorTestValue = config.textScaleFactor;
}
