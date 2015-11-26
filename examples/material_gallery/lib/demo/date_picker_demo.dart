// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'widget_demo.dart';

class DatePickerDemo extends StatefulComponent {
  _DatePickerDemoState createState() => new _DatePickerDemoState();
}

class _DatePickerDemoState extends State<DatePickerDemo> {
  DateTime _selectedDate = new DateTime.now();

  Future _handleSelectDate() async {
    DateTime picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: new DateTime(2015, 8),
      lastDate: new DateTime(2101)
    );
    if (picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget build(BuildContext context) {
    return new Column([
      new Text(new DateFormat.yMMMd().format(_selectedDate)),
      new RaisedButton(
        onPressed: _handleSelectDate,
        child: new Text('SELECT DATE')
      ),
    ], justifyContent: FlexJustifyContent.center);
  }
}

final WidgetDemo kDatePickerDemo = new WidgetDemo(
  title: 'Date Picker',
  routeName: '/date-picker',
  builder: (_) => new DatePickerDemo()
);
