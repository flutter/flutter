// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/date_symbol_data_local.dart' as intl_local_date_data;

import 'i18n/localizations.dart';
import 'time.dart';
import 'typography.dart';

/// Defines the localized resource values used by the Material widgets.
///
/// See also:
///
///  * [DefaultMaterialLocalizations], which implements this interface
///    and supports a variety of locales.
abstract class MaterialLocalizations {
  /// The tooltip for the leading [AppBar] menu (aka 'hamburger') button.
  String get openAppDrawerTooltip;

  /// The [BackButton]'s tooltip.
  String get backButtonTooltip;

  /// The [CloseButton]'s tooltip.
  String get closeButtonTooltip;

  /// The tooltip for the [MonthPicker]'s "next month" button.
  String get nextMonthTooltip;

  /// The tooltip for the [MonthPicker]'s "previous month" button.
  String get previousMonthTooltip;

  /// The tooltip for the [PaginatedDataTable]'s "next page" button.
  String get nextPageTooltip;

  /// The tooltip for the [PaginatedDataTable]'s "previous page" button.
  String get previousPageTooltip;

  /// The default [PopupMenuButton] tooltip.
  String get showMenuTooltip;

  /// The default title for [AboutListTile].
  String aboutListTileTitle(String applicationName);

  /// Title for the [LicensePage] widget.
  String get licensesPageTitle;

  /// Title for the [PaginatedDataTable]'s row info footer.
  String pageRowsInfoTitle(int firstRow, int lastRow, int rowCount, bool rowCountIsApproximate);

  /// Title for the [PaginatedDataTable]'s "rows per page" footer.
  String get rowsPerPageTitle;

  /// Title for the [PaginatedDataTable]'s selected row count header.
  String selectedRowCountTitle(int selectedRowCount);

  /// Label for "cancel" buttons and menu items.
  String get cancelButtonLabel;

  /// Label for "close" buttons and menu items.
  String get closeButtonLabel;

  /// Label for "continue" buttons and menu items.
  String get continueButtonLabel;

  /// Label for "copy" edit buttons and menu items.
  String get copyButtonLabel;

  /// Label for "cut" edit buttons and menu items.
  String get cutButtonLabel;

  /// Label for OK buttons and menu items.
  String get okButtonLabel;

  /// Label for "paste" edit buttons and menu items.
  String get pasteButtonLabel;

  /// Label for "select all" edit buttons and menu items.
  String get selectAllButtonLabel;

  /// Label for the [AboutDialog] button that shows the [LicensePage].
  String get viewLicensesButtonLabel;

  /// The abbreviation for ante meridiem (before noon) shown in the time picker.
  String get anteMeridiemAbbreviation;

  /// The abbreviation for post meridiem (after noon) shown in the time picker.
  String get postMeridiemAbbreviation;

  /// The format used to lay out the time picker.
  ///
  /// The documentation for [TimeOfDayFormat] enum values provides details on
  /// each supported layout.
  TimeOfDayFormat get timeOfDayFormat;

  /// Provides geometric text preferences for the current locale.
  ///
  /// This text theme is incomplete. For example, it lacks text color
  /// information. This theme must be merged with another text theme that
  /// provides the missing values. The text styles provided by this theme have
  /// their [TextStyle.inherit] property set to true.
  ///
  /// Typically a complete theme is obtained via [Theme.of], which can be
  /// localized using the [Localizations] widget.
  ///
  /// See also: https://material.io/guidelines/style/typography.html
  TextTheme get localTextGeometry;

  /// Formats [TimeOfDay.hour] in the given time of day according to the value
  /// of [timeOfDayFormat].
  String formatHour(TimeOfDay timeOfDay);

  /// Formats [TimeOfDay.minute] in the given time of day according to the value
  /// of [timeOfDayFormat].
  String formatMinute(TimeOfDay timeOfDay);

  /// Formats [timeOfDay] according to the value of [timeOfDayFormat].
  String formatTimeOfDay(TimeOfDay timeOfDay);

  /// Full unabbreviated year format, e.g. 2017 rather than 17.
  String formatYear(DateTime date);

  /// Formats the date using a medium-width format.
  ///
  /// Abbreviates month and days of week. This appears in the header of the date
  /// picker invoked using [showDatePicker].
  ///
  /// Examples:
  ///
  /// - US English: Wed, Sep 27
  /// - Russian: ср, сент. 27
  String formatMediumDate(DateTime date);

  /// Formats the month and the year of the given [date].
  ///
  /// The returned string does not contain the day of the month. This appears
  /// in the date picker invoked using [showDatePicker].
  String formatMonthYear(DateTime date);

  /// List of week day names in narrow format, usually 1- or 2-letter
  /// abbreviations of full names.
  ///
  /// The list begins with the value corresponding to Sunday and ends with
  /// Saturday. Use [firstDayOfWeekIndex] to find the first day of week in this
  /// list.
  ///
  /// Examples:
  ///
  /// - US English: S, M, T, W, T, F, S
  /// - Russian: вс, пн, вт, ср, чт, пт, сб - notice that the list begins with
  ///   вс (Sunday) even though the first day of week for Russian is Monday.
  List<String> get narrowWeekDays;

  /// Index of the first day of week, where 0 points to Sunday, and 6 points to
  /// Saturday.
  ///
  /// This getter is compatible with [narrowWeekDays]. For example:
  ///
  /// ```dart
  /// var localizations = MaterialLocalizations.of(context);
  /// // The name of the first day of week for the current locale.
  /// var firstDayOfWeek = localizations.narrowWeekDays[localizations.firstDayOfWeekIndex];
  /// ```
  int get firstDayOfWeekIndex;

  /// The `MaterialLocalizations` from the closest [Localizations] instance
  /// that encloses the given context.
  ///
  /// This method is just a convenient shorthand for:
  /// `Localizations.of<MaterialLocalizations>(context, MaterialLocalizations)`.
  ///
  /// References to the localized resources defined by this class are typically
  /// written in terms of this method. For example:
  ///
  /// ```dart
  /// tooltip: MaterialLocalizations.of(context).backButtonTooltip,
  /// ```
  static MaterialLocalizations of(BuildContext context) {
    return Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
  }
}

/// Localized strings for the material widgets.
class DefaultMaterialLocalizations implements MaterialLocalizations {
  /// Constructs an object that defines the material widgets' localized strings
  /// for the given `locale`.
  ///
  /// [LocalizationsDelegate] implementations typically call the static [load]
  /// function, rather than constructing this class directly.
  DefaultMaterialLocalizations(this.locale)
      : assert(locale != null),
        this._localeName = _computeLocaleName(locale) {
    _loadDateIntlDataIfNotLoaded();

    if (localizations.containsKey(locale.languageCode))
      _nameToValue.addAll(localizations[locale.languageCode]);
    if (localizations.containsKey(_localeName))
      _nameToValue.addAll(localizations[_localeName]);

    const String kMediumDatePattern = 'E, MMM\u00a0d';
    if (intl.DateFormat.localeExists(_localeName)) {
      _fullYearFormat = new intl.DateFormat.y(_localeName);
      _mediumDateFormat = new intl.DateFormat(kMediumDatePattern, _localeName);
      _yearMonthFormat = new intl.DateFormat('yMMMM', _localeName);
    } else if (intl.DateFormat.localeExists(locale.languageCode)) {
      _fullYearFormat = new intl.DateFormat.y(locale.languageCode);
      _mediumDateFormat = new intl.DateFormat(kMediumDatePattern, locale.languageCode);
      _yearMonthFormat = new intl.DateFormat('yMMMM', locale.languageCode);
    } else {
      _fullYearFormat = new intl.DateFormat.y();
      _mediumDateFormat = new intl.DateFormat(kMediumDatePattern);
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

  final Map<String, String> _nameToValue = <String, String>{};

  /// Formats numbers using variable length format with no zero padding.
  ///
  /// See also [_twoDigitZeroPaddedFormat].
  intl.NumberFormat _decimalFormat;

  /// Formats numbers as two-digits.
  ///
  /// If the number is less than 10, zero-pads it.
  intl.NumberFormat _twoDigitZeroPaddedFormat;

  /// Full unabbreviated year format, e.g. 2017 rather than 17.
  intl.DateFormat _fullYearFormat;

  intl.DateFormat _mediumDateFormat;

  intl.DateFormat _yearMonthFormat;

  static String _computeLocaleName(Locale locale) {
    final String localeName = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    return intl.Intl.canonicalizedLocale(localeName);
  }

  // TODO(hmuller): the rules for mapping from an integer value to
  // "one" or "two" etc. are locale specific and an additional "few" category
  // is needed. See http://cldr.unicode.org/index/cldr-spec/plural-rules
  String _nameToPluralValue(int count, String key) {
    String text;
    if (count == 0)
      text = _nameToValue['${key}Zero'];
    else if (count == 1)
      text = _nameToValue['${key}One'];
    else if (count == 2)
      text = _nameToValue['${key}Two'];
    else if (count > 2)
      text = _nameToValue['${key}Many'];
    text ??= _nameToValue['${key}Other'];
    assert(text != null);
    return text;
  }

  @override
  String formatHour(TimeOfDay timeOfDay) {
    switch (hourFormat(of: timeOfDayFormat)) {
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
  String formatMonthYear(DateTime date) {
    return _yearMonthFormat.format(date);
  }

  @override
  List<String> get narrowWeekDays {
    return _fullYearFormat.dateSymbols.NARROWWEEKDAYS;
  }

  @override
  int get firstDayOfWeekIndex => (_fullYearFormat.dateSymbols.FIRSTDAYOFWEEK + 1) % 7;

  /// Formats a [number] using local decimal number format.
  ///
  /// Inserts locale-appropriate thousands separator, if necessary.
  String formatDecimal(int number) {
    return _decimalFormat.format(number);
  }

  @override
  String formatTimeOfDay(TimeOfDay timeOfDay) {
    // Not using intl.DateFormat for two reasons:
    //
    // - DateFormat supports more formats than our material time picker does,
    //   and we want to be consistent across time picker format and the string
    //   formatting of the time of day.
    // - DateFormat operates on DateTime, which is sensitive to time eras and
    //   time zones, while here we want to format hour and minute within one day
    //   no matter what date the day falls on.
    switch (timeOfDayFormat) {
      case TimeOfDayFormat.h_colon_mm_space_a:
        return '${formatHour(timeOfDay)}:${formatMinute(timeOfDay)} ${_formatDayPeriod(timeOfDay)}';
      case TimeOfDayFormat.H_colon_mm:
      case TimeOfDayFormat.HH_colon_mm:
        return '${formatHour(timeOfDay)}:${formatMinute(timeOfDay)}';
      case TimeOfDayFormat.HH_dot_mm:
        return '${formatHour(timeOfDay)}.${formatMinute(timeOfDay)}';
      case TimeOfDayFormat.a_space_h_colon_mm:
        return '${_formatDayPeriod(timeOfDay)} ${formatHour(timeOfDay)}:${formatMinute(timeOfDay)}';
      case TimeOfDayFormat.frenchCanadian:
        return '${formatHour(timeOfDay)} h ${formatMinute(timeOfDay)}';
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
  String get openAppDrawerTooltip => _nameToValue['openAppDrawerTooltip'];

  @override
  String get backButtonTooltip => _nameToValue['backButtonTooltip'];

  @override
  String get closeButtonTooltip => _nameToValue['closeButtonTooltip'];

  @override
  String get nextMonthTooltip => _nameToValue['nextMonthTooltip'];

  @override
  String get previousMonthTooltip => _nameToValue['previousMonthTooltip'];

  @override
  String get nextPageTooltip => _nameToValue['nextPageTooltip'];

  @override
  String get previousPageTooltip => _nameToValue['previousPageTooltip'];

  @override
  String get showMenuTooltip => _nameToValue['showMenuTooltip'];

  @override
  String aboutListTileTitle(String applicationName) {
    final String text = _nameToValue['aboutListTileTitle'];
    return text.replaceFirst(r'$applicationName', applicationName);
  }

  @override
  String get licensesPageTitle => _nameToValue['licensesPageTitle'];

  @override
  String pageRowsInfoTitle(int firstRow, int lastRow, int rowCount, bool rowCountIsApproximate) {
    String text = rowCountIsApproximate ? _nameToValue['pageRowsInfoTitleApproximate'] : null;
    text ??= _nameToValue['pageRowsInfoTitle'];
    assert(text != null, 'A $locale localization was not found for pageRowsInfoTitle or pageRowsInfoTitleApproximate');
    // TODO(hansmuller): this could be more efficient.
    return text
      .replaceFirst(r'$firstRow', formatDecimal(firstRow))
      .replaceFirst(r'$lastRow', formatDecimal(lastRow))
      .replaceFirst(r'$rowCount', formatDecimal(rowCount));
  }

  @override
  String get rowsPerPageTitle => _nameToValue['rowsPerPageTitle'];

  @override
  String selectedRowCountTitle(int selectedRowCount) {
    return _nameToPluralValue(selectedRowCount, 'selectedRowCountTitle') // asserts on no match
      .replaceFirst(r'$selectedRowCount', formatDecimal(selectedRowCount));
  }

  @override
  String get cancelButtonLabel => _nameToValue['cancelButtonLabel'];

  @override
  String get closeButtonLabel => _nameToValue['closeButtonLabel'];

  @override
  String get continueButtonLabel => _nameToValue['continueButtonLabel'];

  @override
  String get copyButtonLabel => _nameToValue['copyButtonLabel'];

  @override
  String get cutButtonLabel => _nameToValue['cutButtonLabel'];

  @override
  String get okButtonLabel => _nameToValue['okButtonLabel'];

  @override
  String get pasteButtonLabel => _nameToValue['pasteButtonLabel'];

  @override
  String get selectAllButtonLabel => _nameToValue['selectAllButtonLabel'];

  @override
  String get viewLicensesButtonLabel => _nameToValue['viewLicensesButtonLabel'];

  @override
  String get anteMeridiemAbbreviation => _nameToValue['anteMeridiemAbbreviation'];

  @override
  String get postMeridiemAbbreviation => _nameToValue['postMeridiemAbbreviation'];

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
  TimeOfDayFormat get timeOfDayFormat {
    final String icuShortTimePattern = _nameToValue['timeOfDayFormat'];

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

    return _icuTimeOfDayToEnum[icuShortTimePattern];
  }

  /// Looks up text geometry defined in [MaterialTextGeometry].
  @override
  TextTheme get localTextGeometry => MaterialTextGeometry.forScriptCategory(_nameToValue["scriptCategory"]);

  /// Creates an object that provides localized resource values for the
  /// for the widgets of the material library.
  ///
  /// This method is typically used to create a [LocalizationsDelegate].
  /// The [MaterialApp] does so by default.
  static Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(new DefaultMaterialLocalizations(locale));
  }
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

/// Tracks if date i18n data has been loaded.
bool _dateIntlDataInitialized = false;

/// Loads i18n data for dates if it hasn't be loaded yet.
///
/// Only the first invocation of this function has the effect of loading the
/// data. Subsequent invocations have no effect.
void _loadDateIntlDataIfNotLoaded() {
  if (!_dateIntlDataInitialized) {
    // The returned Future is intentionally dropped on the floor. The
    // function only returns it to be compatible with the async counterparts.
    // The Future has no value otherwise.
    intl_local_date_data.initializeDateFormatting();
    _dateIntlDataInitialized = true;
  }
}
