// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

enum IconThemeColor { white, black }

class IconThemeData {
  const IconThemeData({ this.color, this.opacity });

  final IconThemeColor color;
  final double opacity;

  double get clampedOpacity => (opacity ?? 1.0).clamp(0.0, 1.0);

  static IconThemeData lerp(IconThemeData begin, IconThemeData end, double t) {
    return new IconThemeData(
      color: t < 0.5 ? begin.color : end.color,
      opacity: ui.lerpDouble(begin.clampedOpacity, end.clampedOpacity, t)
    );
  }

  bool operator ==(dynamic other) {
    if (other is! IconThemeData)
      return false;
    final IconThemeData typedOther = other;
    return color == typedOther.color && opacity == typedOther.opacity;
  }

  int get hashCode => ui.hashValues(color, opacity);

  String toString() => '$color';
}
