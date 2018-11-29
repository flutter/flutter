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

class CupertinoSliderDemo extends StatefulWidget {
  @override
  _CupertinoSliderDemoState createState() => _CupertinoSliderDemoState();
}

class _CupertinoSliderDemoState extends State<CupertinoSliderDemo> {
  static final List<Color> _colors = kColorChoices
      .map((ColorChoice c) => c.color)
      .where((Color c) => c != Colors.white)
      .toList();

  Color _activeColor = Colors.blue;
  double _value = 5.0;

  String get codePreview => '''
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
  Widget build(BuildContext context) {
    return PlaygroundDemo(
      codePreview: codePreview,
      previewWidget: _buildPreviewWidget(context),
      configWidget: _buildConfigWidget(context),
    );
  }

  Widget _buildConfigWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ColorPicker(
          label: 'Active Color',
          selectedValue: _activeColor,
          colors: _colors,
          onItemTapped: (Color color) {
            setState(() {
              _activeColor = color;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreviewWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, right: 25.0),
      child: CupertinoSlider(
        value: _value,
        activeColor: _activeColor,
        min: 0.0,
        max: 10.0,
        divisions: 10,
        onChanged: (double value) {
          setState(() {
            _value = value;
          });
        },
      ),
    );
  }
}
