// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('$MaterialLocalizations localizes text inside the tree', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: new ListView(
        children: <Widget>[
          new LocalizationTracker(key: const ValueKey<String>('outer')),
          new Localizations(
            locale: const Locale('zh', 'CN'),
            delegates: <LocalizationsDelegate<dynamic>>[
              new _MaterialLocalizationsDelegate(
                new DefaultMaterialLocalizations(const Locale('zh', 'CN')),
              ),
              const DefaultWidgetsLocalizationsDelegate(),
            ],
            child: new LocalizationTracker(key: const ValueKey<String>('inner')),
          ),
        ],
      ),
    ));

    final LocalizationTrackerState outerTracker = tester.state(find.byKey(const ValueKey<String>('outer')));
    expect(outerTracker.captionFontSize, 12.0);
    final LocalizationTrackerState innerTracker = tester.state(find.byKey(const ValueKey<String>('inner')));
    expect(innerTracker.captionFontSize, 13.0);
  });

  group(DefaultMaterialLocalizations, () {
    test('uses exact locale when exists', () {
      final DefaultMaterialLocalizations localizations = new DefaultMaterialLocalizations(const Locale('pt', 'PT'));
      expect(localizations.formatDecimal(10000), '10\u00A0000');
    });

    test('falls back to language code when exact locale is missing', () {
      final DefaultMaterialLocalizations localizations = new DefaultMaterialLocalizations(const Locale('pt', 'XX'));
      expect(localizations.formatDecimal(10000), '10.000');
    });

    test('falls back to default format when neither language code nor exact locale are available', () {
      final DefaultMaterialLocalizations localizations = new DefaultMaterialLocalizations(const Locale('xx', 'XX'));
      expect(localizations.formatDecimal(10000), '10,000');
    });

    group('formatHour', () {
      test('formats h', () {
        DefaultMaterialLocalizations localizations;

        localizations = new DefaultMaterialLocalizations(const Locale('en', 'US'));
        expect(localizations.formatHour(const TimeOfDay(hour: 10, minute: 0)), '10');
        expect(localizations.formatHour(const TimeOfDay(hour: 20, minute: 0)), '8');

        localizations = new DefaultMaterialLocalizations(const Locale('ar', ''));
        expect(localizations.formatHour(const TimeOfDay(hour: 10, minute: 0)), '١٠');
        expect(localizations.formatHour(const TimeOfDay(hour: 20, minute: 0)), '٨');
      });

      test('formats HH', () {
        DefaultMaterialLocalizations localizations;

        localizations = new DefaultMaterialLocalizations(const Locale('de', ''));
        expect(localizations.formatHour(const TimeOfDay(hour: 9, minute: 0)), '09');
        expect(localizations.formatHour(const TimeOfDay(hour: 20, minute: 0)), '20');

        localizations = new DefaultMaterialLocalizations(const Locale('en', 'GB'));
        expect(localizations.formatHour(const TimeOfDay(hour: 9, minute: 0)), '09');
        expect(localizations.formatHour(const TimeOfDay(hour: 20, minute: 0)), '20');
      });

      test('formats H', () {
        DefaultMaterialLocalizations localizations;

        localizations = new DefaultMaterialLocalizations(const Locale('es', ''));
        expect(localizations.formatHour(const TimeOfDay(hour: 9, minute: 0)), '9');
        expect(localizations.formatHour(const TimeOfDay(hour: 20, minute: 0)), '20');

        localizations = new DefaultMaterialLocalizations(const Locale('fa', ''));
        expect(localizations.formatHour(const TimeOfDay(hour: 9, minute: 0)), '۹');
        expect(localizations.formatHour(const TimeOfDay(hour: 20, minute: 0)), '۲۰');
      });
    });

    group('formatMinute', () {
      test('formats English', () {
        final DefaultMaterialLocalizations localizations = new DefaultMaterialLocalizations(const Locale('en', 'US'));
        expect(localizations.formatMinute(const TimeOfDay(hour: 1, minute: 32)), '32');
      });

      test('formats Arabic', () {
        final DefaultMaterialLocalizations localizations = new DefaultMaterialLocalizations(const Locale('ar', ''));
        expect(localizations.formatMinute(const TimeOfDay(hour: 1, minute: 32)), '٣٢');
      });
    });

    group('formatTimeOfDay', () {
      test('formats ${TimeOfDayFormat.h_colon_mm_space_a}', () {
        DefaultMaterialLocalizations localizations;

        localizations = new DefaultMaterialLocalizations(const Locale('ar', ''));
        expect(localizations.formatTimeOfDay(const TimeOfDay(hour: 9, minute: 32)), '٩:٣٢ ص');

        localizations = new DefaultMaterialLocalizations(const Locale('en', ''));
        expect(localizations.formatTimeOfDay(const TimeOfDay(hour: 9, minute: 32)), '9:32 AM');
      });

      test('formats ${TimeOfDayFormat.HH_colon_mm}', () {
        DefaultMaterialLocalizations localizations;

        localizations = new DefaultMaterialLocalizations(const Locale('de', ''));
        expect(localizations.formatTimeOfDay(const TimeOfDay(hour: 9, minute: 32)), '09:32');

        localizations = new DefaultMaterialLocalizations(const Locale('en', 'ZA'));
        expect(localizations.formatTimeOfDay(const TimeOfDay(hour: 9, minute: 32)), '09:32');
      });

      test('formats ${TimeOfDayFormat.H_colon_mm}', () {
        DefaultMaterialLocalizations localizations;

        localizations = new DefaultMaterialLocalizations(const Locale('es', ''));
        expect(localizations.formatTimeOfDay(const TimeOfDay(hour: 9, minute: 32)), '9:32');

        localizations = new DefaultMaterialLocalizations(const Locale('ja', ''));
        expect(localizations.formatTimeOfDay(const TimeOfDay(hour: 9, minute: 32)), '9:32');
      });

      test('formats ${TimeOfDayFormat.frenchCanadian}', () {
        DefaultMaterialLocalizations localizations;

        localizations = new DefaultMaterialLocalizations(const Locale('fr', 'CA'));
        expect(localizations.formatTimeOfDay(const TimeOfDay(hour: 9, minute: 32)), '09 h 32');
      });

      test('formats ${TimeOfDayFormat.a_space_h_colon_mm}', () {
        DefaultMaterialLocalizations localizations;

        localizations = new DefaultMaterialLocalizations(const Locale('zh', ''));
        expect(localizations.formatTimeOfDay(const TimeOfDay(hour: 9, minute: 32)), '上午 9:32');
      });
    });
  });
}

class LocalizationTracker extends StatefulWidget {
  LocalizationTracker({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new LocalizationTrackerState();
}

class LocalizationTrackerState extends State<LocalizationTracker> {
  double captionFontSize;

  @override
  Widget build(BuildContext context) {
    captionFontSize = Theme.of(context).textTheme.caption.fontSize;
    return new Container();
  }
}

// Same as _MaterialLocalizationsDelegate in widgets/app.dart
class _MaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsDelegate(this.localizations);

  final MaterialLocalizations localizations;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(localizations);
  }

  @override
  bool shouldReload(_MaterialLocalizationsDelegate old) => false;
}

// Same as _WidgetsLocalizationsDelegate in widgets/app.dart
class DefaultWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const DefaultWidgetsLocalizationsDelegate();

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return new SynchronousFuture<WidgetsLocalizations>(new DefaultWidgetsLocalizations(locale));
  }

  @override
  bool shouldReload(DefaultWidgetsLocalizationsDelegate old) => false;
}
