// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class SelectionControlsDemo extends StatefulWidget {
  @override
  _SelectionControlsDemoState createState() => new _SelectionControlsDemoState();
}

class _SelectionControlsDemoState extends State<SelectionControlsDemo> {
  bool _checkboxValue = false;
  int _radioValue = 0;
  bool _switchValue = false;

  void _setCheckboxValue(bool value) {
    setState(() {
      _checkboxValue = value;
    });
  }

  void _setRadioValue(int value) {
    setState(() {
      _radioValue = value;
    });
  }

  void _setSwitchValue(bool value) {
    setState(() {
      _switchValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Selection Controls")),
      body: new Column(
        children: <Widget>[
          new Row(
            children: <Widget>[
              new Checkbox(value: _checkboxValue, onChanged: _setCheckboxValue),
              new Checkbox(value: false), // Disabled
              new Checkbox(value: true), // Disabled
            ],
            mainAxisAlignment: MainAxisAlignment.spaceAround
          ),
          new Row(
            children: <int>[0, 1, 2].map((int i) {
              return new Radio<int>(
                value: i,
                groupValue: _radioValue,
                onChanged: _setRadioValue
              );
            }).toList(),
            mainAxisAlignment: MainAxisAlignment.spaceAround
          ),
          new Row(
            children: <int>[0, 1].map((int i) {
              return new Radio<int>(value: i, groupValue: 0); // Disabled
            }).toList(),
            mainAxisAlignment: MainAxisAlignment.spaceAround
          ),
          new Row(
            children: <Widget>[
              new Switch(value: _switchValue, onChanged: _setSwitchValue),
              new Switch(value: false), // Disabled
              new Switch(value: true), // Disabled
            ],
            mainAxisAlignment: MainAxisAlignment.spaceAround
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceAround
      )
    );
  }
}
