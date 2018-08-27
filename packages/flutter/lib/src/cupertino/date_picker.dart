// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'localizations.dart';
import 'picker.dart';

/// Default aesthetic values obtained by comparing with iOS pickers.
const double _kItemExtent = 32.0;
const double _kPickerWidth = 330.0;
/// Considers setting the default background color from the theme, in the future.
const Color _kBackgroundColor = CupertinoColors.white;


// The iOS date picker and timer picker has their width fixed to 330.0 in all
// modes.
//
// If the maximum width given to the picker is greater than 330.0, the leftmost
// and rightmost column will be extended equally so that the widths match, and
// the picker is in the center.
//
// If the maximum width given to the picker is smaller than 330.0, the picker's
// layout will be broken.


/// Different modes of [CupertinoTimerPicker].
enum CupertinoTimerPickerMode {
  /// Mode that shows the timer duration in hour and minute.
  ///
  /// Examples: [16 hours | 14 min].
  hm,
  /// Mode that shows the timer duration in minute and second.
  ///
  /// Examples: [14 min | 43 sec].
  ms,
  /// Mode that shows the timer duration in hour, minute, and second.
  ///
  /// Examples: [16 hours | 14 min | 43 sec].
  hms,
}

/// A countdown timer picker in iOS style.
///
/// This picker shows a countdown duration with hour, minute and second spinners.
/// The duration is bound between 0 and 23 hours 59 minutes 59 seconds.
///
/// There are several modes of the timer picker listed in [CupertinoTimerPickerMode].
class CupertinoTimerPicker extends StatefulWidget {
  /// Constructs an iOS style countdown timer picker.
  ///
  /// [mode] is one of the modes listed in [CupertinoTimerPickerMode] and
  /// defaults to [CupertinoTimerPickerMode.hms].
  ///
  /// [onTimerDurationChanged] is the callback when the selected duration changes
  /// and must not be null.
  ///
  /// [initialTimerDuration] defaults to 0 second and is limited from 0 second
  /// to 23 hours 59 minutes 59 seconds.
  ///
  /// [minuteInterval] is the granularity of the minute spinner. Must be a
  /// positive integer factor of 60.
  ///
  /// [secondInterval] is the granularity of the second spinner. Must be a
  /// positive integer factor of 60.
  CupertinoTimerPicker({
    this.mode = CupertinoTimerPickerMode.hms,
    this.initialTimerDuration = const Duration(),
    this.minuteInterval = 1,
    this.secondInterval = 1,
    @required this.onTimerDurationChanged,
  }) : assert(mode != null),
       assert(onTimerDurationChanged != null),
       assert(initialTimerDuration >= const Duration(seconds: 0)),
       assert(initialTimerDuration < const Duration(days: 1)),
       assert(minuteInterval > 0 && 60 % minuteInterval == 0),
       assert(secondInterval > 0 && 60 % secondInterval == 0),
       assert(initialTimerDuration.inMinutes % minuteInterval == 0),
       assert(initialTimerDuration.inSeconds % secondInterval == 0);

  /// The mode of the timer picker.
  final CupertinoTimerPickerMode mode;

  /// The initial duration of the countdown timer.
  final Duration initialTimerDuration;

  /// The granularity of the minute spinner. Must be a positive integer factor
  /// of 60.
  final int minuteInterval;

  /// The granularity of the second spinner. Must be a positive integer factor
  /// of 60.
  final int secondInterval;

  /// Callback when the timer duration changes.
  final ValueChanged<Duration> onTimerDurationChanged;

  @override
  State<StatefulWidget> createState() => new _CupertinoTimerPickerState();
}

class _CupertinoTimerPickerState extends State<CupertinoTimerPicker> {
  int textDirectionFactor;
  CupertinoLocalizations localizations;

  // Alignment based on text direction. The variable name is self descriptive,
  // however, when text direction is rtl, alignment is reversed.
  Alignment alignCenterLeft;
  Alignment alignCenterRight;

  // The currently selected values of the picker.
  int selectedHour;
  int selectedMinute;
  int selectedSecond;

  @override
  void initState() {
    super.initState();

    selectedMinute = widget.initialTimerDuration.inMinutes % 60;

    if (widget.mode != CupertinoTimerPickerMode.ms)
      selectedHour = widget.initialTimerDuration.inHours;

    if (widget.mode != CupertinoTimerPickerMode.hm)
      selectedSecond = widget.initialTimerDuration.inSeconds % 60;
  }

  // Builds a text label with customized scale factor and font weight.
  Widget _buildLabel(String text) {
    return new Text(
      text,
      textScaleFactor: 0.8,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context) ?? const DefaultCupertinoLocalizations();

    alignCenterLeft = textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight = textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;
  }

  Widget _buildHourPicker() {
    return new CupertinoPicker(
      scrollController: new FixedExtentScrollController(initialItem: selectedHour),
      offAxisFraction: -0.5 * textDirectionFactor,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedHour = index;
          widget.onTimerDurationChanged(
            new Duration(
              hours: selectedHour,
              minutes: selectedMinute,
              seconds: selectedSecond ?? 0));
        });
      },
      children: new List<Widget>.generate(24, (int index) {
        final double hourLabelWidth =
          widget.mode == CupertinoTimerPickerMode.hm ? _kPickerWidth / 4 : _kPickerWidth / 6;

        final String semanticsLabel = textDirectionFactor == 1
          ? localizations.timerPickerHour(index) + localizations.timerPickerHourLabel(index)
          : localizations.timerPickerHourLabel(index) + localizations.timerPickerHour(index);

        return new Semantics(
          label: semanticsLabel,
          child: new Container(
            alignment: alignCenterRight,
            padding: textDirectionFactor == 1
              ? new EdgeInsets.only(right: hourLabelWidth)
              : new EdgeInsets.only(left: hourLabelWidth),
            child: new Container(
              alignment: alignCenterRight,
              // Adds some spaces between words.
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: new Text(localizations.timerPickerHour(index)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHourColumn() {
    final Widget hourLabel = new IgnorePointer(
      child: new Container(
        alignment: alignCenterRight,
        child: new Container(
          alignment: alignCenterLeft,
          // Adds some spaces between words.
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          width: widget.mode == CupertinoTimerPickerMode.hm
            ? _kPickerWidth / 4
            : _kPickerWidth / 6,
          child: _buildLabel(localizations.timerPickerHourLabel(selectedHour)),
        ),
      ),
    );

    return new Stack(
      children: <Widget>[
        _buildHourPicker(),
        hourLabel,
      ],
    );
  }

  Widget _buildMinutePicker() {
    double offAxisFraction;
    if (widget.mode == CupertinoTimerPickerMode.hm)
      offAxisFraction = 0.5 * textDirectionFactor;
    else if (widget.mode == CupertinoTimerPickerMode.hms)
      offAxisFraction = 0.0;
    else
      offAxisFraction = -0.5 * textDirectionFactor;

    return new CupertinoPicker(
      scrollController: new FixedExtentScrollController(
        initialItem: selectedMinute ~/ widget.minuteInterval,
      ),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedMinute = index;
          widget.onTimerDurationChanged(
            new Duration(
              hours: selectedHour ?? 0,
              minutes: selectedMinute,
              seconds: selectedSecond ?? 0));
        });
      },
      children: new List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
        final int minute = index * widget.minuteInterval;

        final String semanticsLabel = textDirectionFactor == 1
          ? localizations.timerPickerMinute(minute) + localizations.timerPickerMinuteLabel(minute)
          : localizations.timerPickerMinuteLabel(minute) + localizations.timerPickerMinute(minute);

        if (widget.mode == CupertinoTimerPickerMode.ms) {
          return new Semantics(
            label: semanticsLabel,
            child: new Container(
              alignment: alignCenterRight,
              padding: textDirectionFactor == 1
                ? const EdgeInsets.only(right: _kPickerWidth / 4)
                : const EdgeInsets.only(left: _kPickerWidth / 4),
              child: new Container(
                alignment: alignCenterRight,
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: new Text(localizations.timerPickerMinute(minute)),
              ),
            ),
          );
        }
        else
          return new Semantics(
            label: semanticsLabel,
            child: new Container(
              alignment: alignCenterLeft,
              child: new Container(
                alignment: alignCenterRight,
                width: widget.mode == CupertinoTimerPickerMode.hm
                  ? _kPickerWidth / 10
                  : _kPickerWidth / 6,
                // Adds some spaces between words.
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: new Text(localizations.timerPickerMinute(minute)),
              ),
            ),
          );
      }),
    );
  }

  Widget _buildMinuteColumn() {
    Widget minuteLabel;

    if (widget.mode == CupertinoTimerPickerMode.hm) {
      minuteLabel = new IgnorePointer(
        child: new Container(
          alignment: alignCenterLeft,
          padding: textDirectionFactor == 1
            ? const EdgeInsets.only(left: _kPickerWidth / 10)
            : const EdgeInsets.only(right: _kPickerWidth / 10),
          child: new Container(
            alignment: alignCenterLeft,
            // Adds some spaces between words.
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildLabel(localizations.timerPickerMinuteLabel(selectedMinute)),
          ),
        ),
      );
    }
    else {
      minuteLabel = new IgnorePointer(
        child: new Container(
          alignment: alignCenterRight,
          child: new Container(
            alignment: alignCenterLeft,
            width: widget.mode == CupertinoTimerPickerMode.ms
              ? _kPickerWidth / 4
              : _kPickerWidth / 6,
            // Adds some spaces between words.
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildLabel(localizations.timerPickerMinuteLabel(selectedMinute)),
          ),
        ),
      );
    }

    return Stack(
      children: <Widget>[
        _buildMinutePicker(),
        minuteLabel,
      ],
    );
  }


  Widget _buildSecondPicker() {
    final double offAxisFraction = 0.5 * textDirectionFactor;

    final double secondPickerWidth =
      widget.mode == CupertinoTimerPickerMode.ms ? _kPickerWidth / 10 : _kPickerWidth / 6;

    return new CupertinoPicker(
      scrollController: new FixedExtentScrollController(
        initialItem: selectedSecond ~/ widget.secondInterval,
      ),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedSecond = index;
          widget.onTimerDurationChanged(
            new Duration(
              hours: selectedHour ?? 0,
              minutes: selectedMinute,
              seconds: selectedSecond));
        });
      },
      children: new List<Widget>.generate(60 ~/ widget.secondInterval, (int index) {
        final int second = index * widget.secondInterval;

        final String semanticsLabel = textDirectionFactor == 1
          ? localizations.timerPickerSecond(second) + localizations.timerPickerSecondLabel(second)
          : localizations.timerPickerSecondLabel(second) + localizations.timerPickerSecond(second);

        return new Semantics(
          label: semanticsLabel,
          child: new Container(
            alignment: alignCenterLeft,
            child: new Container(
              alignment: alignCenterRight,
              // Adds some spaces between words.
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              width: secondPickerWidth,
              child: new Text(localizations.timerPickerSecond(second)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSecondColumn() {
    final double secondPickerWidth =
      widget.mode == CupertinoTimerPickerMode.ms ? _kPickerWidth / 10 : _kPickerWidth / 6;

    final Widget secondLabel = new IgnorePointer(
      child: new Container(
        alignment: alignCenterLeft,
        padding: textDirectionFactor == 1
          ? new EdgeInsets.only(left: secondPickerWidth)
          : new EdgeInsets.only(right: secondPickerWidth),
        child: new Container(
          alignment: alignCenterLeft,
          // Adds some spaces between words.
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: _buildLabel(localizations.timerPickerSecondLabel(selectedSecond)),
        ),
      ),
    );
    return Stack(
      children: <Widget>[
        _buildSecondPicker(),
        secondLabel,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // The timer picker can be divided into columns corresponding to hour,
    // minute, and second. Each column consists of a scrollable and a fixed
    // label on top of it.

    Widget picker;

    if (widget.mode == CupertinoTimerPickerMode.hm) {
      picker = new Row(
        children: <Widget>[
          new Expanded(child: _buildHourColumn()),
          new Expanded(child: _buildMinuteColumn()),
        ],
      );
    }
    else if (widget.mode == CupertinoTimerPickerMode.ms) {
      picker = new Row(
        children: <Widget>[
          new Expanded(child: _buildMinuteColumn()),
          new Expanded(child: _buildSecondColumn()),
        ],
      );
    }
    else {
      picker = new Row(
        children: <Widget>[
          new Expanded(child: _buildHourColumn()),
          new Container(
            width: _kPickerWidth / 3,
            child: _buildMinuteColumn(),
          ),
          new Expanded(child: _buildSecondColumn()),
        ],
      );
    }

    return new MediaQuery(
      data: const MediaQueryData(
        // The native iOS picker's text scaling is fixed, so we will also fix it
        // as well in our picker.
        textScaleFactor: 1.0,
      ),
      child: picker,
    );
  }
}