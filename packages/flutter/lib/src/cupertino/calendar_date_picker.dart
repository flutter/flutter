// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'date.dart';
import 'debug.dart';
import 'icons.dart';
import 'localizations.dart';
import 'picker.dart';
import 'text_theme.dart';
import 'theme.dart';

const double _kItemExtent = 32.0;
const bool _kUseMagnifier = true;
const double _kMagnification = 2.35/2.30;
const double _kDatePickerPadSize = 12.0;
const double _kSqueeze = 1.25;

TextStyle _themeTextStyle(BuildContext context, { bool isValid = true }) {
  final TextStyle style = CupertinoTheme.of(context).textTheme.dateTimePickerTextStyle;
  return isValid ? style : style.copyWith(color: CupertinoDynamicColor.resolve(CupertinoColors.inactiveGray, context));
}

const TextStyle _kDefaultPickerTextStyle = TextStyle(
  letterSpacing: -0.83,
);

// Different types of column in CupertinoCalendarPicker.
enum _PickerColumnType {
  // Month column in date mode.
  month,
  // Year column in date mode.
  year,
}

void _animateColumnControllerToItem(FixedExtentScrollController controller, int targetItem) {
  controller.animateToItem(
    targetItem,
    curve: Curves.easeInOut,
    duration: const Duration(milliseconds: 200),
  );
}

const Widget _leftSelectionOverlay = CupertinoPickerDefaultSelectionOverlay(capRightEdge: false);
const Widget _centerSelectionOverlay = CupertinoPickerDefaultSelectionOverlay(capLeftEdge: false, capRightEdge: false);
const Widget _rightSelectionOverlay = CupertinoPickerDefaultSelectionOverlay(capLeftEdge: false);

const int _maxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// One extra row for the day-of-week header.
const double _dayPickerRowHeight = 47.0;
const double _dayPickerRowHeightTall = 55.0;
const Duration _monthScrollDuration = Duration(milliseconds: 200);

/// A graphical date picker widget in iOS style.
///
/// Displays a grid of days for a given month and allows the user to select a
/// date.
///
/// Days are arranged in a rectangular grid with one column for each day of the
/// week. Controls are provided to change between day grid and month/year selection
/// wheel.
///
/// This calendar is one of the picker styles of [CupertinoDatePicker].
/// Which by default displays wheel style calendar picker.
///
/// See also:
///
///  * [CupertinoDatePicker], A date picker widget in iOS style.
///
class CupertinoCalendarPicker extends StatefulWidget {
  /// Creates a calendar date picker.
  ///
  /// It will display a grid of days for the [initialDate]'s month. The day
  /// indicated by [initialDate] will be selected.
  ///
  /// The optional [onDisplayedMonthChanged] callback can be used to track
  /// the currently displayed month.
  ///
  /// The user interface provides a way to change the month and year being
  /// displayed. By default it will show the day grid, but this can be changed
  /// to start in the year selection interface with [initialCalendarMode] set
  /// to [CalendarPickerMode.year].
  ///
  /// The [onDateChanged], and  [initialCalendarMode] must be non-null.
  ///
  /// [maximumDate] must be after or equal to [minimumDate].
  ///
  /// [initialDate] must be between [minimumDate] and [maximumDate] or equal to
  /// one of them.
  ///
  CupertinoCalendarPicker({
    Key? key,
    this.initialCalendarMode = CalendarPickerMode.day,
    required this.onDateChanged,
    DateTime? initialDate,
    this.onDisplayedMonthChanged,
  }) : initialDate = initialDate ?? DateTime.now(),
       minimumDate = DateTime(1900),
       maximumDate = DateTime(2100),
       assert(initialCalendarMode != null),
       assert(onDateChanged != null),
       super(key: key) {
    assert(this.initialDate != null);
  }

  /// The initially selected [DateTime] that the picker should display.
  final CalendarPickerMode initialCalendarMode;

  /// The earliest allowable [DateTime] that the user can select.
  final DateTime initialDate;

  /// The earliest allowable [DateTime] that the user can select.
  final DateTime? minimumDate;

  /// The latest allowable [DateTime] that the user can select.
  final DateTime? maximumDate;

  /// Called when the user change a date in the picker.
  final ValueChanged<DateTime> onDateChanged;

  /// Called when the user navigates to a new month/year in the picker.
  final ValueChanged<DateTime>? onDisplayedMonthChanged;

  @override
  State<CupertinoCalendarPicker> createState() => _CupertinoCalendarPickerState();
}

class _CupertinoCalendarPickerState extends State<CupertinoCalendarPicker> {
  bool _announcedInitialDate = false;
  late CalendarPickerMode _mode;
  late DateTime _currentDisplayedMonthDate;
  late DateTime _selectedDate;
  final GlobalKey _monthPickerKey = GlobalKey();
  final GlobalKey _yearPickerKey = GlobalKey();
  late CupertinoLocalizations _localizations;
  late TextDirection _textDirection;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialCalendarMode;
    _currentDisplayedMonthDate = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  @override
  void didUpdateWidget(CupertinoCalendarPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCalendarMode != oldWidget.initialCalendarMode) {
      _mode = widget.initialCalendarMode;
    }
    if (!DateUtils.isSameDay(widget.initialDate, oldWidget.initialDate)) {
      _currentDisplayedMonthDate = DateTime(widget.initialDate.year, widget.initialDate.month);
      _selectedDate = widget.initialDate;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasCupertinoLocalizations(context));
    assert(debugCheckHasDirectionality(context));
    _localizations = CupertinoLocalizations.of(context);
    _textDirection = Directionality.of(context);
    if (!_announcedInitialDate) {
      _announcedInitialDate = true;
      SemanticsService.announce(
        _localizations.formatFullDate(_selectedDate),
        _textDirection,
      );
    }
  }

  void _handleModeChanged(CalendarPickerMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  void _handleYearChanged(DateTime value) {
    if (value.isBefore(widget.minimumDate!)) {
      value = widget.minimumDate!;
    } else if (value.isAfter(widget.maximumDate!)) {
      value = widget.maximumDate!;
    }

    setState(() {
    _selectedDate = DateTime(value.year, value.month, _selectedDate.day);
    _handleMonthChanged(value);
    widget.onDateChanged.call(_selectedDate);
    });
  }

  void _handleMonthDayChanged(DateTime value) {
    setState(() {
      _selectedDate = value;
      widget.onDateChanged.call(_selectedDate);
    });
  }

  void _handleMonthChanged(DateTime date) {
    setState(() {
      if (_currentDisplayedMonthDate.year != date.year || _currentDisplayedMonthDate.month != date.month) {
        _currentDisplayedMonthDate = DateTime(date.year, date.month);
        widget.onDisplayedMonthChanged?.call(_currentDisplayedMonthDate);
      }
    });
  }

  Widget _buildPicker() {
    switch (_mode) {
      case CalendarPickerMode.day:
        return _MonthPicker(
          key: _monthPickerKey,
          initialMonth: _currentDisplayedMonthDate,
          currentDate: DateUtils.dateOnly(widget.initialDate),
          minimumDate: widget.minimumDate!,
          maximumDate: widget.maximumDate!,
          selectedDate: _selectedDate,
          onChanged: _handleMonthDayChanged,
          onDisplayedMonthChanged: _handleMonthChanged,
        );
      case CalendarPickerMode.year:
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 110.0),
            child: SizedBox(
              height: 160,
              child: _YearPicker(
                key: _yearPickerKey,
                initialDate: DateUtils.monthYearOnly(_currentDisplayedMonthDate),
                minimumDate: DateUtils.monthYearOnly(widget.minimumDate!),
                maximumDate: DateUtils.monthYearOnly(widget.maximumDate!),
                onChanged: _handleYearChanged,
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasCupertinoLocalizations(context));
    assert(debugCheckHasDirectionality(context));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 344,
        child: Stack(
          children: <Widget>[
              _buildPicker(),
              _CalendarPickerModeToggleButton(
                mode: _mode,
                title: '${_localizations.datePickerMonth(_currentDisplayedMonthDate.month) } ${_localizations.datePickerYear(_currentDisplayedMonthDate.year)}',
                onTitlePressed: () {
                  _handleModeChanged(_mode == CalendarPickerMode.day ? CalendarPickerMode.year : CalendarPickerMode.day);
                },
              )
          ],
        ),
      ),
    );
  }
}

/// A button that used to toggle the [CalendarPickerMode] for a date picker.
///
/// This appears above the calendar grid and allows the user to toggle the
/// [CalendarPickerMode] to display either the calendar view or the month/year wheel.
class _CalendarPickerModeToggleButton extends StatefulWidget {
  const _CalendarPickerModeToggleButton({
    required this.mode,
    required this.title,
    required this.onTitlePressed,
  });

  /// The current display of the calendar picker.
  final CalendarPickerMode mode;

  /// The text that displays the current month/year being viewed.
  final String title;

  /// The callback when the title is pressed.
  final VoidCallback onTitlePressed;

  @override
  State<_CalendarPickerModeToggleButton> createState() => _CalendarPickerModeToggleButtonState();
}

class _CalendarPickerModeToggleButtonState extends State<_CalendarPickerModeToggleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: widget.mode == CalendarPickerMode.year ? 0.25 : 0,
      upperBound: 0.25,
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CalendarPickerModeToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode == widget.mode) {
      return;
    }

    if (widget.mode == CalendarPickerMode.year) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =  CupertinoTheme.of(context).textTheme.navTitleTextStyle;
    const Color controlColor =  CupertinoColors.activeBlue;

    return Container(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 4),
      child: Row(
        children: <Widget>[
          Flexible(
            child: SizedBox(
              height: 34,
              child: GestureDetector(
                onTap: widget.onTitlePressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: <Widget>[
                        Flexible(
                          child: Text(
                            widget.title,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle.copyWith(
                              color: widget.mode == CalendarPickerMode.year ? controlColor : null,
                            ),
                          ),
                        ),
                        RotationTransition(
                          turns: _controller,
                          child: const Padding(
                            padding:  EdgeInsets.only(left: 4),
                            child: Align(
                              child: Icon(
                                CupertinoIcons.chevron_right,
                                color: controlColor,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.mode == CalendarPickerMode.day)
            // Give space for the prev/next month buttons that are underneath this row
            const SizedBox(width: 60),
        ],
      ),
    );
  }
}

///
class _DatePickerLayoutDelegate extends MultiChildLayoutDelegate {
  _DatePickerLayoutDelegate({
    required this.columnWidths,
    required this.textDirectionFactor,
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

class _YearPicker extends StatefulWidget {
  _YearPicker({
    Key? key,
    required this.onChanged,
    DateTime? initialDate,
    this.minimumDate,
    this.maximumDate,
    this.minimumYear = 1,
    this.maximumYear,
  }) : initialDate = initialDate ?? DateTime.now(),
       assert(minimumYear != null),
       super(key: key) {
    assert(this.initialDate != null);
    assert(
      minimumDate == null || !this.initialDate.isBefore(minimumDate!),
      'initial date is before minimum date',
    );
    assert(
      maximumDate == null || !this.initialDate.isAfter(maximumDate!),
      'initial date is after maximum date',
    );
    assert(
      minimumYear >= 1 && this.initialDate.year >= minimumYear,
      'initial year is not greater than minimum year, or minimum year is not positive',
    );
    assert(
      maximumYear == null || this.initialDate.year <= maximumYear!,
      'initial year is not smaller than maximum year',
    );
    assert(
      minimumDate == null || !minimumDate!.isAfter(this.initialDate),
      'initial date ${this.initialDate} is not greater than or equal to minimumDate $minimumDate',
    );
    assert(
      maximumDate == null || !maximumDate!.isBefore(this.initialDate),
      'initial date ${this.initialDate} is not less than or equal to maximumDate $maximumDate',
    );
  }

  /// The initial month to display.
  final DateTime initialDate;

  /// The earliest date the user is permitted to pick.
  ///
  /// This date must be on or before the [minimumDate].
  final DateTime? minimumDate;

  /// The latest date the user is permitted to pick.
  ///
  /// This date must be on or after the [maximumDate].
  final DateTime? maximumDate;

  /// Minimum year that the picker can be scrolled to in
  /// [CalendarPickerMode.year] mode. Defaults to 1 and must not be null.
  final int minimumYear;

  /// Maximum year that the picker can be scrolled to in
  /// [CalendarPickerMode.year] mode.
  final int? maximumYear;

  /// Called when the user picks a year.
  final ValueChanged<DateTime> onChanged;

  @override
  _YearPickerState createState() => _YearPickerState();

  // Estimate the minimum width that each column needs to layout its content.
  static double _getColumnWidth(
    _PickerColumnType columnType,
    CupertinoLocalizations localizations,
    BuildContext context,
  ) {
    String longestText = '';

    switch (columnType) {
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

typedef _ColumnBuilder = Widget Function(double offAxisFraction, TransitionBuilder itemPositioningBuilder, Widget selectionOverlay);

class _YearPickerState extends State<_YearPicker> {
  late int textDirectionFactor;
  late CupertinoLocalizations localizations;

  // Alignment based on text direction. The variable name is self descriptive,
  // however, when text direction is rtl, alignment is reversed.
  late Alignment alignCenterLeft;
  late Alignment alignCenterRight;

  // The currently selected values of the picker.
  late int selectedMonth;
  late int selectedYear;

  // The controller of the month/year picker.
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController yearController;

  bool isMonthPickerScrolling = false;
  bool isYearPickerScrolling = false;

  bool get isScrolling => isMonthPickerScrolling || isYearPickerScrolling;

  // Estimated width of columns.
  Map<int, double> estimatedColumnWidths = <int, double>{};

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.initialDate.month;
    selectedYear = widget.initialDate.year;

    monthController = FixedExtentScrollController(initialItem: selectedMonth - 1);
    yearController = FixedExtentScrollController(initialItem: selectedYear);

    PaintingBinding.instance!.systemFonts.addListener(_handleSystemFontsChange);
  }

  void _handleSystemFontsChange() {
    setState(() {
      // System fonts change might cause the text layout width to change.
      _refreshEstimatedColumnWidths();
    });
  }

  @override
  void dispose() {
    monthController.dispose();
    yearController.dispose();

    PaintingBinding.instance!.systemFonts.removeListener(_handleSystemFontsChange);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirectionFactor = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    localizations = CupertinoLocalizations.of(context);

    alignCenterLeft = textDirectionFactor == 1 ? Alignment.centerLeft : Alignment.centerRight;
    alignCenterRight = textDirectionFactor == 1 ? Alignment.centerRight : Alignment.centerLeft;

    _refreshEstimatedColumnWidths();
  }

  void _refreshEstimatedColumnWidths() {
    estimatedColumnWidths[_PickerColumnType.month.index] = _YearPicker._getColumnWidth(_PickerColumnType.month, localizations, context);
    estimatedColumnWidths[_PickerColumnType.year.index] = _YearPicker._getColumnWidth(_PickerColumnType.year, localizations, context);
  }

  Widget _buildMonthPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder, Widget selectionOverlay) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          isMonthPickerScrolling = true;
        } else if (notification is ScrollEndNotification) {
          isMonthPickerScrolling = false;
          _pickerDidStopScrolling();
        }

        return false;
      },
      child: CupertinoPicker(
        scrollController: monthController,
        offAxisFraction: offAxisFraction,
        itemExtent: _kItemExtent,
        useMagnifier: _kUseMagnifier,
        magnification: _kMagnification,
        squeeze: _kSqueeze,
        onSelectedItemChanged: (int index) {
          selectedMonth = index + 1;
        },
        looping: true,
        selectionOverlay: selectionOverlay,
        children: List<Widget>.generate(12, (int index) {
          final int month = index + 1;
          final bool isInvalidMonth = (widget.minimumDate?.year == selectedYear && widget.minimumDate!.month > month)
                                   || (widget.maximumDate?.year == selectedYear && widget.maximumDate!.month < month);

          return itemPositioningBuilder(
            context,
            Text(
              localizations.datePickerMonth(month),
              style: _themeTextStyle(context, isValid: !isInvalidMonth),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildYearPicker(double offAxisFraction, TransitionBuilder itemPositioningBuilder, Widget selectionOverlay) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          isYearPickerScrolling = true;
        } else if (notification is ScrollEndNotification) {
          isYearPickerScrolling = false;
          _pickerDidStopScrolling();
        }

        return false;
      },
      child: CupertinoPicker.builder(
        scrollController: yearController,
        itemExtent: _kItemExtent,
        offAxisFraction: offAxisFraction,
        squeeze: _kSqueeze,
        useMagnifier: _kUseMagnifier,
        magnification: _kMagnification,
        onSelectedItemChanged: (int index) {
          selectedYear = index;
        },
        itemBuilder: (BuildContext context, int year) {
          if (year < widget.minimumYear)
            return null;

          if (widget.maximumYear != null && year > widget.maximumYear!)
            return null;

          final bool isValidYear = (widget.minimumDate == null || widget.minimumDate!.year <= year)
                                && (widget.maximumDate == null || widget.maximumDate!.year >= year);

          return itemPositioningBuilder(
            context,
            Text(
              localizations.datePickerYear(year),
              style: _themeTextStyle(context, isValid: isValidYear),
            ),
          );
        },
        selectionOverlay: selectionOverlay,
      ),
    );
  }

  bool get _isCurrentDateValid {
    // The current date selection represents a range [minSelectedData, maxSelectDate].
    final DateTime minSelectedDate = DateTime(selectedYear, selectedMonth);
    final DateTime maxSelectedDate = DateTime(selectedYear, selectedMonth + 1);

    final bool minCheck = widget.minimumDate?.isBefore(maxSelectedDate) ?? true;
    final bool maxCheck = widget.maximumDate?.isBefore(minSelectedDate) ?? false;

    return minCheck && !maxCheck;
  }

  // One or more pickers have just stopped scrolling.
  void _pickerDidStopScrolling() {
    // Call setState to update the greyed out date.
    setState(() { });

    if (isScrolling) {
      return;
    }

    if (_isCurrentDateValid)
      widget.onChanged(DateTime(selectedYear, selectedMonth));

    // Whenever scrolling lands on an invalid entry, the picker
    // automatically scrolls to a valid one.
    final DateTime minSelectDate = DateTime(selectedYear, selectedMonth);
    final DateTime maxSelectDate = DateTime(selectedYear, selectedMonth + 1);

    final bool minCheck = widget.minimumDate?.isBefore(maxSelectDate) ?? true;
    final bool maxCheck = widget.maximumDate?.isBefore(minSelectDate) ?? false;

    if (!minCheck || maxCheck) {
      // We have minCheck === !maxCheck.
      final DateTime targetDate = minCheck ? widget.maximumDate! : widget.minimumDate!;
      _scrollToDate(targetDate);
      return;
    }
  }

  void _scrollToDate(DateTime newDate) {
    assert(newDate != null);
    SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
      if (selectedYear != newDate.year) {
        _animateColumnControllerToItem(yearController, newDate.year);
      }

      if (selectedMonth != newDate.month) {
        _animateColumnControllerToItem(monthController, newDate.month - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<_ColumnBuilder> pickerBuilders = <_ColumnBuilder>[_buildMonthPicker, _buildYearPicker];

    // Widths of the columns in this picker, ordered from left to right.
    final List<double> columnWidths  = <double>[
      estimatedColumnWidths[_PickerColumnType.month.index]!,
      estimatedColumnWidths[_PickerColumnType.year.index]!,
    ];

    final List<Widget> pickers = <Widget>[];

    for (int i = 0; i < columnWidths.length; i++) {
      final double offAxisFraction = (i - 1) * 0.3 * textDirectionFactor;

      EdgeInsets padding = const EdgeInsets.only(right: _kDatePickerPadSize);
      if (textDirectionFactor == -1)
        padding = const EdgeInsets.only(left: _kDatePickerPadSize);

      Widget selectionOverlay = _centerSelectionOverlay;
      if (i == 0)
        selectionOverlay = _leftSelectionOverlay;
      else if (i == columnWidths.length - 1)
        selectionOverlay = _rightSelectionOverlay;

      pickers.add(LayoutId(
        id: i,
        child: pickerBuilders[i](
          offAxisFraction,
          (BuildContext context, Widget? child) {
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
          selectionOverlay,
        ),
      ));
    }

    final double totalWidth = columnWidths.reduce((double a, double b) => a + b);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: DefaultTextStyle.merge(
        style: _kDefaultPickerTextStyle,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: totalWidth + (_kDatePickerPadSize * columnWidths.length) + 80),
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

///
class _FocusedDate extends InheritedWidget {
  const _FocusedDate({
    Key? key,
    required Widget child,
    this.date,
  }) : super(key: key, child: child);

  final DateTime? date;

  @override
  bool updateShouldNotify(_FocusedDate oldWidget) {
    return !DateUtils.isSameDay(date, oldWidget.date);
  }

  static DateTime? of(BuildContext context) {
    final _FocusedDate? focusedDate = context.dependOnInheritedWidgetOfExactType<_FocusedDate>();
    return focusedDate?.date;
  }
}

class _MonthPicker extends StatefulWidget {
  /// Creates a month picker.
  _MonthPicker({
    Key? key,
    required this.initialMonth,
    required this.currentDate,
    required this.minimumDate,
    required this.maximumDate,
    required this.selectedDate,
    required this.onChanged,
    required this.onDisplayedMonthChanged,
  }) : assert(selectedDate != null),
       assert(currentDate != null),
       assert(onChanged != null),
       assert(minimumDate != null),
       assert(maximumDate!= null),
       assert(!minimumDate.isAfter(maximumDate)),
       assert(!selectedDate.isBefore(minimumDate)),
       assert(!selectedDate.isAfter(maximumDate)),
       super(key: key);

  /// The initial month to display.
  final DateTime initialMonth;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// The earliest date the user is permitted to pick.
  ///
  /// This date must be on or before the [minimumDate].
  final DateTime minimumDate;

  /// The latest date the user is permitted to pick.
  ///
  /// This date must be on or after the [maximumDate].
  final DateTime maximumDate;

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a year.
  final ValueChanged<DateTime> onChanged;

  /// Called when the user navigates to a new month/year in the picker.
  final ValueChanged<DateTime> onDisplayedMonthChanged;

  @override
  __MonthPickerState createState() => __MonthPickerState();
}

class __MonthPickerState extends State<_MonthPicker> {
  final GlobalKey _pageViewKey = GlobalKey();
  late DateTime _currentMonth;
  late DateTime _nextMonthDate;
  late DateTime _previousMonthDate;
  late PageController _pageController;
  late CupertinoLocalizations _localizations;
  late TextDirection _textDirection;
  Map<ShortcutActivator, Intent>? _shortcutMap;
  Map<Type, Action<Intent>>? _actionMap;
  late FocusNode _dayGridFocus;
  DateTime? _focusedDay;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
    _previousMonthDate = DateUtils.addMonthsToMonthDate(_currentMonth, -1);
    _nextMonthDate = DateUtils.addMonthsToMonthDate(_currentMonth, 1);
    _pageController = PageController(initialPage: DateUtils.monthDelta(widget.minimumDate, _currentMonth));
    _shortcutMap = const <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
      SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
      SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
      SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
    };
    _actionMap = <Type, Action<Intent>>{
      NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: _handleGridNextFocus),
      PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: _handleGridPreviousFocus),
      DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(onInvoke: _handleDirectionFocus),
    };
    _dayGridFocus = FocusNode(debugLabel: 'Day Grid');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = CupertinoLocalizations.of(context);
    _textDirection = Directionality.of(context);
  }

  @override
  void didUpdateWidget(_MonthPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth != oldWidget.initialMonth && widget.initialMonth != _currentMonth) {
      // We can't interrupt this widget build with a scroll, so do it next frame
      WidgetsBinding.instance!.addPostFrameCallback(
        (Duration timeStamp) => _showMonth(widget.initialMonth, jump: true),
      );
    }
  }

  void _handleDateSelected(DateTime selectedDate) {
    _focusedDay = selectedDate;
    widget.onChanged(selectedDate);
  }

  void _handleMonthPageChanged(int monthPage) {
    setState(() {
      final DateTime monthDate = DateUtils.addMonthsToMonthDate(widget.minimumDate, monthPage);
      if (!DateUtils.isSameMonth(_currentMonth, monthDate)) {
        _currentMonth = DateTime(monthDate.year, monthDate.month);
        _previousMonthDate = DateUtils.addMonthsToMonthDate(_currentMonth, -1);
        _nextMonthDate = DateUtils.addMonthsToMonthDate(_currentMonth, 1);
        widget.onDisplayedMonthChanged(_currentMonth);
        if (_focusedDay != null && !DateUtils.isSameMonth(_focusedDay, _currentMonth)) {
          // We have navigated to a new month with the grid focused, but the
          // focused day is not in this month. Choose a new one trying to keep
          // the same day of the month.
          _focusedDay = _focusableDayForMonth(_currentMonth, _focusedDay!.day);
        }
      }
    });
  }
  ///
  DateTime? _focusableDayForMonth(DateTime month, int preferredDay) {}

  /// Navigate to the next month.
  void _handleNextMonth() {
    if (!_isDisplayingLastMonth) {
      SemanticsService.announce(
        _localizations.formatMonthYear(_nextMonthDate),
        _textDirection,
      );
      _pageController.nextPage(
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  /// Navigate to the given month.
  void _showMonth(DateTime month, { bool jump = false}) {
    final int monthPage = DateUtils.monthDelta(widget.minimumDate, month);
    if (jump) {
      _pageController.jumpToPage(monthPage);
    } else {
      _pageController.animateToPage(
        monthPage,
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  /// True if the earliest allowable month is displayed.
  bool get _isDisplayingFirstMonth {
    return !_currentMonth.isAfter(
      DateTime(widget.minimumDate.year, widget.minimumDate.month),
    );
  }

  /// True if the latest allowable month is displayed.
  bool get _isDisplayingLastMonth {
    return !_currentMonth.isBefore(
      DateTime(widget.maximumDate.year, widget.maximumDate.month),
    );
  }

  /// Navigate to the previous month.
  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
        _localizations.formatMonthYear(_previousMonthDate),
        _textDirection,
      );
      _pageController.previousPage(
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  /// Handler for when the overall day grid obtains or loses focus.
  void _handleGridFocusChange(bool focused) {
    setState(() {
      if (focused && _focusedDay == null) {
        if (DateUtils.isSameMonth(widget.selectedDate, _currentMonth)) {
          _focusedDay = widget.selectedDate;
        } else if (DateUtils.isSameMonth(widget.currentDate, _currentMonth)) {
          _focusedDay = _focusableDayForMonth(_currentMonth, widget.currentDate.day);
        } else {
          _focusedDay = _focusableDayForMonth(_currentMonth, 1);
        }
      }
    });
  }

  /// Move focus to the next element after the day grid.
  void _handleGridNextFocus(NextFocusIntent intent) {
    _dayGridFocus.requestFocus();
    _dayGridFocus.nextFocus();
  }

  /// Move focus to the previous element before the day grid.
  void _handleGridPreviousFocus(PreviousFocusIntent intent) {
    _dayGridFocus.requestFocus();
    _dayGridFocus.previousFocus();
  }

  /// Move the internal focus date in the direction of the given intent.
  ///
  /// This will attempt to move the focused day to the next selectable day in
  /// the given direction. If the new date is not in the current month, then
  /// the page view will be scrolled to show the new date's month.
  ///
  /// For horizontal directions, it will move forward or backward a day (depending
  /// on the current [TextDirection]). For vertical directions it will move up and
  /// down a week at a time.
  void _handleDirectionFocus(DirectionalFocusIntent intent) {
    assert(_focusedDay != null);
    setState(() {
      final DateTime? nextDate = _nextDateInDirection(_focusedDay!, intent.direction);
      if (nextDate != null) {
        _focusedDay = nextDate;
        if (!DateUtils.isSameMonth(_focusedDay, _currentMonth)) {
          _showMonth(_focusedDay!);
        }
      }
    });
  }

  static const Map<TraversalDirection, int> _directionOffset = <TraversalDirection, int>{
    TraversalDirection.up: -DateTime.daysPerWeek,
    TraversalDirection.right: 1,
    TraversalDirection.down: DateTime.daysPerWeek,
    TraversalDirection.left: -1,
  };

  int _dayDirectionOffset(TraversalDirection traversalDirection, TextDirection textDirection) {
    // Swap left and right if the text direction if RTL
    if (textDirection == TextDirection.rtl) {
      if (traversalDirection == TraversalDirection.left)
        traversalDirection = TraversalDirection.right;
      else if (traversalDirection == TraversalDirection.right)
        traversalDirection = TraversalDirection.left;
    }
    return _directionOffset[traversalDirection]!;
  }

  DateTime? _nextDateInDirection(DateTime date, TraversalDirection direction) {
    final TextDirection textDirection = Directionality.of(context);
    DateTime nextDate = DateUtils.addDaysToDate(date, _dayDirectionOffset(direction, textDirection));
    while (!nextDate.isBefore(widget.minimumDate) && !nextDate.isAfter(widget.maximumDate)) {
      nextDate = DateUtils.addDaysToDate(nextDate, _dayDirectionOffset(direction, textDirection));
    }
    return null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dayGridFocus.dispose();
    super.dispose();
  }

  Widget _buildItems(BuildContext context, int index) {
    final DateTime month = DateUtils.addMonthsToMonthDate(widget.minimumDate, index);
    return _DayPicker(
      key: ValueKey<DateTime>(month),
      selectedDate: widget.selectedDate,
      currentDate: widget.currentDate,
      onChanged: _handleDateSelected,
      minimumDate: widget.minimumDate,
      maximumDate: widget.maximumDate,
      displayedMonth: month,
    );
  }

  /// Builds widgets showing abbreviated days of week. The first widget in the
  /// returned list corresponds to the first day of week for the current locale.
  ///
  /// Examples:
  ///
  /// ```
  /// ┌ Sunday is the first day of week in the US (en_US)
  /// |
  /// S M T W T F S  <-- the returned list contains these widgets
  /// _ _ _ _ _ 1 2
  /// 3 4 5 6 7 8 9
  ///
  /// ┌ But it's Monday in the UK (en_GB)
  /// |
  /// M T W T F S S  <-- the returned list contains these widgets
  /// _ _ _ _ 1 2 3
  /// 4 5 6 7 8 9 10
  /// ```
  List<Widget> _dayHeaders(TextStyle? headerStyle, CupertinoLocalizations localizations) {
    final List<Widget> result = <Widget>[];
    for (int i = localizations.firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final String weekday = localizations.calendarWeekDays[i];
      result.add(ExcludeSemantics(
        child: Center(child: Text(weekday.toUpperCase(), style: headerStyle)),
      ));
      if (i == (localizations.firstDayOfWeekIndex - 1) % 7)
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
    final CupertinoTextThemeData textTheme = theme.textTheme;
    final TextStyle headerStyle = textTheme.navTitleTextStyle.copyWith(
      fontSize: 13,
      color: CupertinoColors.systemGrey3,
    );
    final Color controlColor = theme.primaryColor;

    return Semantics(
      child: Column(
        children: <Widget>[
            Container(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: <Widget>[
                    const Spacer(),
                    GestureDetector(
                      onTap: _isDisplayingFirstMonth ? null : _handlePreviousMonth,
                      child: Icon(
                        CupertinoIcons.chevron_left,
                        color: controlColor,
                        semanticLabel: 'Previous month',
                      ),
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: _isDisplayingLastMonth ? null : _handleNextMonth,
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        color: controlColor,
                        semanticLabel: 'Next month',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 2),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 7,
                padding: EdgeInsets.zero,
                childAspectRatio: 3,
                physics: const NeverScrollableScrollPhysics(),
                children: _dayHeaders(headerStyle, localizations),
                ),
            ),
            Expanded(
              child: FocusableActionDetector(
                shortcuts: _shortcutMap,
                actions: _actionMap,
                focusNode: _dayGridFocus,
                onFocusChange: _handleGridFocusChange,
                child: _FocusedDate(
                  date: _dayGridFocus.hasFocus ? _focusedDay : null,
                  child: PageView.builder(
                    key: _pageViewKey,
                    controller: _pageController,
                    itemBuilder: _buildItems,
                    itemCount: DateUtils.monthDelta(widget.minimumDate, widget.maximumDate) + 1,
                    onPageChanged: _handleMonthPageChanged,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayPicker extends StatefulWidget {
  /// Creates a day picker.
  _DayPicker({
    Key? key,
    required this.currentDate,
    required this.displayedMonth,
    required this.minimumDate,
    required this.maximumDate,
    required this.selectedDate,
    required this.onChanged,
  }) : assert(currentDate != null),
       assert(displayedMonth != null),
       assert(minimumDate != null),
       assert(maximumDate != null),
       assert(selectedDate != null),
       assert(onChanged != null),
       assert(!minimumDate.isAfter(maximumDate)),
       assert(!selectedDate.isBefore(minimumDate)),
       assert(!selectedDate.isAfter(maximumDate)),
       super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// The earliest date the user is permitted to pick.
  ///
  /// This date must be on or before the [minimumDate].
  final DateTime minimumDate;

  /// The latest date the user is permitted to pick.
  ///
  /// This date must be on or after the [maximumDate].
  final DateTime maximumDate;

  /// Called when the user picks a year.
  final ValueChanged<DateTime> onChanged;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  @override
  __DayPickerState createState() => __DayPickerState();
}

class __DayPickerState extends State<_DayPicker> {
  /// List of [FocusNode]s, one for each day of the month.
  late List<FocusNode> _dayFocusNodes;

  @override
  void initState() {
    super.initState();
    final int daysInMonth = DateUtils.getDaysInMonth(widget.displayedMonth.year, widget.displayedMonth.month);
    _dayFocusNodes = List<FocusNode>.generate(
      daysInMonth,
      (int index) => FocusNode(skipTraversal: true, debugLabel: 'Day ${index + 1}'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check to see if the focused date is in this month, if so focus it.
    final DateTime? focusedDate = _FocusedDate.of(context);
    if (focusedDate != null && DateUtils.isSameMonth(widget.displayedMonth, focusedDate)) {
      _dayFocusNodes[focusedDate.day - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final FocusNode node in _dayFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
    final CupertinoTextThemeData textTheme = CupertinoTheme.of(context).textTheme;
    final TextStyle dayStyle = textTheme.dateTimePickerTextStyle;

    final Color enabledDayColor = CupertinoDynamicColor.resolve(CupertinoColors.label, context);
    final Color disabledDayColor = CupertinoDynamicColor.resolve(CupertinoColors.label, context).withOpacity(0.38);
    final Color selectedDayColor = CupertinoDynamicColor.resolve(theme.primaryColor, context);
    final Color selectedDayBackground = CupertinoDynamicColor.withBrightness(
      color: selectedDayColor.withOpacity(.12),
      darkColor: selectedDayColor.withOpacity(.24),
    );
    final Color todayColor = selectedDayColor;

    final int year = widget.displayedMonth.year;
    final int month = widget.displayedMonth.month;

    final int daysInMonth = DateUtils.getDaysInMonth(year, month);
    final int dayOffset = DateUtils.firstDayOffset(year, month, localizations);

    final List<Widget> dayItems = <Widget>[];

    // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
    // a leap year.
    int day = -dayOffset;
    while (day < daysInMonth) {
      day++;
      if (day < 1) {
        dayItems.add(Container());
      } else {
        final DateTime dayToBuild = DateTime(year, month, day);
        final bool isDisabled = dayToBuild.isAfter(widget.maximumDate) ||
            dayToBuild.isBefore(widget.minimumDate);
        final bool isSelectedDay = DateUtils.isSameDay(widget.selectedDate, dayToBuild);
        final bool isToday = DateUtils.isSameDay(widget.currentDate, dayToBuild);

        BoxDecoration? decoration;
        Color dayColor = enabledDayColor;

        if (isToday && isSelectedDay) {
          // The current day gets a different text color and a circle stroke
          // border.
          dayColor = todayColor;
          decoration = BoxDecoration(
            border: Border.all(color: todayColor),
            shape: BoxShape.circle,
            color: dayColor,
          );
        } else if (isSelectedDay) {
          // The selected day gets a circle background highlight, and a
          // contrasting text color.
          dayColor = CupertinoDynamicColor.resolve(CupertinoDynamicColor.resolve(selectedDayBackground, context), context);
          decoration = BoxDecoration(
            color: dayColor,
            shape: BoxShape.circle,
          );
        } else if (isDisabled) {
          dayColor = disabledDayColor;
        } else if (isToday) {
          // The current day gets a different text color and a circle stroke
          // border.
          dayColor = todayColor;
          decoration = const BoxDecoration();
        }

        Widget dayWidget = Container(
          decoration: decoration,
          child: Center(
            child: Text(localizations.formatDecimal(day), style: dayStyle.apply(color: dayColor).copyWith(
              fontWeight: FontWeight.w500,
            )),
          ),
        );

      if (isSelectedDay && isToday) {
          dayWidget = Container(
            decoration: decoration,
            child: Center(
              child: Text(localizations.formatDecimal(day), style: dayStyle.apply(color: CupertinoColors.white).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 22,
              )),
            ),
          );
        } else if (isSelectedDay) {
          dayWidget = Container(
            decoration: decoration,
            child: Center(
              child: Text(localizations.formatDecimal(day), style: dayStyle.apply(color: selectedDayColor).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 22,
              )),
            ),
          );
        } else if (isToday) {
          dayWidget = Container(
            decoration: decoration,
            child: Center(
              child: Text(localizations.formatDecimal(day), style: dayStyle.apply(color: selectedDayColor).copyWith(
                fontWeight: FontWeight.w400,
              )),
            ),
          );
        }
        if (isDisabled) {
          dayWidget = ExcludeSemantics(
            child: dayWidget,
          );
        } else {
          dayWidget = CupertinoButton(
            onPressed: () => widget.onChanged(dayToBuild),
            padding: dayOffset >= 6 ? EdgeInsets.zero : const EdgeInsets.all(4),
            borderRadius: BorderRadius.circular(30),
            pressedOpacity: 1.0,
            child: Semantics(
              // We want the day of month to be spoken first irrespective of the
              // locale-specific preferences or TextDirection. This is because
              // an accessibility user is more likely to be interested in the
              // day of month before the rest of the date, as they are looking
              // for the day of month. To do that we prepend day of month to the
              // formatted full date.
              label: '${localizations.formatDecimal(day)}, ${localizations.formatFullDate(dayToBuild)}',
              selected: isSelectedDay,
              excludeSemantics: true,
              child: dayWidget,
            ),
          );
        }

        dayItems.add(dayWidget);
      }
    }

    return GridView.custom(
      padding: EdgeInsets.zero,
      gridDelegate: _DayPickerGridDelegate(dayOffset >= 6),
      physics: const NeverScrollableScrollPhysics(),
      childrenDelegate: SliverChildListDelegate(
        dayItems,
        addRepaintBoundaries: false,
      ),
    );
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate(
    this.tallTiles,
  );

  final bool tallTiles;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight =
      tallTiles ?
      math.max(
      _dayPickerRowHeight,
      constraints.viewportMainAxisExtent / (_maxDayPickerRowCount + 1),
      ) :
      math.max(
      _dayPickerRowHeightTall,
      constraints.viewportMainAxisExtent / (_maxDayPickerRowCount + 1),
      );
    return SliverGridRegularTileLayout(
      childCrossAxisExtent: tileWidth,
      childMainAxisExtent: tileHeight,
      crossAxisCount: columnCount,
      crossAxisStride: tileWidth,
      mainAxisStride: tileHeight,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}
