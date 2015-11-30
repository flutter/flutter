// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'dialog.dart';
import 'time_picker.dart';
import 'flat_button.dart';

class _TimePickerDialog extends StatefulComponent {
  _TimePickerDialog({
    Key key,
    this.initialTime
  }) : super(key: key);

  final TimeOfDay initialTime;

  _TimePickerDialogState createState() => new _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  void initState() {
    super.initState();
    _selectedTime = config.initialTime;
  }

  TimeOfDay _selectedTime;

  void _handleTimeChanged(TimeOfDay value) {
    setState(() {
      _selectedTime = value;
    });
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    Navigator.pop(context, _selectedTime);
  }

  Widget build(BuildContext context) {
    return new Dialog(
      content: new TimePicker(
        selectedTime: _selectedTime,
        onChanged: _handleTimeChanged
      ),
      contentPadding: EdgeDims.zero,
      actions: <Widget>[
        new FlatButton(
          child: new Text('CANCEL'),
          onPressed: _handleCancel
        ),
        new FlatButton(
          child: new Text('OK'),
          onPressed: _handleOk
        ),
      ]
    );
  }
}

Future<TimeOfDay> showTimePicker({
  BuildContext context,
  TimeOfDay initialTime
}) async {
  return await showDialog(
    context: context,
    child: new _TimePickerDialog(initialTime: initialTime)
  ) ?? initialTime;
}
