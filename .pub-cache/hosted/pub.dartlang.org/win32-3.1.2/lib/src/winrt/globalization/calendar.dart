// calendar.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../utils.dart';
import '../../types.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';

import '../internal/hstring_array.dart';

import 'icalendar.dart';
import 'itimezoneoncalendar.dart';
import 'icalendarfactory.dart';
import 'icalendarfactory2.dart';
import '../foundation/collections/iiterable.dart';
import '../foundation/collections/ivectorview.dart';
import 'enums.g.dart';
import '../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class Calendar extends IInspectable implements ICalendar, ITimeZoneOnCalendar {
  Calendar({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  Calendar.fromRawPointer(super.ptr);

  static const _className = 'Windows.Globalization.Calendar';

  // ICalendarFactory methods
  static Calendar createCalendarDefaultCalendarAndClock(
      IIterable<String> languages) {
    final activationFactory =
        CreateActivationFactory(_className, IID_ICalendarFactory);

    try {
      return ICalendarFactory.fromRawPointer(activationFactory)
          .createCalendarDefaultCalendarAndClock(languages);
    } finally {
      free(activationFactory);
    }
  }

  static Calendar createCalendar(
      IIterable<String> languages, String calendar, String clock) {
    final activationFactory =
        CreateActivationFactory(_className, IID_ICalendarFactory);

    try {
      return ICalendarFactory.fromRawPointer(activationFactory)
          .createCalendar(languages, calendar, clock);
    } finally {
      free(activationFactory);
    }
  }

  // ICalendarFactory2 methods
  static Calendar createCalendarWithTimeZone(IIterable<String> languages,
      String calendar, String clock, String timeZoneId) {
    final activationFactory =
        CreateActivationFactory(_className, IID_ICalendarFactory2);

    try {
      return ICalendarFactory2.fromRawPointer(activationFactory)
          .createCalendarWithTimeZone(languages, calendar, clock, timeZoneId);
    } finally {
      free(activationFactory);
    }
  }

  // ICalendar methods
  late final _iCalendar = ICalendar.from(this);

  @override
  Calendar clone() => _iCalendar.clone();

  @override
  void setToMin() => _iCalendar.setToMin();

  @override
  void setToMax() => _iCalendar.setToMax();

  @override
  List<String> get languages => _iCalendar.languages;

  @override
  String get numeralSystem => _iCalendar.numeralSystem;

  @override
  set numeralSystem(String value) => _iCalendar.numeralSystem = value;

  @override
  String getCalendarSystem() => _iCalendar.getCalendarSystem();

  @override
  void changeCalendarSystem(String value) =>
      _iCalendar.changeCalendarSystem(value);

  @override
  String getClock() => _iCalendar.getClock();

  @override
  void changeClock(String value) => _iCalendar.changeClock(value);

  @override
  DateTime getDateTime() => _iCalendar.getDateTime();

  @override
  void setDateTime(DateTime value) => _iCalendar.setDateTime(value);

  @override
  void setToNow() => _iCalendar.setToNow();

  @override
  int get firstEra => _iCalendar.firstEra;

  @override
  int get lastEra => _iCalendar.lastEra;

  @override
  int get numberOfEras => _iCalendar.numberOfEras;

  @override
  int get era => _iCalendar.era;

  @override
  set era(int value) => _iCalendar.era = value;

  @override
  void addEras(int eras) => _iCalendar.addEras(eras);

  @override
  String eraAsFullString() => _iCalendar.eraAsFullString();

  @override
  String eraAsString(int idealLength) => _iCalendar.eraAsString(idealLength);

  @override
  int get firstYearInThisEra => _iCalendar.firstYearInThisEra;

  @override
  int get lastYearInThisEra => _iCalendar.lastYearInThisEra;

  @override
  int get numberOfYearsInThisEra => _iCalendar.numberOfYearsInThisEra;

  @override
  int get year => _iCalendar.year;

  @override
  set year(int value) => _iCalendar.year = value;

  @override
  void addYears(int years) => _iCalendar.addYears(years);

  @override
  String yearAsString() => _iCalendar.yearAsString();

  @override
  String yearAsTruncatedString(int remainingDigits) =>
      _iCalendar.yearAsTruncatedString(remainingDigits);

  @override
  String yearAsPaddedString(int minDigits) =>
      _iCalendar.yearAsPaddedString(minDigits);

  @override
  int get firstMonthInThisYear => _iCalendar.firstMonthInThisYear;

  @override
  int get lastMonthInThisYear => _iCalendar.lastMonthInThisYear;

  @override
  int get numberOfMonthsInThisYear => _iCalendar.numberOfMonthsInThisYear;

  @override
  int get month => _iCalendar.month;

  @override
  set month(int value) => _iCalendar.month = value;

  @override
  void addMonths(int months) => _iCalendar.addMonths(months);

  @override
  String monthAsFullString() => _iCalendar.monthAsFullString();

  @override
  String monthAsString(int idealLength) =>
      _iCalendar.monthAsString(idealLength);

  @override
  String monthAsFullSoloString() => _iCalendar.monthAsFullSoloString();

  @override
  String monthAsSoloString(int idealLength) =>
      _iCalendar.monthAsSoloString(idealLength);

  @override
  String monthAsNumericString() => _iCalendar.monthAsNumericString();

  @override
  String monthAsPaddedNumericString(int minDigits) =>
      _iCalendar.monthAsPaddedNumericString(minDigits);

  @override
  void addWeeks(int weeks) => _iCalendar.addWeeks(weeks);

  @override
  int get firstDayInThisMonth => _iCalendar.firstDayInThisMonth;

  @override
  int get lastDayInThisMonth => _iCalendar.lastDayInThisMonth;

  @override
  int get numberOfDaysInThisMonth => _iCalendar.numberOfDaysInThisMonth;

  @override
  int get day => _iCalendar.day;

  @override
  set day(int value) => _iCalendar.day = value;

  @override
  void addDays(int days) => _iCalendar.addDays(days);

  @override
  String dayAsString() => _iCalendar.dayAsString();

  @override
  String dayAsPaddedString(int minDigits) =>
      _iCalendar.dayAsPaddedString(minDigits);

  @override
  DayOfWeek get dayOfWeek => _iCalendar.dayOfWeek;

  @override
  String dayOfWeekAsFullString() => _iCalendar.dayOfWeekAsFullString();

  @override
  String dayOfWeekAsString(int idealLength) =>
      _iCalendar.dayOfWeekAsString(idealLength);

  @override
  String dayOfWeekAsFullSoloString() => _iCalendar.dayOfWeekAsFullSoloString();

  @override
  String dayOfWeekAsSoloString(int idealLength) =>
      _iCalendar.dayOfWeekAsSoloString(idealLength);

  @override
  int get firstPeriodInThisDay => _iCalendar.firstPeriodInThisDay;

  @override
  int get lastPeriodInThisDay => _iCalendar.lastPeriodInThisDay;

  @override
  int get numberOfPeriodsInThisDay => _iCalendar.numberOfPeriodsInThisDay;

  @override
  int get period => _iCalendar.period;

  @override
  set period(int value) => _iCalendar.period = value;

  @override
  void addPeriods(int periods) => _iCalendar.addPeriods(periods);

  @override
  String periodAsFullString() => _iCalendar.periodAsFullString();

  @override
  String periodAsString(int idealLength) =>
      _iCalendar.periodAsString(idealLength);

  @override
  int get firstHourInThisPeriod => _iCalendar.firstHourInThisPeriod;

  @override
  int get lastHourInThisPeriod => _iCalendar.lastHourInThisPeriod;

  @override
  int get numberOfHoursInThisPeriod => _iCalendar.numberOfHoursInThisPeriod;

  @override
  int get hour => _iCalendar.hour;

  @override
  set hour(int value) => _iCalendar.hour = value;

  @override
  void addHours(int hours) => _iCalendar.addHours(hours);

  @override
  String hourAsString() => _iCalendar.hourAsString();

  @override
  String hourAsPaddedString(int minDigits) =>
      _iCalendar.hourAsPaddedString(minDigits);

  @override
  int get minute => _iCalendar.minute;

  @override
  set minute(int value) => _iCalendar.minute = value;

  @override
  void addMinutes(int minutes) => _iCalendar.addMinutes(minutes);

  @override
  String minuteAsString() => _iCalendar.minuteAsString();

  @override
  String minuteAsPaddedString(int minDigits) =>
      _iCalendar.minuteAsPaddedString(minDigits);

  @override
  int get second => _iCalendar.second;

  @override
  set second(int value) => _iCalendar.second = value;

  @override
  void addSeconds(int seconds) => _iCalendar.addSeconds(seconds);

  @override
  String secondAsString() => _iCalendar.secondAsString();

  @override
  String secondAsPaddedString(int minDigits) =>
      _iCalendar.secondAsPaddedString(minDigits);

  @override
  int get nanosecond => _iCalendar.nanosecond;

  @override
  set nanosecond(int value) => _iCalendar.nanosecond = value;

  @override
  void addNanoseconds(int nanoseconds) =>
      _iCalendar.addNanoseconds(nanoseconds);

  @override
  String nanosecondAsString() => _iCalendar.nanosecondAsString();

  @override
  String nanosecondAsPaddedString(int minDigits) =>
      _iCalendar.nanosecondAsPaddedString(minDigits);

  @override
  int compare(Calendar other) => _iCalendar.compare(other);

  @override
  int compareDateTime(DateTime other) => _iCalendar.compareDateTime(other);

  @override
  void copyTo(Calendar other) => _iCalendar.copyTo(other);

  @override
  int get firstMinuteInThisHour => _iCalendar.firstMinuteInThisHour;

  @override
  int get lastMinuteInThisHour => _iCalendar.lastMinuteInThisHour;

  @override
  int get numberOfMinutesInThisHour => _iCalendar.numberOfMinutesInThisHour;

  @override
  int get firstSecondInThisMinute => _iCalendar.firstSecondInThisMinute;

  @override
  int get lastSecondInThisMinute => _iCalendar.lastSecondInThisMinute;

  @override
  int get numberOfSecondsInThisMinute => _iCalendar.numberOfSecondsInThisMinute;

  @override
  String get resolvedLanguage => _iCalendar.resolvedLanguage;

  @override
  bool get isDaylightSavingTime => _iCalendar.isDaylightSavingTime;
  // ITimeZoneOnCalendar methods
  late final _iTimeZoneOnCalendar = ITimeZoneOnCalendar.from(this);

  @override
  String getTimeZone() => _iTimeZoneOnCalendar.getTimeZone();

  @override
  void changeTimeZone(String timeZoneId) =>
      _iTimeZoneOnCalendar.changeTimeZone(timeZoneId);

  @override
  String timeZoneAsFullString() => _iTimeZoneOnCalendar.timeZoneAsFullString();

  @override
  String timeZoneAsString(int idealLength) =>
      _iTimeZoneOnCalendar.timeZoneAsString(idealLength);
}
