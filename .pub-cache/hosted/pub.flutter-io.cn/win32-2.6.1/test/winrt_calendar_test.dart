@TestOn('windows')

import 'package:test/test.dart';
import 'package:win32/win32.dart';

// Exhaustively test the WinRT calendar object to make sure overrides,
// properties and methods are working correctly.

void main() {
  if (isWindowsRuntimeAvailable()) {
    late ICalendar calendar;

    setUp(() {
      winrtInitialize();

      final object =
          CreateObject('Windows.Globalization.Calendar', IID_ICalendar);
      calendar = ICalendar(object);
    });

    test('Calendar is a materialized object', () {
      expect(calendar.trustLevel, equals(TrustLevel.baseTrust));
      expect(
          calendar.runtimeClassName, equals('Windows.Globalization.Calendar'));
    });

    test('Calendar day', () {
      expect(calendar.Day, inInclusiveRange(1, 31));
    });

    test('Set calendar day', () {
      calendar.Day = 13;
      expect(calendar.Day, equals(13));
    });

    test('Calendar day of week', () {
      expect(calendar.DayOfWeek, inInclusiveRange(0, 6));
    });

    test('Calendar era', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);
      expect(calendar.Era, equals(1));
      WindowsDeleteString(gregorianCalendar);
    });

    test('Calendar first day of month', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);
      expect(calendar.FirstDayInThisMonth, equals(1));
      WindowsDeleteString(gregorianCalendar);
    });

    test('Calendar first era', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);

      // Per Microsoft docs, the WinRT implementation only recognizes the
      // current era (A.D.). See:
      // https://docs.microsoft.com/en-us/uwp/api/windows.globalization.calendaridentifiers.gregorian
      expect(calendar.FirstEra, equals(1));
      WindowsDeleteString(gregorianCalendar);
    });

    test('Calendar first hour in this period', () {
      final twelveHourClock = convertToHString('12HourClock');
      calendar.ChangeClock(twelveHourClock);
      expect(calendar.FirstHourInThisPeriod, isIn([0, 12]));
      WindowsDeleteString(twelveHourClock);
    });

    test('Calendar first minute in this hour', () {
      expect(calendar.FirstMinuteInThisHour, equals(0));
    });

    test('Calendar first month in this year', () {
      expect(calendar.FirstMonthInThisYear, equals(1));
    });

    test('Calendar first period in this day', () {
      expect(calendar.FirstMonthInThisYear, equals(1));
    });

    test('Calendar first second in this minute', () {
      expect(calendar.FirstSecondInThisMinute, equals(0));
    });

    test('Calendar first year in the current era', () {
      final hebrewCalendar = convertToHString('HebrewCalendar');
      calendar.ChangeCalendarSystem(hebrewCalendar);
      expect(calendar.FirstYearInThisEra, equals(5343));
      WindowsDeleteString(hebrewCalendar);
    });

    test('Calendar hour', () {
      expect(calendar.Hour, inInclusiveRange(0, 23));
    });

    test('Calendar daylight saving time', () {
      expect(() => calendar.IsDaylightSavingTime, returnsNormally);
    });

    test('Calendar languages', () {
      expect(calendar.Languages.length, isPositive);
    });

    test('Calendar last day in month', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);
      expect(calendar.LastDayInThisMonth, isIn([28, 29, 30, 31]));
      WindowsDeleteString(gregorianCalendar);
    });

    test('Calendar last era', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);
      expect(calendar.FirstEra, equals(1));
      expect(calendar.LastEra, equals(1));
      WindowsDeleteString(gregorianCalendar);

      // Most systems should be in the Reiwa (令和) era, but a system without
      // the calendar update will be in the Heisei (平成) era. In either event,
      // there should be at least four Japanese eras registered by WinRT.
      final japaneseCalendar = convertToHString('JapaneseCalendar');
      calendar.ChangeCalendarSystem(japaneseCalendar);
      expect(calendar.FirstEra, equals(1));
      expect(calendar.LastEra, greaterThanOrEqualTo(4));
      WindowsDeleteString(japaneseCalendar);
    });

    test('Calendar last hour in this period', () {
      final twelveHourClock = convertToHString('12HourClock');
      calendar.ChangeClock(twelveHourClock);
      expect(calendar.LastHourInThisPeriod, equals(11));
      WindowsDeleteString(twelveHourClock);
    });

    test('Calendar last minute in this hour', () {
      final twelveHourClock = convertToHString('12HourClock');
      calendar.ChangeClock(twelveHourClock);
      expect(calendar.LastMinuteInThisHour, equals(59));
      WindowsDeleteString(twelveHourClock);
    });

    test('Calendar last month in this year', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);
      expect(calendar.LastMonthInThisYear, equals(12));
      WindowsDeleteString(gregorianCalendar);
    });

    test('Calendar last period in this day', () {
      final twelveHourClock = convertToHString('12HourClock');
      calendar.ChangeClock(twelveHourClock);
      expect(calendar.LastPeriodInThisDay, equals(2));
      WindowsDeleteString(twelveHourClock);
    });

    test('Calendar last second in this minute', () {
      expect(calendar.LastSecondInThisMinute, equals(59));
    });

    test('Calendar last year in this era', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);
      expect(calendar.LastYearInThisEra, equals(9999));
      WindowsDeleteString(gregorianCalendar);
    });

    test('Calendar minute', () {
      expect(calendar.Minute, inInclusiveRange(0, 59));
    });

    test('Calendar month', () {
      expect(calendar.Month, inInclusiveRange(1, 12));
    });

    test('Calendar nanosecond', () {
      expect(calendar.Nanosecond, isPositive);
    });

    test('Calendar days in month', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);
      expect(calendar.NumberOfDaysInThisMonth, isIn([28, 29, 30, 31]));
      WindowsDeleteString(gregorianCalendar);
    });

    test('Calendar number of eras', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);
      expect(calendar.NumberOfEras, equals(1));
      WindowsDeleteString(gregorianCalendar);
    });

    test('Calendar number of hours in this period', () {
      final twentyFourHourClock = convertToHString('24HourClock');
      calendar.ChangeClock(twentyFourHourClock);
      expect(calendar.NumberOfHoursInThisPeriod, equals(24));
      WindowsDeleteString(twentyFourHourClock);
    });

    test('Calendar number of minutes in this hour', () {
      expect(calendar.NumberOfMinutesInThisHour, equals(60));
    });

    test('Calendar number of months in this year', () {
      expect(calendar.NumberOfMonthsInThisYear, equals(12));
    });

    test('Calendar number of periods in this day', () {
      final twentyFourHourClock = convertToHString('24HourClock');
      calendar.ChangeClock(twentyFourHourClock);
      expect(calendar.NumberOfPeriodsInThisDay, equals(1));
      WindowsDeleteString(twentyFourHourClock);
    });

    test('Calendar number of seconds in this minute', () {
      // Allow for a leap second
      expect(calendar.NumberOfSecondsInThisMinute, closeTo(60, 1));
    });

    test('Calendar number of years in this era', () {
      final japaneseCalendar = convertToHString('JapaneseCalendar');
      calendar
        ..ChangeCalendarSystem(japaneseCalendar)
        ..Era = 3; // 昭和 (Showa)
      expect(calendar.NumberOfYearsInThisEra, equals(64));
      WindowsDeleteString(japaneseCalendar);
    });

    test('Change numeral system', () {
      final arabicNumerals = '٠١٢٣٤٥٦٧٨٩'.split('');
      calendar.NumeralSystem = 'arab';
      final date = calendar.MonthAsPaddedNumericString(2);

      expect(arabicNumerals, contains(date[0]));
      expect(arabicNumerals, contains(date[1]));
    });

    test('Calendar current period', () {
      final twelveHourClock = convertToHString('12HourClock');
      calendar.ChangeClock(twelveHourClock);
      expect(calendar.Period, isIn([1, 2]));
      WindowsDeleteString(twelveHourClock);
    });

    test('Calendar second', () {
      expect(calendar.Second, inInclusiveRange(0, 59));
    });

    test('Calendar year', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);
      expect(calendar.Year, greaterThanOrEqualTo(2021));
      WindowsDeleteString(gregorianCalendar);
    });

    test('Calendar era name', () {
      final gregorianCalendar = convertToHString('GregorianCalendar');
      calendar.ChangeCalendarSystem(gregorianCalendar);
      expect(calendar.EraAsFullString(), equals('A.D.'));
      WindowsDeleteString(gregorianCalendar);
    });

    test('Day of week for current month is the same across Dart and WinRT', () {
      // Dart day of week goes [1..7] for [Mon..Sun]
      final date = DateTime.now();
      final firstOfMonth = date.add(Duration(days: -date.day + 1));
      final dartDay = firstOfMonth.weekday == 7 ? 0 : firstOfMonth.weekday;

      // WinRT day of week goes [0..6] for [Sun..Sat]
      calendar.AddDays(-calendar.Day + 1);
      final winrtDay = calendar.DayOfWeek;

      expect(winrtDay, equals(dartDay));
    });

    test('Calendar add years', () {
      calendar.AddYears(10);
      expect(calendar.Year, greaterThanOrEqualTo(2031));
    });

    test('Calendar subtract years', () {
      // These tests will start failing in 2100 :)
      calendar.AddYears(-100);
      expect(calendar.Year, inInclusiveRange(1921, 2000));
      calendar.AddYears(-100);
      expect(calendar.Year, inInclusiveRange(1821, 1900));
      calendar.AddYears(-100);
      expect(calendar.Year, inInclusiveRange(1721, 1800));
    });

    test('Calendar clone', () {
      final calendar2 = ICalendar(calendar.Clone());

      expect(
          calendar2.runtimeClassName, equals('Windows.Globalization.Calendar'));
      expect(calendar2.Year, equals(calendar.Year));
    });

    test('Add and delete days', () {
      final original = calendar.Clone();
      calendar
        ..AddDays(1)
        ..AddDays(-1);
      final compare = calendar.Compare(original);
      expect(compare, isZero);
    });

    test('Add and delete days 2', () {
      final original = calendar.Clone();
      calendar
        ..AddDays(2)
        ..AddDays(-1);
      final compare = calendar.Compare(original);
      expect(compare, isPositive);
    });

    test('Add and delete days 3', () {
      final original = calendar.Clone();
      calendar
        ..AddDays(2)
        ..AddDays(-3);
      final compare = calendar.Compare(original);
      expect(compare, isNegative);
    });

    test('Calendar month as string', () {
      // Repeat to ensure that this doesn't fail because of some kind of memory
      // issue.
      for (var i = 0; i < 10000; i++) {
        final month = calendar.MonthAsFullString();
        expect(
            month,
            isIn([
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
              'December'
            ]));
      }
    });

    test('Calendar month as truncated string', () {
      // Repeat to ensure that this doesn't fail because of some kind of memory
      // issue.
      for (var i = 0; i < 10000; i++) {
        final month = calendar.MonthAsString(3);
        expect(
            month,
            isIn([
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
              'Dec'
            ]));
      }
    });

    test('Calendar resolved language', () {
      final resolvedLanguage = calendar.ResolvedLanguage;

      // Should be something like en-US
      expect(resolvedLanguage[2], equals('-'));
      expect(resolvedLanguage.length, equals(5));
    });

    tearDown(() {
      free(calendar.ptr);
      winrtUninitialize();
    });
  }
}
