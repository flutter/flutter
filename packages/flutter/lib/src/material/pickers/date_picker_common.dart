// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';

/// Mode of the date picker dialog.
///
/// Either a calendar or text input. In [calendar] mode, a calendar view is
/// displayed and the user taps the day they wish to select. In [input] mode a
/// [TextField] is displayed and the user types in the date they wish to select.
///
/// See also:
///
///  * [showDatePicker] and [showDateRangePicker], which use this to control
///    the initial entry mode of their dialogs.
enum DatePickerEntryMode {
  /// Tapping on a calendar.
  calendar,

  /// Text input.
  input,
}

/// Initial display of a calendar date picker.
///
/// Either a grid of available years or a monthly calendar.
///
/// See also:
///
///  * [showDatePicker], which shows a dialog that contains a material design
///    date picker.
///  * [CalendarDatePicker], widget which implements the material design date picker.
enum DatePickerMode {
  /// Choosing a month and day.
  day,

  /// Choosing a year.
  year,
}

/// Signature for predicating dates for enabled date selections.
///
/// See [showDatePicker], which has a [SelectableDayPredicate] parameter used
/// to specify allowable days in the date picker.
typedef SelectableDayPredicate = bool Function(DateTime day);

/// Encapsulates a start and end [DateTime] that represent the range of dates
/// between them.
///
/// See also:
///  * [showDateRangePicker], which displays a dialog that allows the user to
///    select a date range.
@immutable
class DateTimeRange {
  /// Creates a date range for the given start and end [DateTime].
  ///
  /// [start] and [end] must be non-null.
  const DateTimeRange({
    @required this.start,
    @required this.end,
  }) : assert(start != null),
       assert(end != null);

  /// The start of the range of dates.
  final DateTime start;

  /// The end of the range of dates.
  final DateTime end;

  /// Returns a [Duration] of the time between [start] and [end].
  ///
  /// See [DateTime.difference] for more details.
  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is DateTimeRange
      && other.start == start
      && other.end == end;
  }

  @override
  int get hashCode => hashValues(start, end);

  @override
  String toString() => '$start - $end';
}
