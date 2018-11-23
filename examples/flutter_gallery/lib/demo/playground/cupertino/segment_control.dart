// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/playground/playground_demo.dart';
import 'package:flutter_gallery/demo/playground/configuration/material_helpers.dart';

const String _demoWidgetName = 'CupertinoSegmentControl';

class CupertinoSegmentControlDemo extends PlaygroundDemo {
  Color _selectedColor = Colors.blue;
  Color _borderColor = Colors.blue;
  int _groupValue = 0;

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
    final List<Color> colors =
        kColorOptions.where((Color c) => c != Colors.white).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        colorPicker(
            label: 'Selected Color',
            colors: colors,
            selectedValue: _selectedColor,
            onItemTapped: (int index, Color color) {
              updateConfiguration(() {
                _selectedColor = color;
              });
            }),
        colorPicker(
            label: 'Border Color',
            colors: colors,
            inverse: true,
            selectedValue: _borderColor,
            onItemTapped: (int index, Color color) {
              updateConfiguration(() {
                _borderColor = color;
              });
            }),
        
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
      padding: const EdgeInsets.only(left: 15.0).copyWith(right: 15.0),
      child: CupertinoSegmentedControl<int>(
        children: children,
        selectedColor: _selectedColor,
        borderColor: _borderColor,
        pressedColor: _selectedColor.withOpacity(0.4),
        onValueChanged: (int value) {
          updateConfiguration(() {
            _groupValue = value;
          });
        },
        groupValue: _groupValue,
      ),
    );
  }
}
