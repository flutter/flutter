// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() => runApp(new DatePickerDemo());

class DatePickerDemo extends StatefulComponent {
  DatePickerDemoState createState() => new DatePickerDemoState();
}

class DatePickerDemoState extends State<DatePickerDemo> {
  void initState() {
    super.initState();
    DateTime now = new DateTime.now();
    _dateTime = new DateTime(now.year, now.month, now.day);
  }

  DateTime _dateTime;

  void _handleDateChanged(DateTime dateTime) {
    setState(() {
      _dateTime = dateTime;
    });
  }

  Widget build(BuildContext context) {
    return new Theme(
      data: new ThemeData(
        brightness: ThemeBrightness.light,
        primarySwatch: Colors.teal
      ),
      child: new Stack(<Widget>[
        new Scaffold(
          toolBar: new ToolBar(center: new Text("Date Picker")),
          body: new Row(
            <Widget>[new Text(_dateTime.toString())],
            alignItems: FlexAlignItems.end,
            justifyContent: FlexJustifyContent.center
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
          actions: <Widget>[
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
