// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'button_bar.dart';
import 'colors.dart';
import 'dialog.dart';
import 'feedback.dart';
import 'flat_button.dart';
import 'material_localizations.dart';
import 'theme.dart';
import 'typography.dart';

const Duration _kDialAnimateDuration = const Duration(milliseconds: 200);
const double _kTwoPi = 2 * math.PI;
const int _kHoursPerDay = 24;
const int _kHoursPerPeriod = 12;
const int _kMinutesPerHour = 60;
const Duration _kVibrateCommitDelay = const Duration(milliseconds: 100);

/// Whether the [TimeOfDay] is before or after noon.
enum DayPeriod {
  /// Ante meridiem (before noon).
  am,

  /// Post meridiem (after noon).
  pm,
}

/// A value representing a time during the day.
@immutable
class TimeOfDay {
  /// Creates a time of day.
  ///
  /// The [hour] argument must be between 0 and 23, inclusive. The [minute]
  /// argument must be between 0 and 59, inclusive.
  const TimeOfDay({ @required this.hour, @required this.minute });

  /// Creates a time of day based on the given time.
  ///
  /// The [hour] is set to the time's hour and the [minute] is set to the time's
  /// minute in the timezone of the given [DateTime].
  TimeOfDay.fromDateTime(DateTime time) : hour = time.hour, minute = time.minute;

  /// Creates a time of day based on the current time.
  ///
  /// The [hour] is set to the current hour and the [minute] is set to the
  /// current minute in the local time zone.
  factory TimeOfDay.now() { return new TimeOfDay.fromDateTime(new DateTime.now()); }

  /// Returns a new TimeOfDay with the hour and/or minute replaced.
  TimeOfDay replacing({ int hour, int minute }) {
    assert(hour == null || (hour >= 0 && hour < _kHoursPerDay));
    assert(minute == null || (minute >= 0 && minute < _kMinutesPerHour));
    return new TimeOfDay(hour: hour ?? this.hour, minute: minute ?? this.minute);
  }

  /// The selected hour, in 24 hour time from 0..23.
  final int hour;

  /// The selected minute.
  final int minute;

  /// Whether this time of day is before or after noon.
  DayPeriod get period => hour < _kHoursPerPeriod ? DayPeriod.am : DayPeriod.pm;

  /// Which hour of the current period (e.g., am or pm) this time is.
  int get hourOfPeriod => hour - periodOffset;

  String _addLeadingZeroIfNeeded(int value) {
    if (value < 10)
      return '0$value';
    return value.toString();
  }

  /// A string representing the hour, in 24 hour time (e.g., '04' or '18').
  String get hourLabel => _addLeadingZeroIfNeeded(hour);

  /// A string representing the minute (e.g., '07').
  String get minuteLabel => _addLeadingZeroIfNeeded(minute);

  /// A string representing the hour of the current period (e.g., '4' or '6').
  String get hourOfPeriodLabel {
    final int hourOfPeriod = this.hourOfPeriod;
    if (hourOfPeriod == 0)
      return '12';
    return hourOfPeriod.toString();
  }

  /// The hour at which the current period starts.
  int get periodOffset => period == DayPeriod.am ? 0 : _kHoursPerPeriod;

  @override
  bool operator ==(dynamic other) {
    if (other is! TimeOfDay)
      return false;
    final TimeOfDay typedOther = other;
    return typedOther.hour == hour
        && typedOther.minute == minute;
  }

  @override
  int get hashCode => hashValues(hour, minute);

  @override
  String toString() => '$hourLabel:$minuteLabel';
}

enum _TimePickerMode { hour, minute }

const double _kTimePickerHeaderPortraitHeight = 96.0;
const double _kTimePickerHeaderLandscapeWidth = 168.0;

const double _kTimePickerWidthPortrait = 328.0;
const double _kTimePickerWidthLandscape = 512.0;

const double _kTimePickerHeightPortrait = 484.0;
const double _kTimePickerHeightLandscape = 304.0;

/// The horizontal gap between the day period fragment and the fragment
/// positioned next to it horizontally.
///
/// Normally there's only one horizontal sibling, and it may appear on the left
/// or right depending on the current [TextDirection].
const double _kPeriodGap = 8.0;

/// The vertical gap between pieces when laid out vertically (in portrait mode).
const double _kVerticalGap = 8.0;

enum _TimePickerHeaderId {
  hour,
  colon,
  minute,
  period, // AM/PM picker
  dot,
  hString, // French Canadian "h" literal
}

/// Provides properties for rendering time picker header fragments.
@immutable
class _TimePickerFragmentContext {
  const _TimePickerFragmentContext({
    @required this.headerTextTheme,
    @required this.textDirection,
    @required this.selectedTime,
    @required this.mode,
    @required this.activeColor,
    @required this.activeStyle,
    @required this.inactiveColor,
    @required this.inactiveStyle,
    @required this.onTimeChange,
    @required this.onModeChange,
  }) : assert(headerTextTheme != null),
       assert(textDirection != null),
       assert(selectedTime != null),
       assert(mode != null),
       assert(activeColor != null),
       assert(activeStyle != null),
       assert(inactiveColor != null),
       assert(inactiveStyle != null),
       assert(onTimeChange != null),
       assert(onModeChange != null);

  final TextTheme headerTextTheme;
  final TextDirection textDirection;
  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final Color activeColor;
  final TextStyle activeStyle;
  final Color inactiveColor;
  final TextStyle inactiveStyle;
  final ValueChanged<TimeOfDay> onTimeChange;
  final ValueChanged<_TimePickerMode> onModeChange;
}

/// Describes how hours are formatted.
enum _TimePickerHourFormat {
  /// Zero-padded two-digit 24-hour format ranging from "00" to "23".
  HH,

  /// Non-padded variable-length 24-hour format ranging from "0" to "23".
  H,

  /// Non-padded variable-length hour in day period format ranging from "1" to
  /// "12".
  h,
}

/// Contains the [widget] and layout properties of an atom of time information,
/// such as am/pm indicator, hour, minute and string literals appearing in the
/// formatted time string.
class _TimePickerHeaderFragment {
  const _TimePickerHeaderFragment({
    @required this.layoutId,
    @required this.widget,
    this.startMargin: 0.0,
  }) : assert(layoutId != null),
        assert(widget != null),
        assert(startMargin != null);

  /// Identifier used by the custom layout to refer to the widget.
  final _TimePickerHeaderId layoutId;

  /// The widget that renders a piece of time information.
  final Widget widget;

  /// Horizontal distance from the fragment appearing at the start of this
  /// fragment.
  ///
  /// This value contributes to the total horizontal width of all fragments
  /// appearing on the same line, unless it is the first fragment on the line,
  /// in which case this value is ignored.
  final double startMargin;
}

/// An unbreakable part of the time picker header.
///
/// When the picker is laid out vertically, [fragments] of the piece are laid
/// out on the same line, with each piece getting its own line.
class _TimePickerHeaderPiece {
  /// Creates a time picker header piece.
  ///
  /// All arguments must be non-null. If the piece does not contain a pivot
  /// fragment, use the value -1 as a convention.
  const _TimePickerHeaderPiece(this.pivotIndex, this.fragments, { this.bottomMargin: 0.0 })
      : assert(pivotIndex != null),
        assert(fragments != null),
        assert(bottomMargin != null);

  /// Index into the [fragments] list, pointing at the fragment that's centered
  /// horizontally.
  final int pivotIndex;

  /// Fragments this piece is made of.
  final List<_TimePickerHeaderFragment> fragments;

  /// Vertical distance between this piece and the next piece.
  ///
  /// This property applies only when the header is laid out vertically.
  final double bottomMargin;
}

/// Describes how the time picker header must be formatted.
///
/// A [_TimePickerHeaderFormat] is made of multiple [_TimePickerHeaderPiece]s.
/// A piece is made of multiple [_TimePickerHeaderFragment]s. A fragment has a
/// widget used to render some time information and contains some layout
/// properties.
///
/// ## Layout rules
///
/// Pieces are laid out such that all fragments inside the same piece are laid
/// out horizontally. Pieces are laid out horizontally if portrait orientation,
/// and vertically in landscape orientation.
///
/// One of the pieces is identified as a _centrepiece_. It is a piece that is
/// positioned in the center of the header, with all other pieces positioned
/// to the left or right of it.
class _TimePickerHeaderFormat {
  const _TimePickerHeaderFormat(this.centrepieceIndex, this.pieces)
      : assert(centrepieceIndex != null),
        assert(pieces != null);

  /// Index into the [pieces] list pointing at the piece that contains the
  /// pivot fragment.
  final int centrepieceIndex;

  /// Pieces that constitute a time picker header.
  final List<_TimePickerHeaderPiece> pieces;
}

/// Displays the am/pm fragment and provides controls for switching between am
/// and pm.
class _DayPeriodControl extends StatelessWidget {
  const _DayPeriodControl({
    @required this.fragmentContext,
  });

  final _TimePickerFragmentContext fragmentContext;

  void _handleChangeDayPeriod() {
    final int newHour = (fragmentContext.selectedTime.hour + _kHoursPerPeriod) % _kHoursPerDay;
    fragmentContext.onTimeChange(fragmentContext.selectedTime.replacing(hour: newHour));
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations materialLocalizations = MaterialLocalizations.of(context);
    final TextTheme headerTextTheme = fragmentContext.headerTextTheme;
    final TimeOfDay selectedTime = fragmentContext.selectedTime;
    final Color activeColor = fragmentContext.activeColor;
    final Color inactiveColor = fragmentContext.inactiveColor;

    final TextStyle amStyle = headerTextTheme.subhead.copyWith(
        color: selectedTime.period == DayPeriod.am ? activeColor: inactiveColor
    );
    final TextStyle pmStyle = headerTextTheme.subhead.copyWith(
        color: selectedTime.period == DayPeriod.pm ? activeColor: inactiveColor
    );

    return new GestureDetector(
      onTap: Feedback.wrapForTap(_handleChangeDayPeriod, context),
      behavior: HitTestBehavior.opaque,
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new Text(materialLocalizations.anteMeridiemAbbreviation, style: amStyle),
          const SizedBox(width: 0.0, height: 4.0),  // Vertical spacer
          new Text(materialLocalizations.postMeridiemAbbreviation, style: pmStyle),
        ],
      ),
    );
  }
}

/// Displays the hour fragment.
///
/// When tapped changes time picker dial mode to [_TimePickerMode.hour].
class _HourControl extends StatelessWidget {
  const _HourControl({
    @required this.fragmentContext,
    @required this.hourFormat,
  });

  final _TimePickerFragmentContext fragmentContext;
  final _TimePickerHourFormat hourFormat;

  @override
  Widget build(BuildContext context) {
    final TextStyle hourStyle = fragmentContext.mode == _TimePickerMode.hour
        ? fragmentContext.activeStyle
        : fragmentContext.inactiveStyle;

    return new GestureDetector(
      onTap: Feedback.wrapForTap(() => fragmentContext.onModeChange(_TimePickerMode.hour), context),
      child: new Text(_formatHour(), style: hourStyle),
    );
  }

  String _formatHour() {
    assert(hourFormat != null);
    switch (hourFormat) {
      case _TimePickerHourFormat.HH:
        return fragmentContext.selectedTime.hourLabel;
      case _TimePickerHourFormat.H:
        return fragmentContext.selectedTime.hour.toString();
      case _TimePickerHourFormat.h:
        return fragmentContext.selectedTime.hourOfPeriodLabel;
    }
    return null;
  }
}

/// A passive fragment showing a string value.
class _StringFragment extends StatelessWidget {
  const _StringFragment({
    @required this.fragmentContext,
    @required this.value,
  });

  final _TimePickerFragmentContext fragmentContext;
  final String value;

  @override
  Widget build(BuildContext context) {
    return new Text(value, style: fragmentContext.inactiveStyle);
  }
}

/// Displays the minute fragment.
///
/// When tapped changes time picker dial mode to [_TimePickerMode.minute].
class _MinuteControl extends StatelessWidget {
  const _MinuteControl({
    @required this.fragmentContext,
  });

  final _TimePickerFragmentContext fragmentContext;

  @override
  Widget build(BuildContext context) {
    final TextStyle minuteStyle = fragmentContext.mode == _TimePickerMode.minute
        ? fragmentContext.activeStyle
        : fragmentContext.inactiveStyle;

    return new GestureDetector(
      onTap: Feedback.wrapForTap(() => fragmentContext.onModeChange(_TimePickerMode.minute), context),
      child: new Text(fragmentContext.selectedTime.minuteLabel, style: minuteStyle),
    );
  }
}

_TimePickerHourFormat _getHourFormat(TimeOfDayFormat format) {
  switch (format) {
    case TimeOfDayFormat.h_colon_mm_space_a:
    case TimeOfDayFormat.a_space_h_colon_mm:
      return _TimePickerHourFormat.h;
    case TimeOfDayFormat.H_colon_mm:
      return _TimePickerHourFormat.H;
    case TimeOfDayFormat.HH_dot_mm:
    case TimeOfDayFormat.HH_colon_mm:
    case TimeOfDayFormat.frenchCanadian:
      return _TimePickerHourFormat.HH;
  }

  return null;
}

/// Provides time picker header layout configuration for the given
/// [timeOfDayFormat] passing [context] to each widget in the configuration.
///
/// [timeOfDayFormat] and [context] must not be `null`.
_TimePickerHeaderFormat _buildHeaderFormat(TimeOfDayFormat timeOfDayFormat, _TimePickerFragmentContext context) {
  // Creates an hour fragment.
  _TimePickerHeaderFragment hour(_TimePickerHourFormat hourFormat) {
    return new _TimePickerHeaderFragment(
      layoutId: _TimePickerHeaderId.hour,
      widget: new _HourControl(fragmentContext: context, hourFormat: hourFormat),
      startMargin: _kPeriodGap,
    );
  }

  // Creates a minute fragment.
  _TimePickerHeaderFragment minute() {
    return new _TimePickerHeaderFragment(
      layoutId: _TimePickerHeaderId.minute,
      widget: new _MinuteControl(fragmentContext: context),
    );
  }

  // Creates a string fragment.
  _TimePickerHeaderFragment string(_TimePickerHeaderId layoutId, String value) {
    return new _TimePickerHeaderFragment(
      layoutId: layoutId,
      widget: new _StringFragment(
        fragmentContext: context,
        value: value,
      ),
    );
  }

  // Creates an am/pm fragment.
  _TimePickerHeaderFragment dayPeriod() {
    return new _TimePickerHeaderFragment(
      layoutId: _TimePickerHeaderId.period,
      widget: new _DayPeriodControl(fragmentContext: context),
      startMargin: _kPeriodGap,
    );
  }

  // Convenience function for creating a time header format with up to two pieces.
  _TimePickerHeaderFormat format(int centrepieceIndex, _TimePickerHeaderPiece piece1,
      [ _TimePickerHeaderPiece piece2 ]) {
    final List<_TimePickerHeaderPiece> pieces = <_TimePickerHeaderPiece>[];
    switch (context.textDirection) {
      case TextDirection.ltr:
        pieces.add(piece1);
        if (piece2 != null)
          pieces.add(piece2);
        break;
      case TextDirection.rtl:
        if (piece2 != null)
          pieces.add(piece2);
        pieces.add(piece1);
        centrepieceIndex = pieces.length - centrepieceIndex - 1;
        break;
    }
    return new _TimePickerHeaderFormat(centrepieceIndex, pieces);
  }

  // Convenience function for creating a time header piece with up to three fragments.
  _TimePickerHeaderPiece piece({ int pivotIndex: -1, double bottomMargin: 0.0,
      _TimePickerHeaderFragment fragment1, _TimePickerHeaderFragment fragment2, _TimePickerHeaderFragment fragment3 }) {
    final List<_TimePickerHeaderFragment> fragments = <_TimePickerHeaderFragment>[fragment1];
    if (fragment2 != null) {
      fragments.add(fragment2);
      if (fragment3 != null)
        fragments.add(fragment3);
    }
    return new _TimePickerHeaderPiece(pivotIndex, fragments, bottomMargin: bottomMargin);
  }

  switch (timeOfDayFormat) {
    case TimeOfDayFormat.h_colon_mm_space_a:
      return format(
        0,
        piece(
          pivotIndex: 1,
          fragment1: hour(_TimePickerHourFormat.h),
          fragment2: string(_TimePickerHeaderId.colon, ':'),
          fragment3: minute(),
        ),
        piece(
          bottomMargin: _kVerticalGap,
          fragment1: dayPeriod(),
        ),
      );
    case TimeOfDayFormat.H_colon_mm:
      return format(0, piece(
        pivotIndex: 1,
        fragment1: hour(_TimePickerHourFormat.H),
        fragment2: string(_TimePickerHeaderId.colon, ':'),
        fragment3: minute(),
      ));
    case TimeOfDayFormat.HH_dot_mm:
      return format(0, piece(
        pivotIndex: 1,
        fragment1: hour(_TimePickerHourFormat.HH),
        fragment2: string(_TimePickerHeaderId.dot, '.'),
        fragment3: minute(),
      ));
    case TimeOfDayFormat.a_space_h_colon_mm:
      return format(
        1,
        piece(
          bottomMargin: _kVerticalGap,
          fragment1: dayPeriod(),
        ),
        piece(
          pivotIndex: 1,
          fragment1: hour(_TimePickerHourFormat.h),
          fragment2: string(_TimePickerHeaderId.colon, ':'),
          fragment3: minute(),
        ),
      );
    case TimeOfDayFormat.frenchCanadian:
      return format(0, piece(
        pivotIndex: 1,
        fragment1: hour(_TimePickerHourFormat.HH),
        fragment2: string(_TimePickerHeaderId.hString, 'h'),
        fragment3: minute(),
      ));
    case TimeOfDayFormat.HH_colon_mm:
      return format(0, piece(
        pivotIndex: 1,
        fragment1: hour(_TimePickerHourFormat.HH),
        fragment2: string(_TimePickerHeaderId.colon, ':'),
        fragment3: minute(),
      ));
  }

  return null;
}

class _TimePickerHeaderLayout extends MultiChildLayoutDelegate {
  _TimePickerHeaderLayout(this.orientation, this.format)
    : assert(orientation != null),
      assert(format != null);

  final Orientation orientation;
  final _TimePickerHeaderFormat format;

  @override
  void performLayout(Size size) {
    final BoxConstraints constraints = new BoxConstraints.loose(size);

    switch (orientation) {
      case Orientation.portrait:
        _layoutHorizontally(size, constraints);
        break;
      case Orientation.landscape:
        _layoutVertically(size, constraints);
        break;
    }
  }

  void _layoutHorizontally(Size size, BoxConstraints constraints) {
    final List<_TimePickerHeaderFragment> fragmentsFlattened = <_TimePickerHeaderFragment>[];
    final Map<_TimePickerHeaderId, Size> childSizes = <_TimePickerHeaderId, Size>{};
    int pivotIndex = 0;
    for (int pieceIndex = 0; pieceIndex < format.pieces.length; pieceIndex += 1) {
      final _TimePickerHeaderPiece piece = format.pieces[pieceIndex];
      for (final _TimePickerHeaderFragment fragment in piece.fragments) {
        childSizes[fragment.layoutId] = layoutChild(fragment.layoutId, constraints);
        fragmentsFlattened.add(fragment);
      }

      if (pieceIndex == format.centrepieceIndex)
        pivotIndex += format.pieces[format.centrepieceIndex].pivotIndex;
      else if (pieceIndex < format.centrepieceIndex)
        pivotIndex += piece.fragments.length;
    }

    _positionPivoted(size.width, size.height / 2.0, childSizes, fragmentsFlattened, pivotIndex);
  }

  void _layoutVertically(Size size, BoxConstraints constraints) {
    final Map<_TimePickerHeaderId, Size> childSizes = <_TimePickerHeaderId, Size>{};
    final List<double> pieceHeights = <double>[];
    double height = 0.0;
    double margin = 0.0;
    for (final _TimePickerHeaderPiece piece in format.pieces) {
      double pieceHeight = 0.0;
      for (final _TimePickerHeaderFragment fragment in piece.fragments) {
        final Size childSize = childSizes[fragment.layoutId] = layoutChild(fragment.layoutId, constraints);
        pieceHeight = math.max(pieceHeight, childSize.height);
      }
      pieceHeights.add(pieceHeight);
      height += pieceHeight + margin;
      // Delay application of margin until next piece because margin of the
      // bottom-most piece should not contribute to the size.
      margin = piece.bottomMargin;
    }

    final _TimePickerHeaderPiece centrepiece = format.pieces[format.centrepieceIndex];
    double y = (size.height - height) / 2.0;
    for (int pieceIndex = 0; pieceIndex < format.pieces.length; pieceIndex += 1) {
      if (pieceIndex != format.centrepieceIndex)
        _positionPiece(size.width, y, childSizes, format.pieces[pieceIndex].fragments);
      else
        _positionPivoted(size.width, y, childSizes, centrepiece.fragments, centrepiece.pivotIndex);

      y += pieceHeights[pieceIndex] + format.pieces[pieceIndex].bottomMargin;
    }
  }

  void _positionPivoted(double width, double y, Map<_TimePickerHeaderId, Size> childSizes, List<_TimePickerHeaderFragment> fragments, int pivotIndex) {
    double tailWidth = childSizes[fragments[pivotIndex].layoutId].width / 2.0;
    for (_TimePickerHeaderFragment fragment in fragments.skip(pivotIndex + 1)) {
      tailWidth += childSizes[fragment.layoutId].width + fragment.startMargin;
    }

    double x = width / 2.0 + tailWidth;
    x = math.min(x, width);
    for (int i = fragments.length - 1; i >= 0; i -= 1) {
      final _TimePickerHeaderFragment fragment = fragments[i];
      final Size childSize = childSizes[fragment.layoutId];
      x -= childSize.width;
      positionChild(fragment.layoutId, new Offset(x, y - childSize.height / 2.0));
      x -= fragment.startMargin;
    }
  }

  void _positionPiece(double width, double centeredAroundY, Map<_TimePickerHeaderId, Size> childSizes, List<_TimePickerHeaderFragment> fragments) {
    double pieceWidth = 0.0;
    double nextMargin = 0.0;
    for (_TimePickerHeaderFragment fragment in fragments) {
      final Size childSize = childSizes[fragment.layoutId];
      pieceWidth += childSize.width + nextMargin;
      // Delay application of margin until next element because margin of the
      // left-most fragment should not contribute to the size.
      nextMargin = fragment.startMargin;
    }
    double x = (width + pieceWidth) / 2.0;
    for (int i = fragments.length - 1; i >= 0; i -= 1) {
      final _TimePickerHeaderFragment fragment = fragments[i];
      final Size childSize = childSizes[fragment.layoutId];
      x -= childSize.width;
      positionChild(fragment.layoutId, new Offset(x, centeredAroundY - childSize.height / 2.0));
      x -= fragment.startMargin;
    }
  }

  @override
  bool shouldRelayout(_TimePickerHeaderLayout oldDelegate) => orientation != oldDelegate.orientation || format != oldDelegate.format;
}

class _TimePickerHeader extends StatelessWidget {
  const _TimePickerHeader({
    @required this.selectedTime,
    @required this.mode,
    @required this.orientation,
    @required this.onModeChanged,
    @required this.onChanged,
  }) : assert(selectedTime != null),
       assert(mode != null),
       assert(orientation != null);

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final Orientation orientation;
  final ValueChanged<_TimePickerMode> onModeChanged;
  final ValueChanged<TimeOfDay> onChanged;

  void _handleChangeMode(_TimePickerMode value) {
    if (value != mode)
      onModeChanged(value);
  }

  TextStyle _getBaseHeaderStyle(TextTheme headerTextTheme) {
    // These font sizes aren't listed in the spec explicitly. I worked them out
    // by measuring the text using a screen ruler and comparing them to the
    // screen shots of the time picker in the spec.
    assert(orientation != null);
    switch (orientation) {
      case Orientation.portrait:
        return headerTextTheme.display3.copyWith(fontSize: 60.0);
      case Orientation.landscape:
        return headerTextTheme.display2.copyWith(fontSize: 50.0);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TimeOfDayFormat timeOfDayFormat = MaterialLocalizations.of(context).timeOfDayFormat;

    EdgeInsets padding;
    double height;
    double width;

    assert(orientation != null);
    switch (orientation) {
      case Orientation.portrait:
        height = _kTimePickerHeaderPortraitHeight;
        padding = const EdgeInsets.symmetric(horizontal: 24.0);
        break;
      case Orientation.landscape:
        width = _kTimePickerHeaderLandscapeWidth;
        padding = const EdgeInsets.symmetric(horizontal: 16.0);
        break;
    }

    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = themeData.primaryColor;
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    Color activeColor;
    Color inactiveColor;
    switch (themeData.primaryColorBrightness) {
      case Brightness.light:
        activeColor = Colors.black87;
        inactiveColor = Colors.black54;
        break;
      case Brightness.dark:
        activeColor = Colors.white;
        inactiveColor = Colors.white70;
        break;
    }

    final TextTheme headerTextTheme = themeData.primaryTextTheme;
    final TextStyle baseHeaderStyle = _getBaseHeaderStyle(headerTextTheme);
    final _TimePickerFragmentContext fragmentContext = new _TimePickerFragmentContext(
      headerTextTheme: headerTextTheme,
      textDirection: Directionality.of(context),
      selectedTime: selectedTime,
      mode: mode,
      activeColor: activeColor,
      activeStyle: baseHeaderStyle.copyWith(color: activeColor),
      inactiveColor: inactiveColor,
      inactiveStyle: baseHeaderStyle.copyWith(color: inactiveColor),
      onTimeChange: onChanged,
      onModeChange: _handleChangeMode,
    );

    final _TimePickerHeaderFormat format = _buildHeaderFormat(timeOfDayFormat, fragmentContext);

    return new Container(
      width: width,
      height: height,
      padding: padding,
      color: backgroundColor,
      child: new CustomMultiChildLayout(
        delegate: new _TimePickerHeaderLayout(orientation, format),
        children: format.pieces
          .expand<_TimePickerHeaderFragment>((_TimePickerHeaderPiece piece) => piece.fragments)
          .map<Widget>((_TimePickerHeaderFragment fragment) {
            return new LayoutId(
              id: fragment.layoutId,
              child: fragment.widget,
            );
          })
          .toList(),
      )
    );
  }
}

List<TextPainter> _initPainters(TextTheme textTheme, List<String> labels) {
  final TextStyle style = textTheme.subhead;
  final List<TextPainter> painters = new List<TextPainter>(labels.length);
  for (int i = 0; i < painters.length; ++i) {
    final String label = labels[i];
    // TODO(abarth): Handle textScaleFactor.
    // https://github.com/flutter/flutter/issues/5939
    painters[i] = new TextPainter(
      text: new TextSpan(style: style, text: label),
      textDirection: TextDirection.ltr,
    )..layout();
  }
  return painters;
}

enum _DialRing {
  outer,
  inner,
}

List<TextPainter> _initHours(TextTheme textTheme, _DialRing ring, bool is24h) {
  const List<String> amHours = const <String>[
    '12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'
  ];
  const List<String> pmHours = const <String>[
    '00', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'
  ];
  switch (ring) {
    case _DialRing.outer:
      return _initPainters(textTheme, is24h ? pmHours : amHours);
    case _DialRing.inner:
      return is24h ? _initPainters(textTheme, amHours) : null;
  }
  return null;
}

List<TextPainter> _initMinutes(TextTheme textTheme) {
  return _initPainters(textTheme, <String>[
    '00', '05', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55'
  ]);
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    @required this.primaryOuterLabels,
    @required this.primaryInnerLabels,
    @required this.secondaryOuterLabels,
    @required this.secondaryInnerLabels,
    @required this.backgroundColor,
    @required this.accentColor,
    @required this.theta,
    @required this.activeRing,
  });

  final List<TextPainter> primaryOuterLabels;
  final List<TextPainter> primaryInnerLabels;
  final List<TextPainter> secondaryOuterLabels;
  final List<TextPainter> secondaryInnerLabels;
  final Color backgroundColor;
  final Color accentColor;
  final double theta;
  final _DialRing activeRing;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.shortestSide / 2.0;
    final Offset center = new Offset(size.width / 2.0, size.height / 2.0);
    final Offset centerPoint = center;
    canvas.drawCircle(centerPoint, radius, new Paint()..color = backgroundColor);

    const double labelPadding = 24.0;
    final double outerLabelRadius = radius - labelPadding;
    final double innerLabelRadius = radius - labelPadding * 2.5;
    Offset getOffsetForTheta(double theta, _DialRing ring) {
      double labelRadius;
      switch (ring) {
        case _DialRing.outer:
          labelRadius = outerLabelRadius;
          break;
        case _DialRing.inner:
          labelRadius = innerLabelRadius;
          break;
      }
      return center + new Offset(labelRadius * math.cos(theta),
                                 -labelRadius * math.sin(theta));
    }

    void paintLabels(List<TextPainter> labels, _DialRing ring) {
      if (labels == null)
        return;
      final double labelThetaIncrement = -_kTwoPi / labels.length;
      double labelTheta = math.PI / 2.0;

      for (TextPainter label in labels) {
        final Offset labelOffset = new Offset(-label.width / 2.0, -label.height / 2.0);
        label.paint(canvas, getOffsetForTheta(labelTheta, ring) + labelOffset);
        labelTheta += labelThetaIncrement;
      }
    }

    paintLabels(primaryOuterLabels, _DialRing.outer);
    paintLabels(primaryInnerLabels, _DialRing.inner);

    final Paint selectorPaint = new Paint()
      ..color = accentColor;
    final Offset focusedPoint = getOffsetForTheta(theta, activeRing);
    final double focusedRadius = labelPadding - 4.0;
    canvas.drawCircle(centerPoint, 4.0, selectorPaint);
    canvas.drawCircle(focusedPoint, focusedRadius, selectorPaint);
    selectorPaint.strokeWidth = 2.0;
    canvas.drawLine(centerPoint, focusedPoint, selectorPaint);

    final Rect focusedRect = new Rect.fromCircle(
      center: focusedPoint, radius: focusedRadius
    );
    canvas
      ..save()
      ..clipPath(new Path()..addOval(focusedRect));
    paintLabels(secondaryOuterLabels, _DialRing.outer);
    paintLabels(secondaryInnerLabels, _DialRing.inner);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter oldPainter) {
    return oldPainter.primaryOuterLabels != primaryOuterLabels
        || oldPainter.primaryInnerLabels != primaryInnerLabels
        || oldPainter.secondaryOuterLabels != secondaryOuterLabels
        || oldPainter.secondaryInnerLabels != secondaryInnerLabels
        || oldPainter.backgroundColor != backgroundColor
        || oldPainter.accentColor != accentColor
        || oldPainter.theta != theta
        || oldPainter.activeRing != activeRing;
  }
}

class _Dial extends StatefulWidget {
  const _Dial({
    @required this.selectedTime,
    @required this.mode,
    @required this.is24h,
    @required this.onChanged
  }) : assert(selectedTime != null);

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final bool is24h;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  _DialState createState() => new _DialState();
}

class _DialState extends State<_Dial> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _thetaController = new AnimationController(
      duration: _kDialAnimateDuration,
      vsync: this,
    );
    _thetaTween = new Tween<double>(begin: _getThetaForTime(widget.selectedTime));
    _theta = _thetaTween.animate(new CurvedAnimation(
      parent: _thetaController,
      curve: Curves.fastOutSlowIn
    ))..addListener(() => setState(() { }));
  }

  @override
  void didUpdateWidget(_Dial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      if (!_dragging)
        _animateTo(_getThetaForTime(widget.selectedTime));
    }
    if (widget.mode == _TimePickerMode.hour && widget.is24h && widget.selectedTime.period == DayPeriod.am) {
      _activeRing = _DialRing.inner;
    } else {
      _activeRing = _DialRing.outer;
    }
  }

  @override
  void dispose() {
    _thetaController.dispose();
    super.dispose();
  }

  Tween<double> _thetaTween;
  Animation<double> _theta;
  AnimationController _thetaController;
  bool _dragging = false;

  static double _nearest(double target, double a, double b) {
    return ((target - a).abs() < (target - b).abs()) ? a : b;
  }

  void _animateTo(double targetTheta) {
    final double currentTheta = _theta.value;
    double beginTheta = _nearest(targetTheta, currentTheta, currentTheta + _kTwoPi);
    beginTheta = _nearest(targetTheta, beginTheta, currentTheta - _kTwoPi);
    _thetaTween
      ..begin = beginTheta
      ..end = targetTheta;
    _thetaController
      ..value = 0.0
      ..forward();
  }

  double _getThetaForTime(TimeOfDay time) {
    final double fraction = (widget.mode == _TimePickerMode.hour) ?
        (time.hour / _kHoursPerPeriod) % _kHoursPerPeriod :
        (time.minute / _kMinutesPerHour) % _kMinutesPerHour;
    return (math.PI / 2.0 - fraction * _kTwoPi) % _kTwoPi;
  }

  TimeOfDay _getTimeForTheta(double theta) {
    final double fraction = (0.25 - (theta % _kTwoPi) / _kTwoPi) % 1.0;
    if (widget.mode == _TimePickerMode.hour) {
      int newHour = (fraction * _kHoursPerPeriod).round() % _kHoursPerPeriod;
      if (widget.is24h) {
        if (_activeRing == _DialRing.outer) {
          if (newHour != 0)
            newHour = (newHour + _kHoursPerPeriod) % _kHoursPerDay;
        } else if (newHour == 0) {
          newHour = _kHoursPerPeriod;
        }
      } else {
        newHour = newHour + widget.selectedTime.periodOffset;
      }
      return widget.selectedTime.replacing(hour: newHour);
    } else {
      return widget.selectedTime.replacing(
        minute: (fraction * _kMinutesPerHour).round() % _kMinutesPerHour
      );
    }
  }

  void _notifyOnChangedIfNeeded() {
    if (widget.onChanged == null)
      return;
    final TimeOfDay current = _getTimeForTheta(_theta.value);
    if (current != widget.selectedTime)
      widget.onChanged(current);
  }

  void _updateThetaForPan() {
    setState(() {
      final Offset offset = _position - _center;
      final double angle = (math.atan2(offset.dx, offset.dy) - math.PI / 2.0) % _kTwoPi;
      _thetaTween
        ..begin = angle
        ..end = angle; // The controller doesn't animate during the pan gesture.
      final RenderBox box = context.findRenderObject();
      final double radius = box.size.shortestSide / 2.0;
      if (widget.mode == _TimePickerMode.hour && widget.is24h) {
        if (offset.distance * 1.5 < radius)
          _activeRing = _DialRing.inner;
        else
          _activeRing = _DialRing.outer;
      }
    });
  }

  Offset _position;
  Offset _center;
  _DialRing _activeRing = _DialRing.outer;

  void _handlePanStart(DragStartDetails details) {
    assert(!_dragging);
    _dragging = true;
    final RenderBox box = context.findRenderObject();
    _position = box.globalToLocal(details.globalPosition);
    _center = box.size.center(Offset.zero);
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _position += details.delta;
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanEnd(DragEndDetails details) {
    assert(_dragging);
    _dragging = false;
    _position = null;
    _center = null;
    _animateTo(_getThetaForTime(widget.selectedTime));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = Colors.grey[200];
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    final ThemeData theme = Theme.of(context);
    List<TextPainter> primaryOuterLabels;
    List<TextPainter> primaryInnerLabels;
    List<TextPainter> secondaryOuterLabels;
    List<TextPainter> secondaryInnerLabels;
    switch (widget.mode) {
      case _TimePickerMode.hour:
        primaryOuterLabels = _initHours(theme.textTheme, _DialRing.outer, widget.is24h);
        secondaryOuterLabels = _initHours(theme.accentTextTheme, _DialRing.outer, widget.is24h);
        primaryInnerLabels = _initHours(theme.textTheme, _DialRing.inner, widget.is24h);
        secondaryInnerLabels = _initHours(theme.accentTextTheme, _DialRing.inner, widget.is24h);
        break;
      case _TimePickerMode.minute:
        primaryOuterLabels = _initMinutes(theme.textTheme);
        primaryInnerLabels = null;
        secondaryOuterLabels = _initMinutes(theme.accentTextTheme);
        secondaryInnerLabels = null;
        break;
    }

    return new GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: new CustomPaint(
        key: const ValueKey<String>('time-picker-dial'), // used for testing.
        painter: new _DialPainter(
          primaryOuterLabels: primaryOuterLabels,
          primaryInnerLabels: primaryInnerLabels,
          secondaryOuterLabels: secondaryOuterLabels,
          secondaryInnerLabels: secondaryInnerLabels,
          backgroundColor: backgroundColor,
          accentColor: themeData.accentColor,
          theta: _theta.value,
          activeRing: _activeRing,
        )
      )
    );
  }
}

class _TimePickerDialog extends StatefulWidget {
  const _TimePickerDialog({
    Key key,
    @required this.initialTime
  }) : assert(initialTime != null),
       super(key: key);

  final TimeOfDay initialTime;

  @override
  _TimePickerDialogState createState() => new _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  _TimePickerMode _mode = _TimePickerMode.hour;
  TimeOfDay _selectedTime;
  Timer _vibrateTimer;

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        _vibrateTimer?.cancel();
        _vibrateTimer = new Timer(_kVibrateCommitDelay, () {
          HapticFeedback.vibrate();
          _vibrateTimer = null;
        });
        break;
      case TargetPlatform.iOS:
        break;
    }
  }

  void _handleModeChanged(_TimePickerMode mode) {
    _vibrate();
    setState(() {
      _mode = mode;
    });
  }

  void _handleTimeChanged(TimeOfDay value) {
    _vibrate();
    setState(() {
      _selectedTime = value;
    });
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    Navigator.pop(context, _selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    final TimeOfDayFormat timeOfDayFormat = MaterialLocalizations.of(context).timeOfDayFormat;

    final Widget picker = new Padding(
      padding: const EdgeInsets.all(16.0),
      child: new AspectRatio(
        aspectRatio: 1.0,
        child: new _Dial(
          mode: _mode,
          is24h: _getHourFormat(timeOfDayFormat) != _TimePickerHourFormat.h,
          selectedTime: _selectedTime,
          onChanged: _handleTimeChanged,
        )
      )
    );

    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final Widget actions = new ButtonTheme.bar(
      child: new ButtonBar(
        children: <Widget>[
          new FlatButton(
            child: new Text(localizations.cancelButtonLabel),
            onPressed: _handleCancel
          ),
          new FlatButton(
            child: new Text(localizations.okButtonLabel),
            onPressed: _handleOk
          ),
        ]
      )
    );

    return new Dialog(
      child: new OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          final Widget header = new _TimePickerHeader(
            selectedTime: _selectedTime,
            mode: _mode,
            orientation: orientation,
            onModeChanged: _handleModeChanged,
            onChanged: _handleTimeChanged,
          );

          assert(orientation != null);
          switch (orientation) {
            case Orientation.portrait:
              return new SizedBox(
                width: _kTimePickerWidthPortrait,
                height: _kTimePickerHeightPortrait,
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    new Expanded(child: picker),
                    actions,
                  ]
                )
              );
            case Orientation.landscape:
              return new SizedBox(
                width: _kTimePickerWidthLandscape,
                height: _kTimePickerHeightLandscape,
                child: new Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    new Flexible(
                      child: new Column(
                        children: <Widget>[
                          new Expanded(child: picker),
                          actions,
                        ]
                      )
                    ),
                  ]
                )
              );
          }
          return null;
        }
      )
    );
  }

  @override
  void dispose() {
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    super.dispose();
  }
}

/// Shows a dialog containing a material design time picker.
///
/// The returned Future resolves to the time selected by the user when the user
/// closes the dialog. If the user cancels the dialog, null is returned.
///
/// To show a dialog with [initialTime] equal to the current time:
/// ```dart
/// showTimePicker(
///   initialTime: new TimeOfDay.now(),
///   context: context
/// );
/// ```
///
/// See also:
///
///  * [showDatePicker]
///  * <https://material.google.com/components/pickers.html#pickers-time-pickers>
Future<TimeOfDay> showTimePicker({
  @required BuildContext context,
  @required TimeOfDay initialTime
}) async {
  assert(context != null);
  assert(initialTime != null);
  return await showDialog(
    context: context,
    child: new _TimePickerDialog(initialTime: initialTime)
  );
}
