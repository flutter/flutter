// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A formatter and parser for [DateTime] in a fixed format [String] pattern.
///
/// For example, calling
/// `FixedDateTimeCodec('YYYYMMDDhhmmss').decodeToLocal('19960425050322')` has
/// the same result as calling `DateTime(1996, 4, 25, 5, 3, 22)`.
///
/// The allowed characters are
/// * `Y`	for “calendar year”
/// * `M`	for “calendar month”
/// * `D`	for “calendar day”
/// * `E`	for “decade”
/// * `C`	for “century”
/// * `h`	for “clock hour”
/// * `m`	for “clock minute”
/// * `s`	for “clock second”
/// * `S`	for “fractional clock second”
///
/// Note: Negative years are not supported.
///
/// Non-allowed characters in the format [pattern] are included when decoding a
/// string, in this case `YYYY kiwi MM` is the same format string as
/// `YYYY------MM`. When encoding a [DateTime], the non-format characters are in
/// the output verbatim.
///
/// Note: this class differs from
/// [DateFormat](https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html)
/// from [package:intl](https://pub.dev/packages/intl) in that here, the format
/// character count is interpreted literally. For example, using the format
/// string `YYY` to decode the string `996` would result in the same [DateTime]
/// as calling `DateTime(996)`, and the same format string used to encode the
/// `DateTime(1996)` would output only the three digits 996.
class FixedDateTimeFormatter {
  static const _powersOfTen = [1, 10, 100, 1000, 10000, 100000];
  static const _validFormatCharacters = [
    _yearCode,
    _monthCode,
    _dayCode,
    _decadeCode,
    _centuryCode,
    _hourCode,
    _minuteCode,
    _secondCode,
    _fractionSecondCode,
  ];
  static const _yearCode = 0x59; /*Y*/
  static const _monthCode = 0x4D; /*M*/
  static const _dayCode = 0x44; /*D*/
  static const _decadeCode = 0x45; /*E*/
  static const _centuryCode = 0x43; /*C*/
  static const _hourCode = 0x68; /*H*/
  static const _minuteCode = 0x6D; /*m*/
  static const _secondCode = 0x73; /*s*/
  static const _fractionSecondCode = 0x53; /*S*/

  /// The format pattern string of this formatter.
  final String pattern;

  /// Whether to create UTC [DateTime] objects when parsing.
  ///
  /// If not, the created [DateTime] objects are in the local time zone.
  final bool isUtc;

  final _blocks = _ParsedFormatBlocks();

  /// Creates a new [FixedDateTimeFormatter] with the provided [pattern].
  ///
  /// The [pattern] interprets the characters mentioned in
  /// [FixedDateTimeFormatter] to represent fields of a `DateTime` value. Other
  /// characters are not special. If [isUtc] is set to false, the DateTime is
  /// constructed with respect to the local timezone.
  ///
  /// There must at most be one sequence of each special character to ensure a
  /// single source of truth when constructing the [DateTime], so a pattern of
  /// `"CCCC-MM-DD, CC"` is invalid, because it has two separate `C` sequences.
  FixedDateTimeFormatter(this.pattern, {this.isUtc = true}) {
    int? currentCharacter;
    var start = 0;
    for (var i = 0; i < pattern.length; i++) {
      var formatCharacter = pattern.codeUnitAt(i);
      if (currentCharacter != formatCharacter) {
        _blocks.saveBlock(currentCharacter, start, i);
        if (_validFormatCharacters.contains(formatCharacter)) {
          var hasSeenBefore = _blocks.formatCharacters.indexOf(formatCharacter);
          if (hasSeenBefore > -1) {
            throw FormatException(
                "Pattern contains more than one '$formatCharacter' block.\n"
                'Previous occurrence at index ${_blocks.starts[hasSeenBefore]}',
                pattern,
                i);
          } else {
            start = i;
            currentCharacter = formatCharacter;
          }
        } else {
          currentCharacter = null;
        }
      }
    }
    _blocks.saveBlock(currentCharacter, start, pattern.length);
  }

  /// Converts a [DateTime] to a [String] as specified by the [pattern].
  ///
  /// The [DateTime.year] must not be negative.
  String encode(DateTime dateTime) {
    if (dateTime.year < 0) {
      throw ArgumentError.value(
        dateTime,
        'dateTime',
        'Year must not be negative',
      );
    }
    var buffer = StringBuffer();
    for (var i = 0; i < _blocks.length; i++) {
      var start = _blocks.starts[i];
      var end = _blocks.ends[i];
      var length = end - start;

      var previousEnd = i > 0 ? _blocks.ends[i - 1] : 0;
      if (previousEnd < start) {
        buffer.write(pattern.substring(previousEnd, start));
      }
      var formatCharacter = _blocks.formatCharacters[i];
      var number = _extractNumberFromDateTime(
        formatCharacter,
        dateTime,
        length,
      );
      if (number.length > length) {
        number = number.substring(number.length - length);
      } else if (length > number.length) {
        number = number.padLeft(length, '0');
      }
      buffer.write(number);
    }
    if (_blocks.length > 0) {
      var lastEnd = _blocks.ends.last;
      if (lastEnd < pattern.length) {
        buffer.write(pattern.substring(lastEnd, pattern.length));
      }
    }
    return buffer.toString();
  }

  String _extractNumberFromDateTime(
    int? formatCharacter,
    DateTime dateTime,
    int length,
  ) {
    int value;
    switch (formatCharacter) {
      case _yearCode:
        value = dateTime.year;
        break;
      case _centuryCode:
        value = dateTime.year ~/ 100;
        break;
      case _decadeCode:
        value = dateTime.year ~/ 10;
        break;
      case _monthCode:
        value = dateTime.month;
        break;
      case _dayCode:
        value = dateTime.day;
        break;
      case _hourCode:
        value = dateTime.hour;
        break;
      case _minuteCode:
        value = dateTime.minute;
        break;
      case _secondCode:
        value = dateTime.second;
        break;
      case _fractionSecondCode:
        value = dateTime.millisecond;
        switch (length) {
          case 1:
            value ~/= 100;
            break;
          case 2:
            value ~/= 10;
            break;
          case 3:
            break;
          case 4:
            value = value * 10 + dateTime.microsecond ~/ 100;
            break;
          case 5:
            value = value * 100 + dateTime.microsecond ~/ 10;
            break;
          case 6:
            value = value * 1000 + dateTime.microsecond;
            break;
          default:
            throw AssertionError(
                'Unreachable, length is restricted to 6 in the constructor');
        }
        break;
      default:
        throw AssertionError(
            'Unreachable, the key is checked in the constructor');
    }
    return value.toString().padLeft(length, '0');
  }

  /// Parses [formattedDateTime] to a [DateTime] as specified by the [pattern].
  ///
  /// Parts of a [DateTime] which are not mentioned in the pattern default to a
  /// value of zero for time parts and year, and a value of 1 for day and month.
  ///
  /// Throws a [FormatException] if the [formattedDateTime] does not match the
  /// [pattern].
  DateTime decode(String formattedDateTime) =>
      _decode(formattedDateTime, isUtc, true)!;

  /// Parses [formattedDateTime] to a [DateTime] as specified by the [pattern].
  ///
  /// Parts of a [DateTime] which are not mentioned in the pattern default to a
  /// value of zero for time parts and year, and a value of 1 for day and month.
  ///
  /// Returns the parsed value, or `null` if the [formattedDateTime] does not
  /// match the [pattern].
  DateTime? tryDecode(String formattedDateTime) =>
      _decode(formattedDateTime, isUtc, false);

  DateTime? _decode(
    String formattedDateTime,
    bool isUtc,
    bool throwOnError,
  ) {
    var year = 0;
    var month = 1;
    var day = 1;
    var hour = 0;
    var minute = 0;
    var second = 0;
    var microsecond = 0;
    for (var i = 0; i < _blocks.length; i++) {
      var formatCharacter = _blocks.formatCharacters[i];
      var number = _extractNumberFromString(formattedDateTime, i, throwOnError);
      if (number != null) {
        if (formatCharacter == _fractionSecondCode) {
          // Special case, as we want fractional seconds to be the leading
          // digits.
          number *= _powersOfTen[6 - (_blocks.ends[i] - _blocks.starts[i])];
        }
        switch (formatCharacter) {
          case _yearCode:
            year += number;
            break;
          case _centuryCode:
            year += number * 100;
            break;
          case _decadeCode:
            year += number * 10;
            break;
          case _monthCode:
            month = number;
            break;
          case _dayCode:
            day = number;
            break;
          case _hourCode:
            hour = number;
            break;
          case _minuteCode:
            minute = number;
            break;
          case _secondCode:
            second = number;
            break;
          case _fractionSecondCode:
            microsecond = number;
            break;
        }
      } else {
        return null;
      }
    }
    if (isUtc) {
      return DateTime.utc(
        year,
        month,
        day,
        hour,
        minute,
        second,
        0,
        microsecond,
      );
    } else {
      return DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
        0,
        microsecond,
      );
    }
  }

  int? _extractNumberFromString(
    String formattedDateTime,
    int index,
    bool throwOnError,
  ) {
    var parsed = tryParse(
      formattedDateTime,
      _blocks.starts[index],
      _blocks.ends[index],
    );
    if (parsed == null && throwOnError) {
      throw FormatException(
        'Expected digits at ${formattedDateTime.substring(
          _blocks.starts[index],
          _blocks.ends[index],
        )}',
        formattedDateTime,
        _blocks.starts[index],
      );
    }
    return parsed;
  }

  int? tryParse(String formattedDateTime, int start, int end) {
    var result = 0;
    for (var i = start; i < end; i++) {
      var digit = formattedDateTime.codeUnitAt(i) ^ 0x30;
      if (digit <= 9) {
        result = result * 10 + digit;
      } else {
        return null;
      }
    }
    return result;
  }
}

class _ParsedFormatBlocks {
  final formatCharacters = <int>[];
  final starts = <int>[];
  final ends = <int>[];

  _ParsedFormatBlocks();

  int get length => formatCharacters.length;

  void saveBlock(int? char, int start, int end) {
    if (char != null) {
      if (char == FixedDateTimeFormatter._fractionSecondCode &&
          end - start > 6) {
        throw FormatException(
          'Fractional seconds can only be specified up to microseconds',
          char,
          start,
        );
      } else if (end - start > 9) {
        throw FormatException(
          'Length of a format char block cannot be larger than 9',
          char,
          start,
        );
      }
      formatCharacters.add(char);
      starts.add(start);
      ends.add(end);
    }
  }
}
