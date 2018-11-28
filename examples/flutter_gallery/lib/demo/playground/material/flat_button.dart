// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../configuration/helpers.dart';
import '../configuration/pickers.dart';
import '../playground_demo.dart';

const String _demoWidgetName = 'FlatButton';

class FlatButtonDemo extends PlaygroundDemo {
  String _borderShape = 'rounded';
  Color _color = Colors.blue;

  @override
  String tabName() => _demoWidgetName.toUpperCase();

  @override
  String codePreview() => '''
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
  Widget configWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BorderPicker(
          selectedValue: _borderShape,
          onItemTapped: (String shapeName) {
            updateConfiguration(() {
              _borderShape = shapeName;
            });
          },
        ),
        ColorPicker(
          selectedValue: _color,
          onItemTapped: (Color color) {
            updateConfiguration(() {
              _color = color;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget previewWidget(BuildContext context) {
    return Center(
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
          shape: _borderShape == 'circle'
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                )
              : borderShapeFromString(_borderShape, false),
          onPressed: () {},
        ),
      ),
    );
  }
}
