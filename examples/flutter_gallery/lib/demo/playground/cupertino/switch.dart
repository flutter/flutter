// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_gallery/demo/playground/playground_demo.dart';
import 'package:flutter_gallery/demo/playground/configuration/material_helpers.dart';

const String _demoWidgetName = 'CupertinoSwitch';

class CupertinoSwitchDemo extends PlaygroundDemo {
  Color _activeColor = Colors.blue;
  bool _value = true;

  @override
  String tabName() => _demoWidgetName.toUpperCase();

  @override
  String code() => '''
CupertinoSwitch(
  value: $_value,
  activeColor: ${codeSnippetForColor(_activeColor)},
  onChanged: (bool value) {},
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
