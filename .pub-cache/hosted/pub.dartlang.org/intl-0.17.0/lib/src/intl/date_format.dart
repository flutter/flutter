// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:intl/date_symbols.dart';
import 'package:intl/src/date_format_internal.dart';
import 'package:intl/src/intl_helpers.dart' as helpers;

import 'constants.dart' as constants;
import 'date_builder.dart';
import 'date_computation.dart' as date_computation;
import 'intl_stream.dart';
import 'regexp.dart' as regexp;

part 'date_format_field.dart';

// Suppress naming issues as changes would breaking.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

// TODO(efortuna): Customized pattern system -- suggested by i18n needs
// feedback on appropriateness.
/// DateFormat is for formatting and parsing dates in a locale-sensitive
/// manner.
///
/// It allows the user to choose from a set of standard date time formats as
/// well as specify a customized pattern under certain locales. Date elements
/// that vary across locales include month name, week name, field order, etc.
/// We also allow the user to use any customized pattern to parse or format
/// date-time strings under certain locales. Date elements that vary across
/// locales include month name, weekname, field, order, etc.
///
/// Formatting dates in the default 'en_US' format does not require any
/// initialization. e.g.
///
/// ```dart
/// print(DateFormat.yMMMd().format(DateTime.now()));
/// ```
///
/// But for other locales, the formatting data for the locale must be
/// obtained. This can currently be done in one of three ways, determined by
/// which library you import. In all cases, the 'initializeDateFormatting'
/// method must be called and will return a future that is complete once the
/// locale data is available. The result of the future isn't important, but the
/// data for that locale is available to the date formatting and parsing once it
/// completes.
///
/// The easiest option is that the data may be available locally, imported in a
/// library that contains data for all the locales.
///
/// ```dart
/// import 'package:intl/date_symbol_data_local.dart';
/// initializeDateFormatting('fr_FR', null).then((_) => runMyCode());
/// ```
///
/// If we are running outside of a browser, we may want to read the data
/// from files in the file system.
///
/// ```dart
/// import 'package:intl/date_symbol_data_file.dart';
/// initializeDateFormatting('de_DE', null).then((_) => runMyCode());
/// ```
///
/// If we are running in a browser, we may want to read the data from the
/// server using the XmlHttpRequest mechanism.
///
/// ```dart
/// import 'package:intl/date_symbol_data_http_request.dart';
/// initializeDateFormatting('pt_BR', null).then((_) => runMyCode());
/// ```
///
/// Once we have the locale data, we need to specify the particular format.
/// This library uses the ICU/JDK date/time pattern specification both for
/// complete format specifications and also the abbreviated 'skeleton' form
/// which can also adapt to different locales and is preferred where available.
///
/// Skeletons: These can be specified either as the ICU constant name or as the
/// skeleton to which it resolves. The supported set of skeletons is as follows.
/// For each skeleton there is a named constructor that can be used to create
/// it.  It's also possible to pass the skeleton as a string, but the
/// constructor is preferred.
///
///      ICU Name                   Skeleton
///      --------                   --------
///      DAY                          d
///      ABBR_WEEKDAY                 E
///      WEEKDAY                      EEEE
///      ABBR_STANDALONE_MONTH        LLL
///      STANDALONE_MONTH             LLLL
///      NUM_MONTH                    M
///      NUM_MONTH_DAY                Md
///      NUM_MONTH_WEEKDAY_DAY        MEd
///      ABBR_MONTH                   MMM
///      ABBR_MONTH_DAY               MMMd
///      ABBR_MONTH_WEEKDAY_DAY       MMMEd
///      MONTH                        MMMM
///      MONTH_DAY                    MMMMd
///      MONTH_WEEKDAY_DAY            MMMMEEEEd
///      ABBR_QUARTER                 QQQ
///      QUARTER                      QQQQ
///      YEAR                         y
///      YEAR_NUM_MONTH               yM
///      YEAR_NUM_MONTH_DAY           yMd
///      YEAR_NUM_MONTH_WEEKDAY_DAY   yMEd
///      YEAR_ABBR_MONTH              yMMM
///      YEAR_ABBR_MONTH_DAY          yMMMd
///      YEAR_ABBR_MONTH_WEEKDAY_DAY  yMMMEd
///      YEAR_MONTH                   yMMMM
///      YEAR_MONTH_DAY               yMMMMd
///      YEAR_MONTH_WEEKDAY_DAY       yMMMMEEEEd
///      YEAR_ABBR_QUARTER            yQQQ
///      YEAR_QUARTER                 yQQQQ
///      HOUR24                       H
///      HOUR24_MINUTE                Hm
///      HOUR24_MINUTE_SECOND         Hms
///      HOUR                         j
///      HOUR_MINUTE                  jm
///      HOUR_MINUTE_SECOND           jms
///      HOUR_MINUTE_GENERIC_TZ       jmv   (not yet implemented)
///      HOUR_MINUTE_TZ               jmz   (not yet implemented)
///      HOUR_GENERIC_TZ              jv    (not yet implemented)
///      HOUR_TZ                      jz    (not yet implemented)
///      MINUTE                       m
///      MINUTE_SECOND                ms
///      SECOND                       s
//
// TODO(https://github.com/dart-lang/intl/issues/74): Update table above.
///
/// Examples Using the US Locale:
///
///      Pattern                           Result
///      ----------------                  -------
///      DateFormat.yMd()                 -> 7/10/1996
///      DateFormat('yMd')                -> 7/10/1996
///      DateFormat.yMMMMd('en_US')       -> July 10, 1996
///      DateFormat.jm()                  -> 5:08 PM
///      DateFormat.yMd().add_jm()        -> 7/10/1996 5:08 PM
///      DateFormat.Hm()                  -> 17:08 // force 24 hour time
///
/// Explicit Pattern Syntax: Formats can also be specified with a pattern
/// string.  This can be used for formats that don't have a skeleton available,
/// but these will not adapt to different locales. For example, in an explicit
/// pattern the letters 'H' and 'h' are available for 24 hour and 12 hour time
/// formats respectively. But there isn't a way in an explicit pattern to get
/// the behaviour of the 'j' skeleton, which prints 24 hour or 12 hour time
/// according to the conventions of the locale, and also includes am/pm markers
/// where appropriate. So it is preferable to use the skeletons.
///
/// The following characters are available in explicit patterns:
///
///     Symbol   Meaning                Presentation       Example
///     ------   -------                ------------       -------
///     G        era designator         (Text)             AD
///     y        year                   (Number)           1996
///     M        month in year          (Text & Number)    July & 07
///     L        standalone month       (Text & Number)    July & 07
///     d        day in month           (Number)           10
///     c        standalone day         (Number)           10
///     h        hour in am/pm (1~12)   (Number)           12
///     H        hour in day (0~23)     (Number)           0
///     m        minute in hour         (Number)           30
///     s        second in minute       (Number)           55
///     S        fractional second      (Number)           978
///     E        day of week            (Text)             Tuesday
///     D        day in year            (Number)           189
///     a        am/pm marker           (Text)             PM
///     k        hour in day (1~24)     (Number)           24
///     K        hour in am/pm (0~11)   (Number)           0
///     Q        quarter                (Text)             Q3
///     '        escape for text        (Delimiter)        'Date='
///     ''       single quote           (Literal)          'o''clock'
///
//  TODO(https://github.com/dart-lang/intl/issues/74): Merge tables.
//
/// The following characters are reserved and currently are unimplemented:
///
///     Symbol   Meaning                Presentation       Example
///     ------   -------                ------------       -------
///     z        time zone              (Text)             Pacific Standard Time
///     Z        time zone (RFC 822)    (Number)           -0800
///     v        time zone (generic)    (Text)             Pacific Time
///
/// The count of pattern letters determine the format.
///
/// **Text**:
/// * 5 pattern letters--use narrow form for standalone. Otherwise not used.
/// * 4 or more pattern letters--use full form,
/// * 3 pattern letters--use short or abbreviated form if one exists
/// * less than 3--use numeric form if one exists
///
/// **Number**: the minimum number of digits. Shorter numbers are zero-padded to
/// this amount (e.g. if 'm' produces '6', 'mm' produces '06'). Year is handled
/// specially; that is, if the count of 'y' is 2, the Year will be truncated to
/// 2 digits. (e.g., if 'yyyy' produces '1997', 'yy' produces '97'.) Unlike
/// other fields, fractional seconds are padded on the right with zero.
///
/// **(Text & Number)**: 3 or over, use text, otherwise use number.
///
/// Any characters not in the pattern will be treated as quoted text. For
/// instance, characters like ':', '.', ' ', '#' and '@' will appear in the
/// resulting text even though they are not enclosed in single quotes. In our
/// current pattern usage, not all letters have meanings. But those unused
/// letters are strongly discouraged to be used as quoted text without quotes,
/// because we may use other letters as pattern characters in the future.
///
/// Examples Using the US Locale:
///
///     Format Pattern                    Result
///     --------------                    -------
///     'EEE, MMM d, ''yy'                Wed, Jul 10, '96
///     'h:mm a'                          12:08 PM
///     'yyyyy.MMMMM.dd GGG hh:mm aaa'    01996.July.10 AD 12:08 PM
//
// TODO(https://github.com/dart-lang/intl/issues/74): Merge tables.
//
//      NOT YET IMPLEMENTED
//      -------------------
//      'yyyy.MM.dd G 'at' HH:mm:ss vvvv' 1996.07.10 AD at 15:08:56 Pacific Time
//      'hh 'o''clock' a, zzzz'           12 o'clock PM, Pacific Daylight Time
//      'K:mm a, vvv'                     0:00 PM, PT
///
/// When parsing a date string using the abbreviated year pattern ('yy'),
/// DateFormat must interpret the abbreviated year relative to some
/// century. It does this by adjusting dates to be within 80 years before and 20
/// years after the time the parse function is called. For example, using a
/// pattern of 'MM/dd/yy' and a DateFormat instance created on Jan 1, 1997,
/// the string '01/11/12' would be interpreted as Jan 11, 2012 while the string
/// '05/04/64' would be interpreted as May 4, 1964. During parsing, only
/// strings consisting of exactly two digits will be parsed into the default
/// century. Any other numeric string, such as a one digit string, a three or
/// more digit string will be interpreted as its face value. Tests that parse
/// two-digit years can control the current date with package:clock.
///
/// If the year pattern does not have exactly two 'y' characters, the year is
/// interpreted literally, regardless of the number of digits. So using the
/// pattern 'MM/dd/yyyy', '01/11/12' parses to Jan 11, 12 A.D.

class DateFormat {
  /// Creates a new DateFormat, using the format specified by [newPattern].
  ///
  /// For forms that match one of our predefined skeletons, we look up the
  /// corresponding pattern in [locale] (or in the default locale if none is
  /// specified) and use the resulting full format string. This is the preferred
  /// usage, but if [newPattern] does not match one of the skeletons, then it is
  /// used as a format directly, but will not be adapted to suit the locale.
  ///
  /// For example, in an en_US locale, specifying the skeleton
  ///
  /// ```dart
  /// DateFormat.yMEd();
  /// ```
  ///
  /// or the explicit
  ///
  /// ```dart
  /// DateFormat('EEE, M/d/y');
  /// ```
  ///
  /// would produce the same result, a date of the form 'Wed, 6/27/2012'.
  ///
  /// The first version would produce a different format string if used in
  /// another locale, but the second format would always be the same.
  ///
  /// If [locale] does not exist in our set of supported locales then an
  /// [ArgumentError] is thrown.
  DateFormat([String? newPattern, String? locale])
      : _locale = helpers.verifiedLocale(locale, localeExists, null)! {
    // TODO(alanknight): It should be possible to specify multiple skeletons eg
    // date, time, timezone all separately. Adding many or named parameters to
    // the constructor seems awkward, especially with the possibility of
    // confusion with the locale. A 'fluent' interface with cascading on an
    // instance might work better? A list of patterns is also possible.
    addPattern(newPattern);
  }

  /// Allows specifying a different way of creating a DateTime instance for
  /// testing.
  ///
  /// There can be rare and erratic errors in DateTime creation in both
  /// JavaScript and the Dart VM, and this allows us to test ways of
  /// compensating for them.
  _DateTimeConstructor dateTimeConstructor = (int year, int month, int day,
      int hour24, int minute, int second, int fractionalSecond, bool utc) {
    if (utc) {
      return DateTime.utc(
          year, month, day, hour24, minute, second, fractionalSecond);
    } else {
      return DateTime(
          year, month, day, hour24, minute, second, fractionalSecond);
    }
  };

  /// Return a string representing [date] formatted according to our locale
  /// and internal format.
  String format(DateTime date) {
    // TODO(efortuna): read optional TimeZone argument (or similar)?
    var result = StringBuffer();
    for (var field in _formatFields) {
      result.write(field.format(date));
    }
    return result.toString();
  }

  /// NOT YET IMPLEMENTED.
  ///
  /// Returns a date string indicating how long ago (3 hours, 2 minutes)
  /// something has happened or how long in the future something will happen
  /// given a [reference] DateTime relative to the current time.
  String formatDuration(DateTime reference) => '';

  /// NOT YET IMPLEMENTED.
  ///
  /// Formats a string indicating how long ago (negative [duration]) or how far
  /// in the future (positive [duration]) some time is with respect to a
  /// reference [date].
  String formatDurationFrom(Duration duration, DateTime date) => '';

  /// Given user input, attempt to parse the [inputString] into the anticipated
  /// format, treating it as being in the local timezone.
  ///
  /// If [inputString] does not match our format, throws a [FormatException].
  /// This will accept dates whose values are not strictly valid, or strings
  /// with additional characters (including whitespace) after a valid date. For
  /// stricter parsing, use [parseStrict].
  DateTime parse(String inputString, [bool utc = false]) =>
      _parse(inputString, utc: utc, strict: false);

  /// Given user input, attempt to parse the [inputString] 'loosely' into the
  /// anticipated format, accepting some variations from the strict format.
  ///
  /// If [inputString] is accepted by [parseStrict], just return the result. If
  /// not, attempt to parse it, but accepting either upper or lower case,
  /// allowing delimiters to be missing and replaced or supplemented with
  /// whitespace, and allowing arbitrary amounts of whitespace wherever
  /// whitespace is permitted. Note that this does not allow trailing
  /// characters, the way [parse] does.  It also does not allow alternative
  /// names for months or weekdays other than those the format knows about. The
  /// restrictions are quite arbitrary and it's not known how well they'll work
  /// for locales that aren't English-like.
  ///
  /// If [inputString] does not parse, this throws a [FormatException].
  ///
  /// For example, this will accept
  ///
  ///       DateFormat.yMMMd('en_US').parseLoose('SEp   3 2014');
  ///       DateFormat.yMd('en_US').parseLoose('09    03/2014');
  ///       DateFormat.yMd('en_US').parseLoose('09 / 03 / 2014');
  ///
  /// It will NOT accept
  ///
  ///       // 'Sept' is not a valid month name.
  ///       DateFormat.yMMMd('en_US').parseLoose('Sept 3, 2014');
  DateTime parseLoose(String inputString, [bool utc = false]) {
    try {
      return _parse(inputString, utc: utc, strict: true);
    } on FormatException {
      return _parseLoose(inputString.toLowerCase(), utc);
    }
  }

  DateTime _parseLoose(String inputString, bool utc) {
    var dateFields = DateBuilder(locale, dateTimeConstructor);
    if (utc) dateFields.utc = true;
    var stream = IntlStream(inputString);
    for (var field in _formatFields) {
      field.parseLoose(stream, dateFields);
    }
    if (!stream.atEnd()) {
      throw FormatException(
          'Characters remaining after date parsing in $inputString');
    }
    dateFields.verify(inputString);
    return dateFields.asDate();
  }

  /// Given user input, attempt to parse the [inputString] into the anticipated
  /// format, treating it as being in the local timezone.
  ///
  /// If [inputString] does not match our format, throws a [FormatException].
  /// This will reject dates whose values are not strictly valid, even if the
  /// DateTime constructor will accept them. It will also reject strings with
  /// additional characters (including whitespace) after a valid date. For
  /// looser parsing, use [parse].
  DateTime parseStrict(String inputString, [bool utc = false]) =>
      _parse(inputString, utc: utc, strict: true);

  DateTime _parse(String inputString, {bool utc = false, bool strict = false}) {
    // TODO(alanknight): The Closure code refers to special parsing of numeric
    // values with no delimiters, which we currently don't do. Should we?
    var dateFields = DateBuilder(locale, dateTimeConstructor);
    if (utc) dateFields.utc = true;
    dateFields.dateOnly = dateOnly;
    var stream = IntlStream(inputString);
    for (var field in _formatFields) {
      field.parse(stream, dateFields);
    }
    if (strict && !stream.atEnd()) {
      throw FormatException(
          'Characters remaining after date parsing in $inputString');
    }
    if (strict) dateFields.verify(inputString);
    return dateFields.asDate();
  }

  /// Does our format only only date fields, and no time fields.
  ///
  /// For example, 'yyyy-MM-dd' would be true, but 'dd hh:mm' would be false.
  bool get dateOnly => _dateOnly ??= _checkDateOnly;
  bool? _dateOnly;
  bool get _checkDateOnly => _formatFields.every((each) => each.forDate);

  /// Given user input, attempt to parse the [inputString] into the anticipated
  /// format, treating it as being in UTC.
  ///
  /// The canonical Dart style name
  /// is [parseUtc], but [parseUTC] is retained
  /// for backward-compatibility.
  DateTime parseUTC(String inputString) => parse(inputString, true);

  /// Given user input, attempt to parse the [inputString] into the anticipated
  /// format, treating it as being in UTC.
  ///
  /// The canonical Dart style name
  /// is [parseUtc], but [parseUTC] is retained
  /// for backward-compatibility.
  DateTime parseUtc(String inputString) => parse(inputString, true);

  /// Return the locale code in which we operate, e.g. 'en_US' or 'pt'.
  String get locale => _locale;

  /// Returns a list of all locales for which we have date formatting
  /// information.
  static List<String> allLocalesWithSymbols() =>
      List<String>.from(dateTimeSymbols.keys);

  /// The named constructors for this class are all conveniences for creating
  /// instances using one of the known 'skeleton' formats, and having code
  /// completion support for discovering those formats.
  /// So,
  ///
  /// ```dart
  /// DateFormat.yMd('en_US')
  /// ```
  ///
  /// is equivalent to
  ///
  /// ```dart
  /// DateFormat('yMd', 'en_US')
  /// ```
  ///
  /// To create a compound format you can use these constructors in combination
  /// with the 'add_*' methods below. e.g.
  ///
  /// ```dart
  /// DateFormat.yMd().add_Hms();
  /// ```
  ///
  /// If the optional [locale] is omitted, the format will be created using the
  /// default locale in [Intl.systemLocale].
  DateFormat.d([locale]) : this('d', locale);
  DateFormat.E([locale]) : this('E', locale);
  DateFormat.EEEE([locale]) : this('EEEE', locale);
  DateFormat.LLL([locale]) : this('LLL', locale);
  DateFormat.LLLL([locale]) : this('LLLL', locale);
  DateFormat.M([locale]) : this('M', locale);
  DateFormat.Md([locale]) : this('Md', locale);
  DateFormat.MEd([locale]) : this('MEd', locale);
  DateFormat.MMM([locale]) : this('MMM', locale);
  DateFormat.MMMd([locale]) : this('MMMd', locale);
  DateFormat.MMMEd([locale]) : this('MMMEd', locale);
  DateFormat.MMMM([locale]) : this('MMMM', locale);
  DateFormat.MMMMd([locale]) : this('MMMMd', locale);
  DateFormat.MMMMEEEEd([locale]) : this('MMMMEEEEd', locale);
  DateFormat.QQQ([locale]) : this('QQQ', locale);
  DateFormat.QQQQ([locale]) : this('QQQQ', locale);
  DateFormat.y([locale]) : this('y', locale);
  DateFormat.yM([locale]) : this('yM', locale);
  DateFormat.yMd([locale]) : this('yMd', locale);
  DateFormat.yMEd([locale]) : this('yMEd', locale);
  DateFormat.yMMM([locale]) : this('yMMM', locale);
  DateFormat.yMMMd([locale]) : this('yMMMd', locale);
  DateFormat.yMMMEd([locale]) : this('yMMMEd', locale);
  DateFormat.yMMMM([locale]) : this('yMMMM', locale);
  DateFormat.yMMMMd([locale]) : this('yMMMMd', locale);
  DateFormat.yMMMMEEEEd([locale]) : this('yMMMMEEEEd', locale);
  DateFormat.yQQQ([locale]) : this('yQQQ', locale);
  DateFormat.yQQQQ([locale]) : this('yQQQQ', locale);
  DateFormat.H([locale]) : this('H', locale);
  DateFormat.Hm([locale]) : this('Hm', locale);
  DateFormat.Hms([locale]) : this('Hms', locale);
  DateFormat.j([locale]) : this('j', locale);
  DateFormat.jm([locale]) : this('jm', locale);
  DateFormat.jms([locale]) : this('jms', locale);

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  DateFormat.jmv([locale]) : this('jmv', locale);

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  DateFormat.jmz([locale]) : this('jmz', locale);

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  DateFormat.jv([locale]) : this('jv', locale);

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  DateFormat.jz([locale]) : this('jz', locale);
  DateFormat.m([locale]) : this('m', locale);
  DateFormat.ms([locale]) : this('ms', locale);
  DateFormat.s([locale]) : this('s', locale);

  /// The 'add_*' methods append a particular skeleton to the format, or set
  /// it as the only format if none was previously set. These are primarily
  /// useful for creating compound formats. For example
  ///
  /// ```dart
  /// DateFormat.yMd().add_Hms();
  /// ```
  ///
  /// would create a date format that prints both the date and the time.
  DateFormat add_d() => addPattern('d');
  DateFormat add_E() => addPattern('E');
  DateFormat add_EEEE() => addPattern('EEEE');
  DateFormat add_LLL() => addPattern('LLL');
  DateFormat add_LLLL() => addPattern('LLLL');
  DateFormat add_M() => addPattern('M');
  DateFormat add_Md() => addPattern('Md');
  DateFormat add_MEd() => addPattern('MEd');
  DateFormat add_MMM() => addPattern('MMM');
  DateFormat add_MMMd() => addPattern('MMMd');
  DateFormat add_MMMEd() => addPattern('MMMEd');
  DateFormat add_MMMM() => addPattern('MMMM');
  DateFormat add_MMMMd() => addPattern('MMMMd');
  DateFormat add_MMMMEEEEd() => addPattern('MMMMEEEEd');
  DateFormat add_QQQ() => addPattern('QQQ');
  DateFormat add_QQQQ() => addPattern('QQQQ');
  DateFormat add_y() => addPattern('y');
  DateFormat add_yM() => addPattern('yM');
  DateFormat add_yMd() => addPattern('yMd');
  DateFormat add_yMEd() => addPattern('yMEd');
  DateFormat add_yMMM() => addPattern('yMMM');
  DateFormat add_yMMMd() => addPattern('yMMMd');
  DateFormat add_yMMMEd() => addPattern('yMMMEd');
  DateFormat add_yMMMM() => addPattern('yMMMM');
  DateFormat add_yMMMMd() => addPattern('yMMMMd');
  DateFormat add_yMMMMEEEEd() => addPattern('yMMMMEEEEd');
  DateFormat add_yQQQ() => addPattern('yQQQ');
  DateFormat add_yQQQQ() => addPattern('yQQQQ');
  DateFormat add_H() => addPattern('H');
  DateFormat add_Hm() => addPattern('Hm');
  DateFormat add_Hms() => addPattern('Hms');
  DateFormat add_j() => addPattern('j');
  DateFormat add_jm() => addPattern('jm');
  DateFormat add_jms() => addPattern('jms');

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  DateFormat add_jmv() => addPattern('jmv');

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  DateFormat add_jmz() => addPattern('jmz');

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  DateFormat add_jv() => addPattern('jv');

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  DateFormat add_jz() => addPattern('jz');
  DateFormat add_m() => addPattern('m');
  DateFormat add_ms() => addPattern('ms');
  DateFormat add_s() => addPattern('s');

  /// For each of the skeleton formats we also allow the use of the
  /// corresponding ICU constant names.
  static const String ABBR_MONTH = 'MMM';
  static const String DAY = 'd';
  static const String ABBR_WEEKDAY = 'E';
  static const String WEEKDAY = 'EEEE';
  static const String ABBR_STANDALONE_MONTH = 'LLL';
  static const String STANDALONE_MONTH = 'LLLL';
  static const String NUM_MONTH = 'M';
  static const String NUM_MONTH_DAY = 'Md';
  static const String NUM_MONTH_WEEKDAY_DAY = 'MEd';
  static const String ABBR_MONTH_DAY = 'MMMd';
  static const String ABBR_MONTH_WEEKDAY_DAY = 'MMMEd';
  static const String MONTH = 'MMMM';
  static const String MONTH_DAY = 'MMMMd';
  static const String MONTH_WEEKDAY_DAY = 'MMMMEEEEd';
  static const String ABBR_QUARTER = 'QQQ';
  static const String QUARTER = 'QQQQ';
  static const String YEAR = 'y';
  static const String YEAR_NUM_MONTH = 'yM';
  static const String YEAR_NUM_MONTH_DAY = 'yMd';
  static const String YEAR_NUM_MONTH_WEEKDAY_DAY = 'yMEd';
  static const String YEAR_ABBR_MONTH = 'yMMM';
  static const String YEAR_ABBR_MONTH_DAY = 'yMMMd';
  static const String YEAR_ABBR_MONTH_WEEKDAY_DAY = 'yMMMEd';
  static const String YEAR_MONTH = 'yMMMM';
  static const String YEAR_MONTH_DAY = 'yMMMMd';
  static const String YEAR_MONTH_WEEKDAY_DAY = 'yMMMMEEEEd';
  static const String YEAR_ABBR_QUARTER = 'yQQQ';
  static const String YEAR_QUARTER = 'yQQQQ';
  static const String HOUR24 = 'H';
  static const String HOUR24_MINUTE = 'Hm';
  static const String HOUR24_MINUTE_SECOND = 'Hms';
  static const String HOUR = 'j';
  static const String HOUR_MINUTE = 'jm';
  static const String HOUR_MINUTE_SECOND = 'jms';

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  static const String HOUR_MINUTE_GENERIC_TZ = 'jmv';

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  static const String HOUR_MINUTE_TZ = 'jmz';

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  static const String HOUR_GENERIC_TZ = 'jv';

  /// NOT YET IMPLEMENTED.
  // TODO(https://github.com/dart-lang/intl/issues/74)
  static const String HOUR_TZ = 'jz';
  static const String MINUTE = 'm';
  static const String MINUTE_SECOND = 'ms';
  static const String SECOND = 's';

  /// The locale in which we operate, e.g. 'en_US', or 'pt'.
  String _locale;

  /// The full template string. This may have been specified directly, or
  /// it may have been derived from a skeleton and the locale information
  /// on how to interpret that skeleton.
  String? _pattern;

  /// We parse the format string into individual [_DateFormatField] objects
  /// that are used to do the actual formatting and parsing. Do not use
  /// this variable directly, use the getter [_formatFields].
  List<_DateFormatField>? _formatFieldsPrivate;

  /// Getter for [_formatFieldsPrivate] that lazily initializes it.
  List<_DateFormatField> get _formatFields {
    if (_formatFieldsPrivate == null) {
      if (_pattern == null) _useDefaultPattern();
      _formatFieldsPrivate = parsePattern(_pattern!);
    }
    return _formatFieldsPrivate!;
  }

  /// We are being asked to do formatting without having set any pattern.
  /// Use a default.
  void _useDefaultPattern() {
    add_yMMMMd();
    add_jms();
  }

  /// A series of regular expressions used to parse a format string into its
  /// component fields.
  static final List<RegExp> _matchers = [
    // Quoted String - anything between single quotes, with escaping
    //   of single quotes by doubling them.
    // e.g. in the pattern 'hh 'o''clock'' will match 'o''clock'
    RegExp('^\'(?:[^\']|\'\')*\''),
    // Fields - any sequence of 1 or more of the same field characters.
    // e.g. in 'hh:mm:ss' will match hh, mm, and ss. But in 'hms' would
    // match each letter individually.
    RegExp('^(?:G+|y+|M+|k+|S+|E+|a+|h+|K+|H+|c+|L+|Q+|d+|D+|m+|s+|v+|z+|Z+)'),
    // Everything else - A sequence that is not quotes or field characters.
    // e.g. in 'hh:mm:ss' will match the colons.
    RegExp('^[^\'GyMkSEahKHcLQdDmsvzZ]+')
  ];

  /// Set our pattern, appending it to any existing patterns. Also adds a single
  /// space to separate the two.
  void _appendPattern(String inputPattern, [String separator = ' ']) {
    _pattern =
        _pattern == null ? inputPattern : '$_pattern$separator$inputPattern';
  }

  /// Add [inputPattern] to this instance as a pattern.
  ///
  /// If there was a previous pattern, then this appends to it, separating the
  /// two by [separator].  [inputPattern] is first looked up in our list of
  /// known skeletons.  If it's found there, then use the corresponding pattern
  /// for this locale.  If it's not, then treat [inputPattern] as an explicit
  /// pattern.
  DateFormat addPattern(String? inputPattern, [String separator = ' ']) {
    // TODO(alanknight): This is an expensive operation. Caching recently used
    // formats, or possibly introducing an entire 'locale' object that would
    // cache patterns for that locale could be a good optimization.
    // If we have already parsed the format fields, reset them.
    _formatFieldsPrivate = null;
    if (inputPattern == null) return this;
    if (!_availableSkeletons.containsKey(inputPattern)) {
      _appendPattern(inputPattern, separator);
    } else {
      _appendPattern(_availableSkeletons[inputPattern], separator);
    }
    return this;
  }

  /// Return the pattern that we use to format dates.
  String? get pattern => _pattern;

  /// Return the skeletons for our current locale.
  Map<dynamic, dynamic> get _availableSkeletons => dateTimePatterns[locale];

  /// Return the [DateSymbols] information for the locale.
  ///
  /// This can be useful to find lists like the names of weekdays or months in a
  /// locale, but the structure of this data may change, and it's generally
  /// better to go through the [format] and [parse] APIs.
  ///
  /// If the locale isn't present, or is uninitialized, throws.
  DateSymbols get dateSymbols {
    if (_locale != lastDateSymbolLocale) {
      lastDateSymbolLocale = _locale;
      cachedDateSymbols = dateTimeSymbols[_locale];
    }
    return cachedDateSymbols!;
  }

  static final Map<String, bool> _useNativeDigitsByDefault = {};

  /// Should a new DateFormat for [locale] have useNativeDigits true.
  ///
  /// For example, for locale 'ar' when this setting is true, DateFormat will
  /// format using Eastern Arabic digits, e.g. '\u0660, \u0661, \u0662'. If it
  /// is false, a new DateFormat will format using ASCII digits.
  static bool shouldUseNativeDigitsByDefaultFor(String locale) {
    return _useNativeDigitsByDefault[locale] ?? true;
  }

  /// Indicate if a new DateFormat for [locale] should have useNativeDigits
  /// true.
  ///
  /// For example, for locale 'ar' when this setting is true, DateFormat will
  /// format using Eastern Arabic digits, e.g. '\u0660, \u0661, \u0662'. If it
  /// is false, a new DateFormat will format using ASCII digits.
  ///
  /// If not indicated, the default value is true, so native digits will be
  /// used.
  static void useNativeDigitsByDefaultFor(String locale, bool value) {
    _useNativeDigitsByDefault[locale] = value;
  }

  bool? _useNativeDigits;

  /// Should we use native digits for printing DateTime, or ASCII.
  ///
  /// The default for this can be set using [useNativeDigitsByDefaultFor].
  bool get useNativeDigits => _useNativeDigits == null
      ? _useNativeDigits = shouldUseNativeDigitsByDefaultFor(locale)
      : _useNativeDigits!;

  /// Should we use native digits for printing DateTime, or ASCII.
  set useNativeDigits(bool native) {
    _useNativeDigits = native;
    // Invalidate any cached information that would depend on this setting.
    _digitMatcher = null;
    _localeZeroCodeUnit = null;
    _localeZero = null;
  }

  /// Caches digit matchers that we have already calculated for particular
  /// digits.
  ///
  /// Keys are the zero digits, and the values are matchers for digits in that
  /// locale.
  static final Map<String, RegExp> _digitMatchers = {};

  RegExp? _digitMatcher;

  /// A regular expression which matches against digits for this locale.
  RegExp get digitMatcher {
    if (_digitMatcher != null) return _digitMatcher!;
    _digitMatcher = _digitMatchers.putIfAbsent(localeZero, _initDigitMatcher);
    return _digitMatcher!;
  }

  int? _localeZeroCodeUnit;

  /// For performance, keep the code unit of the zero digit available.
  int get localeZeroCodeUnit => _localeZeroCodeUnit == null
      ? _localeZeroCodeUnit = localeZero.codeUnitAt(0)
      : _localeZeroCodeUnit!;

  String? _localeZero;

  /// For performance, keep the zero digit available.
  String get localeZero => _localeZero == null
      ? _localeZero = useNativeDigits ? dateSymbols.ZERODIGIT ?? '0' : '0'
      : _localeZero!;

  // Does this use non-ASCII digits, e.g. Eastern Arabic.
  bool get usesNativeDigits =>
      useNativeDigits && _localeZeroCodeUnit != constants.asciiZeroCodeUnit;

  /// Does this use ASCII digits
  bool get usesAsciiDigits => !usesNativeDigits;

  /// Given a numeric string in ASCII digits, return a copy updated for our
  /// locale digits.
  String _localizeDigits(String numberString) {
    if (usesAsciiDigits) return numberString;
    var newDigits = List<int>.filled(numberString.length, 0);
    var oldDigits = numberString.codeUnits;
    for (var i = 0; i < numberString.length; i++) {
      newDigits[i] =
          oldDigits[i] + localeZeroCodeUnit - constants.asciiZeroCodeUnit;
    }
    return String.fromCharCodes(newDigits);
  }

  /// A regular expression that matches for digits in a particular
  /// locale, defined by the digit for zero in that locale.
  RegExp _initDigitMatcher() {
    if (usesAsciiDigits) return regexp.asciiDigitMatcher;
    var localeDigits = Iterable.generate(10, (i) => i)
        .map((i) => localeZeroCodeUnit + i)
        .toList();
    var localeDigitsString = String.fromCharCodes(localeDigits);
    return RegExp('^[$localeDigitsString]+');
  }

  /// Return true if the locale exists, or if it is null. The null case
  /// is interpreted to mean that we use the default locale.
  static bool localeExists(localeName) {
    if (localeName == null) return false;
    return dateTimeSymbols.containsKey(localeName);
  }

  static List<_DateFormatField Function(String, DateFormat)>
      get _fieldConstructors => [
            (pattern, parent) => _DateFormatQuotedField(pattern, parent),
            (pattern, parent) => _DateFormatPatternField(pattern, parent),
            (pattern, parent) => _DateFormatLiteralField(pattern, parent)
          ];

  /// Parse the template pattern and return a list of field objects.
  List<_DateFormatField> parsePattern(String pattern) {
    return _parsePatternHelper(pattern).reversed.toList();
  }

  /// Recursive helper for parsing the template pattern.
  List<_DateFormatField> _parsePatternHelper(String pattern) {
    if (pattern.isEmpty) return [];

    var matched = _match(pattern);
    if (matched == null) return [];

    var parsed =
        _parsePatternHelper(pattern.substring(matched.fullPattern().length));
    parsed.add(matched);
    return parsed;
  }

  /// Find elements in a string that are patterns for specific fields.
  _DateFormatField? _match(String pattern) {
    for (var i = 0; i < _matchers.length; i++) {
      var regex = _matchers[i];
      var match = regex.firstMatch(pattern);
      if (match != null) {
        return _fieldConstructors[i](match.group(0)!, this);
      }
    }
    return null;
  }
}

/// Defines a function type for creating DateTime instances.
typedef _DateTimeConstructor = DateTime Function(int year, int month, int day,
    int hour24, int minute, int second, int fractionalSecond, bool utc);
