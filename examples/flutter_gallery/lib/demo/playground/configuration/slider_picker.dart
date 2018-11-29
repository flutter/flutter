// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'property_column.dart';

class SliderPicker extends StatelessWidget {
  const SliderPicker({
    Key key,
    @required this.label,
    @required this.divisions,
    this.value = 0.0,
    this.minValue = 0.0,
    this.maxValue = 1.0,
    this.onValueChanged,
  })  : assert(label != null),
        assert(value != null),
        assert(divisions != null),
        super(key: key);

  final String label;
  final double value;
  final double minValue;
  final double maxValue;
  final int divisions;
  final ValueChanged<double> onValueChanged;

  @override
  Widget build(BuildContext context) {
    return PropertyColumn(
      label: label,
      widget: Slider(
        value: value,
        min: minValue,
        max: maxValue,
        divisions: divisions,
        onChanged: onValueChanged,
      ),
    );
  }
}
