// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

import '../configuration/helpers.dart';
import '../configuration/pickers.dart';
import '../playground_demo.dart';

class CupertinoButtonDemo extends StatefulWidget {
  @override
  _CupertinoButtonDemoState createState() => _CupertinoButtonDemoState();
}

class _CupertinoButtonDemoState extends State<CupertinoButtonDemo> {
  Color _color = Colors.blue;

  String get codePreview => '''
CupertinoButton(
  child: const Text('BUTTON'),
  color: ${codeSnippetForColor(_color)},
  onPressed: () {},
)
''';

  @override
  Widget build(BuildContext context) {
    return PlaygroundDemo(
      previewWidget: Center(
        child: CupertinoButton(
          child: const Text('BUTTON'),
          color: _color,
          onPressed: () {},
        ),
      ),
      configWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
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
