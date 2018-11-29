// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

import '../configuration/choices.dart';
import '../configuration/constants.dart';
import '../configuration/helpers.dart';
import '../configuration/pickers.dart';
import '../playground_demo.dart';

class CupertinoSwitchDemo extends StatefulWidget {
  @override
  _CupertinoSwitchDemoState createState() => _CupertinoSwitchDemoState();
}

class _CupertinoSwitchDemoState extends State<CupertinoSwitchDemo> {
  static final List<Color> _colors = kColorChoices
      .map((ColorChoice c) => c.color)
      .where((Color c) => c != Colors.white)
      .toList();

  Color _activeColor = Colors.blue;
  bool _value = true;

  String get codePreview => '''
CupertinoSwitch(
  value: $_value,
  activeColor: ${codeSnippetForColor(_activeColor)},
  onChanged: (bool value) {},
)
''';

  @override
  Widget build(BuildContext context) {
    return PlaygroundDemo(
      previewWidget: Center(
        child: CupertinoSwitch(
          value: _value,
          activeColor: _activeColor,
          onChanged: (bool value) {
            setState(() {
              _value = value;
            });
          },
        ),
      ),
      configWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ColorPicker(
            label: 'Active Color',
            selectedValue: _activeColor,
            colors: _colors,
            onItemTapped: (Color color) {
              setState(() {
                _activeColor = color;
              });
            },
          ),
        ],
      ),
      codePreview: codePreview,
    );
  }
}
