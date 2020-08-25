// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _TimePickerLauncher extends StatelessWidget {
  const _TimePickerLauncher({
    Key key,
    this.onChanged,
    this.locale,
    this.entryMode = TimePickerEntryMode.dial,
  }) : super(key: key);

  final ValueChanged<TimeOfDay> onChanged;
  final Locale locale;
  final TimePickerEntryMode entryMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      supportedLocales: <Locale>[locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Material(
        child: Center(
          child: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                child: const Text('X'),
                onPressed: () async {
                  onChanged(await showTimePicker(
                    context: context,
                    initialEntryMode: entryMode,
                    initialTime: const TimeOfDay(hour: 7, minute: 0),
                  ));
                },
              );
            }
          ),
        ),
      ),
    );
  }
}

Future<Offset> startPicker(
  WidgetTester tester,
  ValueChanged<TimeOfDay> onChanged, {
    Locale locale = const Locale('en', 'US'),
}) async {
  await tester.pumpWidget(_TimePickerLauncher(onChanged: onChanged, locale: locale,));
  await tester.tap(find.text('X'));
  await tester.pumpAndSettle(const Duration(seconds: 1));
  return tester.getCenter(find.byKey(const Key('time-picker-dial')));
}

Future<void> finishPicker(WidgetTester tester) async {
  final MaterialLocalizations materialLocalizations = MaterialLocalizations.of(tester.element(find.byType(ElevatedButton)));
  await tester.tap(find.text(materialLocalizations.okButtonLabel));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  testWidgets('can localize the header in all known formats - portrait', (WidgetTester tester) async {
    // Ensure picker is displayed in portrait mode.
    tester.binding.window.physicalSizeTestValue = const Size(400, 800);
    tester.binding.window.devicePixelRatioTestValue = 1;

    final Finder stringFragmentTextFinder = find.descendant(
      of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_StringFragment'),
      matching: find.byType(Text),
    ).first;
    final Finder hourControlFinder = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_HourControl');
    final Finder minuteControlFinder = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_MinuteControl');
    final Finder dayPeriodControlFinder = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DayPeriodControl');

    // TODO(yjbanov): also test `HH.mm` (in_ID), `a h:mm` (ko_KR) and `HH:mm น.` (th_TH) when we have .arb files for them
    final List<Locale> locales = <Locale>[
      const Locale('en', 'US'), //'h:mm a'
      const Locale('en', 'GB'), //'HH:mm'
      const Locale('es', 'ES'), //'H:mm'
      const Locale('fr', 'CA'), //'HH \'h\' mm'
      const Locale('zh', 'ZH'), //'ah:mm'
      const Locale('fa', 'IR'), //'H:mm' but RTL
    ];

    for (final Locale locale in locales) {
      final Offset center = await startPicker(tester, (TimeOfDay time) { }, locale: locale);
      final Text stringFragmentText = tester.widget(stringFragmentTextFinder);
      final double hourLeftOffset = tester.getTopLeft(hourControlFinder).dx;
      final double minuteLeftOffset = tester.getTopLeft(minuteControlFinder).dx;
      final double stringFragmentLeftOffset = tester.getTopLeft(stringFragmentTextFinder).dx;

      if (locale == const Locale('en', 'US')) {
        final double dayPeriodLeftOffset = tester.getTopLeft(dayPeriodControlFinder).dx;
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(minuteLeftOffset, lessThan(dayPeriodLeftOffset));
      } else if (locale == const Locale('en', 'GB')) {
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      } else if (locale == const Locale('es', 'ES')) {
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      } else if (locale == const Locale('fr', 'CA')) {
        expect(stringFragmentText.data, 'h');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      } else if (locale == const Locale('zh', 'ZH')) {
        final double dayPeriodLeftOffset = tester.getTopLeft(dayPeriodControlFinder).dx;
        expect(stringFragmentText.data, ':');
        expect(dayPeriodLeftOffset, lessThan(hourLeftOffset));
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
      } else if (locale == const Locale('fa', 'IR')) {
        // Even though this is an RTL locale, the hours and minutes positions should remain the same.
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      }
      await tester.tapAt(Offset(center.dx, center.dy - 50.0));
      await finishPicker(tester);
    }

    tester.binding.window.physicalSizeTestValue = null;
    tester.binding.window.devicePixelRatioTestValue = null;
  });

  testWidgets('can localize the header in all known formats - landscape', (WidgetTester tester) async {
    // Ensure picker is displayed in landscape mode.
    tester.binding.window.physicalSizeTestValue = const Size(800, 400);
    tester.binding.window.devicePixelRatioTestValue = 1;

    final Finder stringFragmentTextFinder = find.descendant(
      of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_StringFragment'),
      matching: find.byType(Text),
    ).first;
    final Finder hourControlFinder = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_HourControl');
    final Finder minuteControlFinder = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_MinuteControl');
    final Finder dayPeriodControlFinder = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DayPeriodControl');

    // TODO(yjbanov): also test `HH.mm` (in_ID), `a h:mm` (ko_KR) and `HH:mm น.` (th_TH) when we have .arb files for them
    final List<Locale> locales = <Locale>[
      const Locale('en', 'US'), //'h:mm a'
      const Locale('en', 'GB'), //'HH:mm'
      const Locale('es', 'ES'), //'H:mm'
      const Locale('fr', 'CA'), //'HH \'h\' mm'
      const Locale('zh', 'ZH'), //'ah:mm'
      const Locale('fa', 'IR'), //'H:mm' but RTL
    ];

    for (final Locale locale in locales) {
      final Offset center = await startPicker(tester, (TimeOfDay time) { }, locale: locale);
      final Text stringFragmentText = tester.widget(stringFragmentTextFinder);
      final double hourLeftOffset = tester.getTopLeft(hourControlFinder).dx;
      final double hourTopOffset = tester.getTopLeft(hourControlFinder).dy;
      final double minuteLeftOffset = tester.getTopLeft(minuteControlFinder).dx;
      final double stringFragmentLeftOffset = tester.getTopLeft(stringFragmentTextFinder).dx;

      if (locale == const Locale('en', 'US')) {
        final double dayPeriodLeftOffset = tester.getTopLeft(dayPeriodControlFinder).dx;
        final double dayPeriodTopOffset = tester.getTopLeft(dayPeriodControlFinder).dy;
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(hourLeftOffset, dayPeriodLeftOffset);
        expect(hourTopOffset, lessThan(dayPeriodTopOffset));
      } else if (locale == const Locale('en', 'GB')) {
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      } else if (locale == const Locale('es', 'ES')) {
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      } else if (locale == const Locale('fr', 'CA')) {
        expect(stringFragmentText.data, 'h');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      } else if (locale == const Locale('zh', 'ZH')) {
        final double dayPeriodLeftOffset = tester.getTopLeft(dayPeriodControlFinder).dx;
        final double dayPeriodTopOffset = tester.getTopLeft(dayPeriodControlFinder).dy;
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(hourLeftOffset, dayPeriodLeftOffset);
        expect(hourTopOffset, greaterThan(dayPeriodTopOffset));
      } else if (locale == const Locale('fa', 'IR')) {
        // Even though this is an RTL locale, the hours and minutes positions should remain the same.
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      }
      await tester.tapAt(Offset(center.dx, center.dy - 50.0));
      await finishPicker(tester);
    }

    tester.binding.window.physicalSizeTestValue = null;
    tester.binding.window.devicePixelRatioTestValue = null;
  });

  testWidgets('can localize input mode in all known formats', (WidgetTester tester) async {
    final Finder stringFragmentTextFinder = find.descendant(
      of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_StringFragment'),
      matching: find.byType(Text),
    ).first;
    final Finder hourControlFinder = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_HourTextField');
    final Finder minuteControlFinder = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_MinuteTextField');
    final Finder dayPeriodControlFinder = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DayPeriodControl');

    // TODO(yjbanov): also test `HH.mm` (in_ID), `a h:mm` (ko_KR) and `HH:mm น.` (th_TH) when we have .arb files for them
    final List<Locale> locales = <Locale>[
      const Locale('en', 'US'), //'h:mm a'
      const Locale('en', 'GB'), //'HH:mm'
      const Locale('es', 'ES'), //'H:mm'
      const Locale('fr', 'CA'), //'HH \'h\' mm'
      const Locale('zh', 'ZH'), //'ah:mm'
      const Locale('fa', 'IR'), //'H:mm' but RTL
    ];

    for (final Locale locale in locales) {
      await tester.pumpWidget(_TimePickerLauncher(onChanged: (TimeOfDay time) { }, locale: locale, entryMode: TimePickerEntryMode.input));
      await tester.tap(find.text('X'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final Text stringFragmentText = tester.widget(stringFragmentTextFinder);
      final double hourLeftOffset = tester.getTopLeft(hourControlFinder).dx;
      final double minuteLeftOffset = tester.getTopLeft(minuteControlFinder).dx;
      final double stringFragmentLeftOffset = tester.getTopLeft(stringFragmentTextFinder).dx;

      if (locale == const Locale('en', 'US')) {
        final double dayPeriodLeftOffset = tester.getTopLeft(dayPeriodControlFinder).dx;
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(minuteLeftOffset, lessThan(dayPeriodLeftOffset));
      } else if (locale == const Locale('en', 'GB')) {
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      } else if (locale == const Locale('es', 'ES')) {
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      } else if (locale == const Locale('fr', 'CA')) {
        expect(stringFragmentText.data, 'h');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      } else if (locale == const Locale('zh', 'ZH')) {
        final double dayPeriodLeftOffset = tester.getTopLeft(dayPeriodControlFinder).dx;
        expect(stringFragmentText.data, ':');
        expect(dayPeriodLeftOffset, lessThan(hourLeftOffset));
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
      } else if (locale == const Locale('fa', 'IR')) {
        // Even though this is an RTL locale, the hours and minutes positions should remain the same.
        expect(stringFragmentText.data, ':');
        expect(hourLeftOffset, lessThan(stringFragmentLeftOffset));
        expect(stringFragmentLeftOffset, lessThan(minuteLeftOffset));
        expect(dayPeriodControlFinder, findsNothing);
      }
      await finishPicker(tester);
    }
  });

  testWidgets('uses single-ring 24-hour dial for all formats', (WidgetTester tester) async {
    const List<Locale> locales = <Locale>[
      Locale('en', 'US'), // h
      Locale('en', 'GB'), // HH
      Locale('es', 'ES'), // H
    ];
    for (final Locale locale in locales) {
      // Tap along the segment stretching from the center to the edge at
      // 12:00 AM position. Because there's only one ring, no matter where you
      // tap the time will be the same.
      for (int i = 1; i < 10; i++) {
        TimeOfDay result;
        final Offset center = await startPicker(tester, (TimeOfDay time) { result = time; }, locale: locale);
        final Size size = tester.getSize(find.byKey(const Key('time-picker-dial')));
        final double dy = (size.height / 2.0 / 10) * i;
        await tester.tapAt(Offset(center.dx, center.dy - dy));
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 0, minute: 0)));
      }
    }
  });

  const List<String> labels12To11 = <String>['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];
  const List<String> labels00To22TwoDigit = <String>['00', '02', '04', '06', '08', '10', '12', '14', '16', '18', '20', '22'];

  Future<void> mediaQueryBoilerplate(WidgetTester tester, bool alwaysUse24HourFormat) async {
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: MediaQuery(
          data: MediaQueryData(alwaysUse24HourFormat: alwaysUse24HourFormat),
          child: Material(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Navigator(
                onGenerateRoute: (RouteSettings settings) {
                  return MaterialPageRoute<void>(builder: (BuildContext context) {
                    return TextButton(
                      onPressed: () {
                        showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
                      },
                      child: const Text('X'),
                    );
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
  }

  testWidgets('respects MediaQueryData.alwaysUse24HourFormat == false', (WidgetTester tester) async {
    await mediaQueryBoilerplate(tester, false);

    final CustomPaint dialPaint = tester.widget(find.byKey(const ValueKey<String>('time-picker-dial')));
    final dynamic dialPainter = dialPaint.painter;
    final List<dynamic> primaryLabels = dialPainter.primaryLabels as List<dynamic>;
    expect(
      primaryLabels.map<String>((dynamic tp) => ((tp.painter as TextPainter).text as TextSpan).text),
      labels12To11,
    );

    final List<dynamic> secondaryLabels = dialPainter.secondaryLabels as List<dynamic>;
    expect(
      secondaryLabels.map<String>((dynamic tp) => ((tp.painter as TextPainter).text as TextSpan).text),
      labels12To11,
    );
  });

  testWidgets('respects MediaQueryData.alwaysUse24HourFormat == true', (WidgetTester tester) async {
    await mediaQueryBoilerplate(tester, true);

    final CustomPaint dialPaint = tester.widget(find.byKey(const ValueKey<String>('time-picker-dial')));
    final dynamic dialPainter = dialPaint.painter;
    final List<dynamic> primaryLabels = dialPainter.primaryLabels as List<dynamic>;
    expect(
      primaryLabels.map<String>((dynamic tp) => ((tp.painter as TextPainter).text as TextSpan).text),
      labels00To22TwoDigit,
    );

    final List<dynamic> secondaryLabels = dialPainter.secondaryLabels as List<dynamic>;
    expect(
      secondaryLabels.map<String>((dynamic tp) => ((tp.painter as TextPainter).text as TextSpan).text),
      labels00To22TwoDigit,
    );
  });
}
