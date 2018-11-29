// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../configuration/helpers.dart';
import '../configuration/pickers.dart';
import '../playground_demo.dart';

class FlatButtonDemo extends StatefulWidget {
  @override
  _FlatButtonDemoState createState() => _FlatButtonDemoState();
}

class _FlatButtonDemoState extends State<FlatButtonDemo> {
  String _borderShape = 'rounded';
  Color _color = Colors.blue;

  String get codePreview => '''
FlatButton(
  color: ${codeSnippetForColor(_color)},
  child: Text(
    'BUTTON',
    style: TextStyle(
      fontSize: 16.0,
    ),
  ),
  shape: ${codeSnippetForBorder(_borderShape)},
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
          child: FlatButton(
            color: _color,
            child: Text(
              'BUTTON',
              style: TextStyle(
                fontSize: 16.0,
                color: _color == Colors.white ? Colors.grey[900] : Colors.white,
              ),
            ),
            shape: borderShapeFromString(_borderShape, false),
            onPressed: () {},
          ),
        ),
      ),
      configWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BorderPicker(
            selectedValue: _borderShape,
            onItemTapped: (String shapeName) {
              setState(() {
                _borderShape = shapeName;
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
