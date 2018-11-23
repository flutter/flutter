// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/playground/playground_demo.dart';
import 'package:flutter_gallery/demo/playground/configuration/material_helpers.dart';
import 'package:flutter_gallery/demo/playground/configuration/property_column.dart';

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
  icon: Icon($_icon),
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
        _iconPicker(context),
        colorPicker(
            selectedValue: _color,
            onItemTapped: (int index, Color color) {
              updateConfiguration(() {
                _color = color;
              });
            }),
      ],
    );
  }

  @override
  Widget previewWidget(BuildContext context) {
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

  Widget _iconPicker(BuildContext context) {
    final List<Widget> buttonChildren = <Widget>[];
    for (int i = 0; i < kIconOptions.length; i++) {
      final IconData icon = kIconOptions[i];
      Widget button = IconButton(
        iconSize: 30.0,
        icon: Icon(icon),
        onPressed: () {
          updateConfiguration(() {
            _icon = icon;
          });
        },
        color: _icon == icon ? _color : Colors.grey[400],
        splashColor: _color.withOpacity(0.2),
      );
      if (i < kIconOptions.length - 1) {
        button = Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: button,
        );
      }
      buttonChildren.add(button);
    }
    return PropertyColumn(
      label: 'Icon',
      widget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        height: 46.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: buttonChildren,
        ),
      ),
    );
  }
}
