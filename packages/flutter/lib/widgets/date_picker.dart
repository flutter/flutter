// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/mojo/activity.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbols.dart';

typedef void DatePickerValueChanged(DateTime dateTime);

enum DatePickerMode { day, year }

typedef void DatePickerModeChanged(DatePickerMode value);

class DatePicker extends StatefulComponent {
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

  DateTime selectedDate;
  DatePickerValueChanged onChanged;
  DateTime firstDate;
  DateTime lastDate;

  void syncConstructorArguments(DatePicker source) {
    selectedDate = source.selectedDate;
    onChanged = source.onChanged;
    firstDate = source.firstDate;
    lastDate = source.lastDate;
  }

  DatePickerMode _mode = DatePickerMode.day;

  void _handleModeChanged(DatePickerMode mode) {
    userFeedback.performHapticFeedback(HapticFeedbackType_VIRTUAL_KEY);
    setState(() {
      _mode = mode;
    });
  }

  void _handleYearChanged(DateTime dateTime) {
    userFeedback.performHapticFeedback(HapticFeedbackType_VIRTUAL_KEY);
    setState(() {
      _mode = DatePickerMode.day;
    });
    if (onChanged != null)
      onChanged(dateTime);
  }

  void _handleDayChanged(DateTime dateTime) {
    userFeedback.performHapticFeedback(HapticFeedbackType_VIRTUAL_KEY);
    if (onChanged != null)
      onChanged(dateTime);
  }

  static const double _calendarHeight = 210.0;

  Widget build() {
    Widget header = new DatePickerHeader(
      selectedDate: selectedDate,
      mode: _mode,
      onModeChanged: _handleModeChanged
    );
    Widget picker;
    switch (_mode) {
      case DatePickerMode.day:
        picker = new MonthPicker(
          selectedDate: selectedDate,
          onChanged: _handleDayChanged,
          firstDate: firstDate,
          lastDate: lastDate,
          itemExtent: _calendarHeight
        );
        break;
      case DatePickerMode.year:
        picker = new YearPicker(
          selectedDate: selectedDate,
          onChanged: _handleYearChanged,
          firstDate: firstDate,
          lastDate: lastDate
        );
        break;
    }
    return new BlockBody([header, new Container(height: _calendarHeight, child: picker)]);
  }

}

// Shows the selected date in large font and toggles between year and day mode
class DatePickerHeader extends Component {
  DatePickerHeader({ this.selectedDate, this.mode, this.onModeChanged }) {
    assert(selectedDate != null);
    assert(mode != null);
  }

  DateTime selectedDate;
  DatePickerMode mode;
  DatePickerModeChanged onModeChanged;

  EventDisposition _handleChangeMode(DatePickerMode value) {
    if (value == mode)
      return EventDisposition.ignored;
    onModeChanged(value);
    return EventDisposition.processed;
  }

  Widget build() {
    ThemeData theme = Theme.of(this);
    typography.TextTheme headerTheme;
    Color dayColor;
    Color yearColor;
    switch(theme.primaryColorBrightness) {
      case ThemeBrightness.light:
        headerTheme = typography.black;
        dayColor = mode == DatePickerMode.day ? colors.black87 : colors.black54;
        yearColor = mode == DatePickerMode.year ? colors.black87 : colors.black54;
        break;
      case ThemeBrightness.dark:
        headerTheme = typography.white;
        dayColor = mode == DatePickerMode.day ? colors.white87 : colors.white54;
        yearColor = mode == DatePickerMode.year ? colors.white87 : colors.white54;
        break;
    }
    TextStyle dayStyle = headerTheme.display3.copyWith(color: dayColor, height: 1.0, fontSize: 100.0);
    TextStyle monthStyle = headerTheme.headline.copyWith(color: dayColor, height: 1.0);
    TextStyle yearStyle = headerTheme.headline.copyWith(color: yearColor, height: 1.0);

    return new Container(
      child: new BlockBody([
        new Center(
          child: new Listener(
            child: new Text(new DateFormat("MMM").format(selectedDate).toUpperCase(), style: monthStyle),
            onGestureTap: (_) => _handleChangeMode(DatePickerMode.day)
          )
        ),
        new Center(
          child: new Listener(
            child: new Text(new DateFormat("d").format(selectedDate), style: dayStyle),
            onGestureTap: (_) => _handleChangeMode(DatePickerMode.day)
          )
        ),
        new Center(
          child: new Listener(
            child: new Text(new DateFormat("yyyy").format(selectedDate), style: yearStyle),
            onGestureTap: (_) => _handleChangeMode(DatePickerMode.year)
          )
        )
      ]),
      padding: new EdgeDims.all(10.0),
      decoration: new BoxDecoration(backgroundColor: theme.primaryColor)
    );
  }
}

// Fixed height component shows a single month and allows choosing a day
class DayPicker extends Component {
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

  final DateTime selectedDate;
  final DateTime currentDate;
  final DatePickerValueChanged onChanged;
  final DateTime displayedMonth;

  Widget build() {
    ThemeData theme = Theme.of(this);
    TextStyle headerStyle = theme.text.caption.copyWith(fontWeight: FontWeight.w700);
    TextStyle monthStyle = headerStyle.copyWith(fontSize: 14.0, height: 24.0 / 14.0);
    TextStyle dayStyle = headerStyle.copyWith(fontWeight: FontWeight.w500);
    DateFormat dateFormat = new DateFormat();
    DateSymbols symbols = dateFormat.dateSymbols;

    List<Text> headers = [];
    for (String weekDay in symbols.NARROWWEEKDAYS) {
      headers.add(new Text(weekDay, style: headerStyle));
    }
    List<Widget> rows = [
      new Text(new DateFormat("MMMM y").format(displayedMonth), style: monthStyle),
      new Flex(
        headers,
        justifyContent: FlexJustifyContent.spaceAround
      )
    ];
    int year = displayedMonth.year;
    int month = displayedMonth.month;
    // Dart's Date time constructor is very forgiving and will understand
    // month 13 as January of the next year. :)
    int daysInMonth = new DateTime(year, month + 1).difference(new DateTime(year, month)).inDays;
    int firstDay =  new DateTime(year, month).day;
    int weeksShown = 6;
    List<int> days = [
      DateTime.SUNDAY,
      DateTime.MONDAY,
      DateTime.TUESDAY,
      DateTime.WEDNESDAY,
      DateTime.THURSDAY,
      DateTime.FRIDAY,
      DateTime.SATURDAY
    ];
    int daySlots = weeksShown * days.length;
    List<Widget> labels = [];
    for (int i = 0; i < daySlots; i++) {
      // This assumes a start day of SUNDAY, but could be changed.
      int day = i - firstDay + 1;
      Widget item;
      if (day < 1 || day > daysInMonth) {
        item = new Text("");
      } else {
        // Put a light circle around the selected day
        BoxDecoration decoration = null;
        if (selectedDate.year == year &&
            selectedDate.month == month &&
            selectedDate.day == day)
          decoration = new BoxDecoration(
            backgroundColor: theme.primarySwatch[100],
            shape: Shape.circle
          );

        // Use a different font color for the current day
        TextStyle itemStyle = dayStyle;
        if (currentDate.year == year &&
            currentDate.month == month &&
            currentDate.day == day)
          itemStyle = itemStyle.copyWith(color: theme.primaryColor);

        item = new Listener(
          onGestureTap: (_) {
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
      rows.add(new Container(
        child: new Flex(
          labels.sublist(startIndex, startIndex + days.length),
          justifyContent: FlexJustifyContent.spaceAround
        )
      ));
    }

    return new Column(rows);
  }
}

// Scrollable list of DayPickers to allow choosing a month
class MonthPicker extends ScrollableWidgetList {
  MonthPicker({
    this.selectedDate,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    double itemExtent
  }) : super(itemExtent: itemExtent) {
    assert(selectedDate != null);
    assert(onChanged != null);
    assert(lastDate.isAfter(firstDate));
  }

  DateTime selectedDate;
  DatePickerValueChanged onChanged;
  DateTime firstDate;
  DateTime lastDate;

  void syncConstructorArguments(MonthPicker source) {
    selectedDate = source.selectedDate;
    onChanged = source.onChanged;
    firstDate = source.firstDate;
    lastDate = source.lastDate;
    super.syncConstructorArguments(source);
  }

  void initState() {
    _updateCurrentDate();
    super.initState();
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

  int get itemCount => (lastDate.year - firstDate.year) * 12 + lastDate.month - firstDate.month + 1;

  List<Widget> buildItems(int start, int count) {
    List<Widget> result = new List<Widget>();
    DateTime startDate = new DateTime(firstDate.year + start ~/ 12, firstDate.month + start % 12);
    for (int i = 0; i < count; ++i) {
      DateTime displayedMonth = new DateTime(startDate.year + i ~/ 12, startDate.month + i % 12);
      Widget item = new Container(
        height: itemExtent,
        key: new ObjectKey(displayedMonth),
        child: new DayPicker(
          selectedDate: selectedDate,
          currentDate: _currentDate,
          onChanged: onChanged,
          displayedMonth: displayedMonth
        )
      );
      result.add(item);
    }
    return result;
  }

  void didUnmount() {
    super.didUnmount();
    if (_timer != null) {
      _timer.cancel();
    }
  }
}

// Scrollable list of years to allow picking a year
class YearPicker extends ScrollableWidgetList {
  YearPicker({
    this.selectedDate,
    this.onChanged,
    this.firstDate,
    this.lastDate
  }) : super(itemExtent: 50.0) {
    assert(selectedDate != null);
    assert(onChanged != null);
    assert(lastDate.isAfter(firstDate));
  }
  DateTime selectedDate;
  DatePickerValueChanged onChanged;
  DateTime firstDate;
  DateTime lastDate;

  void syncConstructorArguments(YearPicker source) {
    selectedDate = source.selectedDate;
    onChanged = source.onChanged;
    firstDate = source.firstDate;
    lastDate = source.lastDate;
    super.syncConstructorArguments(source);
  }

  int get itemCount => lastDate.year - firstDate.year + 1;

  List<Widget> buildItems(int start, int count) {
    TextStyle style = Theme.of(this).text.body1.copyWith(color: colors.black54);
    List<Widget> items = new List<Widget>();
    for(int i = start; i < start + count; i++) {
      int year = firstDate.year + i;
      String label = year.toString();
      Widget item = new Listener(
        key: new Key(label),
        onGestureTap: (_) {
          DateTime result = new DateTime(year, selectedDate.month, selectedDate.day);
          onChanged(result);
        },
        child: new InkWell(
          child: new Container(
            height: itemExtent,
            decoration: year == selectedDate.year ? new BoxDecoration(
              backgroundColor: Theme.of(this).primarySwatch[100],
              shape: Shape.circle
            ) : null,
            child: new Center(
              child: new Text(label, style: style)
            )
          )
        )
      );
      items.add(item);
    }
    return items;
  }
}
