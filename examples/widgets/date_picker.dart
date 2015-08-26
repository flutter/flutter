// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

void main() => runApp(new DatePickerDemo());

class DatePickerDemo extends App {

  DateTime _dateTime;

  void initState() {
    DateTime now = new DateTime.now();
    _dateTime = new DateTime(now.year, now.month, now.day);
  }

  void _handleDateChanged(DateTime dateTime) {
    setState(() {
      _dateTime = dateTime;
    });
  }

  Widget build() {
    return new Theme(
      data: new ThemeData(
        brightness: ThemeBrightness.light,
        primarySwatch: colors.Teal
      ),
      child: new Stack([
        new Scaffold(
          toolbar: new ToolBar(center: new Text("Date Picker")),
          body: new Material(
            child: new Row(
              [new Text(_dateTime.toString())],
              alignItems: FlexAlignItems.end,
              justifyContent: FlexJustifyContent.center
            )
          )
        ),
        new Dialog(
          content: new DatePicker(
            selectedDate: _dateTime,
            firstDate: new DateTime(2015, 8),
            lastDate: new DateTime(2101),
            onChanged: _handleDateChanged
          ),
          contentPadding: EdgeDims.zero,
          actions: [
            new FlatButton(
              child: new Text('CANCEL')
            ),
            new FlatButton(
              child: new Text('OK')
            ),
          ]
        )
      ])
    );
  }
}
