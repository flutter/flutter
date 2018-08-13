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
const Color _kBackgroundColor = CupertinoColors.white;

/// Default values for auto scrolling.
///
///
/// There are cases where scrolling lands on invalid entries and the picker has
/// to automatically scrolls to a valid one.
const Duration _kAutoScrollDuration = Duration(milliseconds: 400);
const Curve _kAutoScrollCurveStyle = Curves.easeOut;


/// A countdown timer picker in iOS style.
///
/// This picker shows duration as hour and minute spinners. The minimum duration
/// of the picker is 1 minute and the maximum is 23 hours 59 minutes.
///
/// Example: [12 | 03]
class CupertinoCountdownTimerPicker extends StatefulWidget {
  /// Constructs an iOS style countdown timer picker.
  ///
  /// [onTimerDurationChanged] is the callback when the selected duration changes
  /// and must not be null.
  ///
  /// [initialTimerDuration] defaults to 1 minute and is limited from 1 minute
  /// to 23 hours 59 minutes. Only hour and minute values are extracted
  /// from [initialTimerDuration], so specifying other fields like day, second,
  /// etc. will not affect anything.
  ///
  /// [minuteInterval] is the granularity of the minute spinner. Must be a factor
  /// of 60.
  CupertinoCountdownTimerPicker({
    this.initialTimerDuration = const Duration(minutes: 1),
    this.minuteInterval = 1,
    @required this.onTimerDurationChanged,
  }) : assert(onTimerDurationChanged != null),
       assert(initialTimerDuration >= const Duration(minutes: 1)),
       assert(initialTimerDuration < const Duration(days: 1)),
       assert(60 % minuteInterval == 0);

  /// The initial duration of the countdown timer.
  final Duration initialTimerDuration;

  /// The granularity of the minute spinner. Must be a factor of 60.
  final int minuteInterval;

  /// Callback when the timer duration changes.
  final ValueChanged<Duration> onTimerDurationChanged;

  @override
  State<StatefulWidget> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CupertinoCountdownTimerPicker> {
  int _selectedHour;
  int _selectedMinute;

  FixedExtentScrollController hourController;
  FixedExtentScrollController minuteController;

  @override
  void initState() {
    super.initState();

    _selectedHour = widget.initialTimerDuration.inHours;
    _selectedMinute = widget.initialTimerDuration.inMinutes % 60;

    hourController = new FixedExtentScrollController(initialItem: _selectedHour);
    minuteController = new FixedExtentScrollController(
      initialItem: _selectedMinute ~/ widget.minuteInterval);
  }

  Widget _buildHourPicker(BuildContext context) {
    return new CupertinoPicker(
      scrollController: hourController,
      offAxisFraction: -0.15,
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
    return new CupertinoPicker(
      scrollController: minuteController,
      offAxisFraction: 0.5,
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
        final int toMinute = index * widget.minuteInterval;
        return new Container(
          alignment: Alignment.centerLeft,
          child: new Text(toMinute.toString().padLeft(2, '  ')),
        );
      }),
      looping: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // There are cases where scrolling lands on invalid entries. In such cases,
    // the picker automatically scrolls to a valid one.
    return new NotificationListener<ScrollEndNotification>(
      onNotification: (ScrollEndNotification notification) {
        // Invalid case where both hour and minute values are 0.
        if (_selectedMinute == 0 && _selectedHour == 0) {
          minuteController.animateToItem(
              minuteController.selectedItem + 1,
              duration: _kAutoScrollDuration,
              curve: _kAutoScrollCurveStyle);
        }
      },
      child: new Stack(
        children: <Widget>[
          new Row(
            children: <Widget>[
              new Expanded(child: _buildHourPicker(context)),
              new Expanded(child: _buildMinutePicker(context)),
            ],
          ),
          new Row(
            children: <Widget>[
              new Expanded(
                child: new Container(
                  alignment: const Alignment(0.6, 0.0),
                  child: const Text(
                    'hours',
                    style: TextStyle(fontWeight: FontWeight.w600),
                    textScaleFactor: 0.9,
                  ),
                ),
              ),
              new Expanded(
                child: new Container(
                  alignment: const Alignment(-0.6, 0.0),
                  child: const Text(
                    'min',
                    style: TextStyle(fontWeight: FontWeight.w600),
                    textScaleFactor: 0.9,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}