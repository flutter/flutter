// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart';

import 'button.dart';
import 'button_bar.dart';
import 'colors.dart';
import 'debug.dart';
import 'dialog.dart';
import 'flat_button.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'theme.dart';
import 'typography.dart';

enum _DatePickerMode { day, year }

const double _kDatePickerHeaderPortraitHeight = 100.0;
const double _kDatePickerHeaderLandscapeWidth = 168.0;

const Duration _kMonthScrollDuration = const Duration(milliseconds: 200);
const double _kDayPickerRowHeight = 42.0;
const int _kMaxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// Two extra rows: one for the day-of-week header and one for the month header.
const double _kMaxDayPickerHeight = _kDayPickerRowHeight * (_kMaxDayPickerRowCount + 2);

const double _kMonthPickerPortraitWidth = 330.0;
const double _kMonthPickerLandscapeWidth = 344.0;

const double _kDialogActionBarHeight = 52.0;
const double _kDatePickerLandscapeHeight = _kMaxDayPickerHeight + _kDialogActionBarHeight;

// Shows the selected date in large font and toggles between year and day mode
class _DatePickerHeader extends StatelessWidget {
  const _DatePickerHeader({
    Key key,
    @required this.selectedDate,
    @required this.mode,
    @required this.onModeChanged,
    @required this.orientation,
  }) : assert(selectedDate != null),
       assert(mode != null),
       assert(orientation != null),
       super(key: key);

  final DateTime selectedDate;
  final _DatePickerMode mode;
  final ValueChanged<_DatePickerMode> onModeChanged;
  final Orientation orientation;

  void _handleChangeMode(_DatePickerMode value) {
    if (value != mode)
      onModeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextTheme headerTextTheme = themeData.primaryTextTheme;
    Color dayColor;
    Color yearColor;
    switch(themeData.primaryColorBrightness) {
      case Brightness.light:
        dayColor = mode == _DatePickerMode.day ? Colors.black87 : Colors.black54;
        yearColor = mode == _DatePickerMode.year ? Colors.black87 : Colors.black54;
        break;
      case Brightness.dark:
        dayColor = mode == _DatePickerMode.day ? Colors.white : Colors.white70;
        yearColor = mode == _DatePickerMode.year ? Colors.white : Colors.white70;
        break;
    }
    final TextStyle dayStyle = headerTextTheme.display1.copyWith(color: dayColor, height: 1.4);
    final TextStyle yearStyle = headerTextTheme.subhead.copyWith(color: yearColor, height: 1.4);

    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = themeData.primaryColor;
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    double width;
    double height;
    EdgeInsets padding;
    MainAxisAlignment mainAxisAlignment;
    switch (orientation) {
      case Orientation.portrait:
        height = _kDatePickerHeaderPortraitHeight;
        padding = const EdgeInsets.symmetric(horizontal: 24.0);
        mainAxisAlignment = MainAxisAlignment.center;
        break;
      case Orientation.landscape:
        width = _kDatePickerHeaderLandscapeWidth;
        padding = const EdgeInsets.all(16.0);
        mainAxisAlignment = MainAxisAlignment.start;
        break;
    }

    return new Container(
      width: width,
      height: height,
      padding: padding,
      color: backgroundColor,
      child: new Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new GestureDetector(
            onTap: () => _handleChangeMode(_DatePickerMode.year),
            child: new Text(new DateFormat('yyyy').format(selectedDate), style: yearStyle),
          ),
          new GestureDetector(
            onTap: () => _handleChangeMode(_DatePickerMode.day),
            child: new Text(new DateFormat('E, MMM\u00a0d').format(selectedDate), style: dayStyle),
          ),
        ],
      ),
    );
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final int columnCount = DateTime.DAYS_PER_WEEK;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = math.min(_kDayPickerRowHeight, constraints.viewportMainAxisExtent / (_kMaxDayPickerRowCount + 1));
    return new SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileHeight,
      crossAxisStride: tileWidth,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _kDayPickerGridDelegate = const _DayPickerGridDelegate();

/// Displays the days of a given month and allows choosing a day.
///
/// The days are arranged in a rectangular grid with one column for each day of
/// the week.
///
/// The day picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker dialog.
///
/// See also:
///
///  * [showDatePicker].
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
class DayPicker extends StatelessWidget {
  /// Creates a day picker.
  ///
  /// Rarely used directly. Instead, typically used as part of a [MonthPicker].
  DayPicker({
    Key key,
    @required this.selectedDate,
    @required this.currentDate,
    @required this.onChanged,
    @required this.firstDate,
    @required this.lastDate,
    @required this.displayedMonth,
    this.selectableDayPredicate,
  }) : super(key: key) {
    assert(selectedDate != null);
    assert(currentDate != null);
    assert(onChanged != null);
    assert(displayedMonth != null);
    assert(!firstDate.isAfter(lastDate));
    assert(selectedDate.isAfter(firstDate) || selectedDate.isAtSameMomentAs(firstDate));
  }

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// Called when the user picks a day.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  /// Optional user supplied predicate function to customize selectable days.
  final SelectableDayPredicate selectableDayPredicate;

  List<Widget> _getDayHeaders(TextStyle headerStyle) {
    final DateFormat dateFormat = new DateFormat();
    final DateSymbols symbols = dateFormat.dateSymbols;
    return symbols.NARROWWEEKDAYS.map((String weekDay) {
      return new Center(child: new Text(weekDay, style: headerStyle));
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final int year = displayedMonth.year;
    final int month = displayedMonth.month;
    // Dart's Date time constructor is very forgiving and will understand
    // month 13 as January of the next year. :)
    final int daysInMonth = new DateTime(year, month + 1).difference(new DateTime(year, month)).inDays;
    // This assumes a start day of SUNDAY, but could be changed.
    final int firstWeekday = new DateTime(year, month).weekday % 7;
    final List<Widget> labels = <Widget>[];
    labels.addAll(_getDayHeaders(themeData.textTheme.caption));
    for (int i = 0; true; ++i) {
      final int day = i - firstWeekday + 1;
      if (day > daysInMonth)
        break;
      if (day < 1) {
        labels.add(new Container());
      } else {
        final DateTime dayToBuild = new DateTime(year, month, day);
        final bool disabled = dayToBuild.isAfter(lastDate)
            || dayToBuild.isBefore(firstDate)
            || (selectableDayPredicate != null && !selectableDayPredicate(dayToBuild));

        BoxDecoration decoration;
        TextStyle itemStyle = themeData.textTheme.body1;

        if (selectedDate.year == year && selectedDate.month == month && selectedDate.day == day) {
          // The selected day gets a circle background highlight, and a contrasting text color.
          itemStyle = themeData.accentTextTheme.body2;
          decoration = new BoxDecoration(
            color: themeData.accentColor,
            shape: BoxShape.circle
          );
        } else if (disabled) {
          itemStyle = themeData.textTheme.body1.copyWith(color: themeData.disabledColor);
        } else if (currentDate.year == year && currentDate.month == month && currentDate.day == day) {
          // The current day gets a different text color.
          itemStyle = themeData.textTheme.body2.copyWith(color: themeData.accentColor);
        }

        Widget dayWidget = new Container(
          decoration: decoration,
          child: new Center(
            child: new Text(day.toString(), style: itemStyle),
          ),
        );

        if (!disabled) {
          dayWidget = new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              onChanged(dayToBuild);
            },
            child: dayWidget,
          );
        }

        labels.add(dayWidget);
      }
    }

    return new Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: new Column(
        children: <Widget>[
          new Container(
            height: _kDayPickerRowHeight,
            child: new Center(
              child: new Text(new DateFormat('yMMMM').format(displayedMonth),
                style: themeData.textTheme.subhead,
              ),
            ),
          ),
          new Flexible(
            child: new GridView.custom(
              gridDelegate: _kDayPickerGridDelegate,
              childrenDelegate: new SliverChildListDelegate(labels, addRepaintBoundaries: false),
            ),
          ),
        ],
      ),
    );
  }
}

/// A scrollable list of months to allow picking a month.
///
/// Shows the days of each month in a rectangular grid with one column for each
/// day of the week.
///
/// The month picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker dialog.
///
/// See also:
///
///  * [showDatePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
class MonthPicker extends StatefulWidget {
  /// Creates a month picker.
  ///
  /// Rarely used directly. Instead, typically used as part of the dialog shown
  /// by [showDatePicker].
  MonthPicker({
    Key key,
    @required this.selectedDate,
    @required this.onChanged,
    @required this.firstDate,
    @required this.lastDate,
    this.selectableDayPredicate,
  }) : super(key: key) {
    assert(selectedDate != null);
    assert(onChanged != null);
    assert(!firstDate.isAfter(lastDate));
    assert(selectedDate.isAfter(firstDate) || selectedDate.isAtSameMomentAs(firstDate));
  }

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a month.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// Optional user supplied predicate function to customize selectable days.
  final SelectableDayPredicate selectableDayPredicate;

  @override
  _MonthPickerState createState() => new _MonthPickerState();
}

class _MonthPickerState extends State<MonthPicker> {
  @override
  void initState() {
    super.initState();
    // Initially display the pre-selected date.
    _dayPickerController = new PageController(initialPage: _monthDelta(widget.firstDate, widget.selectedDate));
    _currentDisplayedMonthDate = new DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _updateCurrentDate();
  }

  @override
  void didUpdateWidget(MonthPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _dayPickerController = new PageController(initialPage: _monthDelta(widget.firstDate, widget.selectedDate));
      _currentDisplayedMonthDate =
          new DateTime(widget.selectedDate.year, widget.selectedDate.month);
    }
  }

  DateTime _todayDate;
  DateTime _currentDisplayedMonthDate;
  Timer _timer;
  PageController _dayPickerController;

  void _updateCurrentDate() {
    _todayDate = new DateTime.now();
    final DateTime tomorrow = new DateTime(_todayDate.year, _todayDate.month, _todayDate.day + 1);
    Duration timeUntilTomorrow = tomorrow.difference(_todayDate);
    timeUntilTomorrow += const Duration(seconds: 1);  // so we don't miss it by rounding
    _timer?.cancel();
    _timer = new Timer(timeUntilTomorrow, () {
      setState(() {
        _updateCurrentDate();
      });
    });
  }

  static int _monthDelta(DateTime startDate, DateTime endDate) {
    return (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;
  }

  /// Add months to a month truncated date.
  DateTime _addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    return new DateTime(monthDate.year + monthsToAdd ~/ 12, monthDate.month + monthsToAdd % 12);
  }

  Widget _buildItems(BuildContext context, int index) {
    final DateTime month = _addMonthsToMonthDate(widget.firstDate, index);
    return new DayPicker(
      key: new ValueKey<DateTime>(month),
      selectedDate: widget.selectedDate,
      currentDate: _todayDate,
      onChanged: widget.onChanged,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      displayedMonth: month,
      selectableDayPredicate: widget.selectableDayPredicate,
    );
  }

  void _handleNextMonth() {
    if (!_isDisplayingLastMonth)
      _dayPickerController.nextPage(duration: _kMonthScrollDuration, curve: Curves.ease);
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth)
      _dayPickerController.previousPage(duration: _kMonthScrollDuration, curve: Curves.ease);
  }

  /// True if the earliest allowable month is displayed.
  bool get _isDisplayingFirstMonth {
    return !_currentDisplayedMonthDate.isAfter(
        new DateTime(widget.firstDate.year, widget.firstDate.month));
  }

  /// True if the latest allowable month is displayed.
  bool get _isDisplayingLastMonth {
    return !_currentDisplayedMonthDate.isBefore(
        new DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  void _handleMonthPageChanged(int monthPage) {
    setState(() {
      _currentDisplayedMonthDate = _addMonthsToMonthDate(widget.firstDate, monthPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new SizedBox(
      width: _kMonthPickerPortraitWidth,
      height: _kMaxDayPickerHeight,
      child: new Stack(
        children: <Widget>[
          new PageView.builder(
            key: new ValueKey<DateTime>(widget.selectedDate),
            controller: _dayPickerController,
            scrollDirection: Axis.horizontal,
            itemCount: _monthDelta(widget.firstDate, widget.lastDate) + 1,
            itemBuilder: _buildItems,
            onPageChanged: _handleMonthPageChanged,
          ),
          new Positioned(
            top: 0.0,
            left: 8.0,
            child: new IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
              onPressed: _isDisplayingFirstMonth ? null : _handlePreviousMonth,
            ),
          ),
          new Positioned(
            top: 0.0,
            right: 8.0,
            child: new IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
              onPressed: _isDisplayingLastMonth ? null : _handleNextMonth,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_timer != null)
      _timer.cancel();
    super.dispose();
  }
}

/// A scrollable list of years to allow picking a year.
///
/// The year picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker dialog.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [showDatePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
class YearPicker extends StatefulWidget {
  /// Creates a year picker.
  ///
  /// The [selectedDate] and [onChanged] arguments must not be null. The
  /// [lastDate] must be after the [firstDate].
  ///
  /// Rarely used directly. Instead, typically used as part of the dialog shown
  /// by [showDatePicker].
  YearPicker({
    Key key,
    @required this.selectedDate,
    @required this.onChanged,
    @required this.firstDate,
    @required this.lastDate,
  }) : super(key: key) {
    assert(selectedDate != null);
    assert(onChanged != null);
    assert(!firstDate.isAfter(lastDate));
  }

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a year.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  @override
  _YearPickerState createState() => new _YearPickerState();
}

class _YearPickerState extends State<YearPicker> {
  static const double _itemExtent = 50.0;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData themeData = Theme.of(context);
    final TextStyle style = themeData.textTheme.body1;
    return new ListView.builder(
      itemExtent: _itemExtent,
      itemCount: widget.lastDate.year - widget.firstDate.year + 1,
      itemBuilder: (BuildContext context, int index) {
        final int year = widget.firstDate.year + index;
        final TextStyle itemStyle = year == widget.selectedDate.year ?
            themeData.textTheme.headline.copyWith(color: themeData.accentColor) : style;
        return new InkWell(
          key: new ValueKey<int>(year),
          onTap: () {
            widget.onChanged(new DateTime(year, widget.selectedDate.month, widget.selectedDate.day));
          },
          child: new Center(
            child: new Text(year.toString(), style: itemStyle),
          ),
        );
      },
    );
  }
}

class _DatePickerDialog extends StatefulWidget {
  const _DatePickerDialog({
    Key key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
  }) : super(key: key);

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final SelectableDayPredicate selectableDayPredicate;

  @override
  _DatePickerDialogState createState() => new _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  DateTime _selectedDate;
  _DatePickerMode _mode = _DatePickerMode.day;
  final GlobalKey _pickerKey = new GlobalKey();

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        HapticFeedback.vibrate();
        break;
      case TargetPlatform.iOS:
        break;
    }
  }

  void _handleModeChanged(_DatePickerMode mode) {
    _vibrate();
    setState(() {
      _mode = mode;
    });
  }

  void _handleYearChanged(DateTime value) {
    _vibrate();
    setState(() {
      _mode = _DatePickerMode.day;
      _selectedDate = value;
    });
  }

  void _handleDayChanged(DateTime value) {
    _vibrate();
    setState(() {
      _selectedDate = value;
    });
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    Navigator.pop(context, _selectedDate);
  }

  Widget _buildPicker() {
    assert(_mode != null);
    switch (_mode) {
      case _DatePickerMode.day:
        return new MonthPicker(
          key: _pickerKey,
          selectedDate: _selectedDate,
          onChanged: _handleDayChanged,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          selectableDayPredicate: widget.selectableDayPredicate,
        );
      case _DatePickerMode.year:
        return new YearPicker(
          key: _pickerKey,
          selectedDate: _selectedDate,
          onChanged: _handleYearChanged,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Widget picker = new Flexible(
      child: new SizedBox(
        height: _kMaxDayPickerHeight,
        child: _buildPicker(),
      ),
    );
    final Widget actions = new ButtonTheme.bar(
      child: new ButtonBar(
        children: <Widget>[
          new FlatButton(
            child: const Text('CANCEL'),
            onPressed: _handleCancel,
          ),
          new FlatButton(
            child: const Text('OK'),
            onPressed: _handleOk,
          ),
        ],
      ),
    );
    return new Dialog(
      child: new OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          final Widget header = new _DatePickerHeader(
            selectedDate: _selectedDate,
            mode: _mode,
            onModeChanged: _handleModeChanged,
            orientation: orientation,
          );
          assert(orientation != null);
          switch (orientation) {
            case Orientation.portrait:
              return new SizedBox(
                width: _kMonthPickerPortraitWidth,
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[header, picker, actions],
                ),
              );
            case Orientation.landscape:
              return new SizedBox(
                height: _kDatePickerLandscapeHeight,
                child: new Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    new Flexible(
                      child: new SizedBox(
                        width: _kMonthPickerLandscapeWidth,
                        child: new Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[picker, actions],
                        ),
                      ),
                    ),
                  ],
                ),
              );
          }
          return null;
        }
      )
    );
  }
}

/// Signature for predicating dates for enabled date selections.
///
/// See [showDatePicker].
typedef bool SelectableDayPredicate(DateTime day);

/// Shows a dialog containing a material design date picker.
///
/// The returned [Future] resolves to the date selected by the user when the
/// user closes the dialog. If the user cancels the dialog, null is returned.
///
/// An optional [selectableDayPredicate] function can be passed in to customize
/// the days to enable for selection. If provided, only the days that
/// [selectableDayPredicate] returned true for will be selectable.
///
/// See also:
///
///  * [showTimePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
Future<DateTime> showDatePicker({
  @required BuildContext context,
  @required DateTime initialDate,
  @required DateTime firstDate,
  @required DateTime lastDate,
  SelectableDayPredicate selectableDayPredicate,
}) async {
  assert(!initialDate.isBefore(firstDate), 'initialDate must be on or after firstDate');
  assert(!initialDate.isAfter(lastDate), 'initialDate must be on or before lastDate');
  assert(!firstDate.isAfter(lastDate), 'lastDate must be on or after firstDate');
  assert(
    selectableDayPredicate == null || selectableDayPredicate(initialDate),
    'Provided initialDate must satisfy provided selectableDayPredicate'
  );
  return await showDialog(
    context: context,
    child: new _DatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: selectableDayPredicate,
    )
  );
}
