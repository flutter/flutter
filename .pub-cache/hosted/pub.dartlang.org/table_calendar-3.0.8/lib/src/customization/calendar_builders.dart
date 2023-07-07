// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/widgets.dart';

import '../shared/utils.dart' show DayBuilder, FocusedDayBuilder;

/// Signature for a function that creates a single event marker for a given `day`.
/// Contains a single `event` associated with that `day`.
typedef SingleMarkerBuilder<T> = Widget? Function(
    BuildContext context, DateTime day, T event);

/// Signature for a function that creates an event marker for a given `day`.
/// Contains a list of `events` associated with that `day`.
typedef MarkerBuilder<T> = Widget? Function(
    BuildContext context, DateTime day, List<T> events);

/// Signature for a function that creates a background highlight for a given `day`.
///
/// Used for highlighting current range selection.
/// Contains a value determining if the given `day` falls within the selected range.
typedef HighlightBuilder = Widget? Function(
    BuildContext context, DateTime day, bool isWithinRange);

/// Class containing all custom builders for `TableCalendar`.
class CalendarBuilders<T> {
  /// Custom builder for day cells, with a priority over any other builder.
  final FocusedDayBuilder? prioritizedBuilder;

  /// Custom builder for a day cell that matches the current day.
  final FocusedDayBuilder? todayBuilder;

  /// Custom builder for day cells that are currently marked as selected by `selectedDayPredicate`.
  final FocusedDayBuilder? selectedBuilder;

  /// Custom builder for a day cell that is the start of current range selection.
  final FocusedDayBuilder? rangeStartBuilder;

  /// Custom builder for a day cell that is the end of current range selection.
  final FocusedDayBuilder? rangeEndBuilder;

  /// Custom builder for day cells that fall within the currently selected range.
  final FocusedDayBuilder? withinRangeBuilder;

  /// Custom builder for day cells, of which the `day.month` is different than `focusedDay.month`.
  /// This will affect day cells that do not match the currently focused month.
  final FocusedDayBuilder? outsideBuilder;

  /// Custom builder for day cells that have been disabled.
  ///
  /// This refers to dates disabled by returning false in `enabledDayPredicate`,
  /// as well as dates that are outside of the bounds set up by `firstDay` and `lastDay`.
  final FocusedDayBuilder? disabledBuilder;

  /// Custom builder for day cells that are marked as holidays by `holidayPredicate`.
  final FocusedDayBuilder? holidayBuilder;

  /// Custom builder for day cells that do not match any other builder.
  final FocusedDayBuilder? defaultBuilder;

  /// Custom builder for background highlight of range selection.
  /// If `isWithinRange` is true, then `day` is within the selected range.
  final HighlightBuilder? rangeHighlightBuilder;

  /// Custom builder for a single event marker. Each of those will be displayed in a `Row` above of the day cell.
  /// You can adjust markers' position with `CalendarStyle` properties.
  ///
  /// If `singleMarkerBuilder` is not specified, a default event marker will be displayed (customizable with `CalendarStyle`).
  final SingleMarkerBuilder<T>? singleMarkerBuilder;

  /// Custom builder for event markers. Use to provide your own marker UI for each day cell.
  /// Using `markerBuilder` will override `singleMarkerBuilder` and default event markers.
  final MarkerBuilder<T>? markerBuilder;

  /// Custom builder for days of the week labels (Mon, Tue, Wed, etc.).
  final DayBuilder? dowBuilder;

  /// Use to customize header's title using different widget
  final DayBuilder? headerTitleBuilder;

  /// Custom builder for number of the week labels.
  final Widget? Function(BuildContext context, int weekNumber)?
      weekNumberBuilder;

  /// Creates `CalendarBuilders` for `TableCalendar` widget.
  const CalendarBuilders({
    this.prioritizedBuilder,
    this.todayBuilder,
    this.selectedBuilder,
    this.rangeStartBuilder,
    this.rangeEndBuilder,
    this.withinRangeBuilder,
    this.outsideBuilder,
    this.disabledBuilder,
    this.holidayBuilder,
    this.defaultBuilder,
    this.rangeHighlightBuilder,
    this.singleMarkerBuilder,
    this.markerBuilder,
    this.dowBuilder,
    this.headerTitleBuilder,
    this.weekNumberBuilder,
  });
}
