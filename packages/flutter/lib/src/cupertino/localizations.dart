// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';


/// Defines the localized resource values used by the Cupertino widgets.
///
/// See also:
///
///  * [DefaultCupertinoLocalizations], the default, English-only, implementation
///    of this interface.
// TODO(xster): Supply non-english strings.
abstract class CupertinoLocalizations {
  /// The given number in local writing system.
  ///
  /// Different languages can have different numeral systems, and this function
  /// will return the given number written in the local language.
  /// Example of some numeral systems can be found here:
  /// https://en.wikipedia.org/wiki/List_of_numeral_systems
  String number(int num);

  /// Month that is shown in [CupertinoDatePicker] corresponding to the given
  /// month index.
  ///
  /// Examples: datePickerMonth(1) in:
  ///
  ///  - US English: January
  ///  - Korean: 1월
  String datePickerMonth(int monthIndex);

  /// Day of month that is shown in [CupertinoDatePicker] corresponding to
  /// the given day index.
  ///
  ///
  /// Examples: datePickerDayOfMonth(1) in:
  ///
  ///  - US English: 1
  ///  - Korean: 1일
  String datePickerDayOfMonth(int dayIndex);

  /// Year that is shown in [CupertinoDatePicker] corresponding to the given
  /// year index.
  ///
  ///
  /// Examples: datePickerDayOfMonth(1) in:
  ///
  ///  - US English: 2018
  ///  - Korean: 2018년
  String datePickerYear(int yearIndex);

  /// Formats the date using a medium-width format.
  ///
  /// Abbreviates month and days of week. This appears in the date spinner of
  /// [CupertinoDatePicker].
  ///
  /// Examples:
  ///
  /// - US English: Wed Sep 27
  /// - Russian: ср сент. 27
  String datePickerMediumDate(DateTime date);

  /// The order of the date elements that will be shown in [CupertinoDatePicker].
  /// Can be any permutation of 'DMY' ('D': day, 'M': month, 'Y': year).
  String get datePickerDateOrder;

  /// The abbreviation for ante meridiem (before noon) shown in the time picker.
  String get anteMeridiemAbbreviation;

  /// The abbreviation for post meridiem (after noon) shown in the time picker.
  String get postMeridiemAbbreviation;

  /// Label that appears next to the hour picker in
  /// [CupertinoCountdownTimerPicker] when selected hour value is ```hour```.
  /// This function will deal with pluralization based on the ```hour``` parameter.
  String timerPickerHourLabel(int hour);

  /// Label that appears next to the minute picker in
  /// [CupertinoCountdownTimerPicker] when selected minute value is ```minute```.
  /// This function will deal with pluralization based on the ```minute``` parameter.
  String timerPickerMinuteLabel(int minute);

  /// Label that appears next to the minute picker in
  /// [CupertinoCountdownTimerPicker] when selected minute value is ```second```.
  /// This function will deal with pluralization based on the ```second``` parameter.
  String timerPickerSecondLabel(int second);

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
  /// CupertinoLocalizations.of(context).month(1);
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
  String number(int num) => num.toString();

  @override
  String datePickerMonth(int monthIndex) => _months[monthIndex - 1];

  @override
  String datePickerDayOfMonth(int dayIndex) => dayIndex.toString();

  @override
  String datePickerYear(int yearIndex) => yearIndex.toString();

  @override
  String datePickerMediumDate(DateTime date) {
    return '${_shortWeekdays[date.weekday - DateTime.monday]} '
        '${_shortMonths[date.month - DateTime.january]} '
        '${date.day}';
  }

  @override
  String get datePickerDateOrder => 'MDY';

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String timerPickerHourLabel(int hour) => hour == 1 ? 'hour' : 'hours';

  @override
  String timerPickerMinuteLabel(int minute) => 'min';

  @override
  String timerPickerSecondLabel(int second) => 'sec';

  /// Creates an object that provides US English resource values for the
  /// cupertino library widgets.
  ///
  /// The [locale] parameter is ignored.
  ///
  /// This method is typically used to create a [LocalizationsDelegate].
  static Future<CupertinoLocalizations> load(Locale locale) {
    return new SynchronousFuture<CupertinoLocalizations>(const DefaultCupertinoLocalizations());
  }

  /// A [LocalizationsDelegate] that uses [DefaultCupertinoLocalizations.load]
  /// to create an instance of this class.
  static const LocalizationsDelegate<CupertinoLocalizations> delegate = _CupertinoLocalizationsDelegate();
}
