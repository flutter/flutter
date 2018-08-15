// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'picker.dart';

/// Default aesthetic values obtained by comparing with iOS pickers.
const bool _kUseMagnifier = true;
const double _kMagnification = 1.1;
const double _kItemExtent = 32.0;
/// Consider setting the default background color from the theme, in the future.
const Color _kBackgroundColor = CupertinoColors.white;


/// A countdown timer picker in iOS style.
///
/// This picker shows duration as hour, minute and second spinners. The duration
/// showed has to be non negative and is limited to 23 hours 59 minutes 59 seconds.
///
/// Example: [12 | 3 | 0]
class CupertinoCountdownTimerPicker extends StatefulWidget {
  /// Constructs an iOS style countdown timer picker.
  ///
  /// [onTimerDurationChanged] is the callback when the selected duration changes
  /// and must not be null.
  ///
  /// [initialTimerDuration] defaults to 0 second and is limited from 0 second
  /// to 23 hours 59 minutes. Only hour, minute, and second values are extracted
  /// from [initialTimerDuration], so specifying other fields like day or
  /// millisecond will not affect anything.
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
       assert(60 % minuteInterval == 0),
       assert(60 % secondInterval == 0);

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
  int _selectedHour;
  int _selectedMinute;
  int _selectedSecond;

  // Controllers for the 3 units: hour, minute, and second.
  FixedExtentScrollController hourController;
  FixedExtentScrollController minuteController;
  FixedExtentScrollController secondController;

  @override
  void initState() {
    super.initState();

    _selectedHour = widget.initialTimerDuration.inHours;
    _selectedMinute = widget.initialTimerDuration.inMinutes % 60;
    _selectedSecond = widget.initialTimerDuration.inSeconds % 60;

    hourController = new FixedExtentScrollController(initialItem: _selectedHour);
    minuteController = new FixedExtentScrollController(
      initialItem: _selectedMinute ~/ widget.minuteInterval);
    secondController = new FixedExtentScrollController(
      initialItem: _selectedSecond ~/ widget.secondInterval);
  }

  Widget _buildHourPicker(BuildContext context) {
    final int textDirectionFactor =
      Directionality.of(context) == TextDirection.ltr ? 1 : -1;

    return new CupertinoPicker(
      scrollController: hourController,
      offAxisFraction: -0.15 * textDirectionFactor,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          _selectedHour = index;
          widget.onTimerDurationChanged(
            new Duration(hours: _selectedHour, minutes: _selectedMinute));
        });
      },
      children: new List<Widget>.generate(24, (int index) {
        return new Container(
          alignment: Alignment.center,
          child: new Text(index.toString().padLeft(2, '  ')),
        );
      }),
    );
  }

  Widget _buildMinutePicker(BuildContext context) {
    final int textDirectionFactor =
      Directionality.of(context) == TextDirection.ltr ? 1 : -1;

    return new CupertinoPicker(
      scrollController: minuteController,
      offAxisFraction: 0.0 * textDirectionFactor,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          _selectedMinute = index * widget.minuteInterval;
          widget.onTimerDurationChanged(
              new Duration(hours: _selectedHour, minutes: _selectedMinute));
        });
      },
      children: new List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
        final int toMinutes = index * widget.minuteInterval;
        return new Container(
          alignment: Alignment.center,
//          alignment: new Alignment(-1.0 * textDirectionFactor, 0.0),
          child: new Text(toMinutes.toString().padLeft(2, '  ')),
        );
      }),
      looping: true,
    );
  }

  Widget _buildSecondPicker(BuildContext context) {
    final int textDirectionFactor =
      Directionality.of(context) == TextDirection.ltr ? 1 : -1;

    return new CupertinoPicker(
      scrollController: secondController,
      offAxisFraction: 0.3 * textDirectionFactor,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          _selectedMinute = index * widget.secondInterval;
          widget.onTimerDurationChanged(
              new Duration(hours: _selectedHour, minutes: _selectedMinute));
        });
      },
      children: new List<Widget>.generate(60 ~/ widget.secondInterval, (int index) {
        final int toSeconds = index * widget.secondInterval;
        return new Container(
          alignment: Alignment.center,
//          alignment: new Alignment(-1.0 * textDirectionFactor, 0.0),
          child: new Text(toSeconds.toString().padLeft(2, '  ')),
        );
      }),
      looping: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new MediaQuery(
      data: const MediaQueryData(
        // The iOS picker's text scaling is fixed, so we will also fix it in
        // our picker.
        textScaleFactor: 1.0,
      ),
      child: new Row(
        children: <Widget>[
          new Expanded(
            child: new MergeSemantics(
              child: _buildHourPicker(context),
            ),
          ),
          new Expanded(
            child: new MergeSemantics(
              child: _buildMinutePicker(context),
            ),
          ),
          new Expanded(
            child: new MergeSemantics(
              child: _buildSecondPicker(context),
            ),
          ),
        ],
      ),
    );
  }
}