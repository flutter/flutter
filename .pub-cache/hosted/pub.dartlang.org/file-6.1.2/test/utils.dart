// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:test/test.dart';

const Duration _oneSecond = Duration(seconds: 1);

/// Returns a [DateTime] with an exact second-precision by removing the
/// milliseconds and microseconds from the specified [time].
///
/// If [time] is not specified, it will default to the current time.
DateTime floor([DateTime? time]) {
  time ??= DateTime.now();
  return time.subtract(Duration(
    milliseconds: time.millisecond,
    microseconds: time.microsecond,
  ));
}

/// Returns a [DateTime] with an exact second precision, rounding up to the
/// nearest second if necessary.
///
/// If [time] is not specified, it will default to the current time.
DateTime ceil([DateTime? time]) {
  time ??= DateTime.now();
  int microseconds = (1000 * time.millisecond) + time.microsecond;
  return (microseconds == 0)
      ? time
      // Add just enough milliseconds and microseconds to reach the next second.
      : time.add(Duration(microseconds: 1000000 - microseconds));
}

/// Returns 1 second before the [floor] of the specified [DateTime].
// TODO(jamesderlin): Remove this and use [floor], https://github.com/dart-lang/sdk/issues/42444
DateTime downstairs([DateTime? time]) => floor(time).subtract(_oneSecond);

/// Successfully matches against a [DateTime] that is the same moment or before
/// the specified [time].
Matcher isSameOrBefore(DateTime time) => _IsSameOrBefore(time);

/// Successfully matches against a [DateTime] that is the same moment or after
/// the specified [time].
Matcher isSameOrAfter(DateTime time) => _IsSameOrAfter(time);

/// Successfully matches against a [DateTime] that is after the specified
/// [time].
Matcher isAfter(DateTime time) => _IsAfter(time);

abstract class _CompareDateTime extends Matcher {
  const _CompareDateTime(this._time, this._matcher);

  final DateTime _time;
  final Matcher _matcher;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return item is DateTime &&
        _matcher.matches(item.compareTo(_time), <dynamic, dynamic>{});
  }

  @protected
  String get descriptionOperator;

  @override
  Description describe(Description description) =>
      description.add('a DateTime $descriptionOperator $_time');

  @protected
  String get mismatchAdjective;

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is DateTime) {
      Duration diff = item.difference(_time).abs();
      return description.add('is $mismatchAdjective $_time by $diff');
    } else {
      return description.add('is not a DateTime');
    }
  }
}

class _IsSameOrBefore extends _CompareDateTime {
  const _IsSameOrBefore(DateTime time) : super(time, isNonPositive);

  @override
  String get descriptionOperator => '<=';

  @override
  String get mismatchAdjective => 'after';
}

class _IsSameOrAfter extends _CompareDateTime {
  const _IsSameOrAfter(DateTime time) : super(time, isNonNegative);

  @override
  String get descriptionOperator => '>=';

  @override
  String get mismatchAdjective => 'before';
}

class _IsAfter extends _CompareDateTime {
  const _IsAfter(DateTime time) : super(time, isPositive);

  @override
  String get descriptionOperator => '>';

  @override
  String get mismatchAdjective => 'before';
}
