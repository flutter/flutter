// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'framework.dart' show BuildContext;

/// Defines the color, opacity, and size of icons.
///
/// Used by [IconTheme] to control the color, opacity, and size of icons in a
/// widget subtree.
///
/// To obtain the current icon theme, use [IconTheme.of]. To convert an icon
/// theme to a version with all the fields filled in, use [
/// IconThemeData.fallback].
@immutable
class IconThemeData with Diagnosticable {
  /// Creates an icon theme data.
  ///
  /// The opacity applies to both explicit and default icon colors. The value
  /// is clamped between 0.0 and 1.0.
  const IconThemeData({this.color, double? opacity, this.size, this.shadows}) : _opacity = opacity;

  /// Creates an icon theme with some reasonable default values.
  ///
  /// The [color] is black, the [opacity] is 1.0, and the [size] is 24.0.
  const IconThemeData.fallback()
      : color = const Color(0xFF000000),
        _opacity = 1.0,
        size = 24.0,
        shadows = null;

  /// Creates a copy of this icon theme but with the given fields replaced with
  /// the new values.
  IconThemeData copyWith({Color? color, double? opacity, double? size, List<Shadow>? shadows}) {
    return IconThemeData(
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      size: size ?? this.size,
      shadows: shadows ?? this.shadows,
    );
  }

  /// Returns a new icon theme that matches this icon theme but with some values
  /// replaced by the non-null parameters of the given icon theme. If the given
  /// icon theme is null, simply returns this icon theme.
  IconThemeData merge(IconThemeData? other) {
    if (other == null)
      return this;
    return copyWith(
      color: other.color,
      opacity: other.opacity,
      size: other.size,
      shadows: other.shadows,
    );
  }

  /// Called by [IconTheme.of] to convert this instance to an [IconThemeData]
  /// that fits the given [BuildContext].
  ///
  /// This method gives the ambient [IconThemeData] a chance to update itself,
  /// after it's been retrieved by [IconTheme.of], and before being returned as
  /// the final result. For instance, [CupertinoIconThemeData] overrides this method
  /// to resolve [color], in case [color] is a [CupertinoDynamicColor] and needs
  /// to be resolved against the given [BuildContext] before it can be used as a
  /// regular [Color].
  ///
  /// The default implementation returns this [IconThemeData] as-is.
  ///
  /// See also:
  ///
  ///  * [CupertinoIconThemeData.resolve] an implementation that resolves
  ///    the color of [CupertinoIconThemeData] before returning.
  IconThemeData resolve(BuildContext context) => this;

  /// Whether all the properties of this object are non-null.
  bool get isConcrete => color != null && opacity != null && size != null;

  /// The default color for icons.
  final Color? color;

  /// An opacity to apply to both explicit and default icon colors.
  double? get opacity => _opacity?.clamp(0.0, 1.0);
  final double? _opacity;

  /// The default size for icons.
  final double? size;

  /// The default shadow for icons.
  final List<Shadow>? shadows;

  /// Linearly interpolate between two icon theme data objects.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static IconThemeData lerp(IconThemeData? a, IconThemeData? b, double t) {
    assert(t != null);
    return IconThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      opacity: ui.lerpDouble(a?.opacity, b?.opacity, t),
      size: ui.lerpDouble(a?.size, b?.size, t),
      shadows: Shadow.lerpList(a?.shadows, b?.shadows, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is IconThemeData
        && other.color == color
        && other.opacity == opacity
        && other.size == size
        && listEquals(other.shadows, shadows);
  }

  @override
  int get hashCode => Object.hash(
    color,
    opacity,
    size,
    shadows == null ? null : Object.hashAll(shadows!),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DoubleProperty('opacity', opacity, defaultValue: null));
    properties.add(DoubleProperty('size', size, defaultValue: null));
    properties.add(IterableProperty<Shadow>('shadows', shadows, defaultValue: null));
  }
}
