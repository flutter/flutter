// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

import '../configuration/material_helpers.dart';
import '../playground_demo.dart';

const String _demoWidgetName = 'CupertinoSlider';

/// ignore: must_be_immutable
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

  @override
  Widget configWidget(BuildContext context) {
    final List<Color> colors =
        colorOptions.where((Color c) => c != Colors.white).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        colorPicker(
            label: 'Active Color',
            selectedValue: _activeColor,
            colors: colors,
            onItemTapped: (int index, Color color) {
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
      padding: const EdgeInsets.only(left: 25.0).copyWith(right: 25.0),
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
