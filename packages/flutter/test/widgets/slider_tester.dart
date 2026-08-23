// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A minimal slider widget for widget tests that exposes increase/decrease
/// semantics, avoiding a dependency on the Material library.
///
/// The slider value is in the range [0.0, 1.0]. Each increase or decrease
/// action moves the value by 10%, clamped to [0.0, 1.0].
///
/// See https://github.com/flutter/flutter/issues/177028.
class TestSlider extends StatelessWidget {
  const TestSlider({super.key, required this.value, required this.onChanged});

  /// The current value of the slider, in the range [0.0, 1.0].
  final double value;

  /// Called when the value of the slider should change.
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: '${(value * 100).round()}%',
      increasedValue: '${((value + 0.1).clamp(0.0, 1.0) * 100).round()}%',
      decreasedValue: '${((value - 0.1).clamp(0.0, 1.0) * 100).round()}%',
      onIncrease: () => onChanged((value + 0.1).clamp(0.0, 1.0)),
      onDecrease: () => onChanged((value - 0.1).clamp(0.0, 1.0)),
      child: const SizedBox(width: 200, height: 36),
    );
  }
}
