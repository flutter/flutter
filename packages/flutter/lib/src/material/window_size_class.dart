// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// [WindowSizeClass]es are used to categorize window sizes. They are useful
/// breakpoints for implementing responsive layouts.
enum WindowSizeClass {
  /// The [WindowSizeClass] for windows with a width smaller then 600dp.
  compact(0),

  /// The [WindowSizeClass] for windows with a width of at least 600dp, but
  /// smaller then 840dp.
  medium(600),

  /// The [WindowSizeClass] for windows with a width of at least 840dp, but
  /// smaller then 1200dp.
  expanded(840),

  /// The [WindowSizeClass] for windows with a width of at least 1200dp, but
  /// smaller then 1600dp.
  large(1200),

  /// The [WindowSizeClass] for windows with a width of at least 1600dp.
  extraLarge(1600);

  const WindowSizeClass(this.minWidth);

  /// Get the [WindowSizeClass] of [size].
  ///
  /// [size] must use density-independent pixels (dp). For more information, have a look at [Material 3](https://m3.material.io/foundations/layout/understanding-layout/spacing#748a2194-c82c-4fcd-9c67-9c79bcf5cf26).
  static WindowSizeClass fromSize(Size size) => WindowSizeClass.fromWidth(size.width);

  /// Get the [WindowSizeClass] for [width].
  ///
  /// [width] must use density-independent pixels (dp). For more information, have a look at [Material 3](https://m3.material.io/foundations/layout/understanding-layout/spacing#748a2194-c82c-4fcd-9c67-9c79bcf5cf26).
  static WindowSizeClass fromWidth(double width) {
    // While this implementation seems messy, it's an efficient way for
    // calculating the correct [WindowSizeClass] since it uses at most 3
    // comparisons.
    if (width < WindowSizeClass.expanded.minWidth) {
      if (width < WindowSizeClass.medium.minWidth) {
        return WindowSizeClass.compact;
      } else {
        return WindowSizeClass.medium;
      }
    }else{
      if (width < WindowSizeClass.large.minWidth) {
        return WindowSizeClass.expanded;
      } else if (width < WindowSizeClass.extraLarge.minWidth) {
        return WindowSizeClass.large;
      } else {
        return WindowSizeClass.extraLarge;
      }
    }
  }

  /// The minimal width a windows with this [WindowSizeClass] can have.
  ///
  /// This variable uses density-independent pixels (dp). For more information, have a look at [Material 3](https://m3.material.io/foundations/layout/understanding-layout/spacing#748a2194-c82c-4fcd-9c67-9c79bcf5cf26).
  final double minWidth;

  /// Checks if this [WindowSizeClass] is smaller then [other].
  bool operator <(WindowSizeClass other){
    return minWidth < other.minWidth;
  }

  /// Checks if this [WindowSizeClass] is smaller then or equal to [other].
  bool operator <=(WindowSizeClass other){
    return minWidth <= other.minWidth;
  }

  /// Checks if this [WindowSizeClass] is greater then [other].
  bool operator >(WindowSizeClass other){
    return minWidth > other.minWidth;
  }

  /// Checks if this [WindowSizeClass] is greater then or equal to [other].
  bool operator >=(WindowSizeClass other){
    return minWidth >= other.minWidth;
  }
}
