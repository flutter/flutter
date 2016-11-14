// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

class TimePickerDemo extends StatefulWidget {
  static const String routeName = '/time-picker';

  @override
  _TimePickerDemoState createState() => new _TimePickerDemoState();
}

class _TimePickerDemoState extends State<TimePickerDemo> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 28);

  Future<Null> _handleSelectTime() async {
    TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Time picker')),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text('$_selectedTime'),
            new SizedBox(height: 20.0),
            new RaisedButton(
              onPressed: _handleSelectTime,
              child: new Text('SELECT TIME')
            ),
          ],
        ),
      ),
    );
  }
}
