// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/playground/playground_demo.dart';
import 'package:flutter_gallery/demo/playground/configuration/material_helpers.dart';

class RaisedButtonDemo extends PlaygroundDemo {
  double _elevation = 8.0;
  String _borderShape = 'rounded';
  Color _color = Colors.blue;
  Color _splashColor = Colors.lightBlue;

  @override
  String tabName() => 'RAISEDBUTTON';

  @override
  String code() => '';

  @override
  Widget configWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _elevationPicker(),
        shapePicker(
          selectedValue: _borderShape,
          onItemTapped: (int index, String shapeName) {
            updateConfiguration(() {
              _borderShape = shapeName;
            });
          },
        ),
        colorPicker(
          selectedValue: _color,
          onItemTapped: (int index, Color color) {
            updateConfiguration(() {
              _color = color;
            });
          }
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
        child: RaisedButton(
          padding: const EdgeInsets.all(5.0),
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
                  borderRadius: BorderRadius.circular(30.0))
              : borderShapeFromString(_borderShape, false),
          elevation: _elevation,
          splashColor: _splashColor,
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _elevationPicker() => sliderPicker(
        label: 'Elevation',
        value: _elevation,
        minValue: 0.0,
        maxValue: 24.0,
        divisions: 6,
        onValueChanged: (double value) {
          updateConfiguration(() {
            _elevation = value;
          });
        },
      );
}
