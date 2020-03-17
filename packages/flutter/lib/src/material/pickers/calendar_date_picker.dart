// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../color_scheme.dart';
import '../divider.dart';
import '../icon_button.dart';
import '../icons.dart';
import '../ink_well.dart';
import '../material_localizations.dart';
import '../text_theme.dart';
import '../theme.dart';

import 'date_picker_common.dart';
import 'date_utils.dart' as utils;

const Duration _monthScrollDuration = Duration(milliseconds: 200);

const double _dayPickerRowHeight = 42.0;
const int _maxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// One extra row for the day-of-week header.
const double _maxDayPickerHeight = _dayPickerRowHeight * (_maxDayPickerRowCount + 1);
const double _monthPickerHorizontalPadding = 8.0;

const int _yearPickerColumnCount = 3;
const double _yearPickerPadding = 16.0;
const double _yearPickerRowHeight = 52.0;
const double _yearPickerRowSpacing = 8.0;

/// Displays a grid of days for a given month and allows the user to select a date.
///
/// Days are arranged in a rectangular grid with one column for each day of the
/// week. Controls are provided to change the year and month that the grid is
/// showing.
///
/// The calendar picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which will create a dialog that uses this as well as provides
/// a text entry option.
///
/// See also:
///
///  * [showDatePicker], which creates a Dialog that contains a [CalendarDatePicker]
///    and provides an optional compact view where the user can enter a date as
///    a line of text.
///  * [showTimePicker], which shows a dialog that contains a material design
///    time picker.
///
class CalendarDatePicker extends StatefulWidget {
  /// Creates a calender date picker
  ///
  /// It will display a grid of days for the [initialDate]'s month. The day
  /// indicated by [initialDate] will be selected.
  ///
  /// The optional [onDisplayedMonthChanged] callback can be used to track
  /// the currently displayed month.
  ///
  /// The user interface provides a way to change the year of the month being
  /// displayed. By default it will show the day grid, but this can be changed
  /// to start in the year selection interface with [initialCalendarMode] set
  /// to [DatePickerMode.year].
  ///
  /// The [initialDate], [firstDate], [lastDate], [onDateChanged], and
  /// [initialCalendarMode] must be non-null.
  ///
  /// [lastDate] must be after or equal to [firstDate].
  ///
  /// [initialDate] must be between [firstDate] and [lastDate] or equal to
  /// one of them.
  ///
  /// If [selectableDayPredicate] is non-null, it must return `true` for the
  /// [initialDate].
  CalendarDatePicker({
    Key key,
    @required DateTime initialDate,
    @required DateTime firstDate,
    @required DateTime lastDate,
    @required this.onDateChanged,
    this.onDisplayedMonthChanged,
    this.initialCalendarMode = DatePickerMode.day,
    this.selectableDayPredicate,
  }) : assert(initialDate != null),
       assert(firstDate != null),
       assert(lastDate != null),
       initialDate = utils.dateOnly(initialDate),
       firstDate = utils.dateOnly(firstDate),
       lastDate = utils.dateOnly(lastDate),
       assert(onDateChanged != null),
       assert(initialCalendarMode != null),
       super(key: key) {
    assert(
      !this.lastDate.isBefore(this.firstDate),
      'lastDate ${this.lastDate} must be on or after firstDate ${this.firstDate}.'
    );
    assert(
      !this.initialDate.isBefore(this.firstDate),
      'initialDate ${this.initialDate} must be on or after firstDate ${this.firstDate}.'
    );
    assert(
      !this.initialDate.isAfter(this.lastDate),
      'initialDate ${this.initialDate} must be on or before lastDate ${this.lastDate}.'
    );
    assert(
      selectableDayPredicate == null || selectableDayPredicate(this.initialDate),
      'Provided initialDate ${this.initialDate} must satisfy provided selectableDayPredicate.'
    );
  }

  /// The initially selected [DateTime] that the picker should display.
  final DateTime initialDate;

  /// The earliest allowable [DateTime] that the user can select.
  final DateTime firstDate;

  /// The latest allowable [DateTime] that the user can select.
  final DateTime lastDate;

  /// Called when the user selects a date in the picker.
  final ValueChanged<DateTime> onDateChanged;

  /// Called when the user navigates to a new month/year in the picker.
  final ValueChanged<DateTime> onDisplayedMonthChanged;

  /// The initial display of the calendar picker.
  final DatePickerMode initialCalendarMode;

  /// Function to provide full control over which dates in the calendar can be selected.
  final SelectableDayPredicate selectableDayPredicate;

  @override
  _CalendarDatePickerState createState() => _CalendarDatePickerState();
}

class _CalendarDatePickerState extends State<CalendarDatePicker> {
  bool _announcedInitialDate = false;
  DatePickerMode _mode;
  DateTime _currentDisplayedMonthDate;
  DateTime _nextMonthDate;
  DateTime _previousMonthDate;
  DateTime _selectedDate;
  PageController _pageController;
  final GlobalKey _pickerKey = GlobalKey();
  MaterialLocalizations _localizations;
  TextDirection _textDirection;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialCalendarMode;
    _currentDisplayedMonthDate = DateTime(widget.initialDate.year, widget.initialDate.month);
    _previousMonthDate = utils.addMonthsToMonthDate(_currentDisplayedMonthDate, -1);
    _nextMonthDate = utils.addMonthsToMonthDate(_currentDisplayedMonthDate, 1);
    _selectedDate = widget.initialDate;
    _pageController = PageController(initialPage: utils.monthDelta(widget.firstDate, _currentDisplayedMonthDate));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = MaterialLocalizations.of(context);
    _textDirection = Directionality.of(context);
    if (!_announcedInitialDate) {
      _announcedInitialDate = true;
      SemanticsService.announce(
        _localizations.formatFullDate(_selectedDate),
        _textDirection,
      );
    }
  }

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        HapticFeedback.vibrate();
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
    }
  }

  void _setCurrentMonth(DateTime date) {
    setState(() {
      if (_currentDisplayedMonthDate.year != date.year || _currentDisplayedMonthDate.month != date.month) {
        _currentDisplayedMonthDate = DateTime(date.year, date.month);
        _previousMonthDate = utils.addMonthsToMonthDate(_currentDisplayedMonthDate, -1);
        _nextMonthDate = utils.addMonthsToMonthDate(_currentDisplayedMonthDate, 1);
        _pageController?.dispose();
        _pageController = PageController(initialPage: utils.monthDelta(widget.firstDate, _currentDisplayedMonthDate));
        widget.onDisplayedMonthChanged?.call(_currentDisplayedMonthDate);
      }
    });
  }

  void _handleModeChanged(DatePickerMode mode) {
    _vibrate();
    setState(() {
      _mode = mode;
      if (_mode == DatePickerMode.day) {
        SemanticsService.announce(
          _localizations.formatMonthYear(_selectedDate),
          _textDirection,
        );
      } else {
        SemanticsService.announce(
          _localizations.formatYear(_selectedDate),
          _textDirection,
        );
      }
    });
  }

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

  /// True if the earliest allowable month is displayed.
  bool get _isDisplayingFirstMonth {
    return !_currentDisplayedMonthDate.isAfter(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    );
  }

  /// True if the latest allowable month is displayed.
  bool get _isDisplayingLastMonth {
    return !_currentDisplayedMonthDate.isBefore(
      DateTime(widget.lastDate.year, widget.lastDate.month),
    );
  }

  void _handleMonthPageChanged(int monthPage) {
    _setCurrentMonth(utils.addMonthsToMonthDate(widget.firstDate, monthPage));
  }

  void _handleYearChanged(DateTime value) {
    _vibrate();

    if (value.isBefore(widget.firstDate)) {
      value = widget.firstDate;
    } else if (value.isAfter(widget.lastDate)) {
      value = widget.lastDate;
    }

    setState(() {
      _mode = DatePickerMode.day;
      _setCurrentMonth(DateTime(value.year, value.month));
    });
  }

  void _handleDayChanged(DateTime value) {
    _vibrate();
    setState(() {
      _selectedDate = value;
      widget.onDateChanged?.call(_selectedDate);
    });
  }

  Widget _buildSubheader() {
    final String previousTooltipText = '${_localizations.previousMonthTooltip} ${_localizations.formatMonthYear(_previousMonthDate)}';
    final String nextTooltipText = '${_localizations.nextMonthTooltip} ${_localizations.formatMonthYear(_nextMonthDate)}';
    return _DatePickerSubheader(
      mode: _mode,
      nextTooltipText: _isDisplayingLastMonth ? null : nextTooltipText,
      previousTooltipText: _isDisplayingFirstMonth ? null : previousTooltipText,
      title: _localizations.formatMonthYear(_currentDisplayedMonthDate),
      onNextPressed: _isDisplayingLastMonth ? null : _handleNextMonth,
      onPreviousPressed: _isDisplayingFirstMonth ? null : _handlePreviousMonth,
      onTitlePressed: () {
        // Toggle the day/year mode.
        _handleModeChanged(_mode == DatePickerMode.day ? DatePickerMode.year : DatePickerMode.day);
      },
    );
  }

  Widget _buildPicker() {
    assert(_mode != null);
    switch (_mode) {
      case DatePickerMode.day:
        return _MonthPicker(
          key: _pickerKey,
          currentDate: DateTime.now(),
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          selectedDate: _selectedDate,
          onChanged: _handleDayChanged,
          onPageChanged: _handleMonthPageChanged,
          pageController: _pageController,
          selectableDayPredicate: widget.selectableDayPredicate,
        );
      case DatePickerMode.year:
        return _YearPicker(
          key: _pickerKey,
          currentDate: DateTime.now(),
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          initialDate: _currentDisplayedMonthDate,
          selectedDate: _selectedDate,
          onChanged: _handleYearChanged,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Widget subheader = _buildSubheader();
    final Widget picker = Flexible(
      child: SingleChildScrollView(
        child: SizedBox(
          height: _maxDayPickerHeight,
          child: _buildPicker(),
        ),
      ),
    );

    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        assert(orientation != null);
        switch (orientation) {
          case Orientation.portrait:
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                subheader,
                picker,
              ],
            );
          case Orientation.landscape:
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                subheader,
                picker,
              ],
            );
        }
        return null;
      });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }
}

/// The subheader for the [DatePickerDialog].
///
/// This appears above the calendar grid and allows the user to toggle the
/// [DatePickerMode] and quickly switch between next/previous months.
class _DatePickerSubheader extends StatefulWidget {
  const _DatePickerSubheader({
    @required this.mode,
    @required this.nextTooltipText,
    @required this.previousTooltipText,
    @required this.title,
    @required this.onNextPressed,
    @required this.onPreviousPressed,
    @required this.onTitlePressed,
  });

  /// The current display of the calendar picker.
  final DatePickerMode mode;

  /// The tooltip text for the next month button.
  final String nextTooltipText;

  /// The tooltip text for the previous month button.
  final String previousTooltipText;

  /// The text that displays the current month/year being viewed.
  final String title;

  /// The callback when the next month button is pressed.
  final VoidCallback onNextPressed;

  /// The callback when the previous month button is pressed.
  final VoidCallback onPreviousPressed;

  /// The callback when the title is pressed.
  final VoidCallback onTitlePressed;

  @override
  _DatePickerSubheaderState createState() => _DatePickerSubheaderState();
}

class _DatePickerSubheaderState extends State<_DatePickerSubheader>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: widget.mode == DatePickerMode.year ? 0.5 : 0,
      upperBound: 0.5,
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_DatePickerSubheader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode == widget.mode) {
      return;
    }

    if (widget.mode == DatePickerMode.year) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color controlColor = colorScheme.onSurface.withOpacity(0.60);
    const double height = 52.0;

    return Container(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
      height: height,
      child: Row(
        children: <Widget>[
          Flexible(
            child: Semantics(
              // TODO(darrenaustin): localize 'Select year'
              label: 'Select year',
              excludeSemantics: true,
              button: true,
              child: Container(
                height: height,
                child: InkWell(
                  onTap: widget.onTitlePressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            widget.title,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.subtitle2?.copyWith(
                              color: controlColor,
                            ),
                          ),
                        ),
                        RotationTransition(
                          turns: _controller,
                          child: Icon(
                            Icons.arrow_drop_down,
                            color: controlColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.mode == DatePickerMode.day) ...<Widget>[
            IconButton(
              icon: const Icon(Icons.chevron_left),
              color: controlColor,
              tooltip: widget.previousTooltipText,
              onPressed: widget.onPreviousPressed,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              color: controlColor,
              tooltip: widget.nextTooltipText,
              onPressed: widget.onNextPressed,
            ),
          ]
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _MonthPicker extends StatelessWidget {
  /// Creates a month picker.
  _MonthPicker({
    Key key,
    @required this.currentDate,
    @required this.firstDate,
    @required this.lastDate,
    @required this.selectedDate,
    @required this.pageController,
    @required this.onChanged,
    @required this.onPageChanged,
    this.selectableDayPredicate,
  }) : assert(selectedDate != null),
       assert(currentDate != null),
       assert(onChanged != null),
       assert(firstDate != null),
       assert(lastDate != null),
       assert(!firstDate.isAfter(lastDate)),
       assert(!selectedDate.isBefore(firstDate)),
       assert(!selectedDate.isAfter(lastDate)),
       super(key: key);

  /// The current date.
  ///
  /// This date is subtly highlighted in the picker.
  final DateTime currentDate;

  /// The earliest date the user is permitted to pick.
  ///
  /// This date must be on or before the [lastDate].
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  ///
  /// This date must be on or after the [firstDate].
  final DateTime lastDate;

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Controller to handle paging.
  final PageController pageController;

  /// Called when the user picks a month.
  final ValueChanged<DateTime> onChanged;

  /// Callback to handle page changes.
  final ValueChanged<int> onPageChanged;

  /// Optional user supplied predicate function to customize selectable days.
  final SelectableDayPredicate selectableDayPredicate;

  Widget _buildItems(BuildContext context, int index) {
    final DateTime month = utils.addMonthsToMonthDate(firstDate, index);
    return _DayPicker(
      key: ValueKey<DateTime>(month),
      selectedDate: selectedDate,
      currentDate: currentDate,
      onChanged: onChanged,
      firstDate: firstDate,
      lastDate: lastDate,
      displayedMonth: month,
      selectableDayPredicate: selectableDayPredicate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      child: Column(
        children: <Widget>[
          _DayHeaders(),
          Expanded(
            child: PageView.builder(
              key: ValueKey<DateTime>(selectedDate),
              controller: pageController,
              itemBuilder: _buildItems,
              itemCount: utils.monthDelta(firstDate, lastDate) + 1,
              scrollDirection: Axis.horizontal,
              onPageChanged: onPageChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the days of a given month and allows choosing a day.
///
/// The days are arranged in a rectangular grid with one column for each day of
/// the week.
class _DayPicker extends StatelessWidget {
  /// Creates a day picker.
  _DayPicker({
    Key key,
    @required this.currentDate,
    @required this.displayedMonth,
    @required this.firstDate,
    @required this.lastDate,
    @required this.selectedDate,
    @required this.onChanged,
    this.selectableDayPredicate,
  }) : assert(currentDate != null),
       assert(displayedMonth != null),
       assert(firstDate != null),
       assert(lastDate != null),
       assert(selectedDate != null),
       assert(onChanged != null),
       assert(!firstDate.isAfter(lastDate)),
       assert(!selectedDate.isBefore(firstDate)),
       assert(!selectedDate.isAfter(lastDate)),
       super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// Called when the user picks a day.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  ///
  /// This date must be on or before the [lastDate].
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  ///
  /// This date must be on or after the [firstDate].
  final DateTime lastDate;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  /// Optional user supplied predicate function to customize selectable days.
  final SelectableDayPredicate selectableDayPredicate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle dayStyle = textTheme.caption;
    final Color enabledDayColor = colorScheme.onSurface.withOpacity(0.87);
    final Color disabledDayColor = colorScheme.onSurface.withOpacity(0.38);
    final Color selectedDayColor = colorScheme.onPrimary;
    final Color selectedDayBackground = colorScheme.primary;
    final Color todayColor = colorScheme.primary;

    final int year = displayedMonth.year;
    final int month = displayedMonth.month;

    final int daysInMonth = utils.getDaysInMonth(year, month);
    final int dayOffset = utils.firstDayOffset(year, month, localizations);

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
        final bool isDisabled = dayToBuild.isAfter(lastDate) ||
            dayToBuild.isBefore(firstDate) ||
            (selectableDayPredicate != null && !selectableDayPredicate(dayToBuild));

        BoxDecoration decoration;
        Color dayColor = enabledDayColor;
        final bool isSelectedDay = utils.isSameDay(selectedDate, dayToBuild);
        if (isSelectedDay) {
          // The selected day gets a circle background highlight, and a
          // contrasting text color.
          dayColor = selectedDayColor;
          decoration = BoxDecoration(
            color: selectedDayBackground,
            shape: BoxShape.circle,
          );
        } else if (isDisabled) {
          dayColor = disabledDayColor;
        } else if (utils.isSameDay(currentDate, dayToBuild)) {
          // The current day gets a different text color and a circle stroke
          // border.
          dayColor = todayColor;
          decoration = BoxDecoration(
            border: Border.all(color: todayColor, width: 1),
            shape: BoxShape.circle,
          );
        }

        Widget dayWidget = Container(
          decoration: decoration,
          child: Center(
            child: Text(localizations.formatDecimal(day), style: dayStyle.apply(color: dayColor)),
          ),
        );

        if (isDisabled) {
          dayWidget = ExcludeSemantics(
            child: dayWidget,
          );
        } else {
          dayWidget = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(dayToBuild),
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _monthPickerHorizontalPadding,
      ),
      child: GridView.custom(
        physics: const ClampingScrollPhysics(),
        gridDelegate: _dayPickerGridDelegate,
        childrenDelegate: SliverChildListDelegate(
          dayItems,
          addRepaintBoundaries: false,
        ),
      ),
    );
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = math.min(_dayPickerRowHeight,
      constraints.viewportMainAxisExtent / _maxDayPickerRowCount);
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

const _DayPickerGridDelegate _dayPickerGridDelegate = _DayPickerGridDelegate();

class _DayHeaders extends StatelessWidget {
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
  List<Widget> _getDayHeaders(TextStyle headerStyle, MaterialLocalizations localizations) {
    final List<Widget> result = <Widget>[];
    for (int i = localizations.firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final String weekday = localizations.narrowWeekdays[i];
      result.add(ExcludeSemantics(
        child: Center(child: Text(weekday, style: headerStyle)),
      ));
      if (i == (localizations.firstDayOfWeekIndex - 1) % 7)
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextStyle dayHeaderStyle = theme.textTheme.caption?.apply(
      color: colorScheme.onSurface.withOpacity(0.60),
    );
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final List<Widget> labels = _getDayHeaders(dayHeaderStyle, localizations);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _monthPickerHorizontalPadding,
      ),
      child: GridView.custom(
        shrinkWrap: true,
        gridDelegate: _dayPickerGridDelegate,
        childrenDelegate: SliverChildListDelegate(
          labels,
          addRepaintBoundaries: false,
        ),
      ),
    );
  }
}

/// A scrollable list of years to allow picking a year.
class _YearPicker extends StatefulWidget {
  /// Creates a year picker.
  ///
  /// The [currentDate, [firstDate], [lastDate], [selectedDate], and [onChanged]
  /// arguments must be non-null. The [lastDate] must be after the [firstDate].
  _YearPicker({
    Key key,
    @required this.currentDate,
    @required this.firstDate,
    @required this.lastDate,
    @required this.initialDate,
    @required this.selectedDate,
    @required this.onChanged,
  }) : assert(currentDate != null),
       assert(firstDate != null),
       assert(lastDate != null),
       assert(initialDate != null),
       assert(selectedDate != null),
       assert(onChanged != null),
       assert(!firstDate.isAfter(lastDate)),
       super(key: key);

  /// The current date.
  ///
  /// This date is subtly highlighted in the picker.
  final DateTime currentDate;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// The initial date to center the year display around.
  final DateTime initialDate;

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a year.
  final ValueChanged<DateTime> onChanged;

  @override
  _YearPickerState createState() => _YearPickerState();
}

class _YearPickerState extends State<_YearPicker> {
  ScrollController scrollController;

  // The approximate number of years necessary to fill the available space.
  static const int minYears = 18;

  @override
  void initState() {
    super.initState();

    // Set the scroll position to approximately center the initial year.
    final int initialYearIndex = widget.selectedDate.year - widget.firstDate.year;
    final int initialYearRow = initialYearIndex ~/ _yearPickerColumnCount;
    // Move the offset down by 2 rows to approximately center it.
    final int centeredYearRow = initialYearRow - 2;
    final double scrollOffset = _itemCount < minYears ? 0 : centeredYearRow * _yearPickerRowHeight;
    scrollController = ScrollController(initialScrollOffset: scrollOffset);
  }

  Widget _buildYearItem(BuildContext context, int index) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Backfill the _YearPicker with disabled years if necessary.
    final int offset = _itemCount < minYears ? (minYears - _itemCount) ~/ 2 : 0;
    final int year = widget.firstDate.year + index - offset;
    final bool isSelected = year == widget.selectedDate.year;
    final bool isCurrentYear = year == widget.currentDate.year;
    final bool isDisabled = year < widget.firstDate.year || year > widget.lastDate.year;
    const double decorationHeight = 36.0;
    const double decorationWidth = 72.0;

    Color textColor;
    if (isSelected) {
      textColor = colorScheme.onPrimary;
    } else if (isDisabled) {
      textColor = colorScheme.onSurface.withOpacity(0.38);
    } else if (isCurrentYear) {
      textColor = colorScheme.primary;
    } else {
      textColor = colorScheme.onSurface.withOpacity(0.87);
    }
    final TextStyle itemStyle = textTheme.bodyText1?.apply(color: textColor);

    BoxDecoration decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(decorationHeight / 2),
        shape: BoxShape.rectangle,
      );
    } else if (isCurrentYear && !isDisabled) {
      decoration = BoxDecoration(
        border: Border.all(
          color: colorScheme.primary,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(decorationHeight / 2),
        shape: BoxShape.rectangle,
      );
    }

    Widget yearItem = Center(
      child: Container(
        decoration: decoration,
        height: decorationHeight,
        width: decorationWidth,
        child: Center(
          child: Semantics(
            selected: isSelected,
            child: Text(year.toString(), style: itemStyle),
          ),
        ),
      ),
    );

    if (isDisabled) {
      yearItem = ExcludeSemantics(
        child: yearItem,
      );
    } else {
      yearItem = InkWell(
        key: ValueKey<int>(year),
        onTap: () {
          widget.onChanged(
            DateTime(
              year,
              widget.initialDate.month,
              widget.initialDate.day,
            ),
          );
        },
        child: yearItem,
      );
    }

    return yearItem;
  }

  int get _itemCount {
    return widget.lastDate.year - widget.firstDate.year + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Divider(),
        Expanded(
          child: GridView.builder(
            controller: scrollController,
            gridDelegate: _yearPickerGridDelegate,
            itemBuilder: _buildYearItem,
            itemCount: math.max(_itemCount, minYears),
            padding: const EdgeInsets.symmetric(horizontal: _yearPickerPadding),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class _YearPickerGridDelegate extends SliverGridDelegate {
  const _YearPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double tileWidth =
      (constraints.crossAxisExtent - (_yearPickerColumnCount - 1) * _yearPickerRowSpacing) / _yearPickerColumnCount;
    return SliverGridRegularTileLayout(
      childCrossAxisExtent: tileWidth,
      childMainAxisExtent: _yearPickerRowHeight,
      crossAxisCount: _yearPickerColumnCount,
      crossAxisStride: tileWidth + _yearPickerRowSpacing,
      mainAxisStride: _yearPickerRowHeight,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_YearPickerGridDelegate oldDelegate) => false;
}

const _YearPickerGridDelegate _yearPickerGridDelegate = _YearPickerGridDelegate();
