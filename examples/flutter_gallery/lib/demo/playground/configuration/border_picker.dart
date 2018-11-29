// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'choices.dart';
import 'constants.dart';
import 'helpers.dart';
import 'property_column.dart';

class BorderPicker extends StatelessWidget {
  const BorderPicker({
    Key key,
    @required this.selectedValue,
    this.label = 'Shape',
    this.pickerHeight = kPickerRowHeight,
    this.borderOptions,
    this.onItemTapped,
  })  : assert(label != null),
        assert(pickerHeight != null && pickerHeight > 0.0),
        assert(selectedValue != null),
        super(key: key);

  final String label;
  final double pickerHeight;
  final String selectedValue;
  final List<String> borderOptions;
  final ValueChanged<String> onItemTapped;

  List<Widget> _buildChoices() {
    final List<String> options = borderOptions ?? kBorderChoices.map((BorderChoice c) => c.type).toList();
    final List<Widget> choices = <Widget>[];

    for (int i = 0; i < options.length; i++) {
      final String shapeName = options[i];
      Widget button = _BorderChoiceButton(
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
          padding: const EdgeInsets.only(right: 15.0),
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
        height: pickerHeight + kPickerRowPadding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildChoices(),
          ),
        ),
      ),
    );
  }
}

class _BorderChoiceButton extends StatelessWidget {
  const _BorderChoiceButton({
    Key key,
    @required this.shape,
    this.isSelected = false,
    this.onTapped,
  })  : assert(shape != null),
        assert(isSelected != null),
        super(key: key);

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
