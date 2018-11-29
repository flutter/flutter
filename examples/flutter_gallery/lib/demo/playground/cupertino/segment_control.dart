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

class CupertinoSegmentControlDemo extends StatefulWidget {
  @override
  _CupertinoSegmentControlDemoState createState() => _CupertinoSegmentControlDemoState();
}

class _CupertinoSegmentControlDemoState extends State<CupertinoSegmentControlDemo> {
  static final List<Color> _colors = kColorChoices
      .map((ColorChoice c) => c.color)
      .where((Color c) => c != Colors.white)
      .toList();

  Color _selectedColor = Colors.blue;
  int _groupValue = 0;

  String get codePreview => '''
CupertinoSegmentedControl<int>(
  children: <Widget>[
    Text('A'),
    Text('B'),
    Text('C'),
  ],
  selectedColor: ${codeSnippetForColor(_selectedColor)},
  borderColor: ${codeSnippetForColor(_selectedColor)},
  pressedColor: ${codeSnippetForColor(_selectedColor)}.withOpacity(0.4),
  onValueChanged: (int value) {},
  groupValue: $_groupValue,
) 
''';

  @override
  Widget build(BuildContext context) {
    return PlaygroundDemo(
      previewWidget: Padding(
        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
        child: CupertinoSegmentedControl<int>(
          selectedColor: _selectedColor,
          borderColor: _selectedColor,
          pressedColor: _selectedColor.withOpacity(0.4),
          onValueChanged: (int value) {
            setState(() {
              _groupValue = value;
            });
          },
          groupValue: _groupValue,
          children: const <int, Widget>{
              0: Text('A'),
              1: Text('B'),
              2: Text('C'),
            },
        ),
      ),
      configWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ColorPicker(
            label: 'Selected Color',
            colors: _colors,
            selectedValue: _selectedColor,
            onItemTapped: (Color color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
        ],
      ),
      codePreview: codePreview,
    );
  }
}
