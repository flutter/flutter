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

const String _demoWidgetName = 'CupertinoSwitch';

class CupertinoSwitchDemo extends PlaygroundDemo {
  Color _activeColor = Colors.blue;
  bool _value = true;

  @override
  String tabName() => _demoWidgetName.toUpperCase();

  @override
  String codePreview() => '''
CupertinoSwitch(
  value: $_value,
  activeColor: ${codeSnippetForColor(_activeColor)},
  onChanged: (bool value) {},
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
          },
        ),
      ],
    );
  }

  @override
  Widget previewWidget(BuildContext context) {
    return Center(
      child: CupertinoSwitch(
        value: _value,
        activeColor: _activeColor,
        onChanged: (bool value) {
          updateConfiguration(() {
            _value = value;
          });
        },
      ),
    );
  }
}
