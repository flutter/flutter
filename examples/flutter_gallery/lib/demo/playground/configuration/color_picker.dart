// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'choices.dart';
import 'constants.dart';
import 'property_column.dart';

class ColorPicker extends StatelessWidget {
  const ColorPicker({
    Key key,
    @required this.selectedValue,
    this.label = 'Color',
    this.inverse = false,
    this.pickerHeight = kPickerRowHeight,
    this.colors,
    this.onItemTapped,
  })  : assert(selectedValue != null),
        assert(pickerHeight != null && pickerHeight >= 0.0),
        assert(inverse != null),
        assert(label != null),
        super(key: key);

  final String label;
  final double pickerHeight;
  final bool inverse;
  final Color selectedValue;
  final List<Color> colors;
  final ValueChanged<Color> onItemTapped;

  List<Widget> _buildChoices() {
    final List<Color> options =
        colors ?? kColorChoices.map((ColorChoice c) => c.color).toList();
    final List<Widget> choices = <Widget>[];

    for (int i = 0; i < options.length; i++) {
      final Color color = options[i];
      Widget button = _ColorChoiceButton(
        color: color,
        inverse: inverse,
        isSelected: selectedValue == color,
        onTapped: () {
          if (onItemTapped != null) {
            onItemTapped(color);
          }
        },
      );
      if (i < options.length - 1) {
        button = Padding(
          padding: const EdgeInsets.only(right: 12.0),
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

class _ColorChoiceButton extends StatelessWidget {
  const _ColorChoiceButton({
    Key key,
    @required this.color,
    this.isSelected = false,
    this.inverse = false,
    this.onTapped,
  })  : assert(color != null),
        assert(inverse != null),
        assert(isSelected != null),
        super(key: key);

  final Color color;
  final bool isSelected;
  final bool inverse;
  final VoidCallback onTapped;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      minWidth: kPickerRowHeight,
      height: kPickerRowHeight,
      child: RaisedButton(
        shape: StadiumBorder(
          side: BorderSide(
            width: 2.0,
            color: inverse
                ? color
                : (isSelected ? Colors.white : Colors.grey[350]),
          ),
        ),
        color: inverse ? Colors.white : color,
        splashColor: color == Colors.white
            ? Colors.grey[400].withOpacity(0.3)
            : Colors.white.withOpacity(0.3),
        elevation: isSelected ? kPickerSelectedElevation : 0.0,
        onPressed: onTapped,
      ),
    );
  }
}
