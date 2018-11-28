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

const String _demoWidgetName = 'CupertinoSlider';

class CupertinoSliderDemo extends PlaygroundDemo {
  Color _activeColor = Colors.blue;
  double _value = 5.0;

  @override
  String tabName() => _demoWidgetName.toUpperCase();

  @override
  String codePreview() => '''
CupertinoSlider(
  value: $_value,
  activeColor: ${codeSnippetForColor(_activeColor)},
  min: 0.0,
  max: 10.0,
  divisions: 10,
  onChanged: (double value) {}
)
''';

  final List<Color> _colors = kColorChoices
      .map((ColorChoice c) => c.color)
      .where((Color c) => c != Colors.white)
      .toList();

  @override
  Widget configWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ColorPicker(
          label: 'Active Color',
          selectedValue: _activeColor,
          colors: _colors,
          onItemTapped: (Color color) {
            updateConfiguration(() {
              _activeColor = color;
            });
          }),
      ],
    );
  }

  @override
  Widget previewWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, right: 25.0),
      child: CupertinoSlider(
        value: _value,
        activeColor: _activeColor,
        min: 0.0,
        max: 10.0,
        divisions: 10,
        onChanged: (double value) {
          updateConfiguration(() {
            _value = value;
          });
        }),
    );
  }
}
