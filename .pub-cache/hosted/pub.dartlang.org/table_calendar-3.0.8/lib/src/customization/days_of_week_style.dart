// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/widgets.dart';

import '../shared/utils.dart' show TextFormatter;

/// Class containing styling for `TableCalendar`'s days of week panel.
class DaysOfWeekStyle {
  /// Use to customize days of week panel text (e.g. with different `DateFormat`).
  /// You can use `String` transformations to further customize the text.
  /// Defaults to simple `'E'` format (i.e. Mon, Tue, Wed, etc.).
  ///
  /// Example usage:
  /// ```dart
  /// dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date)[0],
  /// ```
  final TextFormatter? dowTextFormatter;

  /// Decoration for the top row of the table
  final Decoration decoration;

  /// Style for weekdays on the top of calendar.
  final TextStyle weekdayStyle;

  /// Style for weekend days on the top of calendar.
  final TextStyle weekendStyle;

  /// Creates a `DaysOfWeekStyle` used by `TableCalendar` widget.
  const DaysOfWeekStyle({
    this.dowTextFormatter,
    this.decoration = const BoxDecoration(),
    this.weekdayStyle = const TextStyle(color: const Color(0xFF4F4F4F)),
    this.weekendStyle = const TextStyle(color: const Color(0xFF6A6A6A)),
  });
}
