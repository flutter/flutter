// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble;
import 'dart:ui' show Color, hashValues;

/// Defines the color, opacity, and size of icons.
///
/// Used by [IconTheme] to control the color, opacity, and size of icons in a
/// widget subtree.
///
/// To obtain the current icon theme, use [IconTheme.of]. To convert an icon
/// theme to a version with all the fields filled in, use [fallback].
class IconThemeData {
  /// Creates an icon theme data.
  ///
  /// The opacity applies to both explicit and default icon colors. The value
  /// is clamped between 0.0 and 1.0.
  const IconThemeData({ this.color, double opacity, this.size }) : _opacity = opacity;

  /// Creates a copy of this icon theme but with the given fields replaced with
  /// the new values.
  IconThemeData copyWith({ Color color, double opacity, double size }) {
    return new IconThemeData(
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      size: size ?? this.size
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
      size: other.size
    );
  }

  /// Creates an icon theme that is identical to this icon theme but with
  /// any null fields filled in. Specific fallbacks can be given, but in their
  /// absence, this method defaults to black, fully opaque, and size 24.0.
  IconThemeData fallback({
    Color color: const Color(0xFF000000),
    double opacity: 1.0,
    double size: 24.0
  }) {
    if (this.color != null && this.opacity != null && this.size != null)
      return this;
    return new IconThemeData(
      color: this.color ?? color,
      opacity: this.opacity ?? opacity,
      size: this.size ?? size
    );
  }

  /// The default color for icons.
  final Color color;

  /// An opacity to apply to both explicit and default icon colors.
  double get opacity => _opacity?.clamp(0.0, 1.0);
  final double _opacity;

  /// The default size for icons.
  final double size;

  /// Linearly interpolate between two icon theme data objects.
  static IconThemeData lerp(IconThemeData begin, IconThemeData end, double t) {
    return new IconThemeData(
      color: Color.lerp(begin.color, end.color, t),
      opacity: ui.lerpDouble(begin.opacity, end.opacity, t),
      size: ui.lerpDouble(begin.size, end.size, t)
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
  String toString() {
    List<String> result = <String>[];
    if (color != null)
      result.add('color: $color');
    if (_opacity != null)
      result.add('opacity: $_opacity');
    if (size != null)
      result.add('size: $size');
    if (result.length == 0)
      return '<no theme>';
    return result.join(', ');
  }
}
