// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../configuration/helpers.dart';
import '../configuration/pickers.dart';
import '../playground_demo.dart';

class RaisedButtonDemo extends StatefulWidget {
  @override
  _RaisedButtonDemoState createState() => _RaisedButtonDemoState();
}

class _RaisedButtonDemoState extends State<RaisedButtonDemo> {
  double _elevation = 8.0;
  String _borderShape = 'rounded';
  Color _color = Colors.blue;

  static String title = 'RaisedButton'.toUpperCase();

  String get codePreview => '''
RaisedButton(
  color: ${codeSnippetForColor(_color)},
  child: Text(
    'BUTTON',
    style: TextStyle(
      fontSize: 16.0,
    ),
  ),
  shape: ${codeSnippetForBorder(_borderShape)}
  elevation: $_elevation,
  onPressed: () {},
)
''';

  @override
  Widget build(BuildContext context) {
    return PlaygroundDemo(
      previewWidget: Center(
        child: ButtonTheme(
          minWidth: 160.0,
          height: 50.0,
          child: RaisedButton(
            color: _color,
            child: Text(
              'BUTTON',
              style: TextStyle(
                fontSize: 16.0,
                color: _color == Colors.white ? Colors.grey[900] : Colors.white,
              ),
            ),
            shape: borderShapeFromString(_borderShape, false),
            elevation: _elevation,
            onPressed: () {},
          ),
        ),
      ),
      configWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SliderPicker(
            label: 'Elevation',
            value: _elevation,
            minValue: 0.0,
            maxValue: 24.0,
            divisions: 6,
            onValueChanged: (double value) {
              setState(() {
                _elevation = value;
              });
            },
          ),
          BorderPicker(
            selectedValue: _borderShape,
            onItemTapped: (String borderShape) {
              setState(() {
                _borderShape = borderShape;
              });
            },
          ),
          ColorPicker(
            selectedValue: _color,
            onItemTapped: (Color color) {
              setState(() {
                _color = color;
              });
            },
          ),
        ],
      ),
      codePreview: codePreview,
    );
  }
}
