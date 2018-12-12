// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import 'l10n/date_localizations.dart' as date_localizations;

import 'l10n/localizations.dart';
import 'widgets_localizations.dart';

/// Implementation of localized strings for the material widgets using the
/// `intl` package for date and time formatting.
///
/// ## Supported languages
///
/// This class supports locales with the following [Locale.languageCode]s:
///
/// {@macro flutter.localizations.languages}
///
/// This list is available programatically via [kSupportedLanguages].
///
/// ## Sample code
///
/// To include the localizations provided by this class in a [MaterialApp],
/// add [GlobalMaterialLocalizations.delegates] to
/// [MaterialApp.localizationsDelegates], and specify the locales your
/// app supports with [MaterialApp.supportedLocales]:
///
/// ```dart
/// new MaterialApp(
///   localizationsDelegates: GlobalMaterialLocalizations.delegates,
///   supportedLocales: [
///     const Locale('en', 'US'), // American English
///     const Locale('he', 'IL'), // Israeli Hebrew
///     // ...
///   ],
///   // ...
/// )
/// ```
///
/// ## Overriding translations
///
/// To create a translation that's similar to an existing language's translation
/// but has slightly different strings, subclass the relevant translation
/// directly and then create a [LocalizationsDelegate<MaterialLocalizations>]
/// subclass to define how to load it.
///
/// Avoid subclassing an unrelated language (for example, subclassing
/// [MaterialLocalizationEn] and then passing a non-English `localeName` to the
/// constructor). Doing so will cause confusion for locale-specific behaviors;
/// in particular, translations that use the `localeName` for determining how to
/// pluralize will end up doing invalid things. Subclassing an existing
/// language's translations is only suitable for making small changes to the
/// existing strings. For providing a new language entirely, implement
/// [MaterialLocalizations] directly.
///
/// See also:
///
///  * The Flutter Internationalization Tutorial,
///    <https://flutter.io/tutorials/internationalization/>.
///  * [DefaultMaterialLocalizations], which only provides US English translations.
abstract class GlobalMaterialLocalizations implements MaterialLocalizations {
  /// Initializes an object that defines the material widgets' localized strings
  /// for the given `locale`.
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
  const GlobalMaterialLocalizations({
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

  @override
  String formatHour(TimeOfDay timeOfDay, { bool alwaysUse24HourFormat = false }) {
    switch (hourFormat(of: timeOfDayFormat(alwaysUse24HourFormat: alwaysUse24HourFormat))) {
      case HourFormat.HH:
        return _twoDigitZeroPaddedFormat.format(timeOfDay.hour);
      case HourFormat.H:
        return formatDecimal(timeOfDay.hour);
      case HourFormat.h:
        final int hour = timeOfDay.hourOfPeriod;
        return formatDecimal(hour == 0 ? 12 : hour);
    }
    return null;
  }

  @override
  String formatMinute(TimeOfDay timeOfDay) {
    return _twoDigitZeroPaddedFormat.format(timeOfDay.minute);
  }

  @override
  String formatYear(DateTime date) {
    return _fullYearFormat.format(date);
  }

  @override
  String formatMediumDate(DateTime date) {
    return _mediumDateFormat.format(date);
  }

  @override
  String formatFullDate(DateTime date) {
    return _longDateFormat.format(date);
  }

  @override
  String formatMonthYear(DateTime date) {
    return _yearMonthFormat.format(date);
  }

  @override
  List<String> get narrowWeekdays {
    return _longDateFormat.dateSymbols.NARROWWEEKDAYS;
  }

  @override
  int get firstDayOfWeekIndex => (_longDateFormat.dateSymbols.FIRSTDAYOFWEEK + 1) % 7;

  @override
  String formatDecimal(int number) {
    return _decimalFormat.format(number);
  }

  @override
  String formatTimeOfDay(TimeOfDay timeOfDay, { bool alwaysUse24HourFormat = false }) {
    // Not using intl.DateFormat for two reasons:
    //
    // - DateFormat supports more formats than our material time picker does,
    //   and we want to be consistent across time picker format and the string
    //   formatting of the time of day.
    // - DateFormat operates on DateTime, which is sensitive to time eras and
    //   time zones, while here we want to format hour and minute within one day
    //   no matter what date the day falls on.
    final String hour = formatHour(timeOfDay, alwaysUse24HourFormat: alwaysUse24HourFormat);
    final String minute = formatMinute(timeOfDay);
    switch (timeOfDayFormat(alwaysUse24HourFormat: alwaysUse24HourFormat)) {
      case TimeOfDayFormat.h_colon_mm_space_a:
        return '$hour:$minute ${_formatDayPeriod(timeOfDay)}';
      case TimeOfDayFormat.H_colon_mm:
      case TimeOfDayFormat.HH_colon_mm:
        return '$hour:$minute';
      case TimeOfDayFormat.HH_dot_mm:
        return '$hour.$minute';
      case TimeOfDayFormat.a_space_h_colon_mm:
        return '${_formatDayPeriod(timeOfDay)} $hour:$minute';
      case TimeOfDayFormat.frenchCanadian:
        return '$hour h $minute';
    }
    return null;
  }

  String _formatDayPeriod(TimeOfDay timeOfDay) {
    switch (timeOfDay.period) {
      case DayPeriod.am:
        return anteMeridiemAbbreviation;
      case DayPeriod.pm:
        return postMeridiemAbbreviation;
    }
    return null;
  }

  /// The raw version of [aboutListTileTitle], with `$applicationName` verbatim
  /// in the string.
  @protected
  String get aboutListTileTitleRaw;

  @override
  String aboutListTileTitle(String applicationName) {
    final String text = aboutListTileTitleRaw;
    return text.replaceFirst(r'$applicationName', applicationName);
  }

  /// The raw version of [pageRowsInfoTitle], with `$firstRow`, `$lastRow`' and
  /// `$rowCount` verbatim in the string, for the case where the value is
  /// approximate.
  @protected
  String get pageRowsInfoTitleApproximateRaw;

  /// The raw version of [pageRowsInfoTitle], with `$firstRow`, `$lastRow`' and
  /// `$rowCount` verbatim in the string, for the case where the value is
  /// precise.
  @protected
  String get pageRowsInfoTitleRaw;

  @override
  String pageRowsInfoTitle(int firstRow, int lastRow, int rowCount, bool rowCountIsApproximate) {
    String text = rowCountIsApproximate ? pageRowsInfoTitleApproximateRaw : null;
    text ??= pageRowsInfoTitleRaw;
    assert(text != null, 'A $_localeName localization was not found for pageRowsInfoTitle or pageRowsInfoTitleApproximate');
    return text
      .replaceFirst(r'$firstRow', formatDecimal(firstRow))
      .replaceFirst(r'$lastRow', formatDecimal(lastRow))
      .replaceFirst(r'$rowCount', formatDecimal(rowCount));
  }

  /// The raw version of [tabLabel], with `$tabIndex` and `$tabCount` verbatim
  /// in the string.
  @protected
  String get tabLabelRaw;

  @override
  String tabLabel({int tabIndex, int tabCount}) {
    assert(tabIndex >= 1);
    assert(tabCount >= 1);
    final String template = tabLabelRaw;
    return template
      .replaceFirst(r'$tabIndex', formatDecimal(tabIndex))
      .replaceFirst(r'$tabCount', formatDecimal(tabCount));
  }

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

class _MaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => kSupportedLanguages.contains(locale.languageCode);

  /// Tracks if date i18n data has been loaded.
  static bool _dateIntlDataInitialized = false;

  /// Loads i18n data for dates if it hasn't be loaded yet.
  ///
  /// Only the first invocation of this function has the effect of loading the
  /// data. Subsequent invocations have no effect.
  static void _loadDateIntlDataIfNotLoaded() {
    if (!_dateIntlDataInitialized) {
      // TODO(garyq): Add support for scriptCodes. Do not strip scriptCode from string.

      // Keep track of initialzed locales, or will fail on attempted double init.
      // This can only happen if a locale with a stripped scriptCode has already
      // been initialzed. This should be removed when scriptCode stripping is removed.
      final Set<String> initializedLocales = Set<String>();
      date_localizations.dateSymbols.forEach((String locale, dynamic data) {
        // Strip scriptCode from the locale, as we do not distinguish between scripts
        // for dates.
        final List<String> codes = locale.split('_');
        String countryCode;
        if (codes.length == 2) {
          countryCode = codes[1].length < 4 ? codes[1] : null;
        } else if (codes.length == 3) {
          countryCode = codes[1].length < codes[2].length ? codes[1] : codes[2];
        }
        locale = codes[0] + (countryCode != null ? '_' + countryCode : '');
        if (initializedLocales.contains(locale))
          return;
        initializedLocales.add(locale);
        // Perform initialization.
        assert(date_localizations.datePatterns.containsKey(locale));
        final intl.DateSymbols symbols = intl.DateSymbols.deserializeFromMap(data);
        date_symbol_data_custom.initializeDateFormattingCustom(
          locale: locale,
          symbols: symbols,
          patterns: date_localizations.datePatterns[locale],
        );
      });
      _dateIntlDataInitialized = true;
    }
  }

  static final Map<Locale, Future<MaterialLocalizations>> _loadedTranslations = <Locale, Future<MaterialLocalizations>>{};

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    assert(isSupported(locale));
    return _loadedTranslations.putIfAbsent(locale, () {
      _loadDateIntlDataIfNotLoaded();

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

      return SynchronousFuture<MaterialLocalizations>(getTranslation(
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
  bool shouldReload(_MaterialLocalizationsDelegate old) => false;

  @override
  String toString() => 'GlobalMaterialLocalizations.delegate(${kSupportedLanguages.length} locales)';
}
