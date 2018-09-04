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
const bool _kUseMagnifier = true;
const double _kMagnification = 1.1;
const double _kDatePickerPadSize = 12.0;
/// Considers setting the default background color from the theme, in the future.
const Color _kBackgroundColor = CupertinoColors.white;
/// The total types of columns in the date picker. 7 types of columns are
/// date, hour, minute, day period, day of month, month, year.
const int _kColumnTypes = 7;

// Lays out the date picker based on how much space each single column needs.
//
// Each column is a child of this delegate, indexed from 0 to number of columns - 1.
// Each column will be padded horizontally by 12.0 both left and right.
//
// The picker will be placed in the center, and the leftmost and rightmost
// column will be extended equally to the remaining width.
class _DatePickerLayoutDelegate extends MultiChildLayoutDelegate {
  _DatePickerLayoutDelegate({
    @required this.columnWidths,
    @required this.textDirectionFactor,
  }) : assert(columnWidths != null),
       assert(textDirectionFactor != null);

  // The list containing widths of all columns.
  final List<double> columnWidths;

  // textDirectionFactor is 1 if text is written left to right, and -1 if right to left.
  final int textDirectionFactor;

  @override
  void performLayout(Size size) {
    double remainingWidth = size.width;

    for (int i = 0; i < columnWidths.length; i++)
      remainingWidth -= columnWidths[i] + _kDatePickerPadSize * 2;

    double currentHorizontalOffset = 0.0;

    for (int i = 0; i < columnWidths.length; i++) {
      final int index = textDirectionFactor == 1 ? i : columnWidths.length - i - 1;

      double childWidth = columnWidths[index] + _kDatePickerPadSize * 2;
      if (index == 0 || index == columnWidths.length - 1)
        childWidth += remainingWidth / 2;

      layoutChild(index, BoxConstraints.tight(new Size(childWidth, size.height)));
      positionChild(index, new Offset(currentHorizontalOffset, 0.0));

      currentHorizontalOffset += childWidth;
    }
  }

  @override
  bool shouldRelayout(_DatePickerLayoutDelegate oldDelegate) {
    return columnWidths != oldDelegate.columnWidths
      || textDirectionFactor != oldDelegate.textDirectionFactor;
  }
}

/// Different display modes of [CupertinoDatePicker].
///
/// See also:
///
///  * [CupertinoDatePicker], the class that implements different display modes
///  of the iOS-style date picker.
///  * [CupertinoTimerPicker], the class that implements the iOS-style timer picker.
enum CupertinoDatePickerMode {
  /// Mode that shows the date in hour, minute, and (optional) an AM/PM designation.
  /// The AM/PM designation is shown only if [CupertinoDatPicker] does not use 24h format.
  /// Column order is subjected to internationalization.
  ///
  /// Example: [4 | 14 | PM].
  time,
  /// Mode that shows the date in month, day of month, and year.
  /// Name of month is spelled in full.
  /// Column order is subjected to internationalization.
  ///
  /// Example: [July | 13 | 2012].
  date,
  /// Mode that shows the date as day of the week, month, day of month and
  /// the time in hour, minute, and (optional) an AM/PM designation.
  /// The AM/PM designation is shown only if [CupertinoDatPicker] does not use 24h format.
  /// Column order is subjected to internationalization.
  ///
  /// Example: [Fri Jul 13 | 4 | 14 | PM]
  dateAndTime,
}

// Different types of column in CupertinoDatePicker.
enum _pickerColumnType {
  // Day of month column in date mode.
  dayOfMonth,
  // Month column in date mode.
  month,
  // Year column in date mode.
  year,
  // Medium date column in dateAndTime mode.
  date,
  // Hour column in time and dateAndTime mode.
  hour,
  // minute column in time and dateAndTime mode.
  minute,
  // AM/PM column in time and dateAndTime mode.
  dayPeriod,
}

/// A date picker widget in iOS style.
///
/// There are several modes of the date picker listed in [CupertinoDatePickerMode].
///
/// The class will display its children as consecutive columns. Its children
/// order is based on internationalization.
///
/// Example of the picker in date mode:
///
///  * US-English: [July | 13 | 2012]
///  * Vietnamese: [13 | Tháng 7 | 2012]
class CupertinoDatePicker extends StatefulWidget {
  /// Constructs an iOS style date picker.
  ///
  /// [mode] is one of the mode listed in [CupertinoDatePickerMode] and defaults
  /// to [CupertinoDatePickerMode.dateAndTime].
  ///
  /// [onDateTimeChanged] is the callback called when the selected date or time
  /// changes and must not be null.
  ///
  /// [initialDateTime] is the initial date time of the picker. Must not be null.
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
       assert(
         mode != CupertinoDatePickerMode.dateAndTime || minimumDate == null || !initialDateTime.isBefore(minimumDate),
         'initial date is before minimum date',
       ),
       assert(
         mode != CupertinoDatePickerMode.dateAndTime || maximumDate == null || !initialDateTime.isAfter(maximumDate),
         'initial date is after maximum date',
       ),
       assert(minimumYear != null),
       assert(
         mode != CupertinoDatePickerMode.date || (minimumYear >= 1 && initialDateTime.year >= minimumYear),
         'initial year is not greater than minimum year, or mininum year is not positive',
       ),
       assert(
         mode != CupertinoDatePickerMode.date || maximumYear == null || initialDateTime.year <= maximumYear,
         'initial year is not smaller than maximum year',
       ),
       assert(
         minuteInterval > 0 && 60 % minuteInterval == 0,
         'minute interval is not a positive integer factor of 60',
       ),
       assert(
         initialDateTime.minute % minuteInterval == 0,
         'initial minute is not divisible by minute interval',
       );

  /// The mode of the date picker as one of [CupertinoDatePickerMode].
  /// Defaults to [CupertinoDatePickerMode.dateAndTime].
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

  /// Callback called when the selected date and/or time changes.
  final ValueChanged<DateTime> onDateTimeChanged;

  @override
  State<StatefulWidget> createState() {
    // The `time` mode and `dateAndTime` mode of the picker share the time
    // columns, so they are placed together to one state.
    // The `date` mode has different children and is implemented in a different
    // state.
    if (mode == CupertinoDatePickerMode.time || mode == CupertinoDatePickerMode.dateAndTime)
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
  int selectedDayFromInitial; // The difference in days between the initial date and the currently selected date.
  int selectedHour;
  int selectedMinute;
  int selectedAmPm; // 0 means AM, 1 means PM.

  // The controller of the AM/PM column.
  FixedExtentScrollController amPmController;

  // Estimated width of columns.
  List<double> estimatedColumnWidths = new List<double>(_kColumnTypes);

  @override
  void initState() {
    super.initState();
    selectedDayFromInitial = 0;
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

  // Estimate the minimum width that each column needs to layout its content.
  double _getColumnWidth(_pickerColumnType columnType) {
    String longestText = '';

    if (columnType == _pickerColumnType.date) {
      // Measuring the length of all possible date is impossible, so here
      // just some dates are measured.
      for (int i = 1; i <= 12; i++) {
        final String date = localizations.datePickerMediumDate(
          new DateTime(widget.initialDateTime.year, i, 25));
        if (longestText.length < date.length)
          longestText = date;
      }
    } else if (columnType == _pickerColumnType.hour) {
      for (int i = 0 ; i < 24; i++) {
        final String hour = localizations.datePickerHour(i);
        if (longestText.length < hour.length)
          longestText = hour;
      }
    } else if (columnType == _pickerColumnType.minute) {
      for (int i = 0 ; i < 60; i++) {
        final String minute = localizations.datePickerMinute(i);
        if (longestText.length < minute.length)
          longestText = minute;
      }
    } else if (columnType == _pickerColumnType.dayPeriod)
      longestText =
        localizations.anteMeridiemAbbreviation.length > localizations.postMeridiemAbbreviation.length
          ? localizations.anteMeridiemAbbreviation
          : localizations.postMeridiemAbbreviation;
    else
      assert(false, 'column type is not appropriate');

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context) ?? const DefaultCupertinoLocalizations();

    alignCenterLeft = textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight = textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;

    estimatedColumnWidths[_pickerColumnType.date.index] = _getColumnWidth(_pickerColumnType.date);
    estimatedColumnWidths[_pickerColumnType.hour.index] = _getColumnWidth(_pickerColumnType.hour);
    estimatedColumnWidths[_pickerColumnType.minute.index] = _getColumnWidth(_pickerColumnType.minute);
    estimatedColumnWidths[_pickerColumnType.dayPeriod.index] = _getColumnWidth(_pickerColumnType.dayPeriod);
  }

  // Gets the current date time of the picker.
  DateTime _getDateTime() {
    final DateTime date = new DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
    ).add(Duration(days: selectedDayFromInitial));

    return new DateTime(
      date.year,
      date.month,
      date.day,
      selectedHour + selectedAmPm * 12,
      selectedMinute,
    );
  }

  // Builds the date column. The date is displayed in medium date format (e.g. Fri Aug 31).
  Widget _buildMediumDatePicker(double offAxisFraction, Function childPositioning) {
    return new CupertinoPicker.builder(
      scrollController: new FixedExtentScrollController(initialItem: selectedDayFromInitial),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        selectedDayFromInitial = index;
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

        return childPositioning(new Text(localizations.datePickerMediumDate(dateTime)));
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
          // Automatically scrolls the am/pm column when the hour column value
          // goes from 11 to 12, or 12 to 11. This behavior is similar to
          // iOS picker version.
          if (selectedHour == 0 && index % 12 == 11 || selectedHour == 11 && index % 12 == 0) {
            selectedHour = index % 12;
            amPmController.animateToItem(
              1 - amPmController.selectedItem,
              duration: const Duration(milliseconds: 300), // Set by comparing with iOS version.
              curve: Curves.easeOut); // Set by comparing with iOS version.
          }
          else {
            selectedHour = index % 12;
            widget.onDateTimeChanged(_getDateTime());
          }
        }
      },
      children: new List<Widget>.generate(24, (int index) {
        int hour = index;
        if (!widget.use24hFormat)
          hour = hour % 12 == 0 ? 12 : hour % 12;

        return childPositioning(new Text(
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
        return childPositioning(new Text(
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
        return childPositioning(new Text(
          index == 0
            ? localizations.anteMeridiemAbbreviation
            : localizations.postMeridiemAbbreviation
        ));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Widths of the columns in this picker, ordered from left to right.
    final List<double> columnWidths = <double>[
      estimatedColumnWidths[_pickerColumnType.hour.index],
      estimatedColumnWidths[_pickerColumnType.minute.index],
    ];
    final List<Function> pickerBuilders = <Function>[
      _buildHourPicker,
      _buildMinutePicker,
    ];

    // Adds am/pm column if the picker is not using 24h format.
    if (!widget.use24hFormat) {
      if (localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.date_time_dayPeriod
        || localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.time_dayPeriod_date) {
        pickerBuilders.add(_buildAmPmPicker);
        columnWidths.add(estimatedColumnWidths[_pickerColumnType.dayPeriod.index]);
      }
      else {
        pickerBuilders.insert(0, _buildAmPmPicker);
        columnWidths.insert(0, estimatedColumnWidths[_pickerColumnType.dayPeriod.index]);
      }
    }

    // Adds medium date column if the picker's mode is date and time.
    if (widget.mode == CupertinoDatePickerMode.dateAndTime) {
      if (localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.time_dayPeriod_date
          || localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.dayPeriod_time_date) {
        pickerBuilders.add(_buildMediumDatePicker);
        columnWidths.add(estimatedColumnWidths[_pickerColumnType.date.index]);
      }
      else {
        pickerBuilders.insert(0, _buildMediumDatePicker);
        columnWidths.insert(0, estimatedColumnWidths[_pickerColumnType.date.index]);
      }
    }

    final List<Widget> pickers = <Widget>[];

    for (int i = 0; i < columnWidths.length; i++) {
      double offAxisFraction = 0.0;
      if (i == 0)
        offAxisFraction = -0.5 * textDirectionFactor;
      else if (i >= 2 || columnWidths.length == 2)
        offAxisFraction = 0.5 * textDirectionFactor;

      EdgeInsets padding = const EdgeInsets.only(right: _kDatePickerPadSize);
      if (i == columnWidths.length - 1)
        padding = padding.flipped;
      if (textDirectionFactor == -1)
        padding = padding.flipped;

      pickers.add(LayoutId(
        id: i,
        child: pickerBuilders[i](
          offAxisFraction,
          (Widget child) {
            return new Container(
              alignment: i == columnWidths.length - 1
                ? alignCenterLeft
                : alignCenterRight,
              padding: padding,
              child: new Container(
                alignment: i == columnWidths.length - 1 ? alignCenterLeft : alignCenterRight,
                width: i == 0 || i == columnWidths.length - 1
                  ? null
                  : columnWidths[i] + _kDatePickerPadSize,
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
        delegate: new _DatePickerLayoutDelegate(
          columnWidths: columnWidths,
          textDirectionFactor: textDirectionFactor,
        ),
        children: pickers,
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

  // Estimated width of columns.
  List<double> estimatedColumnWidths = new List<double>(_kColumnTypes);

  @override
  void initState() {
    super.initState();
    selectedDay = widget.initialDateTime.day;
    selectedMonth = widget.initialDateTime.month;
    selectedYear = widget.initialDateTime.year;

    dayController = new FixedExtentScrollController(initialItem: selectedDay - 1);
  }

  // Estimate the minimum width that each column needs to layout its content.
  double _getColumnWidth(_pickerColumnType columnType) {
    String longestText = '';

    if (columnType == _pickerColumnType.dayOfMonth) {
      for (int i = 1 ; i <=31; i++) {
        final String dayOfMonth = localizations.datePickerDayOfMonth(i);
        if (longestText.length < dayOfMonth.length)
          longestText = dayOfMonth;
      }
    } else if (columnType == _pickerColumnType.month) {
      for (int i = 1 ; i <=12; i++) {
        final String month = localizations.datePickerMonth(i);
        if (longestText.length < month.length)
          longestText = month;
      }
    } else if(columnType == _pickerColumnType.year)
      longestText = localizations.datePickerYear(2018);
    else
      assert(false, 'column type is not appropriate');

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context) ?? const DefaultCupertinoLocalizations();

    alignCenterLeft = textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight = textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;

    estimatedColumnWidths[_pickerColumnType.dayOfMonth.index] = _getColumnWidth(_pickerColumnType.dayOfMonth);
    estimatedColumnWidths[_pickerColumnType.month.index] = _getColumnWidth(_pickerColumnType.month);
    estimatedColumnWidths[_pickerColumnType.year.index] = _getColumnWidth(_pickerColumnType.year);
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
        return childPositioning(new Text(localizations.datePickerDayOfMonth(index + 1)));
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
        return childPositioning(new Text(localizations.datePickerMonth(index + 1)));
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

        return childPositioning(new Text(localizations.datePickerYear(index)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Function> pickerBuilders = <Function>[];
    List<double> columnWidths = <double>[];

    if (localizations.datePickerDateOrder == DatePickerDateOrder.mdy) {
      pickerBuilders = <Function>[_buildMonthPicker, _buildDayPicker, _buildYearPicker];
      columnWidths = <double>[
        estimatedColumnWidths[_pickerColumnType.month.index],
        estimatedColumnWidths[_pickerColumnType.dayOfMonth.index],
        estimatedColumnWidths[_pickerColumnType.year.index]];
    } else if (localizations.datePickerDateOrder == DatePickerDateOrder.dmy) {
      pickerBuilders = <Function>[_buildDayPicker, _buildMonthPicker, _buildYearPicker];
      columnWidths = <double>[
        estimatedColumnWidths[_pickerColumnType.dayOfMonth.index],
        estimatedColumnWidths[_pickerColumnType.month.index],
        estimatedColumnWidths[_pickerColumnType.year.index]];
    } else if (localizations.datePickerDateOrder == DatePickerDateOrder.ymd) {
      pickerBuilders = <Function>[_buildYearPicker, _buildMonthPicker, _buildDayPicker];
      columnWidths = <double>[
        estimatedColumnWidths[_pickerColumnType.year.index],
        estimatedColumnWidths[_pickerColumnType.month.index],
        estimatedColumnWidths[_pickerColumnType.dayOfMonth.index]];
    } else if (localizations.datePickerDateOrder == DatePickerDateOrder.ydm) {
      pickerBuilders = <Function>[_buildYearPicker, _buildDayPicker, _buildMonthPicker];
      columnWidths = <double>[
        estimatedColumnWidths[_pickerColumnType.year.index],
        estimatedColumnWidths[_pickerColumnType.dayOfMonth.index],
        estimatedColumnWidths[_pickerColumnType.month.index]];
    }
    else
      assert(false, 'date order is not specified');

    final List<Widget> pickers = <Widget>[];

    for (int i = 0; i < columnWidths.length; i++) {
      final double offAxisFraction = (i - 1) * 0.5 * textDirectionFactor;

      EdgeInsets padding = const EdgeInsets.only(right: _kDatePickerPadSize);
      if (textDirectionFactor == -1)
        padding = const EdgeInsets.only(left: _kDatePickerPadSize);

      pickers.add(LayoutId(
        id: i,
        child: pickerBuilders[i](
          offAxisFraction,
              (Widget child) {
            return new Container(
              alignment: i == columnWidths.length - 1
                  ? alignCenterLeft
                  : alignCenterRight,
              padding: i == 0 ? null : padding,
              child: new Container(
                alignment: i == 0 ? alignCenterLeft : alignCenterRight,
                width: columnWidths[i] + _kDatePickerPadSize,
                child: child,
              ),
            );
          },
        ),
      ));
    }

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

            // animateToItem() is not working properly also.
            dayController.animateToItem(
              dayController.selectedItem - 1,
              duration: const Duration(milliseconds: 1),
              curve: Curves.easeOut);
          }
        },
        child: new CustomMultiChildLayout(
          delegate: new _DatePickerLayoutDelegate(
            columnWidths: columnWidths,
            textDirectionFactor: textDirectionFactor,
          ),
          children: pickers,
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
  /// [onTimerDurationChanged] is the callback called when the selected duration
  /// changes and must not be null.
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

  /// Callback called when the timer duration changes.
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
    } else {
      minuteLabel = new IgnorePointer(
        child: new Container(
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
    } else if (widget.mode == CupertinoTimerPickerMode.ms) {
      picker = new Row(
        children: <Widget>[
          Expanded(child: _buildMinuteColumn()),
          Expanded(child: _buildSecondColumn()),
        ],
      );
    } else {
      picker = new Row(
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