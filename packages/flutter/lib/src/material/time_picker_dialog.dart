// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'dialog.dart';
import 'time_picker.dart';
import 'flat_button.dart';

class _TimePickerDialog extends StatefulWidget {
  _TimePickerDialog({
    Key key,
    this.initialTime
  }) : super(key: key);

  final TimeOfDay initialTime;

  @override
  _TimePickerDialogState createState() => new _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  @override
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

  @override
  Widget build(BuildContext context) {
    // TODO(abarth): Use Dialog directly.
    return new AlertDialog(
      content: new TimePicker(
        selectedTime: _selectedTime,
        onChanged: _handleTimeChanged
      ),
      contentPadding: EdgeInsets.zero,
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

/// Shows a dialog containing a material design time picker.
///
/// The returned Future resolves to the time selected by the user when the user
/// closes the dialog. If the user cancels the dialog, the Future resolves to
/// the [initialTime].
///
/// To show a dialog with [initialTime] equal to the current time:
/// ```dart
/// final DateTime now = new DateTime.now();
/// showTimePicker(
///   initialTime: new TimeOfDay(hour: now.hour, minute: now.minute),
///   context: context
/// );
/// ```
///
/// See also:
///
///  * [TimePicker]
///  * [showDatePicker]
///  * <https://www.google.com/design/spec/components/pickers.html#pickers-time-pickers>
Future<TimeOfDay> showTimePicker({
  BuildContext context,
  TimeOfDay initialTime
}) async {
  return await showDialog(
    context: context,
    child: new _TimePickerDialog(initialTime: initialTime)
  ) ?? initialTime;
}
