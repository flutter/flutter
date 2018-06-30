// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A test page with a checkbox, three radio buttons, and a switch.
class SelectionControlsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _SelectionControlsPageState();
}

class _SelectionControlsPageState extends State<SelectionControlsPage> {
  static const ValueKey<String> checkbox1Key = ValueKey<String>('SelectionControls#Checkbox1');
  static const ValueKey<String> checkbox2Key = ValueKey<String>('SelectionControls#Checkbox2');
  static const ValueKey<String> radio1Key = ValueKey<String>('SelectionControls#Radio1');
  static const ValueKey<String> radio2Key = ValueKey<String>('SelectionControls#Radio2');
  static const ValueKey<String> radio3Key = ValueKey<String>('SelectionControls#Radio3');
  static const ValueKey<String> switchKey = ValueKey<String>('SelectionControls#Switch');

  bool _isChecked = false;
  bool _isOn = false;
  int _radio = 0;


  void _updateCheckbox(bool newValue) {
    setState(() {
      _isChecked = newValue;
    });
  }

  void _updateRadio(int newValue) {
    setState(() {
      _radio = newValue;
    });
  }

  void _updateSwitch(bool newValue) {
    setState(() {
      _isOn = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(leading: const BackButton(key: const ValueKey<String>('back'))),
      body: new Material(
        child: new Column(children: <Widget>[
          new Row(
            children: <Widget>[
              new Checkbox(
                key: checkbox1Key,
                value: _isChecked,
                onChanged: _updateCheckbox,
              ),
              const Checkbox(
                key: checkbox2Key,
                value: false,
                onChanged: null,
              )
            ],
          ),
          const Spacer(),
          new Row(children: <Widget>[
            new Radio<int>(key: radio1Key, value: 0, groupValue: _radio, onChanged: _updateRadio),
            new Radio<int>(key: radio2Key, value: 1, groupValue: _radio, onChanged: _updateRadio),
            new Radio<int>(key: radio3Key, value: 2, groupValue: _radio, onChanged: _updateRadio),
          ]),
          const Spacer(),
          new Switch(
            key: switchKey,
            value: _isOn,
            onChanged: _updateSwitch,
          ),
        ]),
      ),
    );
  }
}