// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file defines basic widgets for use in tests for Widgets in `flutter/widgets`.

import 'package:flutter/widgets.dart';

/// A small set of colors for widget tests, inspired by the original Material 2 primary colors.
@visibleForTesting
const List<Color> genericWidgetTestColors = [
  Color(0xFFF44336),
  Color(0xFF9C27B0),
  Color(0xFF2196F3),
  Color(0xFF4CAF50),
  Color(0xFFFFEB3B),
  Color(0xFFFF9800),
];

/// A basic divider widget, which draws a black horizontal line
/// and is surrounded by some padding.
@visibleForTesting
class BasicDivider extends StatelessWidget {
  const BasicDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(color: const Color(0xFF000000), height: 4, width: double.infinity),
    );
  }
}
