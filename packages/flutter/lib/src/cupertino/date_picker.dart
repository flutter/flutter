// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'picker.dart';

/// Default aesthetic values obtained by comparing with iOS pickers.
const double _kItemExtent = 28.0;
const double _kPickerWidth = 330.0;
/// Considers setting the default background color from the theme, in the future.
const Color _kBackgroundColor = CupertinoColors.white;


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
  /// day or millisecond will not affect anything.
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
  
  // The picker can be seen as 3 single-value pickers: hour, minute, and second.
  // Each single-value picker itself has 2 columns, one containing the value and
  // the other one containing the label.
  //
  // Example: [12 | hours | 3 | min | 0 | sec]
  //
  // We want the picker to look the same even if the max width given to it varies.
  // To do so, we set a constant width for the picker, and that width will be
  // divided equally to the 6 columns above. When the given max width is bigger,
  // the leftmost and rightmost column can be extended to match the maximum width.
  // If the max width given to it is smaller than the one we set, the picker's
  // layout will be broken.


  // Builds a text label with custom scale factor and font weight.
  Widget _textLabel(String text) {
    return new Text(
      text,
      textScaleFactor: 0.8,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  // Builds a column with fixed width of PickerWidth / 6. The align parameter 
  // describes how this column is aligned inside its parent.
  Widget _fixedColumn(Widget child, Alignment align) {
    return new IgnorePointer(
      child: Align(
        alignment: align,
        child: Container(
          width: _kPickerWidth / 6,
          child: new Container(
            alignment: -align,
            // A little space between words to look better.
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: child,
          ),
        ),
      ),
    );
  }

  // Builds an extendable column. The padding parameter describes how this 
  // column is padded inside its parent, and the align parameter describes how
  // this column's child is aligned.
  Widget _extendableColumn(Widget child, Alignment align, EdgeInsets padding) {
    return new IgnorePointer(
      child: Padding(
        padding: padding,
        child: new Container(
          // decoration: BoxDecoration(border: Border.all()),
          alignment: align,
          // A little space between words to look better.
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHourPicker(BuildContext context) {
    final int textDirectionFactor =
      Directionality.of(context) == TextDirection.ltr ? 1 : -1;

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
                _selectedHour = index;
                widget.onTimerDurationChanged(
                    new Duration(
                        hours: _selectedHour,
                        minutes: _selectedMinute,
                        seconds: _selectedSecond));
              });
            },
            children: new List<Widget>.generate(24, (int index) {
              return _extendableColumn(
                Text(index.toString()), // Needs l10n when possible.
                Alignment(1.0 * textDirectionFactor, 0.0),
                textDirectionFactor == 1 ? const EdgeInsets.only(right: _kPickerWidth / 6)
                                         : const EdgeInsets.only(left: _kPickerWidth / 6),
              );
            }),
          ),
          _fixedColumn(
            _textLabel('hours'), // Needs l10n when possible.
            Alignment(1.0 * textDirectionFactor, 0.0),
          ),
        ],
      ),
    );
  }

  Widget _buildMinutePicker(BuildContext context) {
    final int textDirectionFactor =
      Directionality.of(context) == TextDirection.ltr ? 1 : -1;

    return new Semantics(
      onScrollUp: () {
        minuteController.jumpToItem(minuteController.selectedItem + 1);
      },
      onScrollDown: () {
        minuteController.jumpToItem(minuteController.selectedItem - 1);
      },
      child: new Stack(
        children: <Widget>[
          new CupertinoPicker(
            scrollController: minuteController,
            offAxisFraction: 0.0 * textDirectionFactor,
            itemExtent: _kItemExtent,
            backgroundColor: _kBackgroundColor,
            onSelectedItemChanged: (int index) {
              setState(() {
                _selectedMinute = index;
                widget.onTimerDurationChanged(
                    new Duration(
                        hours: _selectedHour,
                        minutes: _selectedMinute,
                        seconds: _selectedSecond));
              });
            },
            children: new List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
              int minutes = index * widget.minuteInterval;
              return _fixedColumn(
                new Text(minutes.toString()), // Needs l10n when possible.
                Alignment(-1.0 * textDirectionFactor, 0.0),
              );
            }),
          ),
          _fixedColumn(
            _textLabel('min'), // Needs l10n when possible.
            Alignment(1.0 * textDirectionFactor, 0.0),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondPicker(BuildContext context) {
    final int textDirectionFactor =
    Directionality.of(context) == TextDirection.ltr ? 1 : -1;

    return new Semantics(
      onScrollUp: () {
        secondController.jumpToItem(secondController.selectedItem + 1);
      },
      onScrollDown: () {
        secondController.jumpToItem(secondController.selectedItem - 1);
      },
      child: new Stack(
        children: <Widget>[
          new CupertinoPicker(
            scrollController: secondController,
            offAxisFraction: 0.5 * textDirectionFactor,
            itemExtent: _kItemExtent,
            backgroundColor: _kBackgroundColor,
            onSelectedItemChanged: (int index) {
              setState(() {
                _selectedSecond = index;
                widget.onTimerDurationChanged(
                    new Duration(
                        hours: _selectedHour,
                        minutes: _selectedMinute,
                        seconds: _selectedSecond));
              });
            },
            children: new List<Widget>.generate(60 ~/ widget.secondInterval, (int index) {
              int seconds = index * widget.secondInterval;
              return _fixedColumn(
                new Text(seconds.toString()), // Needs l10n when possible.
                Alignment(-1.0 * textDirectionFactor, 0.0),
              );
            }),
          ),

          _extendableColumn(
            _textLabel('sec'), // Needs l10n when possible.
            Alignment(-1.0 * textDirectionFactor, 0.0),
            textDirectionFactor == 1 ? const EdgeInsets.only(left: _kPickerWidth / 6)
                                     : const EdgeInsets.only(right: _kPickerWidth / 6),
          ),
        ],
      ),
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
          new Expanded(child: _buildHourPicker(context)),
          new Container(
            width: _kPickerWidth / 3,
            child: _buildMinutePicker(context),
          ),
          new Expanded(child: _buildSecondPicker(context)),
        ],
      ),
    );
  }
}