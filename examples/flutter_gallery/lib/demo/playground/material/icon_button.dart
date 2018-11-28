// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../configuration/helpers.dart';
import '../configuration/pickers.dart';
import '../configuration/property_column.dart';
import '../playground_demo.dart';

const String _demoWidgetName = 'IconButton';

class IconButtonDemo extends PlaygroundDemo {
  Color _color = Colors.blue;
  IconData _icon = Icons.thumb_up;

  @override
  String tabName() => _demoWidgetName.toUpperCase();

  @override
  String codePreview() => '''
IconButton(
  iconSize: 50.0,
  icon: Icon(${codeSnippetForIcon(_icon)}),
  onPressed: () {},
  color: ${codeSnippetForColor(_color)},
  splashColor: ${codeSnippetForColor(_color)}.withOpacity(0.2),
)
''';

  @override
  Widget configWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IconPicker(
          activeColor: _color,
          selectedValue: _icon,
          onItemTapped: (IconData icon) {
            updateConfiguration(() {
              _icon = icon;
            });
          }),
        ColorPicker(
          selectedValue: _color,
          onItemTapped: (Color color) {
            updateConfiguration(() {
              _color = color;
            });
          }),
      ],
    );
  }

  @override
  Widget previewWidget(BuildContext context) {

    print(Colors.lightBlue[300]);

    return Center(
      child: IconButton(
        iconSize: 50.0,
        icon: Icon(_icon),
        onPressed: () {},
        color: _color,
        splashColor: _color.withOpacity(0.2),
      ),
    );
  }
}
