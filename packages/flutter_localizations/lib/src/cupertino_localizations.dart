// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbols.dart' as intl;

import 'utils/date_localizations.dart' as util;
import 'widgets_localizations.dart';

/// Implementation of localized strings for Cupertino widgets using the `intl`
/// package for date and time formatting.
abstract class GlobalCupertinoLocalizations implements CupertinoLocalizations {
  /// Initializes an object that defines the Cupertino widgets' localized
  /// strings for the given `locale`.
  ///
  /// The arguments are used for further runtime localization of data,
  /// specifically for selecting plurals, date and time formatting, and number
  /// formatting. They correspond to the following values:
  ///
  ///  1. The string that would be returned by [Intl.canonicalizedLocale] for
  ///     the locale.
  ///  2. The [intl.DateFormat] for [formatYear].
  ///  3. The [intl.DateFormat] for [formatMediumDate].
  ///  4. The [intl.DateFormat] for [formatFullDate].
  ///  5. The [intl.DateFormat] for [formatMonthYear].
  ///  6. The [NumberFormat] for [formatDecimal] (also used by [formatHour] and
  ///     [formatTimeOfDay] when [timeOfDayFormat] doesn't use [HourFormat.HH]).
  ///  7. The [NumberFormat] for [formatHour] and the hour part of
  ///     [formatTimeOfDay] when [timeOfDayFormat] uses [HourFormat.HH], and for
  ///     [formatMinute] and the minute part of [formatTimeOfDay].
  ///
  /// The [narrowWeekdays] and [firstDayOfWeekIndex] properties use the values
  /// from the [intl.DateFormat] used by [formatFullDate].
  const GlobalCupertinoLocalizations({
    @required String localeName,
    @required intl.DateFormat fullYearFormat,
    @required intl.DateFormat dayFormat,
    @required intl.DateFormat longDateFormat,
    @required intl.DateFormat yearMonthFormat,
    @required intl.NumberFormat decimalFormat,
    @required intl.NumberFormat twoDigitZeroPaddedFormat,
  }) : assert(localeName != null),
       _localeName = localeName,
       assert(fullYearFormat != null),
       _fullYearFormat = fullYearFormat,
       assert(dayFormat != null),
       _dayFormat = dayFormat;

  final String _localeName;
  final intl.DateFormat _fullYearFormat;
  final intl.DateFormat _dayFormat;

  @override
  String datePickerYear(int yearIndex) {
    return _fullYearFormat.format(DateTime.utc(yearIndex));
  }

  @override
  String datePickerMonth(int monthIndex) {
    // It doesn't actually have anything to do with _fullYearFormat. It's just
    // taking advantage of the fact that _fullYearFormat loaded the needed
    // locale's symbols.
    return _fullYearFormat.dateSymbols.MONTHS[monthIndex];
  }

  @override
  String datePickerDayOfMonth(int dayIndex) {

  }

  /// The medium-width date format that is shown in [CupertinoDatePicker]
  /// spinner. Abbreviates month and days of week.
  ///
  /// Examples:
  ///
  /// - US English: Wed Sep 27
  /// - Russian: ср сент. 27
  // The global version is based on intl package's DateFormat.MMMEd.
  String datePickerMediumDate(DateTime date);

  /// Hour that is shown in [CupertinoDatePicker] spinner corresponding
  /// to the given hour value.
  ///
  /// Examples: datePickerHour(1) in:
  ///
  ///  - US English: 1
  ///  - Arabic: ٠١
  // The global version uses date symbols data from the intl package.
  String datePickerHour(int hour);

  /// Semantics label for the given hour value in [CupertinoDatePicker].
  // The global version uses the translated string from the arb file.
  String datePickerHourSemanticsLabel(int hour);

  /// Minute that is shown in [CupertinoDatePicker] spinner corresponding
  /// to the given minute value.
  ///
  /// Examples: datePickerMinute(1) in:
  ///
  ///  - US English: 01
  ///  - Arabic: ٠١
  // The global version uses date symbols data from the intl package.
  String datePickerMinute(int minute);

  /// Semantics label for the given minute value in [CupertinoDatePicker].
  // The global version uses the translated string from the arb file.
  String datePickerMinuteSemanticsLabel(int minute);

  /// The order of the date elements that will be shown in [CupertinoDatePicker].
  // The global version uses the translated string from the arb file.
  DatePickerDateOrder get datePickerDateOrder;

  /// The order of the time elements that will be shown in [CupertinoDatePicker].
  // The global version uses the translated string from the arb file.
  DatePickerDateTimeOrder get datePickerDateTimeOrder;

  /// The abbreviation for ante meridiem (before noon) shown in the time picker.
  // The global version uses the translated string from the arb file.
  String get anteMeridiemAbbreviation;

  /// The abbreviation for post meridiem (after noon) shown in the time picker.
  // The global version uses the translated string from the arb file.
  String get postMeridiemAbbreviation;

  /// The term used by the system to announce dialog alerts.
  // The global version uses the translated string from the arb file.
  String get alertDialogLabel;

  /// Hour that is shown in [CupertinoTimerPicker] corresponding to
  /// the given hour value.
  ///
  /// Examples: timerPickerHour(1) in:
  ///
  ///  - US English: 1
  ///  - Arabic: ١
  // The global version uses date symbols data from the intl package.
  String timerPickerHour(int hour);

  /// Minute that is shown in [CupertinoTimerPicker] corresponding to
  /// the given minute value.
  ///
  /// Examples: timerPickerMinute(1) in:
  ///
  ///  - US English: 1
  ///  - Arabic: ١
  // The global version uses date symbols data from the intl package.
  String timerPickerMinute(int minute);

  /// Second that is shown in [CupertinoTimerPicker] corresponding to
  /// the given second value.
  ///
  /// Examples: timerPickerSecond(1) in:
  ///
  ///  - US English: 1
  ///  - Arabic: ١
  // The global version uses date symbols data from the intl package.
  String timerPickerSecond(int second);

  /// Label that appears next to the hour picker in
  /// [CupertinoTimerPicker] when selected hour value is `hour`.
  /// This function will deal with pluralization based on the `hour` parameter.
  // The global version uses the translated string from the arb file.
  String timerPickerHourLabel(int hour);

  /// Label that appears next to the minute picker in
  /// [CupertinoTimerPicker] when selected minute value is `minute`.
  /// This function will deal with pluralization based on the `minute` parameter.
  // The global version uses the translated string from the arb file.
  String timerPickerMinuteLabel(int minute);

  /// Label that appears next to the minute picker in
  /// [CupertinoTimerPicker] when selected minute value is `second`.
  /// This function will deal with pluralization based on the `second` parameter.
  // The global version uses the translated string from the arb file.
  String timerPickerSecondLabel(int second);

  /// The term used for cutting
  // The global version uses the translated string from the arb file.
  String get cutButtonLabel;

  /// The term used for copying
  // The global version uses the translated string from the arb file.
  String get copyButtonLabel;

  /// The term used for pasting
  // The global version uses the translated string from the arb file.
  String get pasteButtonLabel;

  /// The term used for selecting everything
  // The global version uses the translated string from the arb file.
  String get selectAllButtonLabel;

  /// A [LocalizationsDelegate] that uses [GlobalMaterialLocalizations.load]
  /// to create an instance of this class.
  ///
  /// Most internationalized apps will use [GlobalMaterialLocalizations.delegates]
  /// as the value of [MaterialApp.localizationsDelegates] to include
  /// the localizations for both the material and widget libraries.
  static const LocalizationsDelegate<MaterialLocalizations> delegate = _MaterialLocalizationsDelegate();

  /// A value for [MaterialApp.localizationsDelegates] that's typically used by
  /// internationalized apps.
  ///
  /// ## Sample code
  ///
  /// To include the localizations provided by this class and by
  /// [GlobalWidgetsLocalizations] in a [MaterialApp],
  /// use [GlobalMaterialLocalizations.delegates] as the value of
  /// [MaterialApp.localizationsDelegates], and specify the locales your
  /// app supports with [MaterialApp.supportedLocales]:
  ///
  /// ```dart
  /// new MaterialApp(
  ///   localizationsDelegates: GlobalMaterialLocalizations.delegates,
  ///   supportedLocales: [
  ///     const Locale('en', 'US'), // English
  ///     const Locale('he', 'IL'), // Hebrew
  ///   ],
  ///   // ...
  /// )
  /// ```
  static const List<LocalizationsDelegate<dynamic>> delegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}

class _GlobalCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _GlobalCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => kSupportedLanguages.contains(locale.languageCode);

  static final Map<Locale, Future<CupertinoLocalizations>> _loadedTranslations = <Locale, Future<CupertinoLocalizations>>{};

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    assert(isSupported(locale));
    return _loadedTranslations.putIfAbsent(locale, () {
      util.loadDateIntlDataIfNotLoaded();

      final String localeName = intl.Intl.canonicalizedLocale(locale.toString());

      intl.DateFormat fullYearFormat;
      intl.DateFormat mediumDateFormat;
      intl.DateFormat longDateFormat;
      intl.DateFormat yearMonthFormat;
      if (intl.DateFormat.localeExists(localeName)) {
        fullYearFormat = intl.DateFormat.y(localeName);
        mediumDateFormat = intl.DateFormat.MMMEd(localeName);
        longDateFormat = intl.DateFormat.yMMMMEEEEd(localeName);
        yearMonthFormat = intl.DateFormat.yMMMM(localeName);
      } else if (intl.DateFormat.localeExists(locale.languageCode)) {
        fullYearFormat = intl.DateFormat.y(locale.languageCode);
        mediumDateFormat = intl.DateFormat.MMMEd(locale.languageCode);
        longDateFormat = intl.DateFormat.yMMMMEEEEd(locale.languageCode);
        yearMonthFormat = intl.DateFormat.yMMMM(locale.languageCode);
      } else {
        fullYearFormat = intl.DateFormat.y();
        mediumDateFormat = intl.DateFormat.MMMEd();
        longDateFormat = intl.DateFormat.yMMMMEEEEd();
        yearMonthFormat = intl.DateFormat.yMMMM();
      }

      intl.NumberFormat decimalFormat;
      intl.NumberFormat twoDigitZeroPaddedFormat;
      if (intl.NumberFormat.localeExists(localeName)) {
        decimalFormat = intl.NumberFormat.decimalPattern(localeName);
        twoDigitZeroPaddedFormat = intl.NumberFormat('00', localeName);
      } else if (intl.NumberFormat.localeExists(locale.languageCode)) {
        decimalFormat = intl.NumberFormat.decimalPattern(locale.languageCode);
        twoDigitZeroPaddedFormat = intl.NumberFormat('00', locale.languageCode);
      } else {
        decimalFormat = intl.NumberFormat.decimalPattern();
        twoDigitZeroPaddedFormat = intl.NumberFormat('00');
      }

      assert(locale.toString() == localeName, 'comparing "$locale" to "$localeName"');

      return SynchronousFuture<CupertinoLocalizations>(getMaterialTranslation(
        locale,
        fullYearFormat,
        mediumDateFormat,
        longDateFormat,
        yearMonthFormat,
        decimalFormat,
        twoDigitZeroPaddedFormat,
      ));
    });
  }

  @override
  bool shouldReload(_GlobalCupertinoLocalizationsDelegate old) => false;

  @override
  String toString() => 'GlobalMaterialLocalizations.delegate(${kSupportedLanguages.length} locales)';
}
