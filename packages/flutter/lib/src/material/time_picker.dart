// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button_bar.dart';
import 'button_theme.dart';
import 'colors.dart';
import 'debug.dart';
import 'dialog.dart';
import 'feedback.dart';
import 'flat_button.dart';
import 'material_localizations.dart';
import 'text_theme.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'time.dart';

const Duration _kDialAnimateDuration = Duration(milliseconds: 200);
const double _kTwoPi = 2 * math.pi;
const Duration _kVibrateCommitDelay = Duration(milliseconds: 100);

enum _TimePickerMode { hour, minute }

const double _kTimePickerHeaderPortraitHeight = 96.0;
const double _kTimePickerHeaderLandscapeWidth = 168.0;


const double _kTimePickerWidthPortrait = 328.0;
const double _kTimePickerWidthLandscape = 512.0;

const double _kTimePickerHeightPortrait = 496.0;
const double _kTimePickerHeightLandscape = 316.0;

const double _kTimePickerHeightPortraitCollapsed = 484.0;
const double _kTimePickerHeightLandscapeCollapsed = 304.0;

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
    @required this.targetPlatform,
    @required this.use24HourDials,
  }) : assert(headerTextTheme != null),
       assert(textDirection != null),
       assert(selectedTime != null),
       assert(mode != null),
       assert(activeColor != null),
       assert(activeStyle != null),
       assert(inactiveColor != null),
       assert(inactiveStyle != null),
       assert(onTimeChange != null),
       assert(onModeChange != null),
       assert(targetPlatform != null),
       assert(use24HourDials != null);

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
  final TargetPlatform targetPlatform;
  final bool use24HourDials;
}

/// Contains the [widget] and layout properties of an atom of time information,
/// such as am/pm indicator, hour, minute and string literals appearing in the
/// formatted time string.
class _TimePickerHeaderFragment {
  const _TimePickerHeaderFragment({
    @required this.layoutId,
    @required this.widget,
    this.startMargin = 0.0,
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
  const _TimePickerHeaderPiece(this.pivotIndex, this.fragments, { this.bottomMargin = 0.0 })
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
/// One of the pieces is identified as a _centerpiece_. It is a piece that is
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

  void _togglePeriod() {
    final int newHour = (fragmentContext.selectedTime.hour + TimeOfDay.hoursPerPeriod) % TimeOfDay.hoursPerDay;
    final TimeOfDay newTime = fragmentContext.selectedTime.replacing(hour: newHour);
    fragmentContext.onTimeChange(newTime);
  }

  void _setAm(BuildContext context) {
    if (fragmentContext.selectedTime.period == DayPeriod.am) {
      return;
    }
    if (fragmentContext.targetPlatform == TargetPlatform.android) {
      _announceToAccessibility(context, MaterialLocalizations.of(context).anteMeridiemAbbreviation);
    }
    _togglePeriod();
  }

  void _setPm(BuildContext context) {
    if (fragmentContext.selectedTime.period == DayPeriod.pm) {
      return;
    }
    if (fragmentContext.targetPlatform == TargetPlatform.android) {
      _announceToAccessibility(context, MaterialLocalizations.of(context).postMeridiemAbbreviation);
    }
    _togglePeriod();
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations materialLocalizations = MaterialLocalizations.of(context);
    final TextTheme headerTextTheme = fragmentContext.headerTextTheme;
    final TimeOfDay selectedTime = fragmentContext.selectedTime;
    final Color activeColor = fragmentContext.activeColor;
    final Color inactiveColor = fragmentContext.inactiveColor;
    final bool amSelected = selectedTime.period == DayPeriod.am;
    final TextStyle amStyle = headerTextTheme.subhead.copyWith(
      color: amSelected ? activeColor: inactiveColor
    );
    final TextStyle pmStyle = headerTextTheme.subhead.copyWith(
      color: !amSelected ? activeColor: inactiveColor
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GestureDetector(
          excludeFromSemantics: true,
          onTap: Feedback.wrapForTap(() {
            _setAm(context);
          }, context),
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            selected: amSelected,
            onTap: () {
              _setAm(context);
            },
            child: Text(materialLocalizations.anteMeridiemAbbreviation, style: amStyle),
          ),
        ),
        const SizedBox(width: 0.0, height: 4.0), // Vertical spacer
        GestureDetector(
          excludeFromSemantics: true,
          onTap: Feedback.wrapForTap(() {
            _setPm(context);
          }, context),
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            selected: !amSelected,
            onTap: () {
              _setPm(context);
            },
            child: Text(materialLocalizations.postMeridiemAbbreviation, style: pmStyle),
          ),
        ),
      ],
    );
  }
}

/// Displays the hour fragment.
///
/// When tapped changes time picker dial mode to [_TimePickerMode.hour].
class _HourControl extends StatelessWidget {
  const _HourControl({
    @required this.fragmentContext,
  });

  final _TimePickerFragmentContext fragmentContext;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final bool alwaysUse24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final TextStyle hourStyle = fragmentContext.mode == _TimePickerMode.hour
        ? fragmentContext.activeStyle
        : fragmentContext.inactiveStyle;
    final String formattedHour = localizations.formatHour(
      fragmentContext.selectedTime,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );

    TimeOfDay hoursFromSelected(int hoursToAdd) {
      if (fragmentContext.use24HourDials) {
        final int selectedHour = fragmentContext.selectedTime.hour;
        return fragmentContext.selectedTime.replacing(
          hour: (selectedHour + hoursToAdd) % TimeOfDay.hoursPerDay,
        );
      } else {
        // Cycle 1 through 12 without changing day period.
        final int periodOffset = fragmentContext.selectedTime.periodOffset;
        final int hours = fragmentContext.selectedTime.hourOfPeriod;
        return fragmentContext.selectedTime.replacing(
          hour: periodOffset + (hours + hoursToAdd) % TimeOfDay.hoursPerPeriod,
        );
      }
    }

    final TimeOfDay nextHour = hoursFromSelected(1);
    final String formattedNextHour = localizations.formatHour(
      nextHour,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );
    final TimeOfDay previousHour = hoursFromSelected(-1);
    final String formattedPreviousHour = localizations.formatHour(
      previousHour,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );

    return GestureDetector(
      onTap: Feedback.wrapForTap(() => fragmentContext.onModeChange(_TimePickerMode.hour), context),
      child: Semantics(
        hint: localizations.timePickerHourModeAnnouncement,
        value: formattedHour,
        excludeSemantics: true,
        increasedValue: formattedNextHour,
        onIncrease: () {
          fragmentContext.onTimeChange(nextHour);
        },
        decreasedValue: formattedPreviousHour,
        onDecrease: () {
          fragmentContext.onTimeChange(previousHour);
        },
          child: Text(formattedHour, style: hourStyle),
        ),
    );
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
    return ExcludeSemantics(
      child: Text(value, style: fragmentContext.inactiveStyle),
    );
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
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final TextStyle minuteStyle = fragmentContext.mode == _TimePickerMode.minute
        ? fragmentContext.activeStyle
        : fragmentContext.inactiveStyle;
    final String formattedMinute = localizations.formatMinute(fragmentContext.selectedTime);
    final TimeOfDay nextMinute = fragmentContext.selectedTime.replacing(
      minute: (fragmentContext.selectedTime.minute + 1) % TimeOfDay.minutesPerHour,
    );
    final String formattedNextMinute = localizations.formatMinute(nextMinute);
    final TimeOfDay previousMinute = fragmentContext.selectedTime.replacing(
      minute: (fragmentContext.selectedTime.minute - 1) % TimeOfDay.minutesPerHour,
    );
    final String formattedPreviousMinute = localizations.formatMinute(previousMinute);

    return GestureDetector(
      onTap: Feedback.wrapForTap(() => fragmentContext.onModeChange(_TimePickerMode.minute), context),
      child: Semantics(
        excludeSemantics: true,
        hint: localizations.timePickerMinuteModeAnnouncement,
        value: formattedMinute,
        increasedValue: formattedNextMinute,
        onIncrease: () {
          fragmentContext.onTimeChange(nextMinute);
        },
        decreasedValue: formattedPreviousMinute,
        onDecrease: () {
          fragmentContext.onTimeChange(previousMinute);
        },
          child: Text(formattedMinute, style: minuteStyle),
        ),
    );
  }
}

/// Provides time picker header layout configuration for the given
/// [timeOfDayFormat] passing [context] to each widget in the
/// configuration.
///
/// The [timeOfDayFormat] and [context] arguments must not be null.
_TimePickerHeaderFormat _buildHeaderFormat(TimeOfDayFormat timeOfDayFormat, _TimePickerFragmentContext context) {
  // Creates an hour fragment.
  _TimePickerHeaderFragment hour() {
    return _TimePickerHeaderFragment(
      layoutId: _TimePickerHeaderId.hour,
      widget: _HourControl(fragmentContext: context),
      startMargin: _kPeriodGap,
    );
  }

  // Creates a minute fragment.
  _TimePickerHeaderFragment minute() {
    return _TimePickerHeaderFragment(
      layoutId: _TimePickerHeaderId.minute,
      widget: _MinuteControl(fragmentContext: context),
    );
  }

  // Creates a string fragment.
  _TimePickerHeaderFragment string(_TimePickerHeaderId layoutId, String value) {
    return _TimePickerHeaderFragment(
      layoutId: layoutId,
      widget: _StringFragment(
        fragmentContext: context,
        value: value,
      ),
    );
  }

  // Creates an am/pm fragment.
  _TimePickerHeaderFragment dayPeriod() {
    return _TimePickerHeaderFragment(
      layoutId: _TimePickerHeaderId.period,
      widget: _DayPeriodControl(fragmentContext: context),
      startMargin: _kPeriodGap,
    );
  }

  // Convenience function for creating a time header format with up to two pieces.
  _TimePickerHeaderFormat format(_TimePickerHeaderPiece piece1,
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
        break;
    }
    int centrepieceIndex;
    for (int i = 0; i < pieces.length; i += 1) {
      if (pieces[i].pivotIndex >= 0) {
        centrepieceIndex = i;
      }
    }
    assert(centrepieceIndex != null);
    return _TimePickerHeaderFormat(centrepieceIndex, pieces);
  }

  // Convenience function for creating a time header piece with up to three fragments.
  _TimePickerHeaderPiece piece({ int pivotIndex = -1, double bottomMargin = 0.0,
      _TimePickerHeaderFragment fragment1, _TimePickerHeaderFragment fragment2, _TimePickerHeaderFragment fragment3 }) {
    final List<_TimePickerHeaderFragment> fragments = <_TimePickerHeaderFragment>[fragment1];
    if (fragment2 != null) {
      fragments.add(fragment2);
      if (fragment3 != null)
        fragments.add(fragment3);
    }
    return _TimePickerHeaderPiece(pivotIndex, fragments, bottomMargin: bottomMargin);
  }

  switch (timeOfDayFormat) {
    case TimeOfDayFormat.h_colon_mm_space_a:
      return format(
        piece(
          pivotIndex: 1,
          fragment1: hour(),
          fragment2: string(_TimePickerHeaderId.colon, ':'),
          fragment3: minute(),
        ),
        piece(
          bottomMargin: _kVerticalGap,
          fragment1: dayPeriod(),
        ),
      );
    case TimeOfDayFormat.H_colon_mm:
      return format(piece(
        pivotIndex: 1,
        fragment1: hour(),
        fragment2: string(_TimePickerHeaderId.colon, ':'),
        fragment3: minute(),
      ));
    case TimeOfDayFormat.HH_dot_mm:
      return format(piece(
        pivotIndex: 1,
        fragment1: hour(),
        fragment2: string(_TimePickerHeaderId.dot, '.'),
        fragment3: minute(),
      ));
    case TimeOfDayFormat.a_space_h_colon_mm:
      return format(
        piece(
          bottomMargin: _kVerticalGap,
          fragment1: dayPeriod(),
        ),
        piece(
          pivotIndex: 1,
          fragment1: hour(),
          fragment2: string(_TimePickerHeaderId.colon, ':'),
          fragment3: minute(),
        ),
      );
    case TimeOfDayFormat.frenchCanadian:
      return format(piece(
        pivotIndex: 1,
        fragment1: hour(),
        fragment2: string(_TimePickerHeaderId.hString, 'h'),
        fragment3: minute(),
      ));
    case TimeOfDayFormat.HH_colon_mm:
      return format(piece(
        pivotIndex: 1,
        fragment1: hour(),
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
    final BoxConstraints constraints = BoxConstraints.loose(size);

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
      positionChild(fragment.layoutId, Offset(x, y - childSize.height / 2.0));
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
      positionChild(fragment.layoutId, Offset(x, centeredAroundY - childSize.height / 2.0));
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
    @required this.use24HourDials,
  }) : assert(selectedTime != null),
       assert(mode != null),
       assert(orientation != null),
       assert(use24HourDials != null);

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final Orientation orientation;
  final ValueChanged<_TimePickerMode> onModeChanged;
  final ValueChanged<TimeOfDay> onChanged;
  final bool use24HourDials;

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
    assert(debugCheckHasMediaQuery(context));
    final ThemeData themeData = Theme.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final TimeOfDayFormat timeOfDayFormat = MaterialLocalizations.of(context)
        .timeOfDayFormat(alwaysUse24HourFormat: media.alwaysUse24HourFormat);

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
    final _TimePickerFragmentContext fragmentContext = _TimePickerFragmentContext(
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
      targetPlatform: themeData.platform,
      use24HourDials: use24HourDials,
    );

    final _TimePickerHeaderFormat format = _buildHeaderFormat(timeOfDayFormat, fragmentContext);

    return Container(
      width: width,
      height: height,
      padding: padding,
      color: backgroundColor,
      child: CustomMultiChildLayout(
        delegate: _TimePickerHeaderLayout(orientation, format),
        children: format.pieces
          .expand<_TimePickerHeaderFragment>((_TimePickerHeaderPiece piece) => piece.fragments)
          .map<Widget>((_TimePickerHeaderFragment fragment) {
            return LayoutId(
              id: fragment.layoutId,
              child: fragment.widget,
            );
          })
          .toList(),
      )
    );
  }
}

enum _DialRing {
  outer,
  inner,
}

class _TappableLabel {
  _TappableLabel({
    @required this.value,
    @required this.painter,
    @required this.onTap,
  });

  /// The value this label is displaying.
  final int value;

  /// Paints the text of the label.
  final TextPainter painter;

  /// Called when a tap gesture is detected on the label.
  final VoidCallback onTap;
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
    @required this.textDirection,
    @required this.selectedValue,
  });

  final List<_TappableLabel> primaryOuterLabels;
  final List<_TappableLabel> primaryInnerLabels;
  final List<_TappableLabel> secondaryOuterLabels;
  final List<_TappableLabel> secondaryInnerLabels;
  final Color backgroundColor;
  final Color accentColor;
  final double theta;
  final _DialRing activeRing;
  final TextDirection textDirection;
  final int selectedValue;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.shortestSide / 2.0;
    final Offset center = Offset(size.width / 2.0, size.height / 2.0);
    final Offset centerPoint = center;
    canvas.drawCircle(centerPoint, radius, Paint()..color = backgroundColor);

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
      return center + Offset(labelRadius * math.cos(theta),
                                 -labelRadius * math.sin(theta));
    }

    void paintLabels(List<_TappableLabel> labels, _DialRing ring) {
      if (labels == null)
        return;
      final double labelThetaIncrement = -_kTwoPi / labels.length;
      double labelTheta = math.pi / 2.0;

      for (_TappableLabel label in labels) {
        final TextPainter labelPainter = label.painter;
        final Offset labelOffset = Offset(-labelPainter.width / 2.0, -labelPainter.height / 2.0);
        labelPainter.paint(canvas, getOffsetForTheta(labelTheta, ring) + labelOffset);
        labelTheta += labelThetaIncrement;
      }
    }

    paintLabels(primaryOuterLabels, _DialRing.outer);
    paintLabels(primaryInnerLabels, _DialRing.inner);

    final Paint selectorPaint = Paint()
      ..color = accentColor;
    final Offset focusedPoint = getOffsetForTheta(theta, activeRing);
    const double focusedRadius = labelPadding - 4.0;
    canvas.drawCircle(centerPoint, 4.0, selectorPaint);
    canvas.drawCircle(focusedPoint, focusedRadius, selectorPaint);
    selectorPaint.strokeWidth = 2.0;
    canvas.drawLine(centerPoint, focusedPoint, selectorPaint);

    final Rect focusedRect = Rect.fromCircle(
      center: focusedPoint, radius: focusedRadius
    );
    canvas
      ..save()
      ..clipPath(Path()..addOval(focusedRect));
    paintLabels(secondaryOuterLabels, _DialRing.outer);
    paintLabels(secondaryInnerLabels, _DialRing.inner);
    canvas.restore();
  }

  static const double _semanticNodeSizeScale = 1.5;

  @override
  SemanticsBuilderCallback get semanticsBuilder => _buildSemantics;

  /// Creates semantics nodes for the hour/minute labels painted on the dial.
  ///
  /// The nodes are positioned on top of the text and their size is
  /// [_semanticNodeSizeScale] bigger than those of the text boxes to provide
  /// bigger tap area.
  List<CustomPainterSemantics> _buildSemantics(Size size) {
    final double radius = size.shortestSide / 2.0;
    final Offset center = Offset(size.width / 2.0, size.height / 2.0);
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
      return center + Offset(labelRadius * math.cos(theta),
          -labelRadius * math.sin(theta));
    }

    final List<CustomPainterSemantics> nodes = <CustomPainterSemantics>[];

    void paintLabels(List<_TappableLabel> labels, _DialRing ring) {
      if (labels == null)
        return;
      final double labelThetaIncrement = -_kTwoPi / labels.length;
      final double ordinalOffset = ring == _DialRing.inner ? 12.0 : 0.0;
      double labelTheta = math.pi / 2.0;

      for (int i = 0; i < labels.length; i++) {
        final _TappableLabel label = labels[i];
        final TextPainter labelPainter = label.painter;
        final double width = labelPainter.width * _semanticNodeSizeScale;
        final double height = labelPainter.height * _semanticNodeSizeScale;
        final Offset nodeOffset = getOffsetForTheta(labelTheta, ring) + Offset(-width / 2.0, -height / 2.0);
        final CustomPainterSemantics node = CustomPainterSemantics(
          rect: Rect.fromLTRB(
            nodeOffset.dx - 24.0 + width / 2,
            nodeOffset.dy - 24.0 + height / 2,
            nodeOffset.dx + 24.0 + width / 2,
            nodeOffset.dy + 24.0 + height / 2,
          ),
          properties: SemanticsProperties(
            sortKey: OrdinalSortKey(i.toDouble() + ordinalOffset),
            selected: label.value == selectedValue,
            value: labelPainter.text.text,
            textDirection: textDirection,
            onTap: label.onTap,
          ),
          tags: Set<SemanticsTag>.from(const <SemanticsTag>[
            // Used by tests to find this node.
            SemanticsTag('dial-label'),
          ]),
        );
        nodes.add(node);
        labelTheta += labelThetaIncrement;
      }
    }

    paintLabels(primaryOuterLabels, _DialRing.outer);
    paintLabels(primaryInnerLabels, _DialRing.inner);

    return nodes;
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
    @required this.use24HourDials,
    @required this.onChanged
  }) : assert(selectedTime != null);

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final bool use24HourDials;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  _DialState createState() => _DialState();
}

class _DialState extends State<_Dial> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _updateDialRingFromWidget();
    _thetaController = AnimationController(
      duration: _kDialAnimateDuration,
      vsync: this,
    );
    _thetaTween = Tween<double>(begin: _getThetaForTime(widget.selectedTime));
    _theta = _thetaController
      .drive(CurveTween(curve: Curves.fastOutSlowIn))
      .drive(_thetaTween)
      ..addListener(() => setState(() { /* _theta.value has changed */ }));
  }

  ThemeData themeData;
  MaterialLocalizations localizations;
  MediaQueryData media;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMediaQuery(context));
    themeData = Theme.of(context);
    localizations = MaterialLocalizations.of(context);
    media = MediaQuery.of(context);
  }

  @override
  void didUpdateWidget(_Dial oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateDialRingFromWidget();
    if (widget.mode != oldWidget.mode || widget.selectedTime != oldWidget.selectedTime) {
      if (!_dragging)
        _animateTo(_getThetaForTime(widget.selectedTime));
    }
  }

  void _updateDialRingFromWidget() {
    if (widget.mode == _TimePickerMode.hour && widget.use24HourDials) {
      _activeRing = widget.selectedTime.hour >= 1 && widget.selectedTime.hour <= 12
          ? _DialRing.inner
          : _DialRing.outer;
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
    final double fraction = widget.mode == _TimePickerMode.hour
      ? (time.hour / TimeOfDay.hoursPerPeriod) % TimeOfDay.hoursPerPeriod
      : (time.minute / TimeOfDay.minutesPerHour) % TimeOfDay.minutesPerHour;
    return (math.pi / 2.0 - fraction * _kTwoPi) % _kTwoPi;
  }

  TimeOfDay _getTimeForTheta(double theta) {
    final double fraction = (0.25 - (theta % _kTwoPi) / _kTwoPi) % 1.0;
    if (widget.mode == _TimePickerMode.hour) {
      int newHour = (fraction * TimeOfDay.hoursPerPeriod).round() % TimeOfDay.hoursPerPeriod;
      if (widget.use24HourDials) {
        if (_activeRing == _DialRing.outer) {
          if (newHour != 0)
            newHour = (newHour + TimeOfDay.hoursPerPeriod) % TimeOfDay.hoursPerDay;
        } else if (newHour == 0) {
          newHour = TimeOfDay.hoursPerPeriod;
        }
      } else {
        newHour = newHour + widget.selectedTime.periodOffset;
      }
      return widget.selectedTime.replacing(hour: newHour);
    } else {
      return widget.selectedTime.replacing(
        minute: (fraction * TimeOfDay.minutesPerHour).round() % TimeOfDay.minutesPerHour
      );
    }
  }

  TimeOfDay _notifyOnChangedIfNeeded() {
    final TimeOfDay current = _getTimeForTheta(_theta.value);
    if (widget.onChanged == null)
      return current;
    if (current != widget.selectedTime)
      widget.onChanged(current);
    return current;
  }

  void _updateThetaForPan() {
    setState(() {
      final Offset offset = _position - _center;
      final double angle = (math.atan2(offset.dx, offset.dy) - math.pi / 2.0) % _kTwoPi;
      _thetaTween
        ..begin = angle
        ..end = angle; // The controller doesn't animate during the pan gesture.
      final RenderBox box = context.findRenderObject();
      final double radius = box.size.shortestSide / 2.0;
      if (widget.mode == _TimePickerMode.hour && widget.use24HourDials) {
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

  void _handleTapUp(TapUpDetails details) {
    final RenderBox box = context.findRenderObject();
    _position = box.globalToLocal(details.globalPosition);
    _center = box.size.center(Offset.zero);
    _updateThetaForPan();
    final TimeOfDay newTime = _notifyOnChangedIfNeeded();
    if (widget.mode == _TimePickerMode.hour) {
      if (widget.use24HourDials) {
        _announceToAccessibility(context, localizations.formatDecimal(newTime.hour));
      } else {
        _announceToAccessibility(context, localizations.formatDecimal(newTime.hourOfPeriod));
      }
    } else {
      _announceToAccessibility(context, localizations.formatDecimal(newTime.minute));
    }
    _animateTo(_getThetaForTime(_getTimeForTheta(_theta.value)));
    _dragging = false;
    _position = null;
    _center = null;
  }

  void _selectHour(int hour) {
    _announceToAccessibility(context, localizations.formatDecimal(hour));
    TimeOfDay time;
    if (widget.mode == _TimePickerMode.hour && widget.use24HourDials) {
      _activeRing = hour >= 1 && hour <= 12
          ? _DialRing.inner
          : _DialRing.outer;
      time = TimeOfDay(hour: hour, minute: widget.selectedTime.minute);
    } else {
      _activeRing = _DialRing.outer;
      if (widget.selectedTime.period == DayPeriod.am) {
        time = TimeOfDay(hour: hour, minute: widget.selectedTime.minute);
      } else {
        time = TimeOfDay(hour: hour + TimeOfDay.hoursPerPeriod, minute: widget.selectedTime.minute);
      }
    }
    final double angle = _getThetaForTime(time);
    _thetaTween
      ..begin = angle
      ..end = angle;
    _notifyOnChangedIfNeeded();
  }

  void _selectMinute(int minute) {
    _announceToAccessibility(context, localizations.formatDecimal(minute));
    final TimeOfDay time = TimeOfDay(
      hour: widget.selectedTime.hour,
      minute: minute,
    );
    final double angle = _getThetaForTime(time);
    _thetaTween
      ..begin = angle
      ..end = angle;
    _notifyOnChangedIfNeeded();
  }

  static const List<TimeOfDay> _amHours = <TimeOfDay>[
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 1, minute: 0),
    TimeOfDay(hour: 2, minute: 0),
    TimeOfDay(hour: 3, minute: 0),
    TimeOfDay(hour: 4, minute: 0),
    TimeOfDay(hour: 5, minute: 0),
    TimeOfDay(hour: 6, minute: 0),
    TimeOfDay(hour: 7, minute: 0),
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
  ];

  static const List<TimeOfDay> _pmHours = <TimeOfDay>[
    TimeOfDay(hour: 0, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
    TimeOfDay(hour: 19, minute: 0),
    TimeOfDay(hour: 20, minute: 0),
    TimeOfDay(hour: 21, minute: 0),
    TimeOfDay(hour: 22, minute: 0),
    TimeOfDay(hour: 23, minute: 0),
  ];

  _TappableLabel _buildTappableLabel(TextTheme textTheme, int value, String label, VoidCallback onTap) {
    final TextStyle style = textTheme.subhead;
    // TODO(abarth): Handle textScaleFactor.
    // https://github.com/flutter/flutter/issues/5939
    return _TappableLabel(
      value: value,
      painter: TextPainter(
        text: TextSpan(style: style, text: label),
        textDirection: TextDirection.ltr,
      )..layout(),
      onTap: onTap,
    );
  }

  List<_TappableLabel> _build24HourInnerRing(TextTheme textTheme) {
    final List<_TappableLabel> labels = <_TappableLabel>[];
    for (TimeOfDay timeOfDay in _amHours) {
      labels.add(_buildTappableLabel(
        textTheme,
        timeOfDay.hour,
        localizations.formatHour(timeOfDay, alwaysUse24HourFormat: media.alwaysUse24HourFormat),
        () {
          _selectHour(timeOfDay.hour);
        },
      ));
    }
    return labels;
  }

  List<_TappableLabel> _build24HourOuterRing(TextTheme textTheme) {
    final List<_TappableLabel> labels = <_TappableLabel>[];
    for (TimeOfDay timeOfDay in _pmHours) {
      labels.add(_buildTappableLabel(
        textTheme,
        timeOfDay.hour,
        localizations.formatHour(timeOfDay, alwaysUse24HourFormat: media.alwaysUse24HourFormat),
        () {
          _selectHour(timeOfDay.hour);
        },
      ));
    }
    return labels;
  }

  List<_TappableLabel> _build12HourOuterRing(TextTheme textTheme) {
    final List<_TappableLabel> labels = <_TappableLabel>[];
    for (TimeOfDay timeOfDay in _amHours) {
      labels.add(_buildTappableLabel(
        textTheme,
        timeOfDay.hour,
        localizations.formatHour(timeOfDay, alwaysUse24HourFormat: media.alwaysUse24HourFormat),
        () {
          _selectHour(timeOfDay.hour);
        },
      ));
    }
    return labels;
  }

  List<_TappableLabel> _buildMinutes(TextTheme textTheme) {
    const List<TimeOfDay> _minuteMarkerValues = <TimeOfDay>[
      TimeOfDay(hour: 0, minute: 0),
      TimeOfDay(hour: 0, minute: 5),
      TimeOfDay(hour: 0, minute: 10),
      TimeOfDay(hour: 0, minute: 15),
      TimeOfDay(hour: 0, minute: 20),
      TimeOfDay(hour: 0, minute: 25),
      TimeOfDay(hour: 0, minute: 30),
      TimeOfDay(hour: 0, minute: 35),
      TimeOfDay(hour: 0, minute: 40),
      TimeOfDay(hour: 0, minute: 45),
      TimeOfDay(hour: 0, minute: 50),
      TimeOfDay(hour: 0, minute: 55),
    ];

    final List<_TappableLabel> labels = <_TappableLabel>[];
    for (TimeOfDay timeOfDay in _minuteMarkerValues) {
      labels.add(_buildTappableLabel(
        textTheme,
        timeOfDay.minute,
        localizations.formatMinute(timeOfDay),
        () {
          _selectMinute(timeOfDay.minute);
        },
      ));
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
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
    List<_TappableLabel> primaryOuterLabels;
    List<_TappableLabel> primaryInnerLabels;
    List<_TappableLabel> secondaryOuterLabels;
    List<_TappableLabel> secondaryInnerLabels;
    int selectedDialValue;
    switch (widget.mode) {
      case _TimePickerMode.hour:
        if (widget.use24HourDials) {
          selectedDialValue = widget.selectedTime.hour;
          primaryOuterLabels = _build24HourOuterRing(theme.textTheme);
          secondaryOuterLabels = _build24HourOuterRing(theme.accentTextTheme);
          primaryInnerLabels = _build24HourInnerRing(theme.textTheme);
          secondaryInnerLabels = _build24HourInnerRing(theme.accentTextTheme);
        } else {
          selectedDialValue = widget.selectedTime.hourOfPeriod;
          primaryOuterLabels = _build12HourOuterRing(theme.textTheme);
          secondaryOuterLabels = _build12HourOuterRing(theme.accentTextTheme);
        }
        break;
      case _TimePickerMode.minute:
        selectedDialValue = widget.selectedTime.minute;
        primaryOuterLabels = _buildMinutes(theme.textTheme);
        primaryInnerLabels = null;
        secondaryOuterLabels = _buildMinutes(theme.accentTextTheme);
        secondaryInnerLabels = null;
        break;
    }

    return GestureDetector(
      excludeFromSemantics: true,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTapUp: _handleTapUp,
      child: CustomPaint(
        key: const ValueKey<String>('time-picker-dial'),
        painter: _DialPainter(
          selectedValue: selectedDialValue,
          primaryOuterLabels: primaryOuterLabels,
          primaryInnerLabels: primaryInnerLabels,
          secondaryOuterLabels: secondaryOuterLabels,
          secondaryInnerLabels: secondaryInnerLabels,
          backgroundColor: backgroundColor,
          accentColor: themeData.accentColor,
          theta: _theta.value,
          activeRing: _activeRing,
          textDirection: Directionality.of(context),
        ),
      )
    );
  }
}

/// A material design time picker designed to appear inside a popup dialog.
///
/// Pass this widget to [showDialog]. The value returned by [showDialog] is the
/// selected [TimeOfDay] if the user taps the "OK" button, or null if the user
/// taps the "CANCEL" button. The selected time is reported by calling
/// [Navigator.pop].
class _TimePickerDialog extends StatefulWidget {
  /// Creates a material time picker.
  ///
  /// [initialTime] must not be null.
  const _TimePickerDialog({
    Key key,
    @required this.initialTime
  }) : assert(initialTime != null),
       super(key: key);

  /// The time initially selected when the dialog is shown.
  final TimeOfDay initialTime;

  @override
  _TimePickerDialogState createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    _announceInitialTimeOnce();
    _announceModeOnce();
  }

  _TimePickerMode _mode = _TimePickerMode.hour;
  _TimePickerMode _lastModeAnnounced;

  TimeOfDay get selectedTime => _selectedTime;
  TimeOfDay _selectedTime;

  Timer _vibrateTimer;
  MaterialLocalizations localizations;

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        _vibrateTimer?.cancel();
        _vibrateTimer = Timer(_kVibrateCommitDelay, () {
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
      _announceModeOnce();
    });
  }

  void _announceModeOnce() {
    if (_lastModeAnnounced == _mode) {
      // Already announced it.
      return;
    }

    switch (_mode) {
      case _TimePickerMode.hour:
        _announceToAccessibility(context, localizations.timePickerHourModeAnnouncement);
        break;
      case _TimePickerMode.minute:
        _announceToAccessibility(context, localizations.timePickerMinuteModeAnnouncement);
        break;
    }
    _lastModeAnnounced = _mode;
  }

  bool _announcedInitialTime = false;

  void _announceInitialTimeOnce() {
    if (_announcedInitialTime)
      return;

    final MediaQueryData media = MediaQuery.of(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    _announceToAccessibility(
      context,
      localizations.formatTimeOfDay(widget.initialTime, alwaysUse24HourFormat: media.alwaysUse24HourFormat),
    );
    _announcedInitialTime = true;
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
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData media = MediaQuery.of(context);
    final TimeOfDayFormat timeOfDayFormat = localizations.timeOfDayFormat(alwaysUse24HourFormat: media.alwaysUse24HourFormat);
    final bool use24HourDials = hourFormat(of: timeOfDayFormat) != HourFormat.h;
    final ThemeData theme = Theme.of(context);

    final Widget picker = Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: _Dial(
          mode: _mode,
          use24HourDials: use24HourDials,
          selectedTime: _selectedTime,
          onChanged: _handleTimeChanged,
        )
      )
    );

    final Widget actions = ButtonTheme.bar(
      child: ButtonBar(
        children: <Widget>[
          FlatButton(
            child: Text(localizations.cancelButtonLabel),
            onPressed: _handleCancel
          ),
          FlatButton(
            child: Text(localizations.okButtonLabel),
            onPressed: _handleOk
          ),
        ]
      )
    );

    final Dialog dialog = Dialog(
      child: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          final Widget header = _TimePickerHeader(
            selectedTime: _selectedTime,
            mode: _mode,
            orientation: orientation,
            onModeChanged: _handleModeChanged,
            onChanged: _handleTimeChanged,
            use24HourDials: use24HourDials,
          );

          final Widget pickerAndActions = Container(
            color: theme.dialogBackgroundColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(child: picker), // picker grows and shrinks with the available space
                actions,
              ],
            ),
          );

          double timePickerHeightPortrait;
          double timePickerHeightLandscape;
          switch (theme.materialTapTargetSize) {
            case MaterialTapTargetSize.padded:
              timePickerHeightPortrait = _kTimePickerHeightPortrait;
              timePickerHeightLandscape = _kTimePickerHeightLandscape;
              break;
            case MaterialTapTargetSize.shrinkWrap:
              timePickerHeightPortrait = _kTimePickerHeightPortraitCollapsed;
              timePickerHeightLandscape = _kTimePickerHeightLandscapeCollapsed;
              break;
          }

          assert(orientation != null);
          switch (orientation) {
            case Orientation.portrait:
              return SizedBox(
                width: _kTimePickerWidthPortrait,
                height: timePickerHeightPortrait,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    Expanded(
                      child: pickerAndActions,
                    ),
                  ]
                )
              );
            case Orientation.landscape:
              return SizedBox(
                width: _kTimePickerWidthLandscape,
                height: timePickerHeightLandscape,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    Flexible(
                      child: pickerAndActions,
                    ),
                  ]
                )
              );
          }
          return null;
        }
      )
    );

    return Theme(
      data: theme.copyWith(
        dialogBackgroundColor: Colors.transparent,
      ),
      child: dialog,
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
///
/// ```dart
/// showTimePicker(
///   initialTime: TimeOfDay.now(),
///   context: context,
/// );
/// ```
///
/// The `context` argument is passed to [showDialog], the documentation for
/// which discusses how it is used.
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
  assert(debugCheckHasMaterialLocalizations(context));

  return await showDialog<TimeOfDay>(
    context: context,
    builder: (BuildContext context) => _TimePickerDialog(initialTime: initialTime),
  );
}

void _announceToAccessibility(BuildContext context, String message) {
  SemanticsService.announce(message, Directionality.of(context));
}
