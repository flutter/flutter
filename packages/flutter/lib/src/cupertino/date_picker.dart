// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'localizations.dart';
import 'picker.dart';

// Default aesthetic values obtained by comparing with iOS pickers.
const double _kItemExtent = 32.0;
const double _kPickerWidth = 330.0;
const bool _kUseMagnifier = true;
const double _kMagnification = 1.05;
const double _kDatePickerPadSize = 12.0;
// Considers setting the default background color from the theme, in the future.
const Color _kBackgroundColor = CupertinoColors.white;

const TextStyle _kDefaultPickerTextStyle = TextStyle(
  letterSpacing: -0.83,
);

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

      layoutChild(index, BoxConstraints.tight(Size(childWidth, size.height)));
      positionChild(index, Offset(currentHorizontalOffset, 0.0));

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
///    of the iOS-style date picker.
///  * [CupertinoPicker], the class that implements a content agnostic spinner UI.
enum CupertinoDatePickerMode {
  /// Mode that shows the date in hour, minute, and (optional) an AM/PM designation.
  /// The AM/PM designation is shown only if [CupertinoDatePicker] does not use 24h format.
  /// Column order is subject to internationalization.
  ///
  /// Example: [4 | 14 | PM].
  time,
  /// Mode that shows the date in month, day of month, and year.
  /// Name of month is spelled in full.
  /// Column order is subject to internationalization.
  ///
  /// Example: [July | 13 | 2012].
  date,
  /// Mode that shows the date as day of the week, month, day of month and
  /// the time in hour, minute, and (optional) an AM/PM designation.
  /// The AM/PM designation is shown only if [CupertinoDatePicker] does not use 24h format.
  /// Column order is subject to internationalization.
  ///
  /// Example: [Fri Jul 13 | 4 | 14 | PM]
  dateAndTime,
}

// Different types of column in CupertinoDatePicker.
enum _PickerColumnType {
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

/// Controls a Cupertino Date Time or Date picker widget.
///
/// Each controller can only be used with a single Cupertino Date Time or Date
/// picker.
///
/// Used with [CupertinoDatePicker].
///
/// See also:
///
///  * [CupertinoDatePicker] which creates a Cupertino themed date picker.
class CupertinoPickerController {
  /// Creates a DatePickerController.
  ///
  /// The [resetDuration] argument must not be null.
  CupertinoPickerController({
    this.resetDuration = const Duration(milliseconds: 300),
  }) : assert(resetDuration != null);

  /// The time for each picker wheel to swing back to their initial positions.
  ///
  /// By default the duration is 300 milliseconds.
  final Duration resetDuration;

  CupertinoDatePickerDateTimeState _cupertinoDateTimePickerState;
  CupertinoDatePickerDateState _cupertinoDatePickerState;
  CupertinoTimerPickerState _cupertinoTimerPickerState;

  /// Resets the attached picker to the initial date or time or date/time as
  /// specified when creating the attached [CupertinoDatePicker].
  void reset() {
    _cupertinoDateTimePickerState?.reset(resetDuration);
    _cupertinoDatePickerState?.reset(resetDuration);
    _cupertinoTimerPickerState?.reset(resetDuration);
  }

  /// Registers the a date time picker state with this controller.
  ///
  /// After this function returns, the [reset] method on this
  /// controller will reset the attached picker.
  void attachDateTimeState(CupertinoDatePickerDateTimeState state) {
    assert(
      _cupertinoDateTimePickerState == null &&
      _cupertinoDatePickerState == null &&
      _cupertinoTimerPickerState == null
    );
    _cupertinoDateTimePickerState = state;
  }

  /// Registers the a date picker state with this controller.
  ///
  /// After this function returns, the [reset] method on this
  /// controller will reset the attached picker.
  void attachDateState(CupertinoDatePickerDateState state) {
    assert(
    _cupertinoDateTimePickerState == null &&
    _cupertinoDatePickerState == null &&
    _cupertinoTimerPickerState == null
    );
    _cupertinoDatePickerState = state;
  }

  /// Registers the a date picker state with this controller.
  ///
  /// After this function returns, the [reset] method on this
  /// controller will reset the attached picker.
  void attachTimeState(CupertinoTimerPickerState state) {
    assert(
    _cupertinoDateTimePickerState == null &&
    _cupertinoDatePickerState == null &&
    _cupertinoTimerPickerState == null
    );
    _cupertinoTimerPickerState = state;
  }

  /// Unregister the given date picker state with this controller.
  ///
  /// After this function returns, the [reset] method on this
  /// controller will not rest the attached picker.
  void detach() {
    assert(
      _cupertinoDatePickerState != null ||
      _cupertinoDateTimePickerState != null ||
      _cupertinoTimerPickerState != null
    );
    _cupertinoDateTimePickerState = null;
    _cupertinoDatePickerState = null;
    _cupertinoTimerPickerState = null;
  }
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
///
/// See also:
///
///  * [CupertinoTimerPicker], the class that implements the iOS-style timer picker.
///  * [CupertinoPicker], the class that implements a content agnostic spinner UI.
class CupertinoDatePicker extends StatefulWidget {
  /// Constructs an iOS style date picker.
  ///
  /// [mode] is one of the mode listed in [CupertinoDatePickerMode] and defaults
  /// to [CupertinoDatePickerMode.dateAndTime].
  ///
  /// [onDateTimeChanged] is the callback called when the selected date or time
  /// changes and must not be null.
  ///
  /// [initialDateTime] is the initial date time of the picker. Defaults to the
  /// present date and time and must not be null. The present must conform to
  /// the intervals set in [minimumDate], [maximumDate], [minimumYear], and
  /// [maximumYear].
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
    // ignore: always_require_non_null_named_parameters
    DateTime initialDateTime,
    this.minimumDate,
    this.maximumDate,
    this.minimumYear = 1,
    this.maximumYear,
    this.minuteInterval = 1,
    this.use24hFormat = false,
    this.controller,
  }) : initialDateTime = initialDateTime ?? DateTime.now(),
       assert(mode != null),
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
  /// Defaults to [CupertinoDatePickerMode.dateAndTime]. Cannot be null and
  /// value cannot change after initial build.
  final CupertinoDatePickerMode mode;

  /// The initial date and/or time of the picker. Defaults to the present date
  /// and time and must not be null. The present must conform to the intervals
  /// set in [minimumDate], [maximumDate], [minimumYear], and [maximumYear].
  ///
  /// Changing this value after the initial build will not affect the currently
  /// selected date time.
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
  /// Must be an integer factor of 60.
  final int minuteInterval;

  /// Whether to use 24 hour format. Defaults to false.
  final bool use24hFormat;

  /// Callback called when the selected date and/or time changes. Must not be
  /// null.
  final ValueChanged<DateTime> onDateTimeChanged;

  /// An optional controller used to animate the picker back to its
  /// initialization state.
  final CupertinoPickerController controller;

  @override
  State<StatefulWidget> createState() {
    // The `time` mode and `dateAndTime` mode of the picker share the time
    // columns, so they are placed together to one state.
    // The `date` mode has different children and is implemented in a different
    // state.
    if (mode == CupertinoDatePickerMode.time || mode == CupertinoDatePickerMode.dateAndTime)
      return CupertinoDatePickerDateTimeState();
    else
      return CupertinoDatePickerDateState();
  }

  // Estimate the minimum width that each column needs to layout its content.
  static double _getColumnWidth(
    _PickerColumnType columnType,
    CupertinoLocalizations localizations,
    BuildContext context,
  ) {
    String longestText = '';

    switch (columnType) {
      case _PickerColumnType.date:
        // Measuring the length of all possible date is impossible, so here
        // just some dates are measured.
        for (int i = 1; i <= 12; i++) {
          // An arbitrary date.
          final String date =
              localizations.datePickerMediumDate(DateTime(2018, i, 25));
          if (longestText.length < date.length)
            longestText = date;
        }
        break;
      case _PickerColumnType.hour:
        for (int i = 0 ; i < 24; i++) {
          final String hour = localizations.datePickerHour(i);
          if (longestText.length < hour.length)
            longestText = hour;
        }
        break;
      case _PickerColumnType.minute:
        for (int i = 0 ; i < 60; i++) {
          final String minute = localizations.datePickerMinute(i);
          if (longestText.length < minute.length)
            longestText = minute;
        }
        break;
      case _PickerColumnType.dayPeriod:
        longestText =
          localizations.anteMeridiemAbbreviation.length > localizations.postMeridiemAbbreviation.length
            ? localizations.anteMeridiemAbbreviation
            : localizations.postMeridiemAbbreviation;
        break;
      case _PickerColumnType.dayOfMonth:
        for (int i = 1 ; i <=31; i++) {
          final String dayOfMonth = localizations.datePickerDayOfMonth(i);
          if (longestText.length < dayOfMonth.length)
            longestText = dayOfMonth;
        }
        break;
      case _PickerColumnType.month:
        for (int i = 1 ; i <=12; i++) {
          final String month = localizations.datePickerMonth(i);
          if (longestText.length < month.length)
            longestText = month;
        }
        break;
      case _PickerColumnType.year:
        longestText = localizations.datePickerYear(2018);
        break;
    }

    assert(longestText != '', 'column type is not appropriate');

    final TextPainter painter = TextPainter(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        text: longestText,
      ),
      textDirection: Directionality.of(context),
    );

    // This operation is expensive and should be avoided. It is called here only
    // because there's no other way to get the information we want without
    // laying out the text.
    painter.layout();

    return painter.maxIntrinsicWidth;
  }
}

typedef _ColumnBuilder = Widget Function(double offAxisFraction, TransitionBuilder itemPositioningBuilder);

/// State for a [CupertinoDatePicker] initialized with the mode
/// [CupertinoDatePickerMode.time] or [CupertinoDatePickerMode.dateAndTime].
class CupertinoDatePickerDateTimeState extends State<CupertinoDatePicker> {
  int _textDirectionFactor;
  CupertinoLocalizations _localizations;

  // Alignment based on text direction. The variable name is self descriptive,
  // however, when text direction is rtl, alignment is reversed.
  Alignment _alignCenterLeft;
  Alignment _alignCenterRight;

  // Read this out when the state is initially created. Changes in initialDateTime
  // in the widget after first build is ignored.
  DateTime _initialDateTime;

  // The currently selected values of the date picker.
  int _selectedDayFromInitial; // The difference in days between the initial date and the currently selected date.
  int _selectedHour;
  int _selectedMinute;
  int _selectedAmPm; // 0 means AM, 1 means PM.

  // The controller of the AM/PM column.
  FixedExtentScrollController _amPmController;
  FixedExtentScrollController _hourController;
  FixedExtentScrollController _minuteController;
  FixedExtentScrollController _dateController;

  // Estimated width of columns.
  final Map<int, double> _estimatedColumnWidths = <int, double>{};
  @override
  void initState() {
    super.initState();
    _initialDateTime = widget.initialDateTime;
    _selectedDayFromInitial = 0;
    _selectedHour = widget.initialDateTime.hour;
    _selectedMinute = widget.initialDateTime.minute;
    _selectedAmPm = 0;

    if (!widget.use24hFormat) {
      _selectedAmPm = _selectedHour ~/ 12;
      _selectedHour = _selectedHour % 12;
      if (_selectedHour == 0)
        _selectedHour = 12;

      _amPmController = FixedExtentScrollController(initialItem: _selectedAmPm);
    }
    _dateController = FixedExtentScrollController(initialItem: _selectedDayFromInitial);
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);

    widget.controller?.attachDateTimeState(this);
  }

  @override
  void didUpdateWidget(CupertinoDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller?.attachDateTimeState(this);

    assert(
      oldWidget.mode == widget.mode,
      "The CupertinoDatePicker's mode cannot change once it's built",
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    _localizations = CupertinoLocalizations.of(context);

    _alignCenterLeft = _textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    _alignCenterRight = _textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;

    _estimatedColumnWidths.clear();
  }

  /// Resets the picker to the initial date time as originally specified upon
  /// creation of the [CupertionDatePicker] widget.
  void reset(Duration resetDuration) {
    _dateController.animateToItem(0, duration: resetDuration, curve: Curves.easeOut);
    _amPmController?.animateToItem(0, duration: resetDuration, curve: Curves.easeOut);
    _minuteController.animateToItem(0, duration: resetDuration, curve: Curves.easeOut);
    if (_hourController.selectedItem != 12)
      _hourController.animateToItem(0, duration: resetDuration, curve: Curves.easeOut);
  }

  // Lazily calculate the column width of the column being displayed only.
  double _getEstimatedColumnWidth(_PickerColumnType columnType) {
    if (_estimatedColumnWidths[columnType.index] == null) {
      _estimatedColumnWidths[columnType.index] =
          CupertinoDatePicker._getColumnWidth(columnType, _localizations, context);
    }

    return _estimatedColumnWidths[columnType.index];
  }

  // Gets the current date time of the picker.
  DateTime _getDateTime() {
    final DateTime date = DateTime(
      _initialDateTime.year,
      _initialDateTime.month,
      _initialDateTime.day,
    ).add(Duration(days: _selectedDayFromInitial));

    return DateTime(
      date.year,
      date.month,
      date.day,
      _selectedHour + _selectedAmPm * 12,
      _selectedMinute,
    );
  }

  // Builds the date column. The date is displayed in medium date format (e.g. Fri Aug 31).
  Widget _buildMediumDatePicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker.builder(
      scrollController: _dateController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        _selectedDayFromInitial = index;
        widget.onDateTimeChanged(_getDateTime());
      },
      itemBuilder: (BuildContext context, int index) {
        final DateTime dateTime = DateTime(
          _initialDateTime.year,
          _initialDateTime.month,
          _initialDateTime.day,
        ).add(Duration(days: index));

        if (widget.minimumDate != null && dateTime.isBefore(widget.minimumDate))
          return null;
        if (widget.maximumDate != null && dateTime.isAfter(widget.maximumDate))
          return null;

        return itemPositioningBuilder(
          context,
          Text(_localizations.datePickerMediumDate(dateTime)),
        );
      },
    );
  }

  Widget _buildHourPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: _hourController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        if (widget.use24hFormat) {
          _selectedHour = index;
          widget.onDateTimeChanged(_getDateTime());
        }
        else {
          final int currentHourIn24h = _selectedHour + _selectedAmPm * 12;
          // Automatically scrolls the am/pm column when the hour column value
          // goes far enough. This behavior is similar to
          // iOS picker version.
          if (currentHourIn24h ~/ 12 != index ~/ 12) {
            _selectedHour = index % 12;
            _amPmController.animateToItem(
              1 - _amPmController.selectedItem,
              duration: const Duration(milliseconds: 300), // Set by comparing with iOS version.
              curve: Curves.easeOut,
            ); // Set by comparing with iOS version.
          }
          else {
            _selectedHour = index % 12;
            widget.onDateTimeChanged(_getDateTime());
          }
        }
      },
      children: List<Widget>.generate(24, (int index) {
        int hour = index;
        if (!widget.use24hFormat)
          hour = hour % 12 == 0 ? 12 : hour % 12;

        return itemPositioningBuilder(
          context,
          Text(
            _localizations.datePickerHour(hour),
            semanticsLabel: _localizations.datePickerHourSemanticsLabel(hour),
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildMinutePicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: _minuteController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        _selectedMinute = index * widget.minuteInterval;
        widget.onDateTimeChanged(_getDateTime());
      },
      children: List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
        final int minute = index * widget.minuteInterval;
        return itemPositioningBuilder(
          context,
          Text(
            _localizations.datePickerMinute(minute),
            semanticsLabel: _localizations.datePickerMinuteSemanticsLabel(minute),
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildAmPmPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: _amPmController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        _selectedAmPm = index;
        widget.onDateTimeChanged(_getDateTime());
      },
      children: List<Widget>.generate(2, (int index) {
        return itemPositioningBuilder(
          context,
          Text(
            index == 0
              ? _localizations.anteMeridiemAbbreviation
              : _localizations.postMeridiemAbbreviation
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Widths of the columns in this picker, ordered from left to right.
    final List<double> columnWidths = <double>[
      _getEstimatedColumnWidth(_PickerColumnType.hour),
      _getEstimatedColumnWidth(_PickerColumnType.minute),
    ];
    final List<_ColumnBuilder> pickerBuilders = <_ColumnBuilder>[
      _buildHourPicker,
      _buildMinutePicker,
    ];

    // Adds am/pm column if the picker is not using 24h format.
    if (!widget.use24hFormat) {
      if (_localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.date_time_dayPeriod
        || _localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.time_dayPeriod_date) {
        pickerBuilders.add(_buildAmPmPicker);
        columnWidths.add(_getEstimatedColumnWidth(_PickerColumnType.dayPeriod));
      }
      else {
        pickerBuilders.insert(0, _buildAmPmPicker);
        columnWidths.insert(0, _getEstimatedColumnWidth(_PickerColumnType.dayPeriod));
      }
    }

    // Adds medium date column if the picker's mode is date and time.
    if (widget.mode == CupertinoDatePickerMode.dateAndTime) {
      if (_localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.time_dayPeriod_date
          || _localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.dayPeriod_time_date) {
        pickerBuilders.add(_buildMediumDatePicker);
        columnWidths.add(_getEstimatedColumnWidth(_PickerColumnType.date));
      }
      else {
        pickerBuilders.insert(0, _buildMediumDatePicker);
        columnWidths.insert(0, _getEstimatedColumnWidth(_PickerColumnType.date));
      }
    }

    final List<Widget> pickers = <Widget>[];

    for (int i = 0; i < columnWidths.length; i++) {
      double offAxisFraction = 0.0;
      if (i == 0)
        offAxisFraction = -0.5 * _textDirectionFactor;
      else if (i >= 2 || columnWidths.length == 2)
        offAxisFraction = 0.5 * _textDirectionFactor;

      EdgeInsets padding = const EdgeInsets.only(right: _kDatePickerPadSize);
      if (i == columnWidths.length - 1)
        padding = padding.flipped;
      if (_textDirectionFactor == -1)
        padding = padding.flipped;

      pickers.add(LayoutId(
        id: i,
        child: pickerBuilders[i](
          offAxisFraction,
          (BuildContext context, Widget child) {
            return Container(
              alignment: i == columnWidths.length - 1
                ? _alignCenterLeft
                : _alignCenterRight,
              padding: padding,
              child: Container(
                alignment: i == columnWidths.length - 1 ? _alignCenterLeft : _alignCenterRight,
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

    return MediaQuery(
      data: const MediaQueryData(textScaleFactor: 1.0),
      child: DefaultTextStyle.merge(
        style: _kDefaultPickerTextStyle,
        child: CustomMultiChildLayout(
          delegate: _DatePickerLayoutDelegate(
            columnWidths: columnWidths,
            textDirectionFactor: _textDirectionFactor,
          ),
          children: pickers,
        ),
      ),
    );
  }
}

/// State for a [CupertinoDatePicker] initialized with the mode
/// [CupertinoDatePickerMode.date].
class CupertinoDatePickerDateState extends State<CupertinoDatePicker> {
  int _textDirectionFactor;
  CupertinoLocalizations _localizations;

  // Alignment based on text direction. The variable name is self descriptive,
  // however, when text direction is rtl, alignment is reversed.
  Alignment _alignCenterLeft;
  Alignment _alignCenterRight;

  // The currently selected values of the picker.
  int _selectedDay;
  int _selectedMonth;
  int _selectedYear;

  // The controller of the day picker. There are cases where the selected value
  // of the picker is invalid (e.g. February 30th 2018), and this dayController
  // is responsible for jumping to a valid value.
  FixedExtentScrollController _dayController;
  FixedExtentScrollController _monthController;
  FixedExtentScrollController _yearController;

  // Estimated width of columns.
  final Map<int, double> _estimatedColumnWidths = <int, double>{};

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDateTime.day;
    _selectedMonth = widget.initialDateTime.month;
    _selectedYear = widget.initialDateTime.year;

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController = FixedExtentScrollController(initialItem: _selectedYear);

    widget.controller?.attachDateState(this);
  }

  @override
  void didUpdateWidget(CupertinoDatePicker oldWidget) {
    widget.controller?.attachDateState(this);
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    _localizations = CupertinoLocalizations.of(context);

    _alignCenterLeft = _textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    _alignCenterRight = _textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;

    _estimatedColumnWidths[_PickerColumnType.dayOfMonth.index] = CupertinoDatePicker._getColumnWidth(_PickerColumnType.dayOfMonth, _localizations, context);
    _estimatedColumnWidths[_PickerColumnType.month.index] = CupertinoDatePicker._getColumnWidth(_PickerColumnType.month, _localizations, context);
    _estimatedColumnWidths[_PickerColumnType.year.index] = CupertinoDatePicker._getColumnWidth(_PickerColumnType.year, _localizations, context);
  }

  /// Resets the picker to the initial date time as originally specified upon
  /// creation of the [CupertionDatePicker] widget.
  void reset(Duration resetDuration) {
    _dayController.animateToItem(0, duration: resetDuration, curve: Curves.easeOut);
    _monthController.animateToItem(0, duration: resetDuration, curve: Curves.easeOut);
    _yearController.animateToItem(0, duration: resetDuration, curve: Curves.easeOut);
  }

  Widget _buildDayPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    final int daysInCurrentMonth = DateTime(_selectedYear, (_selectedMonth + 1) % 12, 0).day;
    return CupertinoPicker(
      scrollController: _dayController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        _selectedDay = index + 1;
        if (DateTime(_selectedYear, _selectedMonth, _selectedDay).day == _selectedDay)
          widget.onDateTimeChanged(DateTime(_selectedYear, _selectedMonth, _selectedDay));
      },
      children: List<Widget>.generate(31, (int index) {
        TextStyle disableTextStyle; // Null if not out of range.
        if (index >= daysInCurrentMonth) {
          disableTextStyle = const TextStyle(color: CupertinoColors.inactiveGray);
        }
        return itemPositioningBuilder(
          context,
          Text(
            _localizations.datePickerDayOfMonth(index + 1),
            style: disableTextStyle,
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildMonthPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: _monthController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        _selectedMonth = index + 1;
        if (DateTime(_selectedYear, _selectedMonth, _selectedDay).day == _selectedDay)
          widget.onDateTimeChanged(DateTime(_selectedYear, _selectedMonth, _selectedDay));
      },
      children: List<Widget>.generate(12, (int index) {
        return itemPositioningBuilder(
          context,
          Text(_localizations.datePickerMonth(index + 1)),
        );
      }),
      looping: true,
    );
  }

  Widget _buildYearPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker.builder(
      scrollController: _yearController,
      itemExtent: _kItemExtent,
      offAxisFraction: offAxisFraction,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        _selectedYear = index;
        if (DateTime(_selectedYear, _selectedMonth, _selectedDay).day == _selectedDay)
          widget.onDateTimeChanged(DateTime(_selectedYear, _selectedMonth, _selectedDay));
      },
      itemBuilder: (BuildContext context, int index) {
        if (index < widget.minimumYear)
          return null;

        if (widget.maximumYear != null && index > widget.maximumYear)
          return null;

        return itemPositioningBuilder(
          context,
          Text(_localizations.datePickerYear(index)),
        );
      },
    );
  }

  bool _keepInValidRange(ScrollEndNotification notification) {
    // Whenever scrolling lands on an invalid entry, the picker
    // automatically scrolls to a valid one.
    final int desiredDay = DateTime(_selectedYear, _selectedMonth, _selectedDay).day;
    if (desiredDay != _selectedDay) {
      SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
        _dayController.animateToItem(
          // The next valid date is also the amount of days overflown.
          _dayController.selectedItem - desiredDay,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
    setState(() {
      // Rebuild because the number of valid days per month are different
      // depending on the month and year.
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    List<_ColumnBuilder> pickerBuilders = <_ColumnBuilder>[];
    List<double> columnWidths = <double>[];

    switch (_localizations.datePickerDateOrder) {
      case DatePickerDateOrder.mdy:
        pickerBuilders = <_ColumnBuilder>[_buildMonthPicker, _buildDayPicker, _buildYearPicker];
        columnWidths = <double>[
          _estimatedColumnWidths[_PickerColumnType.month.index],
          _estimatedColumnWidths[_PickerColumnType.dayOfMonth.index],
          _estimatedColumnWidths[_PickerColumnType.year.index]];
        break;
      case DatePickerDateOrder.dmy:
        pickerBuilders = <_ColumnBuilder>[_buildDayPicker, _buildMonthPicker, _buildYearPicker];
        columnWidths = <double>[
          _estimatedColumnWidths[_PickerColumnType.dayOfMonth.index],
          _estimatedColumnWidths[_PickerColumnType.month.index],
          _estimatedColumnWidths[_PickerColumnType.year.index]];
        break;
      case DatePickerDateOrder.ymd:
        pickerBuilders = <_ColumnBuilder>[_buildYearPicker, _buildMonthPicker, _buildDayPicker];
        columnWidths = <double>[
          _estimatedColumnWidths[_PickerColumnType.year.index],
          _estimatedColumnWidths[_PickerColumnType.month.index],
          _estimatedColumnWidths[_PickerColumnType.dayOfMonth.index]];
        break;
      case DatePickerDateOrder.ydm:
        pickerBuilders = <_ColumnBuilder>[_buildYearPicker, _buildDayPicker, _buildMonthPicker];
        columnWidths = <double>[
          _estimatedColumnWidths[_PickerColumnType.year.index],
          _estimatedColumnWidths[_PickerColumnType.dayOfMonth.index],
          _estimatedColumnWidths[_PickerColumnType.month.index]];
        break;
      default:
        assert(false, 'date order is not specified');
    }

    final List<Widget> pickers = <Widget>[];

    for (int i = 0; i < columnWidths.length; i++) {
      final double offAxisFraction = (i - 1) * 0.3 * _textDirectionFactor;

      EdgeInsets padding = const EdgeInsets.only(right: _kDatePickerPadSize);
      if (_textDirectionFactor == -1)
        padding = const EdgeInsets.only(left: _kDatePickerPadSize);

      pickers.add(LayoutId(
        id: i,
        child: pickerBuilders[i](
          offAxisFraction,
          (BuildContext context, Widget child) {
            return Container(
              alignment: i == columnWidths.length - 1
                  ? _alignCenterLeft
                  : _alignCenterRight,
              padding: i == 0 ? null : padding,
              child: Container(
                alignment: i == 0 ? _alignCenterLeft : _alignCenterRight,
                width: columnWidths[i] + _kDatePickerPadSize,
                child: child,
              ),
            );
          },
        ),
      ));
    }

    return MediaQuery(
      data: const MediaQueryData(textScaleFactor: 1.0),
      child: NotificationListener<ScrollEndNotification>(
        onNotification: _keepInValidRange,
        child: DefaultTextStyle.merge(
          style: _kDefaultPickerTextStyle,
          child: CustomMultiChildLayout(
            delegate: _DatePickerLayoutDelegate(
              columnWidths: columnWidths,
              textDirectionFactor: _textDirectionFactor,
            ),
            children: pickers,
          ),
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
///
/// See also:
///
///  * [CupertinoTimerPicker], the class that implements the iOS-style timer picker.
///  * [CupertinoPicker], the class that implements a content agnostic spinner UI.
enum CupertinoTimerPickerMode {
  /// Mode that shows the timer duration in hour and minute.
  ///
  /// Examples: 16 hours | 14 min.
  hm,
  /// Mode that shows the timer duration in minute and second.
  ///
  /// Examples: 14 min | 43 sec.
  ms,
  /// Mode that shows the timer duration in hour, minute, and second.
  ///
  /// Examples: 16 hours | 14 min | 43 sec.
  hms,
}

/// A countdown timer picker in iOS style.
///
/// This picker shows a countdown duration with hour, minute and second spinners.
/// The duration is bound between 0 and 23 hours 59 minutes 59 seconds.
///
/// There are several modes of the timer picker listed in [CupertinoTimerPickerMode].
///
/// See also:
///
///  * [CupertinoDatePicker], the class that implements different display modes
///    of the iOS-style date picker.
///  * [CupertinoPicker], the class that implements a content agnostic spinner UI.
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
    this.initialTimerDuration = Duration.zero,
    this.minuteInterval = 1,
    this.secondInterval = 1,
    this.controller,
    @required this.onTimerDurationChanged,
  }) : assert(mode != null),
       assert(onTimerDurationChanged != null),
       assert(initialTimerDuration >= Duration.zero),
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

  /// An optional controller used to animate the picker back to its
  /// initialization state.
  final CupertinoPickerController controller;

  @override
  State<StatefulWidget> createState() => CupertinoTimerPickerState();
}

/// A state for a [CupertinoTimePicker].
class CupertinoTimerPickerState extends State<CupertinoTimerPicker> {
  int _textDirectionFactor;
  CupertinoLocalizations _localizations;

  // Alignment based on text direction. The variable name is self descriptive,
  // however, when text direction is rtl, alignment is reversed.
  Alignment _alignCenterLeft;
  Alignment _alignCenterRight;

  ScrollController _hourController;
  ScrollController _minuteController;
  ScrollController _secondController;


  // The currently selected values of the picker.
  int _selectedHour;
  int _selectedMinute;
  int _selectedSecond;

  @override
  void initState() {
    super.initState();

    _selectedMinute = widget.initialTimerDuration.inMinutes % 60;

    if (widget.mode != CupertinoTimerPickerMode.ms)
      _selectedHour = widget.initialTimerDuration.inHours;

    if (widget.mode != CupertinoTimerPickerMode.hm)
      _selectedSecond = widget.initialTimerDuration.inSeconds % 60;

    widget.controller?.attachTimeState(this);

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute ~/ widget.minuteInterval);
    _secondController = FixedExtentScrollController(initialItem: _selectedSecond ~/ widget.secondInterval);
  }

  @override
  void didUpdateWidget(CupertinoTimerPicker oldWidget) {
    widget.controller?.attachTimeState(this);
    super.didUpdateWidget(oldWidget);
  }

  // Builds a text label with customized scale factor and font weight.
  Widget _buildLabel(String text) {
    return Text(
      text,
      textScaleFactor: 0.8,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  /// Resets the picker to be the initial time.
  void reset(Duration resetDuration) {
    _hourController.animateTo(0, duration: resetDuration, curve: Curves.easeOut);
    _minuteController.animateTo(0, duration: resetDuration, curve: Curves.easeOut);
    _secondController.animateTo(0, duration: resetDuration, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    _localizations = CupertinoLocalizations.of(context);

    _alignCenterLeft = _textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    _alignCenterRight = _textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;
  }

  Widget _buildHourPicker() {

    return CupertinoPicker(
      scrollController: _hourController,
      offAxisFraction: -0.5 * _textDirectionFactor,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          _selectedHour = index;
          widget.onTimerDurationChanged(
            Duration(
              hours: _selectedHour,
              minutes: _selectedMinute,
              seconds: _selectedSecond ?? 0));
        });
      },
      children: List<Widget>.generate(24, (int index) {
        final double hourLabelWidth =
          widget.mode == CupertinoTimerPickerMode.hm ? _kPickerWidth / 4 : _kPickerWidth / 6;

        final String semanticsLabel = _textDirectionFactor == 1
          ? _localizations.timerPickerHour(index) + _localizations.timerPickerHourLabel(index)
          : _localizations.timerPickerHourLabel(index) + _localizations.timerPickerHour(index);

        return Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          child: Container(
            alignment: _alignCenterRight,
            padding: _textDirectionFactor == 1
              ? EdgeInsets.only(right: hourLabelWidth)
              : EdgeInsets.only(left: hourLabelWidth),
            child: Container(
              alignment: _alignCenterRight,
              // Adds some spaces between words.
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(_localizations.timerPickerHour(index)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHourColumn() {
    final Widget hourLabel = IgnorePointer(
      child: Container(
        alignment: _alignCenterRight,
        child: Container(
          alignment: _alignCenterLeft,
          // Adds some spaces between words.
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          width: widget.mode == CupertinoTimerPickerMode.hm
            ? _kPickerWidth / 4
            : _kPickerWidth / 6,
          child: _buildLabel(_localizations.timerPickerHourLabel(_selectedHour)),
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
      offAxisFraction = 0.5 * _textDirectionFactor;
    else if (widget.mode == CupertinoTimerPickerMode.hms)
      offAxisFraction = 0.0;
    else
      offAxisFraction = -0.5 * _textDirectionFactor;


    return CupertinoPicker(
      scrollController: _minuteController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          _selectedMinute = index;
          widget.onTimerDurationChanged(
            Duration(
              hours: _selectedHour ?? 0,
              minutes: _selectedMinute,
              seconds: _selectedSecond ?? 0));
        });
      },
      children: List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
        final int minute = index * widget.minuteInterval;

        final String semanticsLabel = _textDirectionFactor == 1
          ? _localizations.timerPickerMinute(minute) + _localizations.timerPickerMinuteLabel(minute)
          : _localizations.timerPickerMinuteLabel(minute) + _localizations.timerPickerMinute(minute);

        if (widget.mode == CupertinoTimerPickerMode.ms) {
          return Semantics(
            label: semanticsLabel,
            excludeSemantics: true,
            child: Container(
              alignment: _alignCenterRight,
              padding: _textDirectionFactor == 1
                ? const EdgeInsets.only(right: _kPickerWidth / 4)
                : const EdgeInsets.only(left: _kPickerWidth / 4),
              child: Container(
                alignment: _alignCenterRight,
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(_localizations.timerPickerMinute(minute)),
              ),
            ),
          );
        }
        else
          return Semantics(
            label: semanticsLabel,
            excludeSemantics: true,
            child: Container(
              alignment: _alignCenterLeft,
              child: Container(
                alignment: _alignCenterRight,
                width: widget.mode == CupertinoTimerPickerMode.hm
                  ? _kPickerWidth / 10
                  : _kPickerWidth / 6,
                // Adds some spaces between words.
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(_localizations.timerPickerMinute(minute)),
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
          alignment: _alignCenterLeft,
          padding: _textDirectionFactor == 1
            ? const EdgeInsets.only(left: _kPickerWidth / 10)
            : const EdgeInsets.only(right: _kPickerWidth / 10),
          child: Container(
            alignment: _alignCenterLeft,
            // Adds some spaces between words.
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildLabel(_localizations.timerPickerMinuteLabel(_selectedMinute)),
          ),
        ),
      );
    } else {
      minuteLabel = IgnorePointer(
        child: Container(
          alignment: _alignCenterRight,
          child: Container(
            alignment: _alignCenterLeft,
            width: widget.mode == CupertinoTimerPickerMode.ms
              ? _kPickerWidth / 4
              : _kPickerWidth / 6,
            // Adds some spaces between words.
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildLabel(_localizations.timerPickerMinuteLabel(_selectedMinute)),
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
    final double offAxisFraction = 0.5 * _textDirectionFactor;

    final double secondPickerWidth =
      widget.mode == CupertinoTimerPickerMode.ms ? _kPickerWidth / 10 : _kPickerWidth / 6;
    return CupertinoPicker(
      scrollController: _secondController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      backgroundColor: _kBackgroundColor,
      onSelectedItemChanged: (int index) {
        setState(() {
          _selectedSecond = index;
          widget.onTimerDurationChanged(
            Duration(
              hours: _selectedHour ?? 0,
              minutes: _selectedMinute,
              seconds: _selectedSecond));
        });
      },
      children: List<Widget>.generate(60 ~/ widget.secondInterval, (int index) {
        final int second = index * widget.secondInterval;

        final String semanticsLabel = _textDirectionFactor == 1
          ? _localizations.timerPickerSecond(second) + _localizations.timerPickerSecondLabel(second)
          : _localizations.timerPickerSecondLabel(second) + _localizations.timerPickerSecond(second);

        return Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          child: Container(
            alignment: _alignCenterLeft,
            child: Container(
              alignment: _alignCenterRight,
              // Adds some spaces between words.
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              width: secondPickerWidth,
              child: Text(_localizations.timerPickerSecond(second)),
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
        alignment: _alignCenterLeft,
        padding: _textDirectionFactor == 1
          ? EdgeInsets.only(left: secondPickerWidth)
          : EdgeInsets.only(right: secondPickerWidth),
        child: Container(
          alignment: _alignCenterLeft,
          // Adds some spaces between words.
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: _buildLabel(_localizations.timerPickerSecondLabel(_selectedSecond)),
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
      picker = Row(
        children: <Widget>[
          Expanded(child: _buildMinuteColumn()),
          Expanded(child: _buildSecondColumn()),
        ],
      );
    } else {
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
