// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'cupertino_localizations.dart';
import 'picker.dart';

/// Default aesthetic values obtained by comparing with iOS pickers.
const double _kItemExtent = 32.0;
const double _kPickerWidth = 330.0;
/// Considers setting the default background color from the theme, in the future.
const Color _kBackgroundColor = CupertinoColors.white;


/// The iOS date picker has its width fixed to [_kPickerWidth] in all modes.
/// If the maximum width given to the picker is greater than [_kPickerWidth],
/// the leftmost and rightmost column will be extended equally so that the
/// widths matched, and the picker is in the center.
/// If the maximum width given to the picker is smaller than [_kPickerWidth],
/// the picker's layout will be broken.

/// Builds a single column for the picker. The align and padding parameters
/// are properties of this column, and childWidth, childAlign, childPadding
/// are properties of its child.
///
/// This general column builder is sufficient to build all kinds of column
/// of the iOS picker.
Widget _buildColumn(
  Alignment align,
  EdgeInsets padding,
  Widget child,
  double childWidth,
  Alignment childAlign,
  EdgeInsets childPadding,
  ) {
  return new IgnorePointer(
    child: Container(
      alignment: align,
      padding: padding,
      child: new Container(
        width: childWidth,
        alignment: childAlign,
        padding: childPadding,
        child: child,
      ),
    ),
  );
}


/// A countdown timer picker in iOS style.
///
/// This picker shows duration as hour, minute and second spinners. The duration
/// showed has to be non negative and is limited to 23 hours 59 minutes 59 seconds.
///
/// Example: [12 hours |  3 min |  0 sec]
class CupertinoCountdownTimerPicker extends StatefulWidget {
  /// Constructs an iOS style countdown timer picker.
  ///
  /// [onTimerDurationChanged] is the callback when the selected duration changes
  /// and must not be null.
  ///
  /// [initialTimerDuration] defaults to 0 second and is limited from 0 second
  /// to 23 hours 59 minutes 59 seconds. Only hour, minute, and second values
  /// are extracted from [initialTimerDuration], so specifying other fields like
  /// millisecond or microsecond will not affect anything.
  ///
  /// [minuteInterval] is the granularity of the minute spinner. Must be a factor
  /// of 60.
  ///
  /// [secondInterval] is the granularity of the second spinner. Must be a factor
  /// of 60.
  CupertinoCountdownTimerPicker({
    this.initialTimerDuration = const Duration(),
    this.minuteInterval = 1,
    this.secondInterval = 1,
    @required this.onTimerDurationChanged,
  }) : assert(onTimerDurationChanged != null),
       assert(initialTimerDuration >= const Duration(seconds: 0)),
       assert(initialTimerDuration < const Duration(days: 1)),
       assert(minuteInterval > 0 && 60 % minuteInterval == 0),
       assert(secondInterval > 0 && 60 % secondInterval == 0);

  /// The initial duration of the countdown timer.
  final Duration initialTimerDuration;

  /// The granularity of the minute spinner. Must be a factor of 60.
  final int minuteInterval;

  /// The granularity of the second spinner. Must be a factor of 60.
  final int secondInterval;

  /// Callback when the timer duration changes.
  final ValueChanged<Duration> onTimerDurationChanged;

  @override
  State<StatefulWidget> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CupertinoCountdownTimerPicker> {
  // The currently selected values of the picker.
  int selectedHour;
  int selectedMinute;
  int selectedSecond;

  // Controllers for the 3 units: hour, minute, and second.
  FixedExtentScrollController hourController;
  FixedExtentScrollController minuteController;
  FixedExtentScrollController secondController;

  @override
  void initState() {
    super.initState();

    selectedHour = widget.initialTimerDuration.inHours;
    selectedMinute = widget.initialTimerDuration.inMinutes % 60;
    selectedSecond = widget.initialTimerDuration.inSeconds % 60;

    hourController = new FixedExtentScrollController(initialItem: selectedHour);
    minuteController = new FixedExtentScrollController(
      initialItem: selectedMinute ~/ widget.minuteInterval);
    secondController = new FixedExtentScrollController(
      initialItem: selectedSecond ~/ widget.secondInterval);
  }

  // Builds a text label with custom scale factor and font weight.
  Widget textLabel(String text) {
    return new Text(
      text,
      textScaleFactor: 0.8,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  Widget buildHourPicker(BuildContext context) {
    final int textDirectionFactor =
      Directionality.of(context) == TextDirection.ltr ? 1 : -1;

    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);

    return new Semantics(
      child: new Stack(
        children: <Widget>[
          CupertinoPicker(
            scrollController: hourController,
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
                        seconds: selectedSecond));
              });
            },
            children: new List<Widget>.generate(24, (int index) {
              return _buildColumn(
                Alignment(1.0 * textDirectionFactor, 0.0),
                textDirectionFactor == 1
                  ? const EdgeInsets.only(right: _kPickerWidth / 6)
                  : const EdgeInsets.only(left: _kPickerWidth / 6),
                new Text(localizations.number(index)),
                _kPickerWidth / 6,
                Alignment(1.0 * textDirectionFactor, 0.0),
                const EdgeInsets.symmetric(horizontal: 2.0),
              );
            }),
          ),
          _buildColumn(
            Alignment(1.0 * textDirectionFactor, 0.0),
            null,
            textLabel(localizations.hourLabel),
            _kPickerWidth / 6,
            Alignment(-1.0 * textDirectionFactor, 0.0),
            const EdgeInsets.symmetric(horizontal: 2.0),
          ),
        ],
      ),
    );
  }

  Widget buildMinutePicker(BuildContext context) {
    final int textDirectionFactor =
      Directionality.of(context) == TextDirection.ltr ? 1 : -1;

    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);

    return new Semantics(
      child: new Stack(
        children: <Widget>[
          new CupertinoPicker(
            scrollController: minuteController,
            offAxisFraction: 0.0 * textDirectionFactor,
            itemExtent: _kItemExtent,
            backgroundColor: _kBackgroundColor,
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedMinute = index;
                widget.onTimerDurationChanged(
                    new Duration(
                        hours: selectedHour,
                        minutes: selectedMinute,
                        seconds: selectedSecond));
              });
            },
            children: new List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
              int minutes = index * widget.minuteInterval;
              return _buildColumn(
                Alignment(-1.0 * textDirectionFactor, 0.0),
                null,
                new Text(localizations.number(minutes)),
                _kPickerWidth / 6,
                Alignment(1.0 * textDirectionFactor, 0.0),
                const EdgeInsets.symmetric(horizontal: 2.0),
              );
            }),
          ),
          _buildColumn(
            Alignment(1.0 * textDirectionFactor, 0.0),
            null,
            textLabel(localizations.minuteLabel),
            _kPickerWidth / 6,
            Alignment(-1.0 * textDirectionFactor, 0.0),
            const EdgeInsets.symmetric(horizontal: 2.0),
          ),
        ],
      ),
    );
  }

  Widget buildSecondPicker(BuildContext context) {
    final int textDirectionFactor =
      Directionality.of(context) == TextDirection.ltr ? 1 : -1;

    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);

    return new Semantics(
      child: new Stack(
        children: <Widget>[
          new CupertinoPicker(
            scrollController: secondController,
            offAxisFraction: 0.5 * textDirectionFactor,
            itemExtent: _kItemExtent,
            backgroundColor: _kBackgroundColor,
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedSecond = index;
                widget.onTimerDurationChanged(
                    new Duration(
                        hours: selectedHour,
                        minutes: selectedMinute,
                        seconds: selectedSecond));
              });
            },
            children: new List<Widget>.generate(60 ~/ widget.secondInterval, (int index) {
              int seconds = index * widget.secondInterval;
              return _buildColumn(
                Alignment(-1.0 * textDirectionFactor, 0.0),
                null,
                new Text(localizations.number(seconds)),
                _kPickerWidth / 6,
                Alignment(1.0 * textDirectionFactor, 0.0),
                const EdgeInsets.symmetric(horizontal: 2.0),
              );
            }),
          ),

          _buildColumn(
            Alignment(-1.0 * textDirectionFactor, 0.0),
            textDirectionFactor == 1
              ? const EdgeInsets.only(left: _kPickerWidth / 6)
              : const EdgeInsets.only(right: _kPickerWidth / 6),
            textLabel(localizations.secondLabel),
            _kPickerWidth / 6,
            Alignment(-1.0 * textDirectionFactor, 0.0),
            const EdgeInsets.symmetric(horizontal: 2.0),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(CupertinoLocalizations.of(context) != null, 'No cupertino localization is found.');

    return new MediaQuery(
      data: const MediaQueryData(
        // The iOS picker's text scaling is fixed, so we will also fix it in
        // our picker.
        textScaleFactor: 1.0,
      ),
      child: new Row(
        children: <Widget>[
          new Expanded(child: buildHourPicker(context)),
          new Container(
            width: _kPickerWidth / 3,
            child: buildMinutePicker(context),
          ),
          new Expanded(child: buildSecondPicker(context)),
        ],
      ),
    );
  }
}