// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart';

import 'colors.dart';
import 'debug.dart';
import 'ink_well.dart';
import 'theme.dart';
import 'typography.dart';

enum _DatePickerMode { day, year }

/// A material design date picker.
///
/// The date picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker dialog.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [showDatePicker]
///  * <https://www.google.com/design/spec/components/pickers.html#pickers-date-pickers>
class DatePicker extends StatefulWidget {
  /// Creates a date picker.
  ///
  /// Rather than creating a date picker directly, consider using
  /// [showDatePicker] to show a date picker in a dialog.
  DatePicker({
    this.selectedDate,
    this.onChanged,
    this.firstDate,
    this.lastDate
  }) {
    assert(selectedDate != null);
    assert(firstDate != null);
    assert(lastDate != null);
  }

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a date.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  @override
  _DatePickerState createState() => new _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  _DatePickerMode _mode = _DatePickerMode.day;

  void _handleModeChanged(_DatePickerMode mode) {
    HapticFeedback.vibrate();
    setState(() {
      _mode = mode;
    });
  }

  void _handleYearChanged(DateTime dateTime) {
    HapticFeedback.vibrate();
    setState(() {
      _mode = _DatePickerMode.day;
    });
    if (config.onChanged != null)
      config.onChanged(dateTime);
  }

  void _handleDayChanged(DateTime dateTime) {
    HapticFeedback.vibrate();
    if (config.onChanged != null)
      config.onChanged(dateTime);
  }

  static const double _calendarHeight = 210.0;

  @override
  Widget build(BuildContext context) {
    Widget header = new _DatePickerHeader(
      selectedDate: config.selectedDate,
      mode: _mode,
      onModeChanged: _handleModeChanged
    );
    Widget picker;
    switch (_mode) {
      case _DatePickerMode.day:
        picker = new MonthPicker(
          selectedDate: config.selectedDate,
          onChanged: _handleDayChanged,
          firstDate: config.firstDate,
          lastDate: config.lastDate,
          itemExtent: _calendarHeight
        );
        break;
      case _DatePickerMode.year:
        picker = new YearPicker(
          selectedDate: config.selectedDate,
          onChanged: _handleYearChanged,
          firstDate: config.firstDate,
          lastDate: config.lastDate
        );
        break;
    }
    return new Column(
      children: <Widget>[
        header,
        new Container(
          height: _calendarHeight,
          child: picker
        )
      ],
      crossAxisAlignment: CrossAxisAlignment.stretch
    );
  }

}

// Shows the selected date in large font and toggles between year and day mode
class _DatePickerHeader extends StatelessWidget {
  _DatePickerHeader({ this.selectedDate, this.mode, this.onModeChanged }) {
    assert(selectedDate != null);
    assert(mode != null);
  }

  final DateTime selectedDate;
  final _DatePickerMode mode;
  final ValueChanged<_DatePickerMode> onModeChanged;

  void _handleChangeMode(_DatePickerMode value) {
    if (value != mode)
      onModeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextTheme headerTheme = theme.primaryTextTheme;
    Color dayColor;
    Color yearColor;
    switch(theme.primaryColorBrightness) {
      case ThemeBrightness.light:
        dayColor = mode == _DatePickerMode.day ? Colors.black87 : Colors.black54;
        yearColor = mode == _DatePickerMode.year ? Colors.black87 : Colors.black54;
        break;
      case ThemeBrightness.dark:
        dayColor = mode == _DatePickerMode.day ? Colors.white : Colors.white70;
        yearColor = mode == _DatePickerMode.year ? Colors.white : Colors.white70;
        break;
    }
    TextStyle dayStyle = headerTheme.display3.copyWith(color: dayColor, height: 1.0, fontSize: 100.0);
    TextStyle monthStyle = headerTheme.headline.copyWith(color: dayColor, height: 1.0);
    TextStyle yearStyle = headerTheme.headline.copyWith(color: yearColor, height: 1.0);

    return new Container(
      padding: new EdgeInsets.all(10.0),
      decoration: new BoxDecoration(backgroundColor: theme.primaryColor),
      child: new Column(
        children: <Widget>[
          new GestureDetector(
            onTap: () => _handleChangeMode(_DatePickerMode.day),
            child: new Text(new DateFormat("MMM").format(selectedDate).toUpperCase(), style: monthStyle)
          ),
          new GestureDetector(
            onTap: () => _handleChangeMode(_DatePickerMode.day),
            child: new Text(new DateFormat("d").format(selectedDate), style: dayStyle)
          ),
          new GestureDetector(
            onTap: () => _handleChangeMode(_DatePickerMode.year),
            child: new Text(new DateFormat("yyyy").format(selectedDate), style: yearStyle)
          )
        ]
      )
    );
  }
}

/// Displays the days of a given month and allows choosing a day.
///
/// The days are arranged in a rectangular grid with one column for each day of
/// the week.
///
/// Part of the material design [DatePicker].
///
/// See also:
///
///  * [DatePicker].
///  * <https://www.google.com/design/spec/components/pickers.html#pickers-date-pickers>
class DayPicker extends StatelessWidget {
  /// Creates a day picker.
  ///
  /// Rarely used directly. Instead, typically used as part of a [DatePicker].
  DayPicker({
    this.selectedDate,
    this.currentDate,
    this.onChanged,
    this.displayedMonth
  }) {
    assert(selectedDate != null);
    assert(currentDate != null);
    assert(onChanged != null);
    assert(displayedMonth != null);
  }

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// Called when the user picks a day.
  final ValueChanged<DateTime> onChanged;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    TextStyle headerStyle = themeData.textTheme.caption.copyWith(fontWeight: FontWeight.w700);
    TextStyle monthStyle = headerStyle.copyWith(fontSize: 14.0, height: 24.0 / 14.0);
    TextStyle dayStyle = headerStyle.copyWith(fontWeight: FontWeight.w500);
    DateFormat dateFormat = new DateFormat();
    DateSymbols symbols = dateFormat.dateSymbols;

    List<Text> headers = <Text>[];
    for (String weekDay in symbols.NARROWWEEKDAYS) {
      headers.add(new Text(weekDay, style: headerStyle));
    }
    List<Widget> rows = <Widget>[
      new Text(new DateFormat("MMMM y").format(displayedMonth), style: monthStyle),
      new Flex(
        children: headers,
        mainAxisAlignment: MainAxisAlignment.spaceAround
      )
    ];
    int year = displayedMonth.year;
    int month = displayedMonth.month;
    // Dart's Date time constructor is very forgiving and will understand
    // month 13 as January of the next year. :)
    int daysInMonth = new DateTime(year, month + 1).difference(new DateTime(year, month)).inDays;
    int firstDay =  new DateTime(year, month).day;
    int weeksShown = 6;
    List<int> days = <int>[
      DateTime.SUNDAY,
      DateTime.MONDAY,
      DateTime.TUESDAY,
      DateTime.WEDNESDAY,
      DateTime.THURSDAY,
      DateTime.FRIDAY,
      DateTime.SATURDAY
    ];
    int daySlots = weeksShown * days.length;
    List<Widget> labels = <Widget>[];
    for (int i = 0; i < daySlots; i++) {
      // This assumes a start day of SUNDAY, but could be changed.
      int day = i - firstDay + 1;
      Widget item;
      if (day < 1 || day > daysInMonth) {
        item = new Text("");
      } else {
        BoxDecoration decoration;
        TextStyle itemStyle = dayStyle;

        if (selectedDate.year == year && selectedDate.month == month && selectedDate.day == day) {
          // The selected day gets a circle background highlight, and a contrasting text color.
          final ThemeData theme = Theme.of(context);
          itemStyle = itemStyle.copyWith(
            color: (theme.brightness == ThemeBrightness.light) ? Colors.white : Colors.black87
          );
          decoration = new BoxDecoration(
            backgroundColor: themeData.accentColor,
            shape: BoxShape.circle
          );
        } else if (currentDate.year == year && currentDate.month == month && currentDate.day == day) {
          // The current day gets a different text color.
          itemStyle = itemStyle.copyWith(color: themeData.accentColor);
        }

        item = new GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            DateTime result = new DateTime(year, month, day);
            onChanged(result);
          },
          child: new Container(
            height: 30.0,
            decoration: decoration,
            child: new Center(
              child: new Text(day.toString(), style: itemStyle)
            )
          )
        );
      }
      labels.add(new Flexible(child: item));
    }
    for (int w = 0; w < weeksShown; w++) {
      int startIndex = w * days.length;
      rows.add(new Row(
        children: labels.sublist(startIndex, startIndex + days.length)
      ));
    }

    return new Column(children: rows);
  }
}

/// A scrollable list of months to allow picking a month.
///
/// Shows the days of each month in a rectangular grid with one column for each
/// day of the week.
///
/// Part of the material design [DatePicker].
///
/// See also:
///
///  * [DatePicker]
///  * <https://www.google.com/design/spec/components/pickers.html#pickers-date-pickers>
class MonthPicker extends StatefulWidget {
  /// Creates a month picker.
  ///
  /// Rarely used directly. Instead, typically used as part of a [DatePicker].
  MonthPicker({
    Key key,
    this.selectedDate,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.itemExtent
  }) : super(key: key) {
    assert(selectedDate != null);
    assert(onChanged != null);
    assert(lastDate.isAfter(firstDate));
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

  /// The amount of vertical space to use for each month in the picker.
  final double itemExtent;

  @override
  _MonthPickerState createState() => new _MonthPickerState();
}

class _MonthPickerState extends State<MonthPicker> {
  @override
  void initState() {
    super.initState();
    _updateCurrentDate();
  }

  DateTime _currentDate;
  Timer _timer;

  void _updateCurrentDate() {
    _currentDate = new DateTime.now();
    DateTime tomorrow = new DateTime(_currentDate.year, _currentDate.month, _currentDate.day + 1);
    Duration timeUntilTomorrow = tomorrow.difference(_currentDate);
    timeUntilTomorrow += const Duration(seconds: 1);  // so we don't miss it by rounding
    if (_timer != null)
      _timer.cancel();
    _timer = new Timer(timeUntilTomorrow, () {
      setState(() {
        _updateCurrentDate();
      });
    });
  }

  int _monthDelta(DateTime startDate, DateTime endDate) {
    return (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;
  }

  List<Widget> buildItems(BuildContext context, int start, int count) {
    List<Widget> result = new List<Widget>();
    DateTime startDate = new DateTime(config.firstDate.year + start ~/ 12, config.firstDate.month + start % 12);
    for (int i = 0; i < count; ++i) {
      DateTime displayedMonth = new DateTime(startDate.year + i ~/ 12, startDate.month + i % 12);
      Widget item = new Container(
        height: config.itemExtent,
        key: new ObjectKey(displayedMonth),
        child: new DayPicker(
          selectedDate: config.selectedDate,
          currentDate: _currentDate,
          onChanged: config.onChanged,
          displayedMonth: displayedMonth
        )
      );
      result.add(item);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return new ScrollableLazyList(
      key: new ValueKey<DateTime>(config.selectedDate),
      initialScrollOffset: config.itemExtent * _monthDelta(config.firstDate, config.selectedDate),
      itemExtent: config.itemExtent,
      itemCount: _monthDelta(config.firstDate, config.lastDate) + 1,
      itemBuilder: buildItems
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
/// Part of the material design [DatePicker].
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [DatePicker]
///  * <https://www.google.com/design/spec/components/pickers.html#pickers-date-pickers>
class YearPicker extends StatefulWidget {
  YearPicker({
    Key key,
    this.selectedDate,
    this.onChanged,
    this.firstDate,
    this.lastDate
  }) : super(key: key) {
    assert(selectedDate != null);
    assert(onChanged != null);
    assert(lastDate.isAfter(firstDate));
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

  List<Widget> buildItems(BuildContext context, int start, int count) {
    TextStyle style = Theme.of(context).textTheme.body1.copyWith(color: Colors.black54);
    List<Widget> items = new List<Widget>();
    for (int i = start; i < start + count; i++) {
      int year = config.firstDate.year + i;
      String label = year.toString();
      Widget item = new InkWell(
        key: new Key(label),
        onTap: () {
          DateTime result = new DateTime(year, config.selectedDate.month, config.selectedDate.day);
          config.onChanged(result);
        },
        child: new Container(
          height: _itemExtent,
          decoration: year == config.selectedDate.year ? new BoxDecoration(
            backgroundColor: Theme.of(context).backgroundColor,
            shape: BoxShape.circle
          ) : null,
          child: new Center(
            child: new Text(label, style: style)
          )
        )
      );
      items.add(item);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new ScrollableLazyList(
      itemExtent: _itemExtent,
      itemCount: config.lastDate.year - config.firstDate.year + 1,
      itemBuilder: buildItems
    );
  }
}
