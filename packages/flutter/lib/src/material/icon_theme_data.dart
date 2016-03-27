// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble;
import 'dart:ui' show Color, hashValues;

class IconThemeData {
  const IconThemeData({ this.color, this.opacity });

  /// The default color for icons.
  final Color color;

  /// An opacity to apply to both explicit and default icon colors.
  final double opacity;

  double get clampedOpacity => (opacity ?? 1.0).clamp(0.0, 1.0);

  static IconThemeData lerp(IconThemeData begin, IconThemeData end, double t) {
    return new IconThemeData(
      color: Color.lerp(begin.color, end.color, t),
      opacity: ui.lerpDouble(begin.clampedOpacity, end.clampedOpacity, t)
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
