// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Determines the order of the columns inside [CupertinoDatePicker] in
/// time and date time mode.
enum DatePickerDateTimeOrder {
  /// Order of the columns, from left to right: date, hour, minute, am/pm.
  ///
  /// Example: [Fri Aug 31 | 02 | 08 | PM].
  date_time_dayPeriod,
  /// Order of the columns, from left to right: date, am/pm, hour, minute.
  ///
  /// Example: [Fri Aug 31 | PM | 02 | 08].
  date_dayPeriod_time,
  /// Order of the columns, from left to right: hour, minute, am/pm, date.
  ///
  /// Example: [02 | 08 | PM | Fri Aug 31].
  time_dayPeriod_date,
  /// Order of the columns, from left to right: am/pm, hour, minute, date.
  ///
  /// Example: [PM | 02 | 08 | Fri Aug 31].
  dayPeriod_time_date,
}

/// Determines the order of the columns inside [CupertinoDatePicker] in date mode.
enum DatePickerDateOrder {
  /// Order of the columns, from left to right: day, month, year.
  ///
  /// Example: [12 | March | 1996]
  dmy,
  /// Order of the columns, from left to right: month, day, year.
  ///
  /// Example: [March | 12 | 1996]
  mdy,
  /// Order of the columns, from left to right: year, month, day.
  ///
  /// Example: [1996 | March | 12]
  ymd,
  /// Order of the columns, from left to right: year, day, month.
  ///
  /// Example: [1996 | 12 | March]
  ydm,
}

/// Defines the localized resource values used by the Cupertino widgets.
///
/// See also:
///
///  * [DefaultCupertinoLocalizations], the default, English-only, implementation
///    of this interface.
// TODO(xster): Supply non-english strings.
abstract class CupertinoLocalizations {
  /// Year that is shown in [CupertinoDatePicker] spinner corresponding to the
  /// given year index.
  ///
  /// Examples: datePickerYear(1) in:
  ///
  ///  - US English: 2018
  ///  - Korean: 2018년
  String datePickerYear(int yearIndex);

  /// Month that is shown in [CupertinoDatePicker] spinner corresponding to
  /// the given month index.
  ///
  /// Examples: datePickerMonth(1) in:
  ///
  ///  - US English: January
  ///  - Korean: 1월
  String datePickerMonth(int monthIndex);

  /// Day of month that is shown in [CupertinoDatePicker] spinner corresponding
  /// to the given day index.
  ///
  /// Examples: datePickerDayOfMonth(1) in:
  ///
  ///  - US English: 1
  ///  - Korean: 1일
  String datePickerDayOfMonth(int dayIndex);

  /// The medium-width date format that is shown in [CupertinoDatePicker]
  /// spinner. Abbreviates month and days of week.
  ///
  /// Examples:
  ///
  /// - US English: Wed Sep 27
  /// - Russian: ср сент. 27
  String datePickerMediumDate(DateTime date);

  /// Hour that is shown in [CupertinoDatePicker] spinner corresponding
  /// to the given hour value.
  ///
  /// Examples: datePickerHour(1) in:
  ///
  ///  - US English: 1
  ///  - Arabic: ٠١
  String datePickerHour(int hour);

  /// Semantics label for the given hour value in [CupertinoDatePicker].
  String datePickerHourSemanticsLabel(int hour);

  /// Minute that is shown in [CupertinoDatePicker] spinner corresponding
  /// to the given minute value.
  ///
  /// Examples: datePickerMinute(1) in:
  ///
  ///  - US English: 01
  ///  - Arabic: ٠١
  String datePickerMinute(int minute);

  /// Semantics label for the given minute value in [CupertinoDatePicker].
  String datePickerMinuteSemanticsLabel(int minute);

  /// The order of the date elements that will be shown in [CupertinoDatePicker].
  DatePickerDateOrder get datePickerDateOrder;

  /// The order of the time elements that will be shown in [CupertinoDatePicker].
  DatePickerDateTimeOrder get datePickerDateTimeOrder;

  /// The abbreviation for ante meridiem (before noon) shown in the time picker.
  String get anteMeridiemAbbreviation;

  /// The abbreviation for post meridiem (after noon) shown in the time picker.
  String get postMeridiemAbbreviation;

  /// The term used by the system to announce dialog alerts.
  String get alertDialogLabel;

  /// Hour that is shown in [CupertinoCountdownTimerPicker] corresponding to
  /// the given hour value.
  ///
  /// Examples: timerPickerHour(1) in:
  ///
  ///  - US English: 1
  ///  - Arabic: ١
  String timerPickerHour(int hour);

  /// Minute that is shown in [CupertinoCountdownTimerPicker] corresponding to
  /// the given minute value.
  ///
  /// Examples: timerPickerMinute(1) in:
  ///
  ///  - US English: 1
  ///  - Arabic: ١
  String timerPickerMinute(int minute);

  /// Second that is shown in [CupertinoCountdownTimerPicker] corresponding to
  /// the given second value.
  ///
  /// Examples: timerPickerSecond(1) in:
  ///
  ///  - US English: 1
  ///  - Arabic: ١
  String timerPickerSecond(int second);

  /// Label that appears next to the hour picker in
  /// [CupertinoCountdownTimerPicker] when selected hour value is `hour`.
  /// This function will deal with pluralization based on the `hour` parameter.
  String timerPickerHourLabel(int hour);

  /// Label that appears next to the minute picker in
  /// [CupertinoCountdownTimerPicker] when selected minute value is `minute`.
  /// This function will deal with pluralization based on the `minute` parameter.
  String timerPickerMinuteLabel(int minute);

  /// Label that appears next to the minute picker in
  /// [CupertinoCountdownTimerPicker] when selected minute value is `second`.
  /// This function will deal with pluralization based on the `second` parameter.
  String timerPickerSecondLabel(int second);

  /// The term used for cutting
  String get cutButtonLabel;

  /// The term used for copying
  String get copyButtonLabel;

  /// The term used for pasting
  String get pasteButtonLabel;

  /// The term used for selecting everything
  String get selectAllButtonLabel;

  /// The `CupertinoLocalizations` from the closest [Localizations] instance
  /// that encloses the given context.
  ///
  /// This method is just a convenient shorthand for:
  /// `Localizations.of<CupertinoLocalizations>(context, CupertinoLocalizations)`.
  ///
  /// References to the localized resources defined by this class are typically
  /// written in terms of this method. For example:
  ///
  /// ```dart
  /// CupertinoLocalizations.of(context).anteMeridiemAbbreviation;
  /// ```
  static CupertinoLocalizations of(BuildContext context) {
    return Localizations.of<CupertinoLocalizations>(context, CupertinoLocalizations);
  }
}

class _CupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<CupertinoLocalizations> load(Locale locale) => DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_CupertinoLocalizationsDelegate old) => false;

  @override
  String toString() => 'DefaultCupertinoLocalizations.delegate(en_US)';
}

/// US English strings for the cupertino widgets.
class DefaultCupertinoLocalizations implements CupertinoLocalizations {
  /// Constructs an object that defines the cupertino widgets' localized strings
  /// for US English (only).
  ///
  /// [LocalizationsDelegate] implementations typically call the static [load]
  /// function, rather than constructing this class directly.
  const DefaultCupertinoLocalizations();

  static const List<String> _shortWeekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _shortMonths = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];



  @override
  String datePickerYear(int yearIndex) => yearIndex.toString();

  @override
  String datePickerMonth(int monthIndex) => _months[monthIndex - 1];

  @override
  String datePickerDayOfMonth(int dayIndex) => dayIndex.toString();

  @override
  String datePickerHour(int hour) => hour.toString();

  @override
  String datePickerHourSemanticsLabel(int hour) => hour.toString() + " o'clock";

  @override
  String datePickerMinute(int minute) => minute.toString().padLeft(2, '0');

  @override
  String datePickerMinuteSemanticsLabel(int minute) {
    if (minute == 1)
       return '1 minute';
    return minute.toString() + ' minutes';
  }

  @override
  String datePickerMediumDate(DateTime date) {
    return '${_shortWeekdays[date.weekday - DateTime.monday]} '
      '${_shortMonths[date.month - DateTime.january]} '
      '${date.day.toString().padRight(2)}';
  }

  @override
  DatePickerDateOrder get datePickerDateOrder => DatePickerDateOrder.mdy;

  @override
  DatePickerDateTimeOrder get datePickerDateTimeOrder => DatePickerDateTimeOrder.date_time_dayPeriod;

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get alertDialogLabel => 'Alert';

  @override
  String timerPickerHour(int hour) => hour.toString();

  @override
  String timerPickerMinute(int minute) => minute.toString();

  @override
  String timerPickerSecond(int second) => second.toString();

  @override
  String timerPickerHourLabel(int hour) => hour == 1 ? 'hour' : 'hours';

  @override
  String timerPickerMinuteLabel(int minute) => 'min';

  @override
  String timerPickerSecondLabel(int second) => 'sec';

  @override
  String get cutButtonLabel => 'Cut';

  @override
  String get copyButtonLabel => 'Copy';

  @override
  String get pasteButtonLabel => 'Paste';

  @override
  String get selectAllButtonLabel => 'Select All';

  /// Creates an object that provides US English resource values for the
  /// cupertino library widgets.
  ///
  /// The [locale] parameter is ignored.
  ///
  /// This method is typically used to create a [LocalizationsDelegate].
  static Future<CupertinoLocalizations> load(Locale locale) {
    return SynchronousFuture<CupertinoLocalizations>(const DefaultCupertinoLocalizations());
  }

  /// A [LocalizationsDelegate] that uses [DefaultCupertinoLocalizations.load]
  /// to create an instance of this class.
  static const LocalizationsDelegate<CupertinoLocalizations> delegate = _CupertinoLocalizationsDelegate();
}
