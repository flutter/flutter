// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/playground/playground_demo.dart';
import 'package:flutter_gallery/demo/playground/configuration/material_helpers.dart';

const String _demoWidgetName = 'Checkbox';

class CheckboxDemo extends PlaygroundDemo {
  Color _activeColor = Colors.blue;
  bool _previewValue = true;

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
          label: 'Active Color',
          selectedValue: _activeColor,
          onItemTapped: (int index, Color color) {
            updateConfiguration(() {
              _activeColor = color;
            });
          }
        ),
      ],
    );
  }

  @override
  Widget previewWidget(BuildContext context) {
    return Center(
      child: Checkbox(
        value: _previewValue,
        activeColor: _activeColor,
        onChanged: (bool value) {
          updateConfiguration(() {
            _previewValue = value;
          });
        },
      ),
    );
  }
}
