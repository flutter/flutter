// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../configuration/helpers.dart';
import '../configuration/pickers.dart';
import '../playground_demo.dart';

class CheckboxDemo extends StatefulWidget {
  @override
  _CheckboxDemoState createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<CheckboxDemo> {
  Color _activeColor = Colors.blue;
  bool _value = true;

  String get codePreview => '''
Checkbox(
  value: $_value,
  activeColor: ${codeSnippetForColor(_activeColor)},
  onChanged: (bool value) {},
)
''';

  @override
  Widget build(BuildContext context) {
    return PlaygroundDemo(
      previewWidget: Center(
        child: Checkbox(
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
