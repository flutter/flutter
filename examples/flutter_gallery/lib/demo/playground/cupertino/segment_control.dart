// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../configuration/choices.dart';
import '../configuration/constants.dart';
import '../configuration/helpers.dart';
import '../configuration/pickers.dart';
import '../playground_demo.dart';

const String _demoWidgetName = 'CupertinoSegmentControl';

class CupertinoSegmentControlDemo extends PlaygroundDemo {
  Color _selectedColor = Colors.blue;
  Color _borderColor = Colors.blue;
  int _groupValue = 0;

  final List<Color> _colors = kColorChoices
      .map((ColorChoice c) => c.color)
      .where((Color c) => c != Colors.white)
      .toList();

  @override
  String tabName() => _demoWidgetName.toUpperCase();

  @override
  String codePreview() => '''
CupertinoSegmentedControl<int>(
  children: <Widget>[
    Text('A'),
    Text('B'),
    Text('C'),
  ],
  selectedColor: ${codeSnippetForColor(_selectedColor)},
  borderColor: ${codeSnippetForColor(_borderColor)},
  pressedColor: ${codeSnippetForColor(_selectedColor)}.withOpacity(0.4),
  onValueChanged: (int value) {},
  groupValue: $_groupValue,
) 
''';

  @override
  Widget configWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ColorPicker(
          label: 'Selected Color',
          colors: _colors,
          selectedValue: _selectedColor,
          onItemTapped: (Color color) {
            updateConfiguration(() {
              _selectedColor = color;
            });
          },
        ),
        ColorPicker(
          label: 'Border Color',
          colors: _colors,
          inverse: true,
          selectedValue: _borderColor,
          onItemTapped: (Color color) {
            updateConfiguration(() {
              _borderColor = color;
            });
          },
        ),
      ],
    );
  }

  final Map<int, Widget> children = const <int, Widget>{
    0: Text('A'),
    1: Text('B'),
    2: Text('C'),
  };

  @override
  Widget previewWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15.0),
      child: CupertinoSegmentedControl<int>(
        children: children,
        selectedColor: _selectedColor,
        borderColor: _borderColor,
        pressedColor: _selectedColor.withOpacity(0.4),
        groupValue: _groupValue,
        onValueChanged: (int value) {
          updateConfiguration(() {
            _groupValue = value;
          });
        },
      ),
    );
  }
}
