// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../configuration/helpers.dart';
import '../configuration/pickers.dart';
import '../playground_demo.dart';

class SwitchDemo extends StatefulWidget {
  @override
  _SwitchDemoState createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<SwitchDemo> {
  Color _activeColor = Colors.blue;
  Color _activeTrackColor = Colors.blue;
  Color _inactiveTrackColor = Colors.blue;
  bool _previewValue = true;

  String get codePreview => '''
Switch(
  value: $_previewValue,
  activeColor: ${codeSnippetForColor(_activeColor)},
  activeTrackColor: ${codeSnippetForColor(_activeTrackColor)},
  inactiveTrackColor: ${codeSnippetForColor(_inactiveTrackColor)},
  onChanged: (bool value) {},
)
''';

  @override
  Widget build(BuildContext context) {
    return PlaygroundDemo(
      previewWidget: Center(
        child: Switch(
          value: _previewValue,
          activeColor: _activeColor,
          activeTrackColor: _activeTrackColor,
          inactiveTrackColor: _inactiveTrackColor,
          onChanged: (bool value) {
            setState(() {
              _previewValue = value;
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
          ColorPicker(
            label: 'Active Track Color',
            selectedValue: _activeTrackColor,
            onItemTapped: (Color color) {
              setState(() {
                _activeTrackColor = color;
              });
            },
          ),
          ColorPicker(
            label: 'Inactive Track Color',
            selectedValue: _inactiveTrackColor,
            onItemTapped: (Color color) {
              setState(() {
                _inactiveTrackColor = color;
              });
            },
          ),
        ],
      ),
      codePreview: codePreview,
    );
  }
}
