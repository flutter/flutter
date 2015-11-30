// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'dialog.dart';
import 'date_picker.dart';
import 'flat_button.dart';

class _DatePickerDialog extends StatefulComponent {
  _DatePickerDialog({
    Key key,
    this.initialDate,
    this.firstDate,
    this.lastDate
  }) : super(key: key);

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  _DatePickerDialogState createState() => new _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  void initState() {
    super.initState();
    _selectedDate = config.initialDate;
  }

  DateTime _selectedDate;

  void _handleDateChanged(DateTime value) {
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

  Widget build(BuildContext context) {
    return new Dialog(
      content: new DatePicker(
        selectedDate: _selectedDate,
        firstDate: config.firstDate,
        lastDate: config.lastDate,
        onChanged: _handleDateChanged
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

Future<DateTime> showDatePicker({
  BuildContext context,
  DateTime initialDate,
  DateTime firstDate,
  DateTime lastDate
}) async {
  DateTime picked = await showDialog(
    context: context,
    child: new _DatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate
    )
  );
  return picked ?? initialDate;
}
