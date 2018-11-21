// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_gallery/demo/playground/playground_demo.dart';
import 'package:flutter_gallery/demo/playground/configuration/material_helpers.dart';

const String _demoWidgetName = 'CupertinoButton';

class CupertinoButtonDemo extends PlaygroundDemo {
  Color _color = Colors.blue;

  @override
  String tabName() => _demoWidgetName.toUpperCase();

  @override
  String code() => '';

  @override
  Widget configWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
      child: CupertinoButton(
        child: const Text('BUTTON'),
        color: _color,
        // padding: const EdgeInsets.all(5.0),
        // disabledColor: ,
        // minSize: 44.0,
        // pressedOpacity: 0.1,
        // borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        onPressed: () {},
      ),
    );
  }
}
