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
    @required intl.DateFormat mediumDateFormat,
    @required intl.DateFormat longDateFormat,
    @required intl.DateFormat yearMonthFormat,
    @required intl.NumberFormat decimalFormat,
    @required intl.NumberFormat twoDigitZeroPaddedFormat,
  }) : assert(localeName != null),
       _localeName = localeName,
       assert(fullYearFormat != null),
       _fullYearFormat = fullYearFormat,
       assert(mediumDateFormat != null),
       _mediumDateFormat = mediumDateFormat,
       assert(longDateFormat != null),
       _longDateFormat = longDateFormat,
       assert(yearMonthFormat != null),
       _yearMonthFormat = yearMonthFormat,
       assert(decimalFormat != null),
       _decimalFormat = decimalFormat,
       assert(twoDigitZeroPaddedFormat != null),
       _twoDigitZeroPaddedFormat = twoDigitZeroPaddedFormat;

  final String _localeName;
  final intl.DateFormat _fullYearFormat;
  final intl.DateFormat _mediumDateFormat;
  final intl.DateFormat _longDateFormat;
  final intl.DateFormat _yearMonthFormat;
  final intl.NumberFormat _decimalFormat;
  final intl.NumberFormat _twoDigitZeroPaddedFormat;


  /// The "zero" form of [selectedRowCountTitle].
  ///
  /// This form is optional.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [selectedRowCountTitleOne], the "one" form
  ///  * [selectedRowCountTitleTwo], the "two" form
  ///  * [selectedRowCountTitleFew], the "few" form
  ///  * [selectedRowCountTitleMany], the "many" form
  ///  * [selectedRowCountTitleOther], the "other" form
  @protected
  String get selectedRowCountTitleZero => null;

  /// The "one" form of [selectedRowCountTitle].
  ///
  /// This form is optional.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [selectedRowCountTitleZero], the "zero" form
  ///  * [selectedRowCountTitleTwo], the "two" form
  ///  * [selectedRowCountTitleFew], the "few" form
  ///  * [selectedRowCountTitleMany], the "many" form
  ///  * [selectedRowCountTitleOther], the "other" form
  @protected
  String get selectedRowCountTitleOne => null;

  /// The "two" form of [selectedRowCountTitle].
  ///
  /// This form is optional.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [selectedRowCountTitleZero], the "zero" form
  ///  * [selectedRowCountTitleOne], the "one" form
  ///  * [selectedRowCountTitleFew], the "few" form
  ///  * [selectedRowCountTitleMany], the "many" form
  ///  * [selectedRowCountTitleOther], the "other" form
  @protected
  String get selectedRowCountTitleTwo => null;

  /// The "few" form of [selectedRowCountTitle].
  ///
  /// This form is optional.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [selectedRowCountTitleZero], the "zero" form
  ///  * [selectedRowCountTitleOne], the "one" form
  ///  * [selectedRowCountTitleTwo], the "two" form
  ///  * [selectedRowCountTitleMany], the "many" form
  ///  * [selectedRowCountTitleOther], the "other" form
  @protected
  String get selectedRowCountTitleFew => null;

  /// The "many" form of [selectedRowCountTitle].
  ///
  /// This form is optional.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [selectedRowCountTitleZero], the "zero" form
  ///  * [selectedRowCountTitleOne], the "one" form
  ///  * [selectedRowCountTitleTwo], the "two" form
  ///  * [selectedRowCountTitleFew], the "few" form
  ///  * [selectedRowCountTitleOther], the "other" form
  @protected
  String get selectedRowCountTitleMany => null;

  /// The "other" form of [selectedRowCountTitle].
  ///
  /// This form is required.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [selectedRowCountTitleZero], the "zero" form
  ///  * [selectedRowCountTitleOne], the "one" form
  ///  * [selectedRowCountTitleTwo], the "two" form
  ///  * [selectedRowCountTitleFew], the "few" form
  ///  * [selectedRowCountTitleMany], the "many" form
  @protected
  String get selectedRowCountTitleOther;

  @override
  String selectedRowCountTitle(int selectedRowCount) {
    return intl.Intl.pluralLogic(
      selectedRowCount,
      zero: selectedRowCountTitleZero,
      one: selectedRowCountTitleOne,
      two: selectedRowCountTitleTwo,
      few: selectedRowCountTitleFew,
      many: selectedRowCountTitleMany,
      other: selectedRowCountTitleOther,
      locale: _localeName,
    ).replaceFirst(r'$selectedRowCount', formatDecimal(selectedRowCount));
  }

  /// The format to use for [timeOfDayFormat].
  @protected
  TimeOfDayFormat get timeOfDayFormatRaw;

  /// The [TimeOfDayFormat] corresponding to one of the following supported
  /// patterns:
  ///
  ///  * `HH:mm`
  ///  * `HH.mm`
  ///  * `HH 'h' mm`
  ///  * `HH:mm น.`
  ///  * `H:mm`
  ///  * `h:mm a`
  ///  * `a h:mm`
  ///  * `ah:mm`
  ///
  /// See also:
  ///
  ///  * <http://demo.icu-project.org/icu-bin/locexp?d_=en&_=en_US>, which shows
  ///    the short time pattern used in the `en_US` locale.
  @override
  TimeOfDayFormat timeOfDayFormat({ bool alwaysUse24HourFormat = false }) {
    assert(alwaysUse24HourFormat != null);
    if (alwaysUse24HourFormat)
      return _get24HourVersionOf(timeOfDayFormatRaw);
    return timeOfDayFormatRaw;
  }

  /// The "zero" form of [remainingTextFieldCharacterCount].
  ///
  /// This form is required.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [remainingTextFieldCharacterCountZero], the "zero" form
  ///  * [remainingTextFieldCharacterCountOne], the "one" form
  ///  * [remainingTextFieldCharacterCountTwo], the "two" form
  ///  * [remainingTextFieldCharacterCountFew], the "few" form
  ///  * [remainingTextFieldCharacterCountMany], the "many" form
  ///  * [remainingTextFieldCharacterCountOther], the "other" form
  @protected
  String get remainingTextFieldCharacterCountZero;

  /// The "one" form of [remainingTextFieldCharacterCount].
  ///
  /// This form is optional.
  ///
  /// See also:
  ///
  ///  * [remainingTextFieldCharacterCountZero], the "zero" form
  ///  * [remainingTextFieldCharacterCountOne], the "one" form
  ///  * [remainingTextFieldCharacterCountTwo], the "two" form
  ///  * [remainingTextFieldCharacterCountFew], the "few" form
  ///  * [remainingTextFieldCharacterCountMany], the "many" form
  ///  * [remainingTextFieldCharacterCountOther], the "other" form
  @protected
  String get remainingTextFieldCharacterCountOne => null;

  /// The "two" form of [remainingTextFieldCharacterCount].
  ///
  /// This form is optional.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [remainingTextFieldCharacterCountZero], the "zero" form
  ///  * [remainingTextFieldCharacterCountOne], the "one" form
  ///  * [remainingTextFieldCharacterCountTwo], the "two" form
  ///  * [remainingTextFieldCharacterCountFew], the "few" form
  ///  * [remainingTextFieldCharacterCountMany], the "many" form
  ///  * [remainingTextFieldCharacterCountOther], the "other" form
  @protected
  String get remainingTextFieldCharacterCountTwo => null;

  /// The "many" form of [remainingTextFieldCharacterCount].
  ///
  /// This form is optional.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [remainingTextFieldCharacterCountZero], the "zero" form
  ///  * [remainingTextFieldCharacterCountOne], the "one" form
  ///  * [remainingTextFieldCharacterCountTwo], the "two" form
  ///  * [remainingTextFieldCharacterCountFew], the "few" form
  ///  * [remainingTextFieldCharacterCountMany], the "many" form
  ///  * [remainingTextFieldCharacterCountOther], the "other" form
  @protected
  String get remainingTextFieldCharacterCountMany => null;

  /// The "few" form of [remainingTextFieldCharacterCount].
  ///
  /// This form is optional.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [remainingTextFieldCharacterCountZero], the "zero" form
  ///  * [remainingTextFieldCharacterCountOne], the "one" form
  ///  * [remainingTextFieldCharacterCountTwo], the "two" form
  ///  * [remainingTextFieldCharacterCountFew], the "few" form
  ///  * [remainingTextFieldCharacterCountMany], the "many" form
  ///  * [remainingTextFieldCharacterCountOther], the "other" form
  @protected
  String get remainingTextFieldCharacterCountFew => null;

  /// The "other" form of [remainingTextFieldCharacterCount].
  ///
  /// This form is required.
  ///
  /// See also:
  ///
  ///  * [Intl.plural], to which this form is passed.
  ///  * [remainingTextFieldCharacterCountZero], the "zero" form
  ///  * [remainingTextFieldCharacterCountOne], the "one" form
  ///  * [remainingTextFieldCharacterCountTwo], the "two" form
  ///  * [remainingTextFieldCharacterCountFew], the "few" form
  ///  * [remainingTextFieldCharacterCountMany], the "many" form
  ///  * [remainingTextFieldCharacterCountOther], the "other" form
  @protected
  String get remainingTextFieldCharacterCountOther;

  @override
  String remainingTextFieldCharacterCount(int remainingCount) {
    return intl.Intl.pluralLogic(
      remainingCount,
      zero: remainingTextFieldCharacterCountZero,
      one: remainingTextFieldCharacterCountOne,
      two: remainingTextFieldCharacterCountTwo,
      many: remainingTextFieldCharacterCountMany,
      few: remainingTextFieldCharacterCountFew,
      other: remainingTextFieldCharacterCountOther,
      locale: _localeName,
    ).replaceFirst(r'$remainingCount', formatDecimal(remainingCount));
  }

  @override
  ScriptCategory get scriptCategory;

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

/// Finds the [TimeOfDayFormat] to use instead of the `original` when the
/// `original` uses 12-hour format and [MediaQueryData.alwaysUse24HourFormat]
/// is true.
TimeOfDayFormat _get24HourVersionOf(TimeOfDayFormat original) {
  switch (original) {
    case TimeOfDayFormat.HH_colon_mm:
    case TimeOfDayFormat.HH_dot_mm:
    case TimeOfDayFormat.frenchCanadian:
    case TimeOfDayFormat.H_colon_mm:
      return original;
    case TimeOfDayFormat.h_colon_mm_space_a:
    case TimeOfDayFormat.a_space_h_colon_mm:
      return TimeOfDayFormat.HH_colon_mm;
  }
  return TimeOfDayFormat.HH_colon_mm;
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
