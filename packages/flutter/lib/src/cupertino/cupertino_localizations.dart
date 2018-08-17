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
abstract class CupertinoLocalizations {
  /// The given number in local numerical alphabet.
  String number(int num);

  /// The date order of the current locale. Can be any permutation of 'DMY'.
  /// This will affect how the cupertino date picker orders its children.
  String get dateOrder;

  /// Name of the month corresponding to the given integer.
  String month(int month);

  /// Formats the date using a medium-width format.
  ///
  /// Abbreviates month and days of week. This appears in the date spinner of
  /// [CupertinoDatePicker].
  ///
  /// Examples:
  ///
  /// - US English: Wed Sep 27
  /// - Russian: ср сент. 27
  String formatMediumDate(DateTime date);

  /// The abbreviation for ante meridiem (before noon) shown in the time picker.
  String get anteMeridiemAbbreviation;

  /// The abbreviation for post meridiem (after noon) shown in the time picker.
  String get postMeridiemAbbreviation;

  /// Label for the hour picker. This appears in [CupertinoCountdownTimerPicker].
  String get hourLabel;

  /// Label for the minute picker. This appears in [CupertinoCountdownTimerPicker].
  String get minuteLabel;

  /// Label for the second picker. This appears in [CupertinoCountdownTimerPicker].
  String get secondLabel;

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
  String get dateOrder => 'MDY';

  @override
  String month(int month) => _months[month - 1];

  @override
  String formatMediumDate(DateTime date) {
    return '${_shortWeekdays[date.weekday - DateTime.monday]} '
        '${_shortMonths[date.month - DateTime.january]} '
        '${date.day}';
  }

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get hourLabel => 'hours';

  @override
  String get minuteLabel => 'min';

  @override
  String get secondLabel => 'sec';

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
