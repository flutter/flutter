// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/widgets.dart';

/// Class containing styling and configuration for `TableCalendar`'s content.
class CalendarStyle {
  /// Maximum amount of single event marker dots to be displayed.
  final int markersMaxCount;

  /// Specifies if event markers rendered for a day cell can overflow cell's boundaries.
  /// * `true` - Event markers will be drawn over the cell boundaries
  /// * `false` - Event markers will be clipped if they are too big
  final bool canMarkersOverflow;

  /// Determines if single event marker dots should be aligned automatically with `markersAnchor`.
  /// If `false`, `markersOffset` will be used instead.
  final bool markersAutoAligned;

  /// Specifies the anchor point of single event markers if `markersAutoAligned` is `true`.
  /// A value of `0.5` will center the markers at the bottom edge of day cell's decoration.
  ///
  /// Includes `cellMargin` for calculations.
  final double markersAnchor;

  /// The size of single event marker dot.
  ///
  /// By default `markerSizeScale` is used. To use `markerSize` instead, simply provide a non-null value.
  final double? markerSize;

  /// Proportion of single event marker dot size in relation to day cell size.
  ///
  /// Includes `cellMargin` for calculations.
  final double markerSizeScale;

  /// `PositionedOffset` for event markers. Allows to specify `top`, `bottom`, `start` and `end`.
  final PositionedOffset markersOffset;

  /// General `Alignment` for event markers.
  /// Will have no effect on markers if `markersAutoAligned` or `markersOffset` is used.
  final AlignmentGeometry markersAlignment;

  /// Decoration of single event markers. Affects each marker dot.
  final Decoration markerDecoration;

  /// Margin of single event markers. Affects each marker dot.
  final EdgeInsets markerMargin;

  /// Margin of each individual day cell.
  final EdgeInsets cellMargin;

  /// Padding of each individual day cell.
  final EdgeInsets cellPadding;

  /// Alignment of each individual day cell.
  final AlignmentGeometry cellAlignment;

  /// Proportion of range selection highlight size in relation to day cell size.
  ///
  /// Includes `cellMargin` for calculations.
  final double rangeHighlightScale;

  /// Color of range selection highlight.
  final Color rangeHighlightColor;

  /// Determines if day cells that do not match the currently focused month should be visible.
  ///
  /// Affects only `CalendarFormat.month`.
  final bool outsideDaysVisible;

  /// Determines if a day cell that matches the current day should be highlighted.
  final bool isTodayHighlighted;

  /// TextStyle for a day cell that matches the current day.
  final TextStyle todayTextStyle;

  /// Decoration for a day cell that matches the current day.
  final Decoration todayDecoration;

  /// TextStyle for day cells that are currently marked as selected by `selectedDayPredicate`.
  final TextStyle selectedTextStyle;

  /// Decoration for day cells that are currently marked as selected by `selectedDayPredicate`.
  final Decoration selectedDecoration;

  /// TextStyle for a day cell that is the start of current range selection.
  final TextStyle rangeStartTextStyle;

  /// Decoration for a day cell that is the start of current range selection.
  final Decoration rangeStartDecoration;

  /// TextStyle for a day cell that is the end of current range selection.
  final TextStyle rangeEndTextStyle;

  /// Decoration for a day cell that is the end of current range selection.
  final Decoration rangeEndDecoration;

  /// TextStyle for day cells that fall within the currently selected range.
  final TextStyle withinRangeTextStyle;

  /// Decoration for day cells that fall within the currently selected range.
  final Decoration withinRangeDecoration;

  /// TextStyle for day cells, of which the `day.month` is different than `focusedDay.month`.
  /// This will affect day cells that do not match the currently focused month.
  final TextStyle outsideTextStyle;

  /// Decoration for day cells, of which the `day.month` is different than `focusedDay.month`.
  /// This will affect day cells that do not match the currently focused month.
  final Decoration outsideDecoration;

  /// TextStyle for day cells that have been disabled.
  ///
  /// This refers to dates disabled by returning false in `enabledDayPredicate`,
  /// as well as dates that are outside of the bounds set up by `firstDay` and `lastDay`.
  final TextStyle disabledTextStyle;

  /// Decoration for day cells that have been disabled.
  ///
  /// This refers to dates disabled by returning false in `enabledDayPredicate`,
  /// as well as dates that are outside of the bounds set up by `firstDay` and `lastDay`.
  final Decoration disabledDecoration;

  /// TextStyle for day cells that are marked as holidays by `holidayPredicate`.
  final TextStyle holidayTextStyle;

  /// Decoration for day cells that are marked as holidays by `holidayPredicate`.
  final Decoration holidayDecoration;

  /// TextStyle for day cells that match `weekendDay` list.
  final TextStyle weekendTextStyle;

  /// Decoration for day cells that match `weekendDay` list.
  final Decoration weekendDecoration;

  /// TextStyle for week number.
  final TextStyle weekNumberTextStyle;

  /// TextStyle for day cells that do not match any other styles.
  final TextStyle defaultTextStyle;

  /// Decoration for day cells that do not match any other styles.
  final Decoration defaultDecoration;

  /// Decoration for each interior row of day cells.
  final Decoration rowDecoration;

  /// Border for the internal `Table` widget.
  final TableBorder tableBorder;

  /// Padding for the internal `Table` widget.
  final EdgeInsets tablePadding;

  /// Creates a `CalendarStyle` used by `TableCalendar` widget.
  const CalendarStyle({
    this.isTodayHighlighted = true,
    this.canMarkersOverflow = true,
    this.outsideDaysVisible = true,
    this.markersAutoAligned = true,
    this.markerSize,
    this.markerSizeScale = 0.2,
    this.markersAnchor = 0.7,
    this.rangeHighlightScale = 1.0,
    this.markerMargin = const EdgeInsets.symmetric(horizontal: 0.3),
    this.markersAlignment = Alignment.bottomCenter,
    this.markersMaxCount = 4,
    this.cellMargin = const EdgeInsets.all(6.0),
    this.cellPadding = const EdgeInsets.all(0),
    this.cellAlignment = Alignment.center,
    this.markersOffset = const PositionedOffset(),
    this.rangeHighlightColor = const Color(0xFFBBDDFF),
    this.markerDecoration = const BoxDecoration(
      color: const Color(0xFF263238),
      shape: BoxShape.circle,
    ),
    this.todayTextStyle = const TextStyle(
      color: const Color(0xFFFAFAFA),
      fontSize: 16.0,
    ), //
    this.todayDecoration = const BoxDecoration(
      color: const Color(0xFF9FA8DA),
      shape: BoxShape.circle,
    ),
    this.selectedTextStyle = const TextStyle(
      color: const Color(0xFFFAFAFA),
      fontSize: 16.0,
    ),
    this.selectedDecoration = const BoxDecoration(
      color: const Color(0xFF5C6BC0),
      shape: BoxShape.circle,
    ),
    this.rangeStartTextStyle = const TextStyle(
      color: const Color(0xFFFAFAFA),
      fontSize: 16.0,
    ),
    this.rangeStartDecoration = const BoxDecoration(
      color: const Color(0xFF6699FF),
      shape: BoxShape.circle,
    ),
    this.rangeEndTextStyle = const TextStyle(
      color: const Color(0xFFFAFAFA),
      fontSize: 16.0,
    ),
    this.rangeEndDecoration = const BoxDecoration(
      color: const Color(0xFF6699FF),
      shape: BoxShape.circle,
    ),
    this.withinRangeTextStyle = const TextStyle(),
    this.withinRangeDecoration = const BoxDecoration(shape: BoxShape.circle),
    this.outsideTextStyle = const TextStyle(color: const Color(0xFFAEAEAE)),
    this.outsideDecoration = const BoxDecoration(shape: BoxShape.circle),
    this.disabledTextStyle = const TextStyle(color: const Color(0xFFBFBFBF)),
    this.disabledDecoration = const BoxDecoration(shape: BoxShape.circle),
    this.holidayTextStyle = const TextStyle(color: const Color(0xFF5C6BC0)),
    this.holidayDecoration = const BoxDecoration(
      border: const Border.fromBorderSide(
        const BorderSide(color: const Color(0xFF9FA8DA), width: 1.4),
      ),
      shape: BoxShape.circle,
    ),
    this.weekendTextStyle = const TextStyle(color: const Color(0xFF5A5A5A)),
    this.weekendDecoration = const BoxDecoration(shape: BoxShape.circle),
    this.weekNumberTextStyle =
        const TextStyle(fontSize: 12, color: const Color(0xFFBFBFBF)),
    this.defaultTextStyle = const TextStyle(),
    this.defaultDecoration = const BoxDecoration(shape: BoxShape.circle),
    this.rowDecoration = const BoxDecoration(),
    this.tableBorder = const TableBorder(),
    this.tablePadding = const EdgeInsets.all(0),
  });
}

/// Helper class containing data for internal `Positioned` widget.
class PositionedOffset {
  /// Distance from the top edge.
  final double? top;

  /// Distance from the bottom edge.
  final double? bottom;

  /// Distance from the leading edge.
  final double? start;

  /// Distance from the trailing edge.
  final double? end;

  /// Creates a `PositionedOffset`. Values are set to `null` by default.
  const PositionedOffset({this.top, this.bottom, this.start, this.end});
}
