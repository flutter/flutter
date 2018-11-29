// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'choices.dart';
import 'constants.dart';
import 'property_column.dart';

class IconPicker extends StatelessWidget {
  const IconPicker({
    Key key,
    @required this.selectedValue,
    this.label = 'Icon',
    this.isSelected = false,
    this.pickerHeight = kPickerRowHeight,
    this.icons,
    this.activeColor,
    this.onItemTapped,
  })  : assert(label != null),
        assert(pickerHeight != null && pickerHeight > 0.0),
        assert(isSelected != null),
        super(key: key);

  final String label;
  final double pickerHeight;
  final bool isSelected;
  final List<IconData> icons;
  final IconData selectedValue;
  final Color activeColor;
  final ValueChanged<IconData> onItemTapped;

  List<Widget> _buildChoices() {
    final List<IconData> options =
        icons ?? kIconChoices.map((IconChoice c) => c.icon).toList();
    final List<Widget> choices = <Widget>[];
    for (int i = 0; i < options.length; i++) {
      final IconData icon = options[i];
      Widget button = _IconChoiceButton(
        icon: icon,
        isSelected: selectedValue == icon,
        activeColor: activeColor,
        onTapped: () {
          if (onItemTapped != null) {
            onItemTapped(icon);
          }
        },
      );
      if (i < options.length - 1) {
        button = Padding(
          padding: const EdgeInsets.only(right: 9.0),
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
      label: 'Icon',
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

class _IconChoiceButton extends StatelessWidget {
  const _IconChoiceButton({
    Key key,
    @required this.icon,
    @required this.isSelected,
    this.activeColor,
    this.onTapped,
  })  : assert(icon != null),
        assert(isSelected != null),
        super(key: key);

  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTapped;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 30.0,
      icon: Icon(icon),
      onPressed: onTapped,
      color: isSelected ? activeColor : Colors.grey[400],
      splashColor: activeColor.withOpacity(0.2),
    );
  }
}
