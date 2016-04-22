// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble;
import 'dart:ui' show Color, hashValues;

/// Defines the color and opacity of icons.
///
/// Used by [IconTheme] to control the color and opacity of icons in a widget
/// subtree.
class IconThemeData {
  /// Creates an icon theme data.
  ///
  /// The opacity applies to both explicit and default icon colors. The value
  /// is clamped between 0.0 and 1.0.
  const IconThemeData({ this.color, double opacity: 1.0 }) : _opacity = opacity;

  /// The default color for icons.
  final Color color;

  /// An opacity to apply to both explicit and default icon colors.
  double get opacity => (_opacity ?? 1.0).clamp(0.0, 1.0);
  final double _opacity;

  /// Linearly interpolate between two icon theme data objects.
  static IconThemeData lerp(IconThemeData begin, IconThemeData end, double t) {
    return new IconThemeData(
      color: Color.lerp(begin.color, end.color, t),
      opacity: ui.lerpDouble(begin.opacity, end.opacity, t)
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! IconThemeData)
      return false;
    final IconThemeData typedOther = other;
    return color == typedOther.color && opacity == typedOther.opacity;
  }

  @override
  int get hashCode => hashValues(color, opacity);

  @override
  String toString() => '$color';
}
