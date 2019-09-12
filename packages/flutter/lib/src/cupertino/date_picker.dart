// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'localizations.dart';
import 'picker.dart';
import 'theme.dart';

// Values derived from https://developer.apple.com/design/resources/ and on iOS
// simulators with "Debug View Hierarchy".
const double _kItemExtent = 32.0;
// From the picker's intrinsic content size constraint.
const double _kPickerWidth = 320.0;
const double _kPickerHeight = 216.0;
const bool _kUseMagnifier = true;
const double _kMagnification = 2.35/2.1;
const double _kDatePickerPadSize = 12.0;
// The density of a date picker is different from a generic picker.
// Eyeballed from iOS.
const double _kSqueeze = 1.25;
// Considers setting the default background color from the theme, in the future.
const Color _kBackgroundColor = CupertinoColors.white;

const TextStyle _kDefaultPickerTextStyle = TextStyle(
  letterSpacing: -0.83,
);

// Half of the horizontal padding value between the timer picker's columns.
const double _kTimerPickerHalfColumnPadding = 2;
// The horizontal padding between the timer picker's number label and its
// corresponding unit label.
const double _kTimerPickerLabelPadSize = 4.5;
const double _kTimerPickerLabelFontSize = 17.0;

// The width of each colmn of the countdown time picker.
const double _kTimerPickerColumnIntrinsicWidth = 106;
// Unfortunately turning on magnification for the timer picker messes up the label
// alignment. So we'll have to hard code the font size and turn magnification off
// for now.
const double _kTimerPickerNumberLabelFontSize = 23;

TextStyle _themeTextStyle(BuildContext context) {
  return CupertinoTheme.of(context).textTheme.dateTimePickerTextStyle;
}

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

      // We can't actually assert here because it would break things badly for
      // semantics, which will expect that we laid things out here.
      assert(() {
        if (childWidth < 0) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: FlutterError(
                'Insufficient horizontal space to render the '
                'CupertinoDatePicker because the parent is too narrow at '
                '${size.width}px.\n'
                'An additional ${-remainingWidth}px is needed to avoid '
                'overlapping columns.',
              ),
            ),
          );
        }
        return true;
      }());
      layoutChild(index, BoxConstraints.tight(Size(math.max(0.0, childWidth), size.height)));
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
/// Can be used with [showCupertinoModalPopup] to display the picker modally at
/// the bottom of the screen.
///
/// Sizes itself to its parent and may not render correctly if not given the
/// full screen width. Content texts are shown with
/// [CupertinoTextThemeData.dateTimePickerTextStyle].
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
    DateTime initialDateTime,
    this.minimumDate,
    this.maximumDate,
    this.minimumYear = 1,
    this.maximumYear,
    this.minuteInterval = 1,
    this.use24hFormat = false,
    this.backgroundColor = _kBackgroundColor
  }) : initialDateTime = initialDateTime ?? DateTime.now(),
       assert(mode != null),
       assert(onDateTimeChanged != null),
       assert(minimumYear != null),
       assert(backgroundColor != null),
       assert(
         minuteInterval > 0 && 60 % minuteInterval == 0,
         'minute interval is not a positive integer factor of 60',
       ) {
    assert(this.initialDateTime != null);
    assert(
      mode != CupertinoDatePickerMode.dateAndTime || minimumDate == null || !this.initialDateTime.isBefore(minimumDate),
      'initial date is before minimum date',
    );
    assert(
      mode != CupertinoDatePickerMode.dateAndTime || maximumDate == null || !this.initialDateTime.isAfter(maximumDate),
      'initial date is after maximum date',
    );
    assert(
      mode != CupertinoDatePickerMode.date || (minimumYear >= 1 && this.initialDateTime.year >= minimumYear),
      'initial year is not greater than minimum year, or mininum year is not positive',
    );
    assert(
      mode != CupertinoDatePickerMode.date || maximumYear == null || this.initialDateTime.year <= maximumYear,
      'initial year is not smaller than maximum year',
    );
    assert(
      this.initialDateTime.minute % minuteInterval == 0,
      'initial minute is not divisible by minute interval',
    );
  }

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

  /// Background color of date picker.
  ///
  /// Defaults to [CupertinoColors.white] when null.
  final Color backgroundColor;

  @override
  State<StatefulWidget> createState() {
    // The `time` mode and `dateAndTime` mode of the picker share the time
    // columns, so they are placed together to one state.
    // The `date` mode has different children and is implemented in a different
    // state.
    if (mode == CupertinoDatePickerMode.time || mode == CupertinoDatePickerMode.dateAndTime)
      return _CupertinoDatePickerDateTimeState();
    else
      return _CupertinoDatePickerDateState();
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
        for (int i = 0; i < 24; i++) {
          final String hour = localizations.datePickerHour(i);
          if (longestText.length < hour.length)
            longestText = hour;
        }
        break;
      case _PickerColumnType.minute:
        for (int i = 0; i < 60; i++) {
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
        for (int i = 1; i <=31; i++) {
          final String dayOfMonth = localizations.datePickerDayOfMonth(i);
          if (longestText.length < dayOfMonth.length)
            longestText = dayOfMonth;
        }
        break;
      case _PickerColumnType.month:
        for (int i = 1; i <=12; i++) {
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
        style: _themeTextStyle(context),
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

class _CupertinoDatePickerDateTimeState extends State<CupertinoDatePicker> {
  // Fraction of the farthest column's vanishing point vs its width. Eyeballed
  // vs iOS.
  static const double _kMaximumOffAxisFraction = 0.45;

  int textDirectionFactor;
  CupertinoLocalizations localizations;

  // Alignment based on text direction. The variable name is self descriptive,
  // however, when text direction is rtl, alignment is reversed.
  Alignment alignCenterLeft;
  Alignment alignCenterRight;

  // Read this out when the state is initially created. Changes in initialDateTime
  // in the widget after first build is ignored.
  DateTime initialDateTime;

  // The difference in days between the initial date and the currently selected date.
  int selectedDayFromInitial;

  // The current selection of the hour picker.
  //
  // If [widget.use24hFormat] is true, values range from 1-24. Otherwise values
  // range from 1-12.
  int selectedHour;

  // The previous selection index of the hour column.
  //
  // This ranges from 0-23 even if [widget.use24hFormat] is false. As a result,
  // it can be used for determining if we just changed from AM -> PM or vice
  // versa.
  int previousHourIndex;

  // The current selection of the minute picker. Values range from 0 to 59.
  int selectedMinute;

  // The current selection of the AM/PM picker.
  //
  // - 0 means AM
  // - 1 means PM
  int selectedAmPm;

  // The controller of the AM/PM column.
  FixedExtentScrollController amPmController;

  // The estimated width of columns.
  final Map<int, double> estimatedColumnWidths = <int, double>{};

  @override
  void initState() {
    super.initState();
    initialDateTime = widget.initialDateTime;
    selectedDayFromInitial = 0;
    selectedHour = widget.initialDateTime.hour;
    selectedMinute = widget.initialDateTime.minute;
    selectedAmPm = 0;

    if (!widget.use24hFormat) {
      selectedAmPm = selectedHour ~/ 12;
      selectedHour = selectedHour % 12;
      if (selectedHour == 0)
        selectedHour = 12;

      amPmController = FixedExtentScrollController(initialItem: selectedAmPm);
    }

    previousHourIndex = selectedHour;
  }

  @override
  void didUpdateWidget(CupertinoDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    assert(
      oldWidget.mode == widget.mode,
      "The CupertinoDatePicker's mode cannot change once it's built",
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context);

    alignCenterLeft = textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight = textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;

    estimatedColumnWidths.clear();
  }

  // Lazily calculate the column width of the column being displayed only.
  double _getEstimatedColumnWidth(_PickerColumnType columnType) {
    if (estimatedColumnWidths[columnType.index] == null) {
      estimatedColumnWidths[columnType.index] =
          CupertinoDatePicker._getColumnWidth(columnType, localizations, context);
    }

    return estimatedColumnWidths[columnType.index];
  }

  // Gets the current date time of the picker.
  DateTime _getDateTime() {
    final DateTime date = DateTime(
      initialDateTime.year,
      initialDateTime.month,
      initialDateTime.day,
    ).add(Duration(days: selectedDayFromInitial));

    return DateTime(
      date.year,
      date.month,
      date.day,
      widget.use24hFormat ? selectedHour : selectedHour % 12 + selectedAmPm * 12,
      selectedMinute,
    );
  }

  // Builds the date column. The date is displayed in medium date format (e.g. Fri Aug 31).
  Widget _buildMediumDatePicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker.builder(
      scrollController: FixedExtentScrollController(initialItem: selectedDayFromInitial),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: widget.backgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        selectedDayFromInitial = index;
        widget.onDateTimeChanged(_getDateTime());
      },
      itemBuilder: (BuildContext context, int index) {
        final DateTime dateTime = DateTime(
          initialDateTime.year,
          initialDateTime.month,
          initialDateTime.day,
        ).add(Duration(days: index));

        if (widget.minimumDate != null && dateTime.isBefore(widget.minimumDate))
          return null;
        if (widget.maximumDate != null && dateTime.isAfter(widget.maximumDate))
          return null;

        final DateTime now = DateTime.now();
        String dateText;

        if (dateTime == DateTime(now.year, now.month, now.day)) {
          dateText = localizations.todayLabel;
        } else {
          dateText = localizations.datePickerMediumDate(dateTime);
        }

        return itemPositioningBuilder(
          context,
          Text(
            dateText,
            style: _themeTextStyle(context),
          ),
        );
      },
    );
  }

  Widget _buildHourPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: selectedHour),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: widget.backgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        if (widget.use24hFormat) {
          selectedHour = index;
          widget.onDateTimeChanged(_getDateTime());
        } else {
          selectedHour = index % 12;

          // Automatically scrolls the am/pm column when the hour column value
          // goes far enough.

          final bool wasAm = previousHourIndex >=0 && previousHourIndex <= 11;
          final bool isAm = index >= 0 && index <= 11;

          if (wasAm != isAm) {
            // Animation values obtained by comparing with iOS version.
            amPmController.animateToItem(
              1 - amPmController.selectedItem,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } else {
            widget.onDateTimeChanged(_getDateTime());
          }
        }

        previousHourIndex = index;
      },
      children: List<Widget>.generate(24, (int index) {
        int hour = index;
        if (!widget.use24hFormat)
          hour = hour % 12 == 0 ? 12 : hour % 12;

        return itemPositioningBuilder(
          context,
          Text(
            localizations.datePickerHour(hour),
            semanticsLabel: localizations.datePickerHourSemanticsLabel(hour),
            style: _themeTextStyle(context),
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildMinutePicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: selectedMinute ~/ widget.minuteInterval),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: widget.backgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        selectedMinute = index * widget.minuteInterval;
        widget.onDateTimeChanged(_getDateTime());
      },
      children: List<Widget>.generate(60 ~/ widget.minuteInterval, (int index) {
        final int minute = index * widget.minuteInterval;
        return itemPositioningBuilder(
          context,
          Text(
            localizations.datePickerMinute(minute),
            semanticsLabel: localizations.datePickerMinuteSemanticsLabel(minute),
            style: _themeTextStyle(context),
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildAmPmPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: amPmController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: widget.backgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        selectedAmPm = index;
        widget.onDateTimeChanged(_getDateTime());
      },
      children: List<Widget>.generate(2, (int index) {
        return itemPositioningBuilder(
          context,
          Text(
            index == 0
              ? localizations.anteMeridiemAbbreviation
              : localizations.postMeridiemAbbreviation,
            style: _themeTextStyle(context),
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
      if (localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.date_time_dayPeriod
        || localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.time_dayPeriod_date) {
        pickerBuilders.add(_buildAmPmPicker);
        columnWidths.add(_getEstimatedColumnWidth(_PickerColumnType.dayPeriod));
      } else {
        pickerBuilders.insert(0, _buildAmPmPicker);
        columnWidths.insert(0, _getEstimatedColumnWidth(_PickerColumnType.dayPeriod));
      }
    }

    // Adds medium date column if the picker's mode is date and time.
    if (widget.mode == CupertinoDatePickerMode.dateAndTime) {
      if (localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.time_dayPeriod_date
          || localizations.datePickerDateTimeOrder == DatePickerDateTimeOrder.dayPeriod_time_date) {
        pickerBuilders.add(_buildMediumDatePicker);
        columnWidths.add(_getEstimatedColumnWidth(_PickerColumnType.date));
      } else {
        pickerBuilders.insert(0, _buildMediumDatePicker);
        columnWidths.insert(0, _getEstimatedColumnWidth(_PickerColumnType.date));
      }
    }

    final List<Widget> pickers = <Widget>[];

    for (int i = 0; i < columnWidths.length; i++) {
      double offAxisFraction = 0.0;
      if (i == 0)
        offAxisFraction = -_kMaximumOffAxisFraction * textDirectionFactor;
      else if (i >= 2 || columnWidths.length == 2)
        offAxisFraction = _kMaximumOffAxisFraction * textDirectionFactor;

      EdgeInsets padding = const EdgeInsets.only(right: _kDatePickerPadSize);
      if (i == columnWidths.length - 1)
        padding = padding.flipped;
      if (textDirectionFactor == -1)
        padding = padding.flipped;

      pickers.add(LayoutId(
        id: i,
        child: pickerBuilders[i](
          offAxisFraction,
          (BuildContext context, Widget child) {
            return Container(
              alignment: i == columnWidths.length - 1
                ? alignCenterLeft
                : alignCenterRight,
              padding: padding,
              child: Container(
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

    return MediaQuery(
      data: const MediaQueryData(textScaleFactor: 1.0),
      child: DefaultTextStyle.merge(
        style: _kDefaultPickerTextStyle,
        child: CustomMultiChildLayout(
          delegate: _DatePickerLayoutDelegate(
            columnWidths: columnWidths,
            textDirectionFactor: textDirectionFactor,
          ),
          children: pickers,
        ),
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
  Map<int, double> estimatedColumnWidths = <int, double>{};

  @override
  void initState() {
    super.initState();
    selectedDay = widget.initialDateTime.day;
    selectedMonth = widget.initialDateTime.month;
    selectedYear = widget.initialDateTime.year;

    dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context);

    alignCenterLeft = textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight = textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;

    estimatedColumnWidths[_PickerColumnType.dayOfMonth.index] = CupertinoDatePicker._getColumnWidth(_PickerColumnType.dayOfMonth, localizations, context);
    estimatedColumnWidths[_PickerColumnType.month.index] = CupertinoDatePicker._getColumnWidth(_PickerColumnType.month, localizations, context);
    estimatedColumnWidths[_PickerColumnType.year.index] = CupertinoDatePicker._getColumnWidth(_PickerColumnType.year, localizations, context);
  }

  Widget _buildDayPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    final int daysInCurrentMonth = DateTime(selectedYear, (selectedMonth + 1) % 12, 0).day;
    return CupertinoPicker(
      scrollController: dayController,
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: widget.backgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        selectedDay = index + 1;
        if (DateTime(selectedYear, selectedMonth, selectedDay).day == selectedDay)
          widget.onDateTimeChanged(DateTime(selectedYear, selectedMonth, selectedDay));
      },
      children: List<Widget>.generate(31, (int index) {
        TextStyle textStyle = _themeTextStyle(context);
        if (index >= daysInCurrentMonth) {
          textStyle = textStyle.copyWith(color: CupertinoColors.inactiveGray);
        }
        return itemPositioningBuilder(
          context,
          Text(
            localizations.datePickerDayOfMonth(index + 1),
            style: textStyle,
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildMonthPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: selectedMonth - 1),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: widget.backgroundColor,
      squeeze: _kSqueeze,
      onSelectedItemChanged: (int index) {
        selectedMonth = index + 1;
        if (DateTime(selectedYear, selectedMonth, selectedDay).day == selectedDay)
          widget.onDateTimeChanged(DateTime(selectedYear, selectedMonth, selectedDay));
      },
      children: List<Widget>.generate(12, (int index) {
        return itemPositioningBuilder(
          context,
          Text(
            localizations.datePickerMonth(index + 1),
            style: _themeTextStyle(context),
          ),
        );
      }),
      looping: true,
    );
  }

  Widget _buildYearPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder) {
    return CupertinoPicker.builder(
      scrollController: FixedExtentScrollController(initialItem: selectedYear),
      itemExtent: _kItemExtent,
      offAxisFraction: offAxisFraction,
      useMagnifier: _kUseMagnifier,
      magnification: _kMagnification,
      backgroundColor: widget.backgroundColor,
      onSelectedItemChanged: (int index) {
        selectedYear = index;
        if (DateTime(selectedYear, selectedMonth, selectedDay).day == selectedDay)
          widget.onDateTimeChanged(DateTime(selectedYear, selectedMonth, selectedDay));
      },
      itemBuilder: (BuildContext context, int index) {
        if (index < widget.minimumYear)
          return null;

        if (widget.maximumYear != null && index > widget.maximumYear)
          return null;

        return itemPositioningBuilder(
          context,
          Text(
            localizations.datePickerYear(index),
            style: _themeTextStyle(context),
          ),
        );
      },
    );
  }

  bool _keepInValidRange(ScrollEndNotification notification) {
    // Whenever scrolling lands on an invalid entry, the picker
    // automatically scrolls to a valid one.
    final int desiredDay = DateTime(selectedYear, selectedMonth, selectedDay).day;
    if (desiredDay != selectedDay) {
      SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
        dayController.animateToItem(
          // The next valid date is also the amount of days overflown.
          dayController.selectedItem - desiredDay,
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

    switch (localizations.datePickerDateOrder) {
      case DatePickerDateOrder.mdy:
        pickerBuilders = <_ColumnBuilder>[_buildMonthPicker, _buildDayPicker, _buildYearPicker];
        columnWidths = <double>[
          estimatedColumnWidths[_PickerColumnType.month.index],
          estimatedColumnWidths[_PickerColumnType.dayOfMonth.index],
          estimatedColumnWidths[_PickerColumnType.year.index]];
        break;
      case DatePickerDateOrder.dmy:
        pickerBuilders = <_ColumnBuilder>[_buildDayPicker, _buildMonthPicker, _buildYearPicker];
        columnWidths = <double>[
          estimatedColumnWidths[_PickerColumnType.dayOfMonth.index],
          estimatedColumnWidths[_PickerColumnType.month.index],
          estimatedColumnWidths[_PickerColumnType.year.index]];
        break;
      case DatePickerDateOrder.ymd:
        pickerBuilders = <_ColumnBuilder>[_buildYearPicker, _buildMonthPicker, _buildDayPicker];
        columnWidths = <double>[
          estimatedColumnWidths[_PickerColumnType.year.index],
          estimatedColumnWidths[_PickerColumnType.month.index],
          estimatedColumnWidths[_PickerColumnType.dayOfMonth.index]];
        break;
      case DatePickerDateOrder.ydm:
        pickerBuilders = <_ColumnBuilder>[_buildYearPicker, _buildDayPicker, _buildMonthPicker];
        columnWidths = <double>[
          estimatedColumnWidths[_PickerColumnType.year.index],
          estimatedColumnWidths[_PickerColumnType.dayOfMonth.index],
          estimatedColumnWidths[_PickerColumnType.month.index]];
        break;
      default:
        assert(false, 'date order is not specified');
    }

    final List<Widget> pickers = <Widget>[];

    for (int i = 0; i < columnWidths.length; i++) {
      final double offAxisFraction = (i - 1) * 0.3 * textDirectionFactor;

      EdgeInsets padding = const EdgeInsets.only(right: _kDatePickerPadSize);
      if (textDirectionFactor == -1)
        padding = const EdgeInsets.only(left: _kDatePickerPadSize);

      pickers.add(LayoutId(
        id: i,
        child: pickerBuilders[i](
          offAxisFraction,
          (BuildContext context, Widget child) {
            return Container(
              alignment: i == columnWidths.length - 1
                  ? alignCenterLeft
                  : alignCenterRight,
              padding: i == 0 ? null : padding,
              child: Container(
                alignment: i == 0 ? alignCenterLeft : alignCenterRight,
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
              textDirectionFactor: textDirectionFactor,
            ),
            children: pickers,
          ),
        ),
      ),
    );
  }
}


// The iOS date picker and timer picker has their width fixed to 320.0 in all
// modes. The only exception is the hms mode (which doesn't have a native counterpart),
// with a fixed width of 330.0 px.
//
// For date pickers, if the maximum width given to the picker is greater than
// 320.0, the leftmost and rightmost column will be extended equally so that the
// widths match, and the picker is in the center.
//
// For timer pickers, if the maximum width given to the picker is greater than
// its intrinsic width, it will keep its intrinsic size and position itself in the
// parent using its alignment parameter.
//
// If the maximum width given to the picker is smaller than 320.0, the picker's
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
/// The picker has a fixed size of 320 x 216, in logical pixels, with the exception
/// of [CupertinoTimerPickerMode.hms], which is 330 x 216. If the parent widget
/// provides more space than it needs, the picker will position itself according
/// to its [alignment] property.
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
    Key key,
    this.mode = CupertinoTimerPickerMode.hms,
    this.initialTimerDuration = Duration.zero,
    this.minuteInterval = 1,
    this.secondInterval = 1,
    this.alignment = Alignment.center,
    this.backgroundColor = _kBackgroundColor,
    @required this.onTimerDurationChanged,
  }) : assert(mode != null),
       assert(onTimerDurationChanged != null),
       assert(initialTimerDuration >= Duration.zero),
       assert(initialTimerDuration < const Duration(days: 1)),
       assert(minuteInterval > 0 && 60 % minuteInterval == 0),
       assert(secondInterval > 0 && 60 % secondInterval == 0),
       assert(initialTimerDuration.inMinutes % minuteInterval == 0),
       assert(initialTimerDuration.inSeconds % secondInterval == 0),
       assert(backgroundColor != null),
       assert(alignment != null),
       super(key: key);

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

  /// Defines how the timper picker should be positioned within its parent.
  ///
  /// This property must not be null. It defaults to [Alignment.center].
  final AlignmentGeometry alignment;

  /// Background color of timer picker.
  ///
  /// Defaults to [CupertinoColors.white] when null.
  final Color backgroundColor;

  @override
  State<StatefulWidget> createState() => _CupertinoTimerPickerState();
}

class _CupertinoTimerPickerState extends State<CupertinoTimerPicker> {
  TextDirection textDirection;
  CupertinoLocalizations localizations;
  int get textDirectionFactor {
    switch (textDirection) {
      case TextDirection.ltr:
        return 1;
      case TextDirection.rtl:
        return -1;
    }
    return 1;
  }

  // The currently selected values of the picker.
  int selectedHour;
  int selectedMinute;
  int selectedSecond;

  // On iOS the selected values won't be reported until the scrolling fully stops.
  // The values below are the latest selected values when the picker comes to a full stop.
  int lastSelectedHour;
  int lastSelectedMinute;
  int lastSelectedSecond;

  final TextPainter textPainter = TextPainter();
  final List<String> numbers = List<String>.generate(10, (int i) => '${9 - i}');
  double numberLabelWidth;
  double numberLabelHeight;
  double numberLabelBaseline;

  @override
  void initState() {
    super.initState();

    selectedMinute = widget.initialTimerDuration.inMinutes % 60;

    if (widget.mode != CupertinoTimerPickerMode.ms)
      selectedHour = widget.initialTimerDuration.inHours;

    if (widget.mode != CupertinoTimerPickerMode.hm)
      selectedSecond = widget.initialTimerDuration.inSeconds % 60;
  }

  @override
  void didUpdateWidget(CupertinoTimerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    assert(
      oldWidget.mode == widget.mode,
      "The CupertinoTimerPicker's mode cannot change once it's built",
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirection = Directionality.of(context);
    localizations = CupertinoLocalizations.of(context);

    textPainter.textDirection = textDirection;
    final TextStyle textStyle = _textStyleFrom(context);

    double maxWidth = double.negativeInfinity;
    String widestNumber;

    // Assumes that:
    // - 2-digit numbers are always wider than 1-digit numbers.
    // - There's at least one number in 1-9 that's wider than or equal to 0.
    // - The widest 2-digit number is composed of 2 same 1-digit numbers
    //   that has the biggest width.
    // - If two different 1-digit numbers are of the same width, their corresponding
    //   2 digit numbers are of the same width.
    for (String input in numbers) {
      textPainter.text = TextSpan(
        text: input,
        style: textStyle
      );
      textPainter.layout();

      if (textPainter.maxIntrinsicWidth > maxWidth) {
        maxWidth = textPainter.maxIntrinsicWidth;
        widestNumber = input;
      }
    }

    textPainter.text = TextSpan(
      text: '$widestNumber$widestNumber',
      style: textStyle
    );

    textPainter.layout();
    numberLabelWidth = textPainter.maxIntrinsicWidth;
    numberLabelHeight = textPainter.height;
    numberLabelBaseline = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  }

  // Builds a text label with scale factor 1.0 and font weight semi-bold.
  // `pickerPadding ` is the additional padding the corresponding picker has to apply
  // around the `Text`, in order to extend its separators towards the closest
  // horizontal edge of the encompassing widget.
  Widget _buildLabel(String text, EdgeInsetsDirectional pickerPadding) {
    final EdgeInsetsDirectional padding = EdgeInsetsDirectional.only(
      start: numberLabelWidth
           + _kTimerPickerLabelPadSize
           + pickerPadding.start,
    );

    return IgnorePointer(
      child: Container(
        alignment: AlignmentDirectional.centerStart.resolve(textDirection),
        padding: padding.resolve(textDirection),
        child: SizedBox(
          height: numberLabelHeight,
          child: Baseline(
            baseline: numberLabelBaseline,
            baselineType: TextBaseline.alphabetic,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: _kTimerPickerLabelFontSize,
                fontWeight: FontWeight.w600
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
      ),
    );
  }

  // The picker has to be wider than its content, since the separators
  // are part of the picker.
  Widget _buildPickerNumberLabel(String text, EdgeInsetsDirectional padding) {
    return Container(
      width: _kTimerPickerColumnIntrinsicWidth + padding.horizontal,
      padding: padding.resolve(textDirection),
      alignment: AlignmentDirectional.centerStart.resolve(textDirection),
      child: Container(
        width: numberLabelWidth,
        alignment: AlignmentDirectional.centerEnd.resolve(textDirection),
        child: Text(text, softWrap: false, maxLines: 1, overflow: TextOverflow.visible),
      ),
    );
  }

  Widget _buildHourPicker(EdgeInsetsDirectional additionalPadding) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: selectedHour),
      offAxisFraction: -0.5 * textDirectionFactor,
      itemExtent: _kItemExtent,
      backgroundColor: widget.backgroundColor,
      squeeze: _kSqueeze,
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
        final String semanticsLabel = textDirectionFactor == 1
          ? localizations.timerPickerHour(index) + localizations.timerPickerHourLabel(index)
          : localizations.timerPickerHourLabel(index) + localizations.timerPickerHour(index);

        return Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          child: _buildPickerNumberLabel(localizations.timerPickerHour(index), additionalPadding),
        );
      }),
    );
  }

  Widget _buildHourColumn(EdgeInsetsDirectional additionalPadding) {
    return Stack(
      children: <Widget>[
        NotificationListener<ScrollEndNotification>(
          onNotification: (ScrollEndNotification notification) {
            setState(() { lastSelectedHour = selectedHour; });
            return false;
          },
          child: _buildHourPicker(additionalPadding),
        ),
        _buildLabel(
          localizations.timerPickerHourLabel(lastSelectedHour ?? selectedHour),
          additionalPadding
        ),
      ],
    );
  }

  Widget _buildMinutePicker(EdgeInsetsDirectional additionalPadding) {
    double offAxisFraction;
    switch (widget.mode) {
      case CupertinoTimerPickerMode.hm:
        offAxisFraction = 0.5 * textDirectionFactor;
        break;
      case CupertinoTimerPickerMode.hms:
        offAxisFraction = 0.0;
        break;
      case CupertinoTimerPickerMode.ms:
        offAxisFraction = -0.5 * textDirectionFactor;
    }

    return CupertinoPicker(
      scrollController: FixedExtentScrollController(
        initialItem: selectedMinute ~/ widget.minuteInterval,
      ),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      backgroundColor: widget.backgroundColor,
      squeeze: _kSqueeze,
      looping: true,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedMinute = index * widget.minuteInterval;
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

        return Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          child: _buildPickerNumberLabel(localizations.timerPickerMinute(minute), additionalPadding),
        );
      }),
    );
  }

  Widget _buildMinuteColumn(EdgeInsetsDirectional additionalPadding) {
    return Stack(
      children: <Widget>[
        NotificationListener<ScrollEndNotification>(
          onNotification: (ScrollEndNotification notification) {
            setState(() { lastSelectedMinute = selectedMinute; });
            return false;
          },
          child: _buildMinutePicker(additionalPadding),
        ),
        _buildLabel(
          localizations.timerPickerMinuteLabel(lastSelectedMinute ?? selectedMinute),
          additionalPadding,
        ),
      ],
    );
  }

  Widget _buildSecondPicker(EdgeInsetsDirectional additionalPadding) {
    final double offAxisFraction = 0.5 * textDirectionFactor;

    return CupertinoPicker(
      scrollController: FixedExtentScrollController(
        initialItem: selectedSecond ~/ widget.secondInterval,
      ),
      offAxisFraction: offAxisFraction,
      itemExtent: _kItemExtent,
      backgroundColor: widget.backgroundColor,
      squeeze: _kSqueeze,
      looping: true,
      onSelectedItemChanged: (int index) {
        setState(() {
          selectedSecond = index * widget.secondInterval;
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
          child: _buildPickerNumberLabel(localizations.timerPickerSecond(second), additionalPadding),
        );
      }),
    );
  }

  Widget _buildSecondColumn(EdgeInsetsDirectional additionalPadding) {
    return Stack(
      children: <Widget>[
        NotificationListener<ScrollEndNotification>(
          onNotification: (ScrollEndNotification notification) {
            setState(() { lastSelectedSecond = selectedSecond; });
            return false;
          },
          child: _buildSecondPicker(additionalPadding),
        ),
        _buildLabel(
          localizations.timerPickerSecondLabel(lastSelectedSecond ?? selectedSecond),
          additionalPadding,
        ),
      ],
    );
  }

  TextStyle _textStyleFrom(BuildContext context) {
    return CupertinoTheme.of(context).textTheme
      .pickerTextStyle.merge(
        const TextStyle(
          fontSize: _kTimerPickerNumberLabelFontSize,
        )
      );
  }

  @override
  Widget build(BuildContext context) {
    // The timer picker can be divided into columns corresponding to hour,
    // minute, and second. Each column consists of a scrollable and a fixed
    // label on top of it.

    List<Widget> columns;
    const double paddingValue = _kPickerWidth - 2 * _kTimerPickerColumnIntrinsicWidth - 2 * _kTimerPickerHalfColumnPadding;
    // The default totalWidth for 2-column modes.
    double totalWidth = _kPickerWidth;
    assert(paddingValue >= 0);

    switch (widget.mode) {
      case CupertinoTimerPickerMode.hm:
        // Pad the widget to make it as wide as `_kPickerWidth`.
        columns = <Widget>[
          _buildHourColumn(const EdgeInsetsDirectional.only(start: paddingValue / 2, end: _kTimerPickerHalfColumnPadding)),
          _buildMinuteColumn(const EdgeInsetsDirectional.only(start: _kTimerPickerHalfColumnPadding, end: paddingValue / 2))
        ];
        break;
      case CupertinoTimerPickerMode.ms:
        // Pad the widget to make it as wide as `_kPickerWidth`.
        columns = <Widget>[
          _buildMinuteColumn(const EdgeInsetsDirectional.only(start: paddingValue / 2, end: _kTimerPickerHalfColumnPadding)),
          _buildSecondColumn(const EdgeInsetsDirectional.only(start: _kTimerPickerHalfColumnPadding, end: paddingValue / 2))
        ];
        break;
      case CupertinoTimerPickerMode.hms:
        const double paddingValue = _kTimerPickerHalfColumnPadding * 2;
        totalWidth = _kTimerPickerColumnIntrinsicWidth * 3 + 4 * _kTimerPickerHalfColumnPadding + paddingValue;
        columns = <Widget>[
          _buildHourColumn(const EdgeInsetsDirectional.only(start: paddingValue / 2, end: _kTimerPickerHalfColumnPadding)),
          _buildMinuteColumn(const EdgeInsetsDirectional.only(start: _kTimerPickerHalfColumnPadding, end: _kTimerPickerHalfColumnPadding)),
          _buildSecondColumn(const EdgeInsetsDirectional.only(start: _kTimerPickerHalfColumnPadding, end: paddingValue / 2))
        ];
        break;
    }
    final CupertinoThemeData themeData = CupertinoTheme.of(context);
    return MediaQuery(
      data: const MediaQueryData(
        // The native iOS picker's text scaling is fixed, so we will also fix it
        // as well in our picker.
        textScaleFactor: 1.0,
      ),
      child: CupertinoTheme(
        data: themeData.copyWith(
          textTheme: themeData.textTheme.copyWith(
            pickerTextStyle: _textStyleFrom(context),
          )
        ),
        child: Align(
          alignment: widget.alignment,
          child: Container(
            color: _kBackgroundColor,
            width: totalWidth,
            height: _kPickerHeight,
            child: DefaultTextStyle(
              style: _textStyleFrom(context),
              child: Row(children: columns.map((Widget child) => Expanded(child: child)).toList(growable: false)),
            ),
          ),
        ),
      ),
    );
  }
}
