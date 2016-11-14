// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerDemo extends StatefulWidget {
  static const String routeName = '/date-picker';

  @override
  _DatePickerDemoState createState() => new _DatePickerDemoState();
}

class _DatePickerDemoState extends State<DatePickerDemo> {
  DateTime _selectedDate = new DateTime.now();

  Future<Null> _handleSelectDate() async {
    DateTime picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: new DateTime(2015, 8),
      lastDate: new DateTime(2101)
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return
      new Scaffold(
      appBar: new AppBar(title: new Text('Date picker')),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(new DateFormat.yMMMd().format(_selectedDate)),
            new SizedBox(height: 20.0),
            new RaisedButton(
              onPressed: _handleSelectDate,
              child: new Text('SELECT DATE')
            ),
          ],
        ),
      )
    );
  }
}
