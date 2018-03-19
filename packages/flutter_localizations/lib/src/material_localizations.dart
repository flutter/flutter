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

import 'l10n/localizations.dart' show TranslationBundle, translationBundleForLocale;
import 'widgets_localizations.dart';

// Watch out: the supported locales list in the doc comment below must be kept
// in sync with the list we test, see test/translations_test.dart, and of course
// the acutal list of supported locales in _MaterialLocalizationsDelegate.

/// Localized strings for the material widgets.
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
///     const Locale('en', 'US'), // English
///     const Locale('he', 'IL'), // Hebrew
///     // ...
///   ],
///   // ...
/// )
/// ```
///
/// This class supports locales with the following [Locale.languageCode]s:
///
///   * ar - Arabic
///   * de - German
///   * en - English
///   * es - Spanish
///   * fa - Farsi
///   * fr - French
///   * he - Hebrew
///   * it - Italian
///   * ja - Japanese
///   * ko - Korean
///   * nl - Dutch
///   * pl - Polish
///   * ps - Pashto
///   * pt - Portuguese
///   * ro - Romanian
///   * ru - Russian
///   * th - Thai
///   * tr - Turkish
///   * ur - Urdu
///   * zh - Simplified Chinese
///
/// See also:
///
///  * The Flutter Internationalization Tutorial,
///    <https://flutter.io/tutorials/internationalization/>.
///  * [DefaultMaterialLocalizations], which only provides US English translations.
class GlobalMaterialLocalizations implements MaterialLocalizations {
  /// Constructs an object that defines the material widgets' localized strings
  /// for the given `locale`.
  ///
  /// [LocalizationsDelegate] implementations typically call the static [load]
  /// function, rather than constructing this class directly.
  GlobalMaterialLocalizations(this.locale)
      : assert(locale != null),
        _localeName = _computeLocaleName(locale) {
    _loadDateIntlDataIfNotLoaded();

    _translationBundle = translationBundleForLocale(locale);
    assert(_translationBundle != null);

    const String kMediumDatePattern = 'E, MMM\u00a0d';
    if (intl.DateFormat.localeExists(_localeName)) {
      _fullYearFormat = new intl.DateFormat.y(_localeName);
      _mediumDateFormat = new intl.DateFormat(kMediumDatePattern, _localeName);
      _longDateFormat = new intl.DateFormat.yMMMMEEEEd(_localeName);
      _yearMonthFormat = new intl.DateFormat('yMMMM', _localeName);
    } else if (intl.DateFormat.localeExists(locale.languageCode)) {
      _fullYearFormat = new intl.DateFormat.y(locale.languageCode);
      _mediumDateFormat = new intl.DateFormat(kMediumDatePattern, locale.languageCode);

      _longDateFormat = new intl.DateFormat.yMMMMEEEEd(locale.languageCode);
      _yearMonthFormat = new intl.DateFormat('yMMMM', locale.languageCode);
    } else {
      _fullYearFormat = new intl.DateFormat.y();
      _mediumDateFormat = new intl.DateFormat(kMediumDatePattern);
      _longDateFormat = new intl.DateFormat.yMMMMEEEEd();
      _yearMonthFormat = new intl.DateFormat('yMMMM');
    }

    if (intl.NumberFormat.localeExists(_localeName)) {
      _decimalFormat = new intl.NumberFormat.decimalPattern(_localeName);
      _twoDigitZeroPaddedFormat = new intl.NumberFormat('00', _localeName);
    } else if (intl.NumberFormat.localeExists(locale.languageCode)) {
      _decimalFormat = new intl.NumberFormat.decimalPattern(locale.languageCode);
      _twoDigitZeroPaddedFormat = new intl.NumberFormat('00', locale.languageCode);
    } else {
      _decimalFormat = new intl.NumberFormat.decimalPattern();
      _twoDigitZeroPaddedFormat = new intl.NumberFormat('00');
    }
  }

  /// The locale for which the values of this class's localized resources
  /// have been translated.
  final Locale locale;

  final String _localeName;

  TranslationBundle _translationBundle;

  intl.NumberFormat _decimalFormat;

  intl.NumberFormat _twoDigitZeroPaddedFormat;

  intl.DateFormat _fullYearFormat;

  intl.DateFormat _mediumDateFormat;

  intl.DateFormat _longDateFormat;

  intl.DateFormat _yearMonthFormat;

  static String _computeLocaleName(Locale locale) {
    final String localeName = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    return intl.Intl.canonicalizedLocale(localeName);
  }

  @override
  String formatHour(TimeOfDay timeOfDay, { bool alwaysUse24HourFormat: false }) {
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
    return _fullYearFormat.dateSymbols.NARROWWEEKDAYS;
  }

  @override
  int get firstDayOfWeekIndex => (_fullYearFormat.dateSymbols.FIRSTDAYOFWEEK + 1) % 7;

  @override
  String formatDecimal(int number) {
    return _decimalFormat.format(number);
  }

  @override
  String formatTimeOfDay(TimeOfDay timeOfDay, { bool alwaysUse24HourFormat: false }) {
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

  @override
  String get openAppDrawerTooltip => _translationBundle.openAppDrawerTooltip;

  @override
  String get backButtonTooltip => _translationBundle.backButtonTooltip;

  @override
  String get closeButtonTooltip => _translationBundle.closeButtonTooltip;

  @override
  String get deleteButtonTooltip => _translationBundle.deleteButtonTooltip;

  @override
  String get nextMonthTooltip => _translationBundle.nextMonthTooltip;

  @override
  String get previousMonthTooltip => _translationBundle.previousMonthTooltip;

  @override
  String get nextPageTooltip => _translationBundle.nextPageTooltip;

  @override
  String get previousPageTooltip => _translationBundle.previousPageTooltip;

  @override
  String get showMenuTooltip => _translationBundle.showMenuTooltip;

  @override
  String aboutListTileTitle(String applicationName) {
    final String text = _translationBundle.aboutListTileTitle;
    return text.replaceFirst(r'$applicationName', applicationName);
  }

  @override
  String get licensesPageTitle => _translationBundle.licensesPageTitle;

  @override
  String pageRowsInfoTitle(int firstRow, int lastRow, int rowCount, bool rowCountIsApproximate) {
    String text = rowCountIsApproximate ? _translationBundle.pageRowsInfoTitleApproximate : null;
    text ??= _translationBundle.pageRowsInfoTitle;
    assert(text != null, 'A $locale localization was not found for pageRowsInfoTitle or pageRowsInfoTitleApproximate');
    // TODO(hansmuller): this could be more efficient.
    return text
      .replaceFirst(r'$firstRow', formatDecimal(firstRow))
      .replaceFirst(r'$lastRow', formatDecimal(lastRow))
      .replaceFirst(r'$rowCount', formatDecimal(rowCount));
  }

  @override
  String get rowsPerPageTitle => _translationBundle.rowsPerPageTitle;

  @override
  String tabLabel({int tabIndex, int tabCount}) {
    assert(tabIndex >= 1);
    assert(tabCount >= 1);
    final String template = _translationBundle.tabLabel;
    return template
      .replaceFirst(r'$tabIndex', formatDecimal(tabIndex))
      .replaceFirst(r'$tabCount', formatDecimal(tabCount));
  }

  @override
  String selectedRowCountTitle(int selectedRowCount) {
    // TODO(hmuller): the rules for mapping from an integer value to
    // "one" or "two" etc. are locale specific and an additional "few" category
    // is needed. See http://cldr.unicode.org/index/cldr-spec/plural-rules
    String text;
    if (selectedRowCount == 0)
      text = _translationBundle.selectedRowCountTitleZero;
    else if (selectedRowCount == 1)
      text = _translationBundle.selectedRowCountTitleOne;
    else if (selectedRowCount == 2)
      text = _translationBundle.selectedRowCountTitleTwo;
    else if (selectedRowCount > 2)
      text = _translationBundle.selectedRowCountTitleMany;
    text ??= _translationBundle.selectedRowCountTitleOther;
    assert(text != null);

    return text.replaceFirst(r'$selectedRowCount', formatDecimal(selectedRowCount));
  }

  @override
  String get cancelButtonLabel => _translationBundle.cancelButtonLabel;

  @override
  String get closeButtonLabel => _translationBundle.closeButtonLabel;

  @override
  String get continueButtonLabel => _translationBundle.continueButtonLabel;

  @override
  String get copyButtonLabel => _translationBundle.copyButtonLabel;

  @override
  String get cutButtonLabel => _translationBundle.cutButtonLabel;

  @override
  String get okButtonLabel => _translationBundle.okButtonLabel;

  @override
  String get pasteButtonLabel => _translationBundle.pasteButtonLabel;

  @override
  String get selectAllButtonLabel => _translationBundle.selectAllButtonLabel;

  @override
  String get viewLicensesButtonLabel => _translationBundle.viewLicensesButtonLabel;

  @override
  String get anteMeridiemAbbreviation => _translationBundle.anteMeridiemAbbreviation;

  @override
  String get postMeridiemAbbreviation => _translationBundle.postMeridiemAbbreviation;

  @override
  String get timePickerHourModeAnnouncement => _translationBundle.timePickerHourModeAnnouncement;

  @override
  String get timePickerMinuteModeAnnouncement => _translationBundle.timePickerMinuteModeAnnouncement;

  @override
  String get modalBarrierDismissLabel => _translationBundle.modalBarrierDismissLabel;

  @override
  String get signedInLabel => _translationBundle.signedInLabel;

  @override
  String get hideAccountsLabel => _translationBundle.hideAccountsLabel;

  @override
  String get showAccountsLabel => _translationBundle.showAccountsLabel;

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
  ///  * http://demo.icu-project.org/icu-bin/locexp?d_=en&_=en_US shows the
  ///    short time pattern used in locale en_US
  @override
  TimeOfDayFormat timeOfDayFormat({ bool alwaysUse24HourFormat: false }) {
    final String icuShortTimePattern = _translationBundle.timeOfDayFormat;

    assert(() {
      if (!_icuTimeOfDayToEnum.containsKey(icuShortTimePattern)) {
        throw new FlutterError(
          '"$icuShortTimePattern" is not one of the ICU short time patterns '
          'supported by the material library. Here is the list of supported '
          'patterns:\n  ' +
          _icuTimeOfDayToEnum.keys.join('\n  ')
        );
      }
      return true;
    }());

    final TimeOfDayFormat icuFormat = _icuTimeOfDayToEnum[icuShortTimePattern];

    if (alwaysUse24HourFormat)
      return _get24HourVersionOf(icuFormat);

    return icuFormat;
  }

  /// Looks up text geometry defined in [MaterialTextGeometry].
  @override
  TextTheme get localTextGeometry => MaterialTextGeometry.forScriptCategory(_translationBundle.scriptCategory);

  /// Creates an object that provides localized resource values for the
  /// for the widgets of the material library.
  ///
  /// This method is typically used to create a [LocalizationsDelegate].
  /// The [MaterialApp] does so by default.
  static Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(new GlobalMaterialLocalizations(locale));
  }

  /// A [LocalizationsDelegate] that uses [GlobalMaterialLocalizations.load]
  /// to create an instance of this class.
  ///
  /// Most internationalized apps will use [GlobalMaterialLocalizations.delegates]
  /// as the value of [MaterialApp.localizationsDelegates] to include
  /// the localizations for both the material and widget libraries.
  static const LocalizationsDelegate<MaterialLocalizations> delegate = const _MaterialLocalizationsDelegate();

  /// A value for [MaterialApp.localizationsDelegates] that's typically used by
  /// internationalized apps.
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
  static const List<LocalizationsDelegate<dynamic>> delegates = const <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}

const Map<String, TimeOfDayFormat> _icuTimeOfDayToEnum = const <String, TimeOfDayFormat>{
  'HH:mm': TimeOfDayFormat.HH_colon_mm,
  'HH.mm': TimeOfDayFormat.HH_dot_mm,
  "HH 'h' mm": TimeOfDayFormat.frenchCanadian,
  'HH:mm น.': TimeOfDayFormat.HH_colon_mm,
  'H:mm': TimeOfDayFormat.H_colon_mm,
  'h:mm a': TimeOfDayFormat.h_colon_mm_space_a,
  'a h:mm': TimeOfDayFormat.a_space_h_colon_mm,
  'ah:mm': TimeOfDayFormat.a_space_h_colon_mm,
};

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

/// Tracks if date i18n data has been loaded.
bool _dateIntlDataInitialized = false;

/// Loads i18n data for dates if it hasn't be loaded yet.
///
/// Only the first invocation of this function has the effect of loading the
/// data. Subsequent invocations have no effect.
void _loadDateIntlDataIfNotLoaded() {
  if (!_dateIntlDataInitialized) {
    date_localizations.dateSymbols.forEach((String locale, dynamic data) {
      assert(date_localizations.datePatterns.containsKey(locale));
      final intl.DateSymbols symbols = new intl.DateSymbols.deserializeFromMap(data);
      date_symbol_data_custom.initializeDateFormattingCustom(
        locale: locale,
        symbols: symbols,
        patterns: date_localizations.datePatterns[locale],
      );
    });
    _dateIntlDataInitialized = true;
  }
}

class _MaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsDelegate();

  // Watch out: this list must match the one in the GlobalMaterialLocalizations
  // class doc and the list we test, see test/translations_test.dart.
  static const List<String> _supportedLanguages = const <String>[
    'ar', // Arabic
    'de', // German
    'en', // English
    'es', // Spanish
    'fa', // Farsi (Persian)
    'fr', // French
    'he', // Hebrew
    'it', // Italian
    'ja', // Japanese
    'ko', // Korean
    'nl', // Dutch
    'pl', // Polish
    'ps', // Pashto
    'pt', // Portugese
    'ro', // Romanian
    'ru', // Russian
    'th', // Thai
    'tr', // Turkish
    'ur', // Urdu
    'zh', // Chinese (simplified)
  ];

  @override
  bool isSupported(Locale locale) => _supportedLanguages.contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) => GlobalMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_MaterialLocalizationsDelegate old) => false;
}
