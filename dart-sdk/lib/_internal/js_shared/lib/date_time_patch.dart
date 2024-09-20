// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;
import 'dart:_internal' show patch;
import 'dart:_js_helper' show checkInt, Primitives;

// Patch for DateTime implementation.
@patch
class DateTime {
  /// The value component of this DateTime, equal to [millisecondsSinceEpoch].
  final int _value;

  /// The [microsecond] component of this DateTime, in the range [0...999].
  final int _microsecond;

  /// Constructor for pre-validated components.
  DateTime._(this._value, this._microsecond, {required this.isUtc});

  /// Constructs a new [DateTime] instance with the given value.
  ///
  /// If [isUtc] is false, then the date is in the local time zone.
  DateTime._withValueChecked(int millisecondsSinceEpoch, int microsecond,
      {required bool isUtc})
      : _value = _validate(millisecondsSinceEpoch, microsecond, isUtc),
        _microsecond = microsecond,
        this.isUtc = isUtc;

  @patch
  DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc = false})
      : this._withValueChecked(millisecondsSinceEpoch, 0, isUtc: isUtc);

  @patch
  DateTime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc = false})
      : this._withValueChecked(
            (microsecondsSinceEpoch - microsecondsSinceEpoch % 1000) ~/ 1000,
            microsecondsSinceEpoch % 1000,
            isUtc: isUtc);

  @patch
  DateTime._internal(int year, int month, int day, int hour, int minute,
      int second, int millisecond, int microsecond, bool isUtc)
      // checkBool is manually inlined here because dart2js doesn't inline it
      // and [isUtc] is usually a constant.
      : this.isUtc =
            isUtc is bool ? isUtc : throw ArgumentError.value(isUtc, 'isUtc'),
        _value = Primitives.valueFromDecomposedDate(year, month, day, hour,
                minute, second, millisecond, microsecond, isUtc) ??
            _sentinel,
        _microsecond = microsecond % 1000 {
    if (_value == _sentinel) {
      throw ArgumentError('($year, $month, $day,'
          ' $hour, $minute, $second, $millisecond, $microsecond)');
    }
  }

  static const _sentinel = _maxMillisecondsSinceEpoch * 10;
  static const _sentinelConstraint = _sentinel < -_maxMillisecondsSinceEpoch ||
      _sentinel > _maxMillisecondsSinceEpoch;
  static const _sentinelAssertion = 1 ~/ (_sentinelConstraint ? 1 : 0);

  @patch
  DateTime._now()
      : isUtc = false,
        _value = Primitives.dateNow(),
        _microsecond = 0;

  @patch
  DateTime._nowUtc()
      : isUtc = true,
        _value = Primitives.dateNow(),
        _microsecond = 0;

  @patch
  DateTime _withUtc({required bool isUtc}) {
    return DateTime._(_value, _microsecond, isUtc: isUtc);
  }

  @patch
  static DateTime? _finishParse(int year, int month, int day, int hour,
      int minute, int second, int millisecond, int microsecond, bool isUtc) {
    final value = Primitives.valueFromDecomposedDate(year, month, day, hour,
        minute, second, millisecond, microsecond, isUtc);
    if (value == null) return null;
    return DateTime._withValueChecked(value, microsecond, isUtc: isUtc);
  }

  @patch
  String get timeZoneName {
    if (isUtc) return "UTC";
    return Primitives.getTimeZoneName(this);
  }

  @patch
  Duration get timeZoneOffset {
    if (isUtc) return Duration.zero;
    return Duration(minutes: Primitives.getTimeZoneOffsetInMinutes(this));
  }

  @patch
  DateTime add(Duration duration) => _addMicroseconds(duration.inMicroseconds);

  @patch
  DateTime subtract(Duration duration) =>
      _addMicroseconds(0 - duration.inMicroseconds);

  DateTime _addMicroseconds(int durationMicroseconds) {
    final durationLo = durationMicroseconds % 1000;
    final durationHi = (durationMicroseconds - durationLo) ~/ 1000;
    final sumLo = _microsecond + durationLo;
    final microsecond = sumLo % 1000;
    final carry = (sumLo - microsecond) ~/ 1000;
    final milliseconds = _value + carry + durationHi;
    return DateTime._withValueChecked(milliseconds, microsecond, isUtc: isUtc);
  }

  @patch
  Duration difference(DateTime other) {
    final deltaMilliseconds =
        millisecondsSinceEpoch - other.millisecondsSinceEpoch;
    final deltaMicroseconds = microsecond - other.microsecond;
    return Duration(
        milliseconds: deltaMilliseconds, microseconds: deltaMicroseconds);
  }

  @patch
  int get millisecondsSinceEpoch => _value;

  @patch
  int get microsecondsSinceEpoch => 1000 * _value + _microsecond;

  @patch
  int get year => Primitives.getYear(this);

  @patch
  int get month => Primitives.getMonth(this);

  @patch
  int get day => Primitives.getDay(this);

  @patch
  int get hour => Primitives.getHours(this);

  @patch
  int get minute => Primitives.getMinutes(this);

  @patch
  int get second => Primitives.getSeconds(this);

  @patch
  int get millisecond => Primitives.getMilliseconds(this);

  @patch
  int get microsecond => _microsecond;

  @patch
  int get weekday => Primitives.getWeekday(this);

  @patch
  bool operator ==(Object other) =>
      other is DateTime &&
      millisecondsSinceEpoch == other.millisecondsSinceEpoch &&
      microsecond == other.microsecond &&
      isUtc == other.isUtc;

  @patch
  int get hashCode => Object.hash(_value, _microsecond);

  @patch
  bool isBefore(DateTime other) =>
      millisecondsSinceEpoch < other.millisecondsSinceEpoch ||
      millisecondsSinceEpoch == other.millisecondsSinceEpoch &&
          microsecond < other.microsecond;

  @patch
  bool isAfter(DateTime other) =>
      millisecondsSinceEpoch > other.millisecondsSinceEpoch ||
      millisecondsSinceEpoch == other.millisecondsSinceEpoch &&
          microsecond > other.microsecond;

  @patch
  bool isAtSameMomentAs(DateTime other) =>
      millisecondsSinceEpoch == other.millisecondsSinceEpoch &&
      microsecond == other.microsecond;

  @patch
  int compareTo(DateTime other) {
    final r = millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);
    if (r != 0) return r;
    return microsecond.compareTo(other.microsecond);
  }
}
