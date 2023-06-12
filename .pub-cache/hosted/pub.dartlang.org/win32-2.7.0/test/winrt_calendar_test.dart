// ignore_for_file: constant_identifier_names

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

      calendar = Calendar();
    });

    test('Calendar is a materialized object', () {
      expect(calendar.trustLevel, equals(TrustLevel.baseTrust));
      expect(
          calendar.runtimeClassName, equals('Windows.Globalization.Calendar'));
    });

    test('Calendar.Clone', () {
      final calendar2 = Calendar.fromPointer(calendar.Clone());

      expect(
          calendar2.runtimeClassName, equals('Windows.Globalization.Calendar'));
      expect(calendar2.Year, equals(calendar.Year));
    });

    test('Calendar.SetToMin', () {
      final today = calendar.Clone();

      calendar.SetToMin();
      expect(calendar.Compare(today), isNegative);
    });

    test('Calendar.SetToMax', () {
      final today = calendar.Clone();

      calendar.SetToMax();
      expect(calendar.Compare(today), isPositive);
    });

    test('Calendar.Languages', () {
      expect(calendar.Languages.length, isPositive);
      expect(calendar.Languages.first, contains('-')); // e.g. en-US
    });

    test('Calendar.NumeralSystem getter', () {
      // Examples: Arab, ArabExt, Bali, Beng, Cham, etc.
      expect(calendar.NumeralSystem.length, greaterThan(3));
    });

    test('Calendar.NumeralSystem setter', () {
      final arabicNumerals = '٠١٢٣٤٥٦٧٨٩'.split('');
      calendar.NumeralSystem = 'arab';
      final date = calendar.MonthAsPaddedNumericString(2);

      expect(arabicNumerals, contains(date[0]));
      expect(arabicNumerals, contains(date[1]));
    });

    test('Calendar.GetCalendarSystem', () {
      // Examples: GregorianCalendar, JapaneseCalendar etc.
      final calendarSystem = calendar.GetCalendarSystem();
      expect(calendarSystem, endsWith('Calendar'));
    });

    test('Calendar.ChangeCalendarSystem', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.Era, equals(1));
    });

    test('Calendar.GetClock', () {
      // Examples: 12HourClock, 24HourClock
      final clock = calendar.GetClock();
      expect(clock, endsWith('Clock'));
    });

    test('Calendar.ChangeClock', () {
      calendar.ChangeClock('12HourClock');
      expect(calendar.Hour, inInclusiveRange(1, 12));
    });

    test('Calendar.GetDateTime', () {
      final winrtDate = calendar.GetDateTime();
      final dartDate = DateTime.now().toUtc();

      expect(winrtDate.year, equals(dartDate.year));
      expect(winrtDate.month, equals(dartDate.month));
      expect(winrtDate.day, equals(dartDate.day));
      expect(winrtDate.hour, equals(dartDate.hour));
      expect(winrtDate.minute, equals(dartDate.minute));
      expect(winrtDate.second, closeTo(dartDate.second, 2)); // allow flex
    });

    test('Calendar.SetDateTime', () {
      final dartDate = DateTime.utc(2017, 9, 7, 17, 30);
      calendar.SetDateTime(dartDate);
      final winrtDate = calendar.GetDateTime();
      expect(winrtDate.year, equals(2017));
      expect(winrtDate.month, equals(9));
      expect(winrtDate.day, equals(7));
      expect(winrtDate.hour, equals(17));
      expect(winrtDate.minute, equals(30));
    });

    test('Calendar.SetToNow', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      final dartDate = DateTime.utc(2017, 9, 7, 17, 30);
      calendar
        ..SetDateTime(dartDate) // set to a known time
        ..SetToNow(); // change to now

      expect(calendar.Year, greaterThanOrEqualTo(2022));
    });

    test('Calendar.FirstEra', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');

      // Per Microsoft docs, the WinRT implementation only recognizes the
      // current era (A.D.). See:
      // https://docs.microsoft.com/en-us/uwp/api/windows.globalization.calendaridentifiers.gregorian
      expect(calendar.FirstEra, equals(1));
    });

    test('Calendar.LastEra', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.FirstEra, equals(1));
      expect(calendar.LastEra, equals(1));

      // Most systems should be in the Reiwa (令和) era, but a system without
      // the calendar update will be in the Heisei (平成) era. In either event,
      // there should be at least four Japanese eras registered by WinRT.
      calendar.ChangeCalendarSystem('JapaneseCalendar');
      expect(calendar.FirstEra, equals(1));
      expect(calendar.LastEra, greaterThanOrEqualTo(4));
    });

    test('Calendar.NumberOfEras', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.NumberOfEras, equals(1));
    });

    test('Calendar.Era getter', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.Era, equals(1));
    });

    test('Calendar.Era setter', () {
      // Set an invalid era.
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(() => calendar.Era = 2, throwsA(isA<WindowsException>()));
    });

    test('Calendar.AddEras', () {
      calendar
        ..ChangeCalendarSystem('JapaneseCalendar')
        ..Era = 1 // 明治 (Meiji)
        ..AddEras(3); // 平成 (Heisei)
      expect(calendar.Era, equals(4));
    });

    test('Calendar.EraAsFullString', () {
      calendar
        ..ChangeCalendarSystem('JapaneseCalendar')
        ..Era = 1 // 明治 (Meiji)
        ..AddEras(3); // 平成 (Heisei)
      expect(calendar.EraAsFullString(), equals('平成'));
    });

    test('Calendar.EraAsString', () {
      calendar
        ..ChangeCalendarSystem('JapaneseCalendar')
        ..Era = 1; // 明治 (Meiji)
      expect(calendar.EraAsString(1), equals('明'));
    });

    test('Calendar.FirstYearInThisEra', () {
      calendar.ChangeCalendarSystem('HebrewCalendar');
      expect(calendar.FirstYearInThisEra, equals(5343));
    });

    test('Calendar.LastYearInThisEra', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.LastYearInThisEra, equals(9999));
    });

    test('Calendar.NumberOfYearsInThisEra', () {
      calendar
        ..ChangeCalendarSystem('JapaneseCalendar')
        ..Era = 3; // 昭和 (Showa)
      expect(calendar.NumberOfYearsInThisEra, equals(64));
    });

    test('Calendar.Year getter', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.Year, greaterThanOrEqualTo(2021));
    });

    test('Calendar.Day getter', () {
      expect(calendar.Day, inInclusiveRange(1, 31));
    });

    test('Calendar.Day setter', () {
      calendar.Day = 13;
      expect(calendar.Day, equals(13));
    });

    test('Calendar.DayOfWeek getter', () {
      expect(calendar.DayOfWeek, inInclusiveRange(0, 6));
    });

    test('Calendar.FirstDayInThisMonth getter', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.FirstDayInThisMonth, equals(1));
    });

    test('Calendar.FirstHourInThisPeriod getter', () {
      calendar.ChangeClock('12HourClock');
      expect(calendar.FirstHourInThisPeriod, isIn([0, 12]));
    });

    test('Calendar.FirstMinuteInThisHour getter', () {
      expect(calendar.FirstMinuteInThisHour, equals(0));
    });

    test('Calendar.FirstMonthInThisYear getter', () {
      expect(calendar.FirstMonthInThisYear, equals(1));
    });

    test('Calendar.FirstMonthInThisYear getter', () {
      expect(calendar.FirstMonthInThisYear, equals(1));
    });

    test('Calendar.FirstSecondInThisMinute getter', () {
      expect(calendar.FirstSecondInThisMinute, equals(0));
    });

    test('Calendar.Hour getter', () {
      expect(calendar.Hour, inInclusiveRange(0, 23));
    });

    test('Calendar.IsDaylightSavingTime getter', () {
      expect(() => calendar.IsDaylightSavingTime, returnsNormally);
    });

    test('Calendar.LastDayInThisMonth getter', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.LastDayInThisMonth, isIn([28, 29, 30, 31]));
    });

    test('Calendar.LastHourInThisPeriod getter', () {
      calendar.ChangeClock('12HourClock');
      expect(calendar.LastHourInThisPeriod, equals(11));
    });

    test('Calendar.LastMinuteInThisHour getter', () {
      calendar.ChangeClock('12HourClock');
      expect(calendar.LastMinuteInThisHour, equals(59));
    });

    test('Calendar.LastMonthInThisYear getter', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.LastMonthInThisYear, equals(12));
    });

    test('Calendar.LastPeriodInThisDay getter', () {
      calendar.ChangeClock('12HourClock');
      expect(calendar.LastPeriodInThisDay, equals(2));
    });

    test('Calendar.LastSecondInThisMinute getter', () {
      expect(calendar.LastSecondInThisMinute, equals(59));
    });

    test('Calendar.Minute getter', () {
      expect(calendar.Minute, inInclusiveRange(0, 59));
    });

    test('Calendar.Month getter', () {
      expect(calendar.Month, inInclusiveRange(1, 12));
    });

    test('Calendar.Nanosecond getter', () {
      expect(calendar.Nanosecond, isPositive);
    });

    test('Calendar.NumberOfDaysInThisMonth getter', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.NumberOfDaysInThisMonth, isIn([28, 29, 30, 31]));
    });

    test('Calendar.NumberOfHoursInThisPeriod', () {
      calendar.ChangeClock('24HourClock');
      expect(calendar.NumberOfHoursInThisPeriod, equals(24));
    });

    test('Calendar.NumberOfMinutesInThisHour getter', () {
      expect(calendar.NumberOfMinutesInThisHour, equals(60));
    });

    test('Calendar.NumberOfMonthsInThisYear getter', () {
      expect(calendar.NumberOfMonthsInThisYear, equals(12));
    });

    test('Calendar.NumberOfPeriodsInThisDay getter', () {
      calendar.ChangeClock('24HourClock');
      expect(calendar.NumberOfPeriodsInThisDay, equals(1));
    });

    test('Calendar.NumberOfSecondsInThisMinute getter', () {
      // Allow for a leap second
      expect(calendar.NumberOfSecondsInThisMinute, closeTo(60, 1));
    });

    test('Calendar.ResolvedLanguage getter', () {
      final resolvedLanguage = calendar.ResolvedLanguage;

      // Should be something like en-US
      expect(resolvedLanguage[2], equals('-'));
      expect(resolvedLanguage.length, equals(5));
    });

    test('Calendar.NumeralSystem getter', () {
      final arabicNumerals = '٠١٢٣٤٥٦٧٨٩'.split('');
      calendar.NumeralSystem = 'arab';
      final date = calendar.MonthAsPaddedNumericString(2);

      expect(arabicNumerals, contains(date[0]));
      expect(arabicNumerals, contains(date[1]));
    });

    test('Calendar.Period getter', () {
      calendar.ChangeClock('12HourClock');
      expect(calendar.Period, isIn([1, 2]));
    });

    test('Calendar.Second getter', () {
      expect(calendar.Second, inInclusiveRange(0, 59));
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

    test('Calendar.AddYears', () {
      calendar.AddYears(10);
      expect(calendar.Year, greaterThanOrEqualTo(2031));
    });

    test('Calendar.AddYears 2', () {
      // These tests will start failing in 2100 :)
      calendar.AddYears(-100);
      expect(calendar.Year, inInclusiveRange(1921, 2000));
      calendar.AddYears(-100);
      expect(calendar.Year, inInclusiveRange(1821, 1900));
      calendar.AddYears(-100);
      expect(calendar.Year, inInclusiveRange(1721, 1800));
    });

    test('Compare equality', () {
      final original = calendar.Clone();
      calendar
        ..AddDays(1)
        ..AddDays(-1);
      final compare = calendar.Compare(original);
      expect(compare, isZero);
    });

    test('Compare positive', () {
      final original = calendar.Clone();
      calendar
        ..AddDays(2)
        ..AddDays(-1);
      final compare = calendar.Compare(original);
      expect(compare, isPositive);
    });

    test('Compare negative', () {
      final original = calendar.Clone();
      calendar
        ..AddDays(2)
        ..AddDays(-3);
      final compare = calendar.Compare(original);
      expect(compare, isNegative);
    });

    test('Calendar.EraAsFullString', () {
      calendar.ChangeCalendarSystem('GregorianCalendar');
      expect(calendar.EraAsFullString(), equals('A.D.'));
    });

    test('Calendar.MonthAsFullString', () {
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

    test('Calendar.MonthAsString', () {
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

    // test('Calendar.CreateCalendarWithTimeZone constructor', () {
    //   final pickerPtr = CreateObject(
    //       'Windows.Storage.Pickers.FileOpenPicker', IID_IFileOpenPicker);
    //   final picker = IFileOpenPicker(pickerPtr);
    //   final languages = picker.FileTypeFilter..ReplaceAll(['en-US', 'en-GB']);

    //   const IID_Iterable = '{E2FCC7C1-3BFC-5A0B-B2B0-72E769D1CB7E}';
    //   final pIterable = languages.toInterface(IID_Iterable);
    //   final customCal = Calendar.CreateCalendarWithTimeZone(
    //       pIterable, 'GregorianCalendar', '24HourClock', 'America/Los_Angeles');

    //   expect(customCal.GetTimeZone(), equals('America/Los_Angeles'));
    // });

    tearDown(() {
      free(calendar.ptr);
      winrtUninitialize();
    });
  }
}
