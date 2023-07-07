// calendar.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../api_ms_win_core_winrt_string_l1_1_0.dart';
import '../combase.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../utils.dart';
import '../types.dart';
import '../winrt_helpers.dart';

import '../extensions/hstring_array.dart';
import 'ivector.dart';
import 'ivectorview.dart';

import 'icalendar.dart';
import 'itimezoneoncalendar.dart';
import 'icalendarfactory.dart';
import 'icalendarfactory2.dart';
import '../com/iinspectable.dart';

/// @nodoc
const IID_Calendar = 'null';

/// {@category Interface}
/// {@category winrt}
class Calendar extends IInspectable implements ICalendar, ITimeZoneOnCalendar {
  Calendar({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  Calendar.fromPointer(super.ptr);

  static const _className = 'Windows.Globalization.Calendar';

  // ICalendarFactory methods
  static Calendar CreateCalendarDefaultCalendarAndClock(
      Pointer<COMObject> languages) {
    final activationFactory =
        CreateActivationFactory(_className, IID_ICalendarFactory);

    try {
      final result = ICalendarFactory(activationFactory)
          .CreateCalendarDefaultCalendarAndClock(languages);
      return Calendar.fromPointer(result);
    } finally {
      free(activationFactory);
    }
  }

  static Calendar CreateCalendar(
      Pointer<COMObject> languages, String calendar, String clock) {
    final activationFactory =
        CreateActivationFactory(_className, IID_ICalendarFactory);

    try {
      final result = ICalendarFactory(activationFactory)
          .CreateCalendar(languages, calendar, clock);
      return Calendar.fromPointer(result);
    } finally {
      free(activationFactory);
    }
  }

  // ICalendarFactory2 methods
  static Calendar CreateCalendarWithTimeZone(Pointer<COMObject> languages,
      String calendar, String clock, String timeZoneId) {
    final activationFactory =
        CreateActivationFactory(_className, IID_ICalendarFactory2);

    try {
      final result = ICalendarFactory2(activationFactory)
          .CreateCalendarWithTimeZone(languages, calendar, clock, timeZoneId);
      return Calendar.fromPointer(result);
    } finally {
      free(activationFactory);
    }
  }

  // ICalendar methods
  late final _iCalendar = ICalendar(toInterface(IID_ICalendar));

  @override
  Pointer<COMObject> Clone() => _iCalendar.Clone();

  @override
  void SetToMin() => _iCalendar.SetToMin();

  @override
  void SetToMax() => _iCalendar.SetToMax();

  @override
  List<String> get Languages => _iCalendar.Languages;

  @override
  String get NumeralSystem => _iCalendar.NumeralSystem;

  @override
  set NumeralSystem(String value) => _iCalendar.NumeralSystem = value;

  @override
  String GetCalendarSystem() => _iCalendar.GetCalendarSystem();

  @override
  void ChangeCalendarSystem(String value) =>
      _iCalendar.ChangeCalendarSystem(value);

  @override
  String GetClock() => _iCalendar.GetClock();

  @override
  void ChangeClock(String value) => _iCalendar.ChangeClock(value);

  @override
  DateTime GetDateTime() => _iCalendar.GetDateTime();

  @override
  void SetDateTime(DateTime value) => _iCalendar.SetDateTime(value);

  @override
  void SetToNow() => _iCalendar.SetToNow();

  @override
  int get FirstEra => _iCalendar.FirstEra;

  @override
  int get LastEra => _iCalendar.LastEra;

  @override
  int get NumberOfEras => _iCalendar.NumberOfEras;

  @override
  int get Era => _iCalendar.Era;

  @override
  set Era(int value) => _iCalendar.Era = value;

  @override
  void AddEras(int eras) => _iCalendar.AddEras(eras);

  @override
  String EraAsFullString() => _iCalendar.EraAsFullString();

  @override
  String EraAsString(int idealLength) => _iCalendar.EraAsString(idealLength);

  @override
  int get FirstYearInThisEra => _iCalendar.FirstYearInThisEra;

  @override
  int get LastYearInThisEra => _iCalendar.LastYearInThisEra;

  @override
  int get NumberOfYearsInThisEra => _iCalendar.NumberOfYearsInThisEra;

  @override
  int get Year => _iCalendar.Year;

  @override
  set Year(int value) => _iCalendar.Year = value;

  @override
  void AddYears(int years) => _iCalendar.AddYears(years);

  @override
  String YearAsString() => _iCalendar.YearAsString();

  @override
  String YearAsTruncatedString(int remainingDigits) =>
      _iCalendar.YearAsTruncatedString(remainingDigits);

  @override
  String YearAsPaddedString(int minDigits) =>
      _iCalendar.YearAsPaddedString(minDigits);

  @override
  int get FirstMonthInThisYear => _iCalendar.FirstMonthInThisYear;

  @override
  int get LastMonthInThisYear => _iCalendar.LastMonthInThisYear;

  @override
  int get NumberOfMonthsInThisYear => _iCalendar.NumberOfMonthsInThisYear;

  @override
  int get Month => _iCalendar.Month;

  @override
  set Month(int value) => _iCalendar.Month = value;

  @override
  void AddMonths(int months) => _iCalendar.AddMonths(months);

  @override
  String MonthAsFullString() => _iCalendar.MonthAsFullString();

  @override
  String MonthAsString(int idealLength) =>
      _iCalendar.MonthAsString(idealLength);

  @override
  String MonthAsFullSoloString() => _iCalendar.MonthAsFullSoloString();

  @override
  String MonthAsSoloString(int idealLength) =>
      _iCalendar.MonthAsSoloString(idealLength);

  @override
  String MonthAsNumericString() => _iCalendar.MonthAsNumericString();

  @override
  String MonthAsPaddedNumericString(int minDigits) =>
      _iCalendar.MonthAsPaddedNumericString(minDigits);

  @override
  void AddWeeks(int weeks) => _iCalendar.AddWeeks(weeks);

  @override
  int get FirstDayInThisMonth => _iCalendar.FirstDayInThisMonth;

  @override
  int get LastDayInThisMonth => _iCalendar.LastDayInThisMonth;

  @override
  int get NumberOfDaysInThisMonth => _iCalendar.NumberOfDaysInThisMonth;

  @override
  int get Day => _iCalendar.Day;

  @override
  set Day(int value) => _iCalendar.Day = value;

  @override
  void AddDays(int days) => _iCalendar.AddDays(days);

  @override
  String DayAsString() => _iCalendar.DayAsString();

  @override
  String DayAsPaddedString(int minDigits) =>
      _iCalendar.DayAsPaddedString(minDigits);

  @override
  int get DayOfWeek => _iCalendar.DayOfWeek;

  @override
  String DayOfWeekAsFullString() => _iCalendar.DayOfWeekAsFullString();

  @override
  String DayOfWeekAsString(int idealLength) =>
      _iCalendar.DayOfWeekAsString(idealLength);

  @override
  String DayOfWeekAsFullSoloString() => _iCalendar.DayOfWeekAsFullSoloString();

  @override
  String DayOfWeekAsSoloString(int idealLength) =>
      _iCalendar.DayOfWeekAsSoloString(idealLength);

  @override
  int get FirstPeriodInThisDay => _iCalendar.FirstPeriodInThisDay;

  @override
  int get LastPeriodInThisDay => _iCalendar.LastPeriodInThisDay;

  @override
  int get NumberOfPeriodsInThisDay => _iCalendar.NumberOfPeriodsInThisDay;

  @override
  int get Period => _iCalendar.Period;

  @override
  set Period(int value) => _iCalendar.Period = value;

  @override
  void AddPeriods(int periods) => _iCalendar.AddPeriods(periods);

  @override
  String PeriodAsFullString() => _iCalendar.PeriodAsFullString();

  @override
  String PeriodAsString(int idealLength) =>
      _iCalendar.PeriodAsString(idealLength);

  @override
  int get FirstHourInThisPeriod => _iCalendar.FirstHourInThisPeriod;

  @override
  int get LastHourInThisPeriod => _iCalendar.LastHourInThisPeriod;

  @override
  int get NumberOfHoursInThisPeriod => _iCalendar.NumberOfHoursInThisPeriod;

  @override
  int get Hour => _iCalendar.Hour;

  @override
  set Hour(int value) => _iCalendar.Hour = value;

  @override
  void AddHours(int hours) => _iCalendar.AddHours(hours);

  @override
  String HourAsString() => _iCalendar.HourAsString();

  @override
  String HourAsPaddedString(int minDigits) =>
      _iCalendar.HourAsPaddedString(minDigits);

  @override
  int get Minute => _iCalendar.Minute;

  @override
  set Minute(int value) => _iCalendar.Minute = value;

  @override
  void AddMinutes(int minutes) => _iCalendar.AddMinutes(minutes);

  @override
  String MinuteAsString() => _iCalendar.MinuteAsString();

  @override
  String MinuteAsPaddedString(int minDigits) =>
      _iCalendar.MinuteAsPaddedString(minDigits);

  @override
  int get Second => _iCalendar.Second;

  @override
  set Second(int value) => _iCalendar.Second = value;

  @override
  void AddSeconds(int seconds) => _iCalendar.AddSeconds(seconds);

  @override
  String SecondAsString() => _iCalendar.SecondAsString();

  @override
  String SecondAsPaddedString(int minDigits) =>
      _iCalendar.SecondAsPaddedString(minDigits);

  @override
  int get Nanosecond => _iCalendar.Nanosecond;

  @override
  set Nanosecond(int value) => _iCalendar.Nanosecond = value;

  @override
  void AddNanoseconds(int nanoseconds) =>
      _iCalendar.AddNanoseconds(nanoseconds);

  @override
  String NanosecondAsString() => _iCalendar.NanosecondAsString();

  @override
  String NanosecondAsPaddedString(int minDigits) =>
      _iCalendar.NanosecondAsPaddedString(minDigits);

  @override
  int Compare(Pointer<COMObject> other) => _iCalendar.Compare(other);

  @override
  int CompareDateTime(DateTime other) => _iCalendar.CompareDateTime(other);

  @override
  void CopyTo(Pointer<COMObject> other) => _iCalendar.CopyTo(other);

  @override
  int get FirstMinuteInThisHour => _iCalendar.FirstMinuteInThisHour;

  @override
  int get LastMinuteInThisHour => _iCalendar.LastMinuteInThisHour;

  @override
  int get NumberOfMinutesInThisHour => _iCalendar.NumberOfMinutesInThisHour;

  @override
  int get FirstSecondInThisMinute => _iCalendar.FirstSecondInThisMinute;

  @override
  int get LastSecondInThisMinute => _iCalendar.LastSecondInThisMinute;

  @override
  int get NumberOfSecondsInThisMinute => _iCalendar.NumberOfSecondsInThisMinute;

  @override
  String get ResolvedLanguage => _iCalendar.ResolvedLanguage;

  @override
  bool get IsDaylightSavingTime => _iCalendar.IsDaylightSavingTime;
  // ITimeZoneOnCalendar methods
  late final _iTimeZoneOnCalendar =
      ITimeZoneOnCalendar(toInterface(IID_ITimeZoneOnCalendar));

  @override
  String GetTimeZone() => _iTimeZoneOnCalendar.GetTimeZone();

  @override
  void ChangeTimeZone(String timeZoneId) =>
      _iTimeZoneOnCalendar.ChangeTimeZone(timeZoneId);

  @override
  String TimeZoneAsFullString() => _iTimeZoneOnCalendar.TimeZoneAsFullString();

  @override
  String TimeZoneAsString(int idealLength) =>
      _iTimeZoneOnCalendar.TimeZoneAsString(idealLength);
}
