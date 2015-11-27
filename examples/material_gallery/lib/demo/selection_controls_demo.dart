// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'widget_demo.dart';

class SelectionControlsDemo extends StatefulComponent {
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

  Widget build(BuildContext context) {
    return new Column(<Widget>[
      new Row(<Widget>[
        new Checkbox(value: _checkboxValue, onChanged: _setCheckboxValue),
        new Checkbox(value: false), // Disabled
        new Checkbox(value: true), // Disabled
      ], justifyContent: FlexJustifyContent.spaceAround),
      new Row(<int>[0, 1, 2].map((int i) {
        return new Radio<int>(
          value: i,
          groupValue: _radioValue,
          onChanged: _setRadioValue
        );
      }).toList(), justifyContent: FlexJustifyContent.spaceAround),
      new Row(<int>[0, 1].map((int i) {
        return new Radio<int>(value: i, groupValue: 0); // Disabled
      }).toList(), justifyContent: FlexJustifyContent.spaceAround),
      new Row(<Widget>[
        new Switch(value: _switchValue, onChanged: _setSwitchValue),
        new Switch(value: false), // Disabled
        new Switch(value: true), // Disabled
      ], justifyContent: FlexJustifyContent.spaceAround),
    ], justifyContent: FlexJustifyContent.spaceAround);
  }
}

final WidgetDemo kSelectionControlsDemo = new WidgetDemo(
  title: 'Selection Controls',
  routeName: '/selection-controls',
  builder: (_) => new SelectionControlsDemo()
);
