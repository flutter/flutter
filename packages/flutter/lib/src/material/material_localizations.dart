// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'time.dart';
import 'typography.dart';

// ADDING A NEW STRING
//
// If you (someone contributing to the Flutter framework) want to add a new
// string to the MaterialLocalizations object (e.g. because you've added a new
// widget and it has a tooltip), follow these steps:
//
// 1. Add the new getter to MaterialLocalizations below.
//
// 2. Implement a default value in DefaultMaterialLocalizations below.
//
// 3. Add a test to test/material/localizations_test.dart that verifies that
//    this new value is implemented.
//
// 4. Update the flutter_localizations package. To add a new string to the
//    flutter_localizations package, you must first add it to the English
//    translations (lib/src/l10n/material_en.arb), including a description, then
//    you must add it to every other language (all the other *.arb files in that
//    same directory), including a best guess as to the translation, e.g.
//    obtained by optimistic use of Google Translate
//    (https://translate.google.com/). After that you have to re-generate
//    lib/src/l10n/localizations.dart by running
//    `dart dev/tools/gen_localizations.dart --overwrite`. There is a README
//    file with further information in the lib/src/l10n/ directory.
//
// 5. If you are a Google employee, you should then also follow the instructions
//    at go/flutter-l10n. If you're not, don't worry about it.

/// Defines the localized resource values used by the Material widgets.
///
/// See also:
///
///  * [DefaultMaterialLocalizations], the default, English-only, implementation
///    of this interface.
///  * [GlobalMaterialLocalizations], which provides material localizations for
///    many languages.
abstract class MaterialLocalizations {
  /// The tooltip for the leading [AppBar] menu (a.k.a. 'hamburger') button.
  String get openAppDrawerTooltip;

  /// The [BackButton]'s tooltip.
  String get backButtonTooltip;

  /// The [CloseButton]'s tooltip.
  String get closeButtonTooltip;

  /// The tooltip for the delete button on a [Chip].
  String get deleteButtonTooltip;

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

  /// The accessibility label used on a tab in a [TabBar].
  ///
  /// This message describes the index of the selected tab and how many tabs
  /// there are, e.g. 'Tab 1 of 2' in United States English.
  ///
  /// `tabIndex` and `tabCount` must be greater than or equal to one.
  String tabLabel({int tabIndex, int tabCount});

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

  /// The text-to-speech announcement made when a time picker invoked using
  /// [showTimePicker] is set to the hour picker mode.
  String get timePickerHourModeAnnouncement;

  /// The text-to-speech announcement made when a time picker invoked using
  /// [showTimePicker] is set to the minute picker mode.
  String get timePickerMinuteModeAnnouncement;

  /// Label read out by accessibility tools (TalkBack or VoiceOver) for a modal
  /// barrier to indicate that a tap dismisses the barrier.
  ///
  /// A modal barrier can for example be found behind a alert or popup to block
  /// user interaction with elements behind it.
  String get modalBarrierDismissLabel;

  /// The format used to lay out the time picker.
  ///
  /// The documentation for [TimeOfDayFormat] enum values provides details on
  /// each supported layout.
  TimeOfDayFormat timeOfDayFormat({ bool alwaysUse24HourFormat: false });

  /// Provides geometric text preferences for the current locale.
  ///
  /// This text theme is incomplete. For example, it lacks text color
  /// information. This theme must be merged with another text theme that
  /// provides the missing values.
  ///
  /// Typically a complete theme is obtained via [Theme.of], which can be
  /// localized using the [Localizations] widget.
  ///
  /// The text styles provided by this theme are expected to have their
  /// [TextStyle.inherit] property set to false, so that the [ThemeData]
  /// obtained from [Theme.of] no longer inherits text style properties and
  /// contains a complete set of properties needed to style a [Text] widget.
  ///
  /// See also: https://material.io/guidelines/style/typography.html
  TextTheme get localTextGeometry;

  /// Formats [number] as a decimal, inserting locale-appropriate thousands
  /// separators as necessary.
  String formatDecimal(int number);

  /// Formats [TimeOfDay.hour] in the given time of day according to the value
  /// of [timeOfDayFormat].
  ///
  /// If [alwaysUse24HourFormat] is true, formats hour using [HourFormat.HH]
  /// rather than the default for the current locale.
  String formatHour(TimeOfDay timeOfDay, { bool alwaysUse24HourFormat: false });

  /// Formats [TimeOfDay.minute] in the given time of day according to the value
  /// of [timeOfDayFormat].
  String formatMinute(TimeOfDay timeOfDay);

  /// Formats [timeOfDay] according to the value of [timeOfDayFormat].
  ///
  /// If [alwaysUse24HourFormat] is true, formats hour using [HourFormat.HH]
  /// rather than the default for the current locale. This value is usually
  /// passed from [MediaQueryData.alwaysUse24HourFormat], which has platform-
  /// specific behavior.
  String formatTimeOfDay(TimeOfDay timeOfDay, { bool alwaysUse24HourFormat: false });

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

  /// Formats day of week, month, day of month and year in a long-width format.
  ///
  /// Does not abbreviate names. Appears in spoken announcements of the date
  /// picker invoked using [showDatePicker], when accessibility mode is on.
  ///
  /// Examples:
  ///
  /// - US English: Wednesday, September 27, 2017
  /// - Russian: Среда, Сентябрь 27, 2017
  String formatFullDate(DateTime date);

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
  List<String> get narrowWeekdays;

  /// Index of the first day of week, where 0 points to Sunday, and 6 points to
  /// Saturday.
  ///
  /// This getter is compatible with [narrowWeekdays]. For example:
  ///
  /// ```dart
  /// var localizations = MaterialLocalizations.of(context);
  /// // The name of the first day of week for the current locale.
  /// var firstDayOfWeek = localizations.narrowWeekdays[localizations.firstDayOfWeekIndex];
  /// ```
  int get firstDayOfWeekIndex;

  /// The semantics label used to indicate which account is signed in in the
  /// [UserAccountsDrawerHeader] widget.
  String get signedInLabel;

  /// The semantics label used for the button on [UserAccountsDrawerHeader] that
  /// hides the list of accounts.
  String get hideAccountsLabel;

  /// The semantics label used for the button on [UserAccountsDrawerHeader] that
  /// shows the list of accounts.
  String get showAccountsLabel;

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

class _MaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) => DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_MaterialLocalizationsDelegate old) => false;
}

/// US English strings for the material widgets.
///
/// See also:
///
///  * [GlobalMaterialLocalizations], which provides material localizations for
///    many languages.
///  * [MaterialApp.delegates], which automatically includes
///    [DefaultMaterialLocalizations.delegate] by default.
class DefaultMaterialLocalizations implements MaterialLocalizations {
  /// Constructs an object that defines the material widgets' localized strings
  /// for US English (only).
  ///
  /// [LocalizationsDelegate] implementations typically call the static [load]
  /// function, rather than constructing this class directly.
  const DefaultMaterialLocalizations();

  // Ordered to match DateTime.monday=1, DateTime.sunday=6
  static const List<String> _shortWeekdays = const <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Ordered to match DateTime.monday=1, DateTime.sunday=6
  static const List<String> _weekdays = const <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _narrowWeekdays = const <String>[
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  static const List<String> _shortMonths = const <String>[
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

  static const List<String> _months = const <String>[
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
  String formatHour(TimeOfDay timeOfDay, { bool alwaysUse24HourFormat: false }) {
    final TimeOfDayFormat format = timeOfDayFormat(alwaysUse24HourFormat: alwaysUse24HourFormat);
    switch (format) {
      case TimeOfDayFormat.h_colon_mm_space_a:
        return formatDecimal(timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod);
      case TimeOfDayFormat.HH_colon_mm:
        return _formatTwoDigitZeroPad(timeOfDay.hour);
      default:
        throw new AssertionError('$runtimeType does not support $format.');
    }
  }

  /// Formats [number] using two digits, assuming it's in the 0-99 inclusive
  /// range. Not designed to format values outside this range.
  String _formatTwoDigitZeroPad(int number) {
    assert(0 <= number && number < 100);

    if (number < 10)
      return '0$number';

    return '$number';
  }

  @override
  String formatMinute(TimeOfDay timeOfDay) {
    final int minute = timeOfDay.minute;
    return minute < 10 ? '0$minute' : minute.toString();
  }

  @override
  String formatYear(DateTime date) => date.year.toString();

  @override
  String formatMediumDate(DateTime date) {
    final String day = _shortWeekdays[date.weekday - DateTime.monday];
    final String month = _shortMonths[date.month - DateTime.january];
    return '$day, $month ${date.day}';
  }

  @override
  String formatFullDate(DateTime date) {
    final String month = _months[date.month - DateTime.january];
    return '${_weekdays[date.weekday - DateTime.monday]}, $month ${date.day}, ${date.year}';
  }

  @override
  String formatMonthYear(DateTime date) {
    final String year = formatYear(date);
    final String month = _months[date.month - DateTime.january];
    return '$month $year';
  }

  @override
  List<String> get narrowWeekdays => _narrowWeekdays;

  @override
  int get firstDayOfWeekIndex => 0; // narrowWeekdays[0] is 'S' for Sunday

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
  String formatDecimal(int number) {
    if (number > -1000 && number < 1000)
      return number.toString();

    final String digits = number.abs().toString();
    final StringBuffer result = new StringBuffer(number < 0 ? '-' : '');
    final int maxDigitIndex = digits.length - 1;
    for (int i = 0; i <= maxDigitIndex; i += 1) {
      result.write(digits[i]);
      if (i < maxDigitIndex && (maxDigitIndex - i) % 3 == 0)
        result.write(',');
    }
    return result.toString();
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
    final StringBuffer buffer = new StringBuffer();

    // Add hour:minute.
    buffer
      ..write(formatHour(timeOfDay, alwaysUse24HourFormat: alwaysUse24HourFormat))
      ..write(':')
      ..write(formatMinute(timeOfDay));

    if (alwaysUse24HourFormat) {
      // There's no AM/PM indicator in 24-hour format.
      return '$buffer';
    }

    // Add AM/PM indicator.
    buffer
      ..write(' ')
      ..write(_formatDayPeriod(timeOfDay));
    return '$buffer';
  }

  @override
  String get openAppDrawerTooltip => 'Open navigation menu';

  @override
  String get backButtonTooltip => 'Back';

  @override
  String get closeButtonTooltip => 'Close';

  @override
  String get deleteButtonTooltip => 'Delete';

  @override
  String get nextMonthTooltip => 'Next month';

  @override
  String get previousMonthTooltip => 'Previous month';

  @override
  String get nextPageTooltip => 'Next page';

  @override
  String get previousPageTooltip => 'Previous page';

  @override
  String get showMenuTooltip => 'Show menu';

  @override
  String aboutListTileTitle(String applicationName) => 'About $applicationName';

  @override
  String get licensesPageTitle => 'Licenses';

  @override
  String pageRowsInfoTitle(int firstRow, int lastRow, int rowCount, bool rowCountIsApproximate) {
    return rowCountIsApproximate
      ? '$firstRow–$lastRow of about $rowCount'
      : '$firstRow–$lastRow of $rowCount';
  }

  @override
  String get rowsPerPageTitle => 'Rows per page:';

  @override
  String tabLabel({int tabIndex, int tabCount}) {
    assert(tabIndex >= 1);
    assert(tabCount >= 1);
    return 'Tab $tabIndex of $tabCount';
  }

  @override
  String selectedRowCountTitle(int selectedRowCount) {
    switch (selectedRowCount) {
      case 0:
        return 'No items selected';
      case 1:
        return '1 item selected';
      default:
        return '$selectedRowCount items selected';
    }
  }

  @override
  String get cancelButtonLabel => 'CANCEL';

  @override
  String get closeButtonLabel => 'CLOSE';

  @override
  String get continueButtonLabel => 'CONTINUE';

  @override
  String get copyButtonLabel => 'COPY';

  @override
  String get cutButtonLabel => 'CUT';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get pasteButtonLabel => 'PASTE';

  @override
  String get selectAllButtonLabel => 'SELECT ALL';

  @override
  String get viewLicensesButtonLabel => 'VIEW LICENSES';

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get timePickerHourModeAnnouncement => 'Select hours';

  @override
  String get timePickerMinuteModeAnnouncement => 'Select minutes';

  @override
  String get modalBarrierDismissLabel => 'Dismiss';

  @override
  TimeOfDayFormat timeOfDayFormat({ bool alwaysUse24HourFormat: false }) {
    return alwaysUse24HourFormat
      ? TimeOfDayFormat.HH_colon_mm
      : TimeOfDayFormat.h_colon_mm_space_a;
  }

  /// Looks up text geometry defined in [MaterialTextGeometry].
  @override
  TextTheme get localTextGeometry => MaterialTextGeometry.englishLike;

  @override
  String get signedInLabel => 'Signed in';

  @override
  String get hideAccountsLabel => 'Hide accounts';

  @override
  String get showAccountsLabel => 'Show accounts';

  /// Creates an object that provides US English resource values for the material
  /// library widgets.
  ///
  /// The [locale] parameter is ignored.
  ///
  /// This method is typically used to create a [LocalizationsDelegate].
  /// The [MaterialApp] does so by default.
  static Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(const DefaultMaterialLocalizations());
  }

  /// A [LocalizationsDelegate] that uses [DefaultMaterialLocalizations.load]
  /// to create an instance of this class.
  ///
  /// [MaterialApp] automatically adds this value to [MaterialApp.localizationsDelegates].
  static const LocalizationsDelegate<MaterialLocalizations> delegate = const _MaterialLocalizationsDelegate();
}
