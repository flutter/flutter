// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'choices.dart';
import 'constants.dart';
import 'helpers.dart';
import 'property_column.dart';

class BorderPicker extends StatelessWidget {
  const BorderPicker ({
    this.label = 'Shape',
    this.pickerHeight = kPickerRowHeight,
    this.selectedValue,
    this.borderOptions,
    this.onItemTapped,
  });

  final String label;
  final double pickerHeight;
  final String selectedValue;
  final List<String> borderOptions;
  final ValueChanged<String> onItemTapped;

  List<Widget> _buildChoices() {
    final List<String> options =
      borderOptions ?? kBorderChoices.map((BorderChoice c) => c.type).toList();
    final List<Widget> choices = <Widget>[];

    for (int i = 0; i < options.length; i++) {
      final String shapeName = options[i];

      Widget button = BorderChoiceButton(
        shape: shapeName,
        isSelected: selectedValue == shapeName,
        onTapped: () {
          if (onItemTapped != null) {
            onItemTapped(shapeName);
          }
        },
      );

      if (i < options.length - 1) {
        button = Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: button,
        );
      }

      choices.add(button);
    }
    return choices;
  }

  @override
  Widget build(BuildContext context) {
    return PropertyColumn(
      label: label,
      widget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        height: pickerHeight,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildChoices(),
        ),
      ),
    );
  }
}

class BorderChoiceButton extends StatelessWidget {
  const BorderChoiceButton({
    Key key,
    @required this.shape,
    this.isSelected = false,
    this.onTapped,
  }) : assert(shape != null), super(key: key);

  final String shape;
  final bool isSelected;
  final VoidCallback onTapped;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      minWidth: kPickerRowHeight,
      height: kPickerRowHeight,
      child: RaisedButton(
        shape: borderShapeFromString(shape),
        color: isSelected ? Colors.blue : Colors.white,
        elevation: isSelected ? kPickerSelectedElevation : 0.0,
        onPressed: onTapped,
      ),
    );
  }
}