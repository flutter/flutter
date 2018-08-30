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
const bool _kUseMagnifier = false;
const double _kMagnification = 1.0;
const double _kDatePickerPadSize = 18.0;
/// Considers setting the default background color from the theme, in the future.
const Color _kBackgroundColor = CupertinoColors.white;

// Lays out the date picker based on how much space each single column needs.
//
// Each column will be padded horizontally by 18.0 both left and right.
//
// The picker will be placed in the center, and the leftmost and rightmost
// column will be extended equally to the remaining width.
class _DatePickerLayout extends MultiChildLayoutDelegate {
  _DatePickerLayout({
    @required this.columnWidth,
    @required this.textDirectionFactor,
  }) : assert(columnWidth != null),
       assert(textDirectionFactor != null);

  // The list containing widths of all columns.
  final List<double> columnWidth;

  // textDirectionFactor is 1 if text is written left to right, and -1 if right to left.
  final int textDirectionFactor;

  @override
  void performLayout(Size size) {
    double remainingWidth = size.width;

    for (int i = 0; i < columnWidth.length; i++)
      remainingWidth -= columnWidth[i] + _kDatePickerPadSize * 2;

    double currentHorizontalOffset = 0.0;

    for (int i = 0; i < columnWidth.length; i++) {
      final int index = textDirectionFactor == 1 ? i : columnWidth.length - i - 1;

      double childWidth = columnWidth[index] + _kDatePickerPadSize * 2;
      if (index == 0 || index == columnWidth.length - 1)
        childWidth += remainingWidth / 2;

      layoutChild(index, BoxConstraints.tight(new Size(childWidth, size.height)));
      positionChild(index, new Offset(currentHorizontalOffset, 0.0));

      currentHorizontalOffset += childWidth;
    }
  }

  @override
  bool shouldRelayout(_DatePickerLayout oldDelegate) {
    return columnWidth != oldDelegate.columnWidth
      || textDirectionFactor != oldDelegate.textDirectionFactor;
  }
}

/// Different modes of [CupertinoDatePicker].
enum CupertinoDatePickerMode {
  /// Mode that shows the date in hour, minute, and (optional) an AM/PM designation.
  ///
  /// Example: [4 | 14 | PM].
  time,
  /// Mode that shows the date in month, day of month, and year.
  ///
  /// Example: [July | 13 | 2012].
  date,
  /// Mode that shows the date as day of the week, month, day of month and
  /// the time in hour, minute, and (optional) an AM/PM designation.
  ///
  /// Example: [Fri Jul 13 | 4 | 14 | PM]
  dateAndTime,
}

/// A date picker widget in iOS style.
///
/// There are several modes of the date picker listed in [CupertinoDatePickerMode].
class CupertinoDatePicker extends StatefulWidget {
  /// Constructs an iOS style date picker.
  ///
  /// [mode] is one of the mode listed in [CupertinoDatePickerMode] and defaults
  /// to [CupertinoDatePickerMode.dateAndTime].
  ///
  /// [onDateTimeChanged] is the callback when the selected date or time changes
  /// and must not be null.
  ///
  /// [initialDateTime] is the initial value of the picker. Must not be null.
  ///
  /// [minimumDate] is the minimum date that the picker can be scrolled to in
  /// [CupertinoDatePickerMode.dateAndTime] mode. Null if there's no limit.
  ///
  /// [maximumDate] is the maximum date that the picker can be scrolled to in
  /// [CupertinoDatePickerMode.dateAndTime] mode. Null if there's no limit.
  ///
  /// [minimumYear] is the minimum year that the picker can be scrolled to in
  /// [CupertinoDatePickerMode.date] mode. Defaults to 1 and must not be null.
  ///
  /// [maximumYear] is the maximum year that the picker can be scrolled to in
  /// [CupertinoDatePickerMode.date] mode. Null if there's no limit.
  ///
  /// [minuteInterval] is the granularity of the minute spinner. Must be a
  /// positive integer factor of 60.
  ///
  /// [use24hFormat] decides whether 24 hour format is used. Defaults to false.
  CupertinoDatePicker({
    this.mode = CupertinoDatePickerMode.dateAndTime,
    @required this.onDateTimeChanged,
    @required this.initialDateTime,
    this.minimumDate,
    this.maximumDate,
    this.minimumYear = 1,
    this.maximumYear,
    this.minuteInterval = 1,
    this.use24hFormat = false,
  }) : assert(mode != null),
       assert(onDateTimeChanged != null),
       assert(initialDateTime != null),
       assert(mode != CupertinoDatePickerMode.dateAndTime || minimumDate == null || !initialDateTime.isBefore(minimumDate)),
       assert(mode != CupertinoDatePickerMode.dateAndTime || maximumDate == null || !initialDateTime.isAfter(maximumDate)),
       assert(minimumYear != null),
       assert(mode != CupertinoDatePickerMode.date || (minimumYear >= 1 && initialDateTime.year >= minimumYear)),
       assert(mode != CupertinoDatePickerMode.date || maximumYear == null || initialDateTime.year <= maximumYear),
       assert(minuteInterval > 0 && 60 % minuteInterval == 0),
       assert(initialDateTime.minute % minuteInterval == 0);

  /// The mode of the date picker.
  final CupertinoDatePickerMode mode;

  /// The initial date and/or time of the picker.
  final DateTime initialDateTime;

  /// Minimum date that the picker can be scrolled to in
  /// [CupertinoDatePickerMode.dateAndTime] mode. Null if there's no limit.
  final DateTime minimumDate;

  /// Maximum date that the picker can be scrolled to in
  /// [CupertinoDatePickerMode.dateAndTime] mode. Null if there's no limit.
  final DateTime maximumDate;

  /// Minimum year that the picker can be scrolled to in
  /// [CupertinoDatePickerMode.date] mode. Defaults to 1 and must not be null.
  final int minimumYear;

  /// Maximum year that the picker can be scrolled to in
  /// [CupertinoDatePickerMode.date] mode. Null if there's no limit.
  final int maximumYear;

  /// The granularity of the minutes spinner, if it is shown in the current mode.
  ///  Must be a factor of 60.
  final int minuteInterval;

  /// Whether to use 24 hour format.
  final bool use24hFormat;

  /// Callback when the selected date and/or time changes.
  final ValueChanged<DateTime> onDateTimeChanged;

  @override
  State<StatefulWidget> createState() {
    if (mode == CupertinoDatePickerMode.time || mode ==CupertinoDatePickerMode.dateAndTime)
      return new _CupertinoDatePickerDateTimeState();
    else
      return new _CupertinoDatePickerDateState();
  }
}

class _CupertinoDatePickerDateTimeState extends State<CupertinoDatePicker> {
  int textDirectionFactor;
  CupertinoLocalizations localizations;

  // Alignment based on text direction. The variable name is self descriptive,
  // however, when text direction is rtl, alignment is reversed.
  Alignment alignCenterLeft;
  Alignment alignCenterRight;

  // The currently selected values of the date picker.
  int selectedDayDifference;
  int selectedHour;
  int selectedMinute;
  int selectedAmPm;

  // The controller of the AM/PM column.
  FixedExtentScrollController amPmController;

  @override
  void initState() {
    super.initState();
    selectedDayDifference = 0;
    selectedHour = widget.initialDateTime.hour;
    selectedMinute = widget.initialDateTime.minute;
    selectedAmPm = 0;

    if (!widget.use24hFormat) {
      selectedAmPm = selectedHour ~/ 12;
      selectedHour = selectedHour % 12;
      if (selectedHour == 0)
        selectedHour = 12;

      amPmController = new FixedExtentScrollController(initialItem: selectedAmPm);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context) ?? const DefaultCupertinoLocalizations();

    alignCenterLeft = textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight = textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;
  }

  // Gets the current date time of the picker.
  DateTime _getDateTime() {
    final DateTime date = new DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
    ).add(Duration(days: selectedDayDifference));

    return new DateTime(
      date.year,
      date.month,
      date.day,
      selectedHour + selectedAmPm * 12,
      selectedMinute,
    );
  }

  Widget _buildMediumDatePicker(double offAxisFraction, Function childPositioning) {
    return new CupertinoPicker.builder(
      scrollController: new FixedExtentScrollController(initialItem: selectedDayDifference),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        selectedDayDifference = index;
        widget.onDateTimeChanged(_getDateTime());
      },
      itemBuilder: (BuildContext context, int index) {
        final DateTime dateTime = new DateTime(
          widget.initialDateTime.year,
          widget.initialDateTime.month,
          widget.initialDateTime.day,
        ).add(Duration(days: index));

        if (widget.minimumDate != null && dateTime.isBefore(widget.minimumDate))
          return null;
        if (widget.maximumDate != null && dateTime.isAfter(widget.maximumDate))
          return null;

        return childPositioning(Text(localizations.datePickerMediumDate(dateTime)));
      },
    );
  }

  Widget _buildHourPicker(double offAxisFraction, Function childPositioning) {
    return new CupertinoPicker(
      scrollController: new FixedExtentScrollController(initialItem: selectedHour),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        if (widget.use24hFormat) {
          selectedHour = index;
          widget.onDateTimeChanged(_getDateTime());
        }
        else {
          // Automatically scrolls the am/pm column if condition is met.
          if(selectedHour == 0 && index == 11 || selectedHour == 11 && index == 0) {
            selectedHour = index;
            amPmController.animateToItem(
              1 - amPmController.selectedItem,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut);
          }
          else {
            selectedHour = index;
            widget.onDateTimeChanged(_getDateTime());
          }
        }
      },
      children: new List<Widget>.generate(24, (int index) {
        int hour = index;
        if (!widget.use24hFormat)
          hour = hour % 12 == 0 ? 12 : hour % 12;

        return childPositioning(Text(
          localizations.datePickerHour(hour),
          semanticsLabel: localizations.datePickerHourSemanticsLabel(hour),
        ));
      }),
      looping: true,
    );
  }

  Widget _buildMinutePicker(double offAxisFraction, Function childPositioning) {
    return new CupertinoPicker(
      scrollController: new FixedExtentScrollController(initialItem: selectedMinute),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        selectedMinute = index * widget.minuteInterval;
        widget.onDateTimeChanged(_getDateTime());
      },
      children: new List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
        final int minute = index * widget.minuteInterval;
        return childPositioning(Text(
          localizations.datePickerMinute(minute),
          semanticsLabel: localizations.datePickerMinuteSemanticsLabel(minute),
        ));
      }),
      looping: true,
    );
  }

  Widget _buildAmPmPicker(double offAxisFraction, Function childPositioning) {
    return new CupertinoPicker(
      scrollController: amPmController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        selectedAmPm = index;
        widget.onDateTimeChanged(_getDateTime());
      },
      children: new List<Widget>.generate(2, (int index) {
        return childPositioning(Text(
          index == 0
            ? localizations.anteMeridiemAbbreviation
            : localizations.postMeridiemAbbreviation
        ));
      }),
    );
  }

  // Estimate the minimum width that each column needs to layout its content.
  // columnType is one of 'd', 'h', 'm', 'a', which stands for date column,
  // hour column, minute column, am/pm column, respectively.
  double _getPickerWidth(String columnType) {
    String longestText = '';

    if (columnType == 'd') {
      // Measuring the length of all possible date is very costly, so here
      // just some dates are measured.
      for (int i = 1; i <= 12; i++) {
        final DateTime date = new DateTime(widget.initialDateTime.year, i, 16);
        if (longestText.length < localizations.datePickerMediumDate(date).length)
          longestText = localizations.datePickerMediumDate(date);
      }
    }
    else if (columnType == 'h') {
      for(int i = 0 ; i < 24; i++)
        if (longestText.length < localizations.datePickerHour(i).length)
          longestText = localizations.datePickerHour(i);
    }
    else if (columnType == 'm') {
      for(int i = 0 ; i < 60; i++)
        if (longestText.length < localizations.datePickerMinute(i).length)
          longestText = localizations.datePickerMinute(i);
    }
    else
      longestText =
        localizations.anteMeridiemAbbreviation.length > localizations.postMeridiemAbbreviation.length
        ? localizations.anteMeridiemAbbreviation
        : localizations.postMeridiemAbbreviation;

    final TextPainter painter = new TextPainter(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        text: longestText,
      ),
      textDirection: Directionality.of(context),
    );
    painter.layout();

    return painter.maxIntrinsicWidth;
  }

  @override
  Widget build(BuildContext context) {
    // Widths of the columns in this picker, ordered from left to right.
    final List<double> columnWidth = <double>[
      _getPickerWidth('h'),
      _getPickerWidth('m'),
    ];
    final List<Function> pickerBuilder = <Function>[
      _buildHourPicker,
      _buildMinutePicker,
    ];

    // Adds am/pm column if the picker is not using 24h format.
    if (!widget.use24hFormat) {
      if (localizations.datePickerTimeOrder == DatePickerTimeOrder.hma) {
        pickerBuilder.add(_buildAmPmPicker);
        columnWidth.add(_getPickerWidth('a'));
      }
      else {
        pickerBuilder.insert(0, _buildAmPmPicker);
        columnWidth.insert(0, _getPickerWidth('a'));
      }
    }

    // Adds medium date column if the picker's mode is date and time.
    if (widget.mode == CupertinoDatePickerMode.dateAndTime) {
      pickerBuilder.insert(0, _buildMediumDatePicker);
      columnWidth.insert(0, _getPickerWidth('d'));
    }

    final List<Widget> children = <Widget>[];

    for (int i = 0; i < columnWidth.length; i++) {
      double offAxisFraction = 0.0;
      if (i == 0)
        offAxisFraction = -0.5 * textDirectionFactor;
      else if (i >= 2 || columnWidth.length == 2)
        offAxisFraction = 0.5 * textDirectionFactor;

      EdgeInsets padding = const EdgeInsets.only(right: _kDatePickerPadSize);
      if (textDirectionFactor == -1)
        padding = const EdgeInsets.only(left: _kDatePickerPadSize);

      children.add(LayoutId(
        id: i,
        child: pickerBuilder[i](
          offAxisFraction,
          (Widget child) {
            return new Container(
              alignment: i == columnWidth.length - 1
                ? alignCenterLeft
                : alignCenterRight,
              padding: padding,
              child: new Container(
                alignment: alignCenterRight,
                width: columnWidth[i] + _kDatePickerPadSize,
                child: child,
              ),
            );
          },
        ),
      ));
    }

    return new MediaQuery(
      data: const MediaQueryData(textScaleFactor: 1.0),
      child: new CustomMultiChildLayout(
        delegate: new _DatePickerLayout(
          columnWidth: columnWidth,
          textDirectionFactor: textDirectionFactor,
        ),
        children: children,
      ),
    );
  }
}

class _CupertinoDatePickerDateState extends State<CupertinoDatePicker> {
  int textDirectionFactor;
  CupertinoLocalizations localizations;

  // Alignment based on text direction. The variable name is self descriptive,
  // however, when text direction is rtl, alignment is reversed.
  Alignment alignCenterLeft;
  Alignment alignCenterRight;

  // The currently selected values of the picker.
  int selectedDay;
  int selectedMonth;
  int selectedYear;

  // The controller of the day picker. There are cases where the selected value
  // of the picker is invalid (e.g. February 30th 2018), and this dayController
  // is responsible for jumping to a valid value.
  FixedExtentScrollController dayController;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.initialDateTime.day;
    selectedMonth = widget.initialDateTime.month;
    selectedYear = widget.initialDateTime.year;

    dayController = new FixedExtentScrollController(initialItem: selectedDay - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context) ?? const DefaultCupertinoLocalizations();

    alignCenterLeft = textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight = textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;
  }

  Widget _buildDayPicker(double offAxisFraction, Function childPositioning) {
    return new CupertinoPicker(
      scrollController: dayController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedDay = index + 1;
          if (new DateTime(selectedYear, selectedMonth, selectedDay).day == selectedDay)
            widget.onDateTimeChanged(new DateTime(selectedYear, selectedMonth, selectedDay));
        });
      },
      children: new List<Widget>.generate(31, (int index) {
        return childPositioning(Text(localizations.datePickerDayOfMonth(index + 1)));
      }),
      looping: true,
    );
  }

  Widget _buildMonthPicker(double offAxisFraction, Function childPositioning) {
    return new CupertinoPicker(
      scrollController: new FixedExtentScrollController(initialItem: selectedMonth - 1),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedMonth = index + 1;
          if (new DateTime(selectedYear, selectedMonth, selectedDay).day == selectedDay)
            widget.onDateTimeChanged(new DateTime(selectedYear, selectedMonth, selectedDay));
        });
      },
      children: new List<Widget>.generate(12, (int index) {
        return childPositioning(Text(localizations.datePickerMonth(index + 1)));
      }),
      looping: true,
    );
  }

  Widget _buildYearPicker(double offAxisFraction, Function childPositioning) {
    return new CupertinoPicker.builder(
      scrollController: new FixedExtentScrollController(initialItem: selectedYear),
      itemExtent: _kItemExtent,
      offAxisFraction: offAxisFraction,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedYear = index;
          if (new DateTime(selectedYear, selectedMonth, selectedDay).day == selectedDay)
            widget.onDateTimeChanged(new DateTime(selectedYear, selectedMonth, selectedDay));
        });
      },
      itemBuilder: (BuildContext context, int index) {
        if (index < widget.minimumYear)
          return null;

        if (widget.maximumYear != null && index > widget.maximumYear)
          return null;

        return childPositioning(Text(localizations.datePickerYear(index)));
      },
    );
  }

  // Estimate the minimum width that each column needs to layout its content.
  // columnType is one of 'D', 'M', 'Y', which stands for day column,
  // month column, year column, respectively.
  double _getPickerWidth(String columnType) {
    String longestText = '';

    if (columnType == 'D') {
      for(int i = 1 ; i <=31; i++)
        if (longestText.length < localizations.datePickerDayOfMonth(i).length)
          longestText = localizations.datePickerDayOfMonth(i);
    }
    else if (columnType == 'M') {
      for(int i = 1 ; i <=12; i++)
        if (longestText.length < localizations.datePickerMonth(i).length)
          longestText = localizations.datePickerMonth(i);
    }
    else
      longestText = localizations.datePickerYear(2018);

    final TextPainter painter = new TextPainter(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        text: longestText,
      ),
      textDirection: Directionality.of(context),
    );
    painter.layout();

    return painter.maxIntrinsicWidth;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Function> pickerBuilder = <String, Function>{
      'D' : _buildDayPicker,
      'M' : _buildMonthPicker,
      'Y' : _buildYearPicker,
    };

    final List<double> columnWidth = <double>[
      _getPickerWidth(localizations.datePickerDateOrder[0]),
      _getPickerWidth(localizations.datePickerDateOrder[1]),
      _getPickerWidth(localizations.datePickerDateOrder[2]),
    ];

    return new MediaQuery(
      data: const MediaQueryData(textScaleFactor: 1.0),
      child: new NotificationListener<ScrollEndNotification>(
        onNotification: (ScrollEndNotification notification) {
          // Whenever scrolling lands on an invalid entry, the picker
          // automatically scrolls to a valid one.
          if (new DateTime(selectedYear, selectedMonth, selectedDay).day != selectedDay) {
            // dayController.jumpToItem() won't work here, at least for now,
            // because jumpToItem() calls to goIdle(), which will trigger a
            // ScrollEndNotification at the same scroll position and therefore
            // leads to an infinite loop.
            // Animates at super speed is used instead.
            dayController.animateToItem(
              dayController.selectedItem - 1,
              duration: const Duration(milliseconds: 1),
              curve: Curves.linear);
          }
        },
        child: new CustomMultiChildLayout(
          delegate: new _DatePickerLayout(
            columnWidth: columnWidth,
            textDirectionFactor: textDirectionFactor,
          ),
          children: <Widget>[
            new LayoutId(
              id: 0,
              child: pickerBuilder[localizations.datePickerDateOrder[0]](
                -0.5 * textDirectionFactor,
                (Widget child) {
                  return new Container(
                    alignment: alignCenterRight,
                    child: new Container(
                      alignment: alignCenterLeft,
                      width: columnWidth[0] + _kDatePickerPadSize,
                      child: child,
                    ),
                  );
                }
              ),
            ),
            new LayoutId(
              id: 1,
              child: pickerBuilder[localizations.datePickerDateOrder[1]](
                  0.0,
                  (Widget child) {
                    return new Container(
                      alignment: alignCenterLeft,
                      child: new Container(
                        alignment: alignCenterRight,
                        width: columnWidth[1] + _kDatePickerPadSize,
                        child: child,
                      ),
                    );
                  }
              ),
            ),
            new LayoutId(
              id: 2,
              child: pickerBuilder[localizations.datePickerDateOrder[2]](
                0.5 * textDirectionFactor,
                (Widget child) {
                  return new Container(
                    alignment: alignCenterLeft,
                    child: new Container(
                      alignment: alignCenterRight,
                      width: columnWidth[2] + _kDatePickerPadSize,
                      child: child,
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}


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
  State<StatefulWidget> createState() => _CupertinoTimerPickerState();
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
    return Text(
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
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: selectedHour),
      offAxisFraction: -0.5 * textDirectionFactor,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedHour = index;
          widget.onTimerDurationChanged(
            Duration(
              hours: selectedHour,
              minutes: selectedMinute,
              seconds: selectedSecond ?? 0));
        });
      },
      children: List<Widget>.generate(24, (int index) {
        final double hourLabelWidth =
          widget.mode == CupertinoTimerPickerMode.hm ? _kPickerWidth / 4 : _kPickerWidth / 6;

        final String semanticsLabel = textDirectionFactor == 1
          ? localizations.timerPickerHour(index) + localizations.timerPickerHourLabel(index)
          : localizations.timerPickerHourLabel(index) + localizations.timerPickerHour(index);

        return Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          child: Container(
            alignment: alignCenterRight,
            padding: textDirectionFactor == 1
              ? EdgeInsets.only(right: hourLabelWidth)
              : EdgeInsets.only(left: hourLabelWidth),
            child: Container(
              alignment: alignCenterRight,
              // Adds some spaces between words.
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(localizations.timerPickerHour(index)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHourColumn() {
    final Widget hourLabel = IgnorePointer(
      child: Container(
        alignment: alignCenterRight,
        child: Container(
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

    return Stack(
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

    return CupertinoPicker(
      scrollController: FixedExtentScrollController(
        initialItem: selectedMinute ~/ widget.minuteInterval,
      ),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedMinute = index;
          widget.onTimerDurationChanged(
            Duration(
              hours: selectedHour ?? 0,
              minutes: selectedMinute,
              seconds: selectedSecond ?? 0));
        });
      },
      children: List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
        final int minute = index * widget.minuteInterval;

        final String semanticsLabel = textDirectionFactor == 1
          ? localizations.timerPickerMinute(minute) + localizations.timerPickerMinuteLabel(minute)
          : localizations.timerPickerMinuteLabel(minute) + localizations.timerPickerMinute(minute);

        if (widget.mode == CupertinoTimerPickerMode.ms) {
          return Semantics(
            label: semanticsLabel,
            excludeSemantics: true,
            child: Container(
              alignment: alignCenterRight,
              padding: textDirectionFactor == 1
                ? const EdgeInsets.only(right: _kPickerWidth / 4)
                : const EdgeInsets.only(left: _kPickerWidth / 4),
              child: Container(
                alignment: alignCenterRight,
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(localizations.timerPickerMinute(minute)),
              ),
            ),
          );
        }
        else
          return Semantics(
            label: semanticsLabel,
            excludeSemantics: true,
            child: Container(
              alignment: alignCenterLeft,
              child: Container(
                alignment: alignCenterRight,
                width: widget.mode == CupertinoTimerPickerMode.hm
                  ? _kPickerWidth / 10
                  : _kPickerWidth / 6,
                // Adds some spaces between words.
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(localizations.timerPickerMinute(minute)),
              ),
            ),
          );
      }),
    );
  }

  Widget _buildMinuteColumn() {
    Widget minuteLabel;

    if (widget.mode == CupertinoTimerPickerMode.hm) {
      minuteLabel = IgnorePointer(
        child: Container(
          alignment: alignCenterLeft,
          padding: textDirectionFactor == 1
            ? const EdgeInsets.only(left: _kPickerWidth / 10)
            : const EdgeInsets.only(right: _kPickerWidth / 10),
          child: Container(
            alignment: alignCenterLeft,
            // Adds some spaces between words.
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildLabel(localizations.timerPickerMinuteLabel(selectedMinute)),
          ),
        ),
      );
    }
    else {
      minuteLabel = IgnorePointer(
        child: Container(
          alignment: alignCenterRight,
          child: Container(
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

    return CupertinoPicker(
      scrollController: FixedExtentScrollController(
        initialItem: selectedSecond ~/ widget.secondInterval,
      ),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedSecond = index;
          widget.onTimerDurationChanged(
            Duration(
              hours: selectedHour ?? 0,
              minutes: selectedMinute,
              seconds: selectedSecond));
        });
      },
      children: List<Widget>.generate(60 ~/ widget.secondInterval, (int index) {
        final int second = index * widget.secondInterval;

        final String semanticsLabel = textDirectionFactor == 1
          ? localizations.timerPickerSecond(second) + localizations.timerPickerSecondLabel(second)
          : localizations.timerPickerSecondLabel(second) + localizations.timerPickerSecond(second);

        return Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          child: Container(
            alignment: alignCenterLeft,
            child: Container(
              alignment: alignCenterRight,
              // Adds some spaces between words.
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              width: secondPickerWidth,
              child: Text(localizations.timerPickerSecond(second)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSecondColumn() {
    final double secondPickerWidth =
      widget.mode == CupertinoTimerPickerMode.ms ? _kPickerWidth / 10 : _kPickerWidth / 6;

    final Widget secondLabel = IgnorePointer(
      child: Container(
        alignment: alignCenterLeft,
        padding: textDirectionFactor == 1
          ? EdgeInsets.only(left: secondPickerWidth)
          : EdgeInsets.only(right: secondPickerWidth),
        child: Container(
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
      picker = Row(
        children: <Widget>[
          Expanded(child: _buildHourColumn()),
          Expanded(child: _buildMinuteColumn()),
        ],
      );
    }
    else if (widget.mode == CupertinoTimerPickerMode.ms) {
      picker = Row(
        children: <Widget>[
          Expanded(child: _buildMinuteColumn()),
          Expanded(child: _buildSecondColumn()),
        ],
      );
    }
    else {
      picker = Row(
        children: <Widget>[
          Expanded(child: _buildHourColumn()),
          Container(
            width: _kPickerWidth / 3,
            child: _buildMinuteColumn(),
          ),
          Expanded(child: _buildSecondColumn()),
        ],
      );
    }

    return MediaQuery(
      data: const MediaQueryData(
        // The native iOS picker's text scaling is fixed, so we will also fix it
        // as well in our picker.
        textScaleFactor: 1.0,
      ),
      child: picker,
    );
  }
}