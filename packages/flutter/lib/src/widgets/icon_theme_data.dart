// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, hashValues;
import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/foundation.dart';

/// Defines the color, opacity, and size of icons.
///
/// Used by [IconTheme] to control the color, opacity, and size of icons in a
/// widget subtree.
///
/// To obtain the current icon theme, use [IconTheme.of]. To convert an icon
/// theme to a version with all the fields filled in, use [new
/// IconThemeData.fallback].
class IconThemeData extends Diagnosticable {
  /// Creates an icon theme data.
  ///
  /// The opacity applies to both explicit and default icon colors. The value
  /// is clamped between 0.0 and 1.0.
  const IconThemeData({this.color, double opacity, this.size}) : _opacity = opacity;

  /// Creates an icon them with some reasonable default values.
  ///
  /// The [color] is black, the [opacity] is 1.0, and the [size] is 24.0.
  const IconThemeData.fallback()
      : color = const Color(0xFF000000),
        _opacity = 1.0,
        size = 24.0;

  /// Creates a copy of this icon theme but with the given fields replaced with
  /// the new values.
  IconThemeData copyWith({Color color, double opacity, double size}) {
    return IconThemeData(
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      size: size ?? this.size,
    );
  }

  /// Returns a new icon theme that matches this icon theme but with some values
  /// replaced by the non-null parameters of the given icon theme. If the given
  /// icon theme is null, simply returns this icon theme.
  IconThemeData merge(IconThemeData other) {
    if (other == null)
      return this;
    return copyWith(
      color: other.color,
      opacity: other.opacity,
      size: other.size,
    );
  }

  /// Whether all the properties of this object are non-null.
  bool get isConcrete => color != null && opacity != null && size != null;

  /// The default color for icons.
  final Color color;

  /// An opacity to apply to both explicit and default icon colors.
  double get opacity => _opacity?.clamp(0.0, 1.0);
  final double _opacity;

  /// The default size for icons.
  final double size;

  /// Linearly interpolate between two icon theme data objects.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static IconThemeData lerp(IconThemeData a, IconThemeData b, double t) {
    assert(t != null);
    return IconThemeData(
      color: Color.lerp(a.color, b.color, t),
      opacity: ui.lerpDouble(a.opacity, b.opacity, t),
      size: ui.lerpDouble(a.size, b.size, t),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final IconThemeData typedOther = other;
    return color == typedOther.color
        && opacity == typedOther.opacity
        && size == typedOther.size;
  }

  @override
  int get hashCode => hashValues(color, opacity, size);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(DoubleProperty('opacity', opacity, defaultValue: null));
    properties.add(DoubleProperty('size', size, defaultValue: null));
  }
}
