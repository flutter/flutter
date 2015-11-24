// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';
import 'typography.dart';

class TimeOfDay {
  const TimeOfDay({ this.hour, this.minute });

  /// The selected hour, in 24 hour time from 0..23
  final int hour;

  /// The selected minute.
  final int minute;
}

enum _TimePickerMode { hour, minute }

class TimePicker extends StatefulComponent {
  TimePicker({
    this.selectedTime,
    this.onChanged
  }) {
    assert(selectedTime != null);
  }

  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onChanged;

  _TimePickerState createState() => new _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  _TimePickerMode _mode = _TimePickerMode.hour;

  void _handleModeChanged(_TimePickerMode mode) {
    userFeedback.performHapticFeedback(HapticFeedbackType.VIRTUAL_KEY);
    setState(() {
      _mode = mode;
    });
  }

  Widget build(BuildContext context) {
    Widget header = new _TimePickerHeader(
      selectedTime: config.selectedTime,
      mode: _mode,
      onModeChanged: _handleModeChanged
    );
    return new Column(<Widget>[
      header,
      new AspectRatio(
        aspectRatio: 1.0,
        child: new Container(
          margin: const EdgeDims.all(12.0),
          decoration: new BoxDecoration(
            backgroundColor: Colors.grey[300],
            shape: Shape.circle
          )
        )
      )
    ], alignItems: FlexAlignItems.stretch);
  }

}

// Shows the selected date in large font and toggles between year and day mode
class _TimePickerHeader extends StatelessComponent {
  _TimePickerHeader({ this.selectedTime, this.mode, this.onModeChanged }) {
    assert(selectedTime != null);
    assert(mode != null);
  }

  TimeOfDay selectedTime;
  _TimePickerMode mode;
  ValueChanged<_TimePickerMode> onModeChanged;

  void _handleChangeMode(_TimePickerMode value) {
    if (value != mode)
      onModeChanged(value);
  }

  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextTheme headerTheme = theme.primaryTextTheme;

    Color activeColor;
    Color inactiveColor;
    switch(theme.primaryColorBrightness) {
      case ThemeBrightness.light:
        activeColor = Colors.black87;
        inactiveColor = Colors.black54;
        break;
      case ThemeBrightness.dark:
        activeColor = Colors.white;
        inactiveColor = Colors.white70;
        break;
    }
    TextStyle activeStyle = headerTheme.display3.copyWith(color: activeColor, height: 1.0);
    TextStyle inactiveStyle = headerTheme.display3.copyWith(color: inactiveColor, height: 1.0);

    TextStyle hourStyle = mode == _TimePickerMode.hour ? activeStyle : inactiveStyle;
    TextStyle minuteStyle = mode == _TimePickerMode.minute ? activeStyle : inactiveStyle;

    return new Container(
      padding: new EdgeDims.all(10.0),
      decoration: new BoxDecoration(backgroundColor: theme.primaryColor),
      child: new Row(<Widget>[
        new GestureDetector(
          onTap: () => _handleChangeMode(_TimePickerMode.hour),
          child: new Text(selectedTime.hour.toString(), style: hourStyle)
        ),
        new Text(':', style: inactiveStyle),
        new GestureDetector(
          onTap: () => _handleChangeMode(_TimePickerMode.minute),
          child: new Text(selectedTime.minute.toString(), style: minuteStyle)
        ),
      ], justifyContent: FlexJustifyContent.end)
    );
  }
}
