// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../configuration/helpers.dart';
import '../configuration/pickers.dart';
import '../playground_demo.dart';

class IconButtonDemo extends StatefulWidget {
  @override
  _IconButtonDemoState createState() => _IconButtonDemoState();
}

class _IconButtonDemoState extends State<IconButtonDemo> {
  Color _color = Colors.blue;
  IconData _icon = Icons.thumb_up;

  String get codePreview => '''
IconButton(
  iconSize: 50.0,
  icon: Icon(${codeSnippetForIcon(_icon)}),
  onPressed: () {},
  color: ${codeSnippetForColor(_color)},
  splashColor: ${codeSnippetForColor(_color)}.withOpacity(0.2),
)
''';

  @override
  Widget build(BuildContext context) {
    return PlaygroundDemo(
      previewWidget: Center(
        child: IconButton(
          iconSize: 50.0,
          icon: Icon(_icon),
          onPressed: () {},
          color: _color,
          splashColor: _color.withOpacity(0.2),
        ),
      ),
      configWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          IconPicker(
            activeColor: _color,
            selectedValue: _icon,
            onItemTapped: (IconData icon) {
              setState(() {
                _icon = icon;
              });
            },
          ),
          ColorPicker(
            selectedValue: _color,
            onItemTapped: (Color color) {
              setState(() {
                _color = color;
              });
            },
          ),
        ],
      ),
      codePreview: codePreview,
    );
  }
}
