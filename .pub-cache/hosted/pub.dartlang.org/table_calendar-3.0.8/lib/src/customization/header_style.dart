// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';

import '../shared/utils.dart' show TextFormatter;

/// Class containing styling and configuration of `TableCalendar`'s header.
class HeaderStyle {
  /// Responsible for making title Text centered.
  final bool titleCentered;

  /// Responsible for FormatButton visibility.
  final bool formatButtonVisible;

  /// Controls the text inside FormatButton.
  /// * `true` - the button will show next CalendarFormat
  /// * `false` - the button will show current CalendarFormat
  final bool formatButtonShowsNext;

  /// Use to customize header's title text (e.g. with different `DateFormat`).
  /// You can use `String` transformations to further customize the text.
  /// Defaults to simple `'yMMMM'` format (i.e. January 2019, February 2019, March 2019, etc.).
  ///
  /// Example usage:
  /// ```dart
  /// titleTextFormatter: (date, locale) => DateFormat.yM(locale).format(date),
  /// ```
  final TextFormatter? titleTextFormatter;

  /// Style for title Text (month-year) displayed in header.
  final TextStyle titleTextStyle;

  /// Style for FormatButton `Text`.
  final TextStyle formatButtonTextStyle;

  /// Background `Decoration` for FormatButton.
  final BoxDecoration formatButtonDecoration;

  /// Internal padding of the whole header.
  final EdgeInsets headerPadding;

  /// External margin of the whole header.
  final EdgeInsets headerMargin;

  /// Internal padding of FormatButton.
  final EdgeInsets formatButtonPadding;

  /// Internal padding of left chevron.
  /// Determines how much of ripple animation is visible during taps.
  final EdgeInsets leftChevronPadding;

  /// Internal padding of right chevron.
  /// Determines how much of ripple animation is visible during taps.
  final EdgeInsets rightChevronPadding;

  /// External margin of left chevron.
  final EdgeInsets leftChevronMargin;

  /// External margin of right chevron.
  final EdgeInsets rightChevronMargin;

  /// Widget used for left chevron.
  ///
  /// Tapping on it will navigate to previous calendar page.
  final Widget leftChevronIcon;

  /// Widget used for right chevron.
  ///
  /// Tapping on it will navigate to next calendar page.
  final Widget rightChevronIcon;

  /// Determines left chevron's visibility.
  final bool leftChevronVisible;

  /// Determines right chevron's visibility.
  final bool rightChevronVisible;

  /// Decoration of the header.
  final BoxDecoration decoration;

  /// Creates a `HeaderStyle` used by `TableCalendar` widget.
  const HeaderStyle({
    this.titleCentered = false,
    this.formatButtonVisible = true,
    this.formatButtonShowsNext = true,
    this.titleTextFormatter,
    this.titleTextStyle = const TextStyle(fontSize: 17.0),
    this.formatButtonTextStyle = const TextStyle(fontSize: 14.0),
    this.formatButtonDecoration = const BoxDecoration(
      border: const Border.fromBorderSide(BorderSide()),
      borderRadius: const BorderRadius.all(Radius.circular(12.0)),
    ),
    this.headerMargin = const EdgeInsets.all(0.0),
    this.headerPadding = const EdgeInsets.symmetric(vertical: 8.0),
    this.formatButtonPadding =
        const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
    this.leftChevronPadding = const EdgeInsets.all(12.0),
    this.rightChevronPadding = const EdgeInsets.all(12.0),
    this.leftChevronMargin = const EdgeInsets.symmetric(horizontal: 8.0),
    this.rightChevronMargin = const EdgeInsets.symmetric(horizontal: 8.0),
    this.leftChevronIcon = const Icon(Icons.chevron_left),
    this.rightChevronIcon = const Icon(Icons.chevron_right),
    this.leftChevronVisible = true,
    this.rightChevronVisible = true,
    this.decoration = const BoxDecoration(),
  });
}
