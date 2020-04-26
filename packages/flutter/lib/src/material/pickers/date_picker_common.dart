// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Mode of the date picker dialog.
///
/// Either a calendar or text input. In [calendar] mode, a calendar view is
/// displayed and the user taps the day they wish to select. In [input] mode a
/// [TextField] is displayed and the user types in the date they wish to select.
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
/// See [showDatePicker].
typedef SelectableDayPredicate = bool Function(DateTime day);
