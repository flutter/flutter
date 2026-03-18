// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file defines a basic slider widget for use in tests for Widgets in `flutter/widgets`.

import 'package:flutter/widgets.dart';

/// A very basic slider for use in widget tests.
///
/// This widget provides minimal slider functionality without depending on
/// Material Design components. It only handles semantic actions for testing
/// purposes and does not render any visual elements.
class TestSlider extends StatelessWidget {
  const TestSlider({
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    super.key,
  }) : assert(value >= min && value <= max, 'Value must be between min and max');

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;

  double get _normalizedValue {
    if (max == min) {
      return 0.0;
    }
    return (value - min) / (max - min);
  }

  double get _semanticActionUnit {
    if (divisions != null) {
      return 1.0 / divisions!;
    }
    // Use a consistent 10% adjustment for continuous sliders
    return 0.1;
  }

  String _formatPercentage(double normalizedValue) {
    return '${(normalizedValue * 100).round()}%';
  }

  void _increaseAction() {
    final double newNormalizedValue = (_normalizedValue + _semanticActionUnit).clamp(0.0, 1.0);
    onChanged?.call(min + newNormalizedValue * (max - min));
  }

  void _decreaseAction() {
    final double newNormalizedValue = (_normalizedValue - _semanticActionUnit).clamp(0.0, 1.0);
    onChanged?.call(min + newNormalizedValue * (max - min));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      enabled: onChanged != null,
      value: _formatPercentage(_normalizedValue),
      increasedValue: _formatPercentage((_normalizedValue + _semanticActionUnit).clamp(0.0, 1.0)),
      decreasedValue: _formatPercentage((_normalizedValue - _semanticActionUnit).clamp(0.0, 1.0)),
      onIncrease: onChanged != null ? _increaseAction : null,
      onDecrease: onChanged != null ? _decreaseAction : null,
      child: const SizedBox(width: 200.0, height: 48.0),
    );
  }
}