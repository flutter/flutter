// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines a theme for [BottomAppBar] widgets.
///
/// Descendant widgets obtain the current [BottomAppBarTheme] object using
/// `BottomAppBarTheme.of(context)`. Instances of [BottomAppBarTheme] can be
/// customized with [BottomAppBarTheme.copyWith].
///
/// See also:
///
///  * [BottomAppBar], a material bottom app bar that can be customized using
///    this [BottomAppBarTheme].
///  * [ThemeData], which describes the overall theme information for the
///    application.
class BottomAppBarTheme extends Diagnosticable {
  /// Creates a BAB theme that can be used for [ThemeData.BottomAppBarTheme].
  const BottomAppBarTheme({
    this.color,
    this.elevation,
    this.shape,
  });

  /// Default value for [BottomAppBar.color].
  ///
  /// If null, [ThemeData.bottomAppBarColor] is used, if that's null, defaults
  /// to [Colors.white].
  final Color color;

  /// Default value for [BottomAppBar.elevation].
  ///
  /// If null, defaults to `8.0`.
  final double elevation;

  /// Default value for [BottomAppBar.shape].
  final NotchedShape shape;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  BottomAppBarTheme copyWith({
    Color color,
    double elevation,
    NotchedShape shape,
  }) {
    return BottomAppBarTheme(
      color: color ?? this.color,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
    );
  }

  /// The data from the closest [BottomAppBarTheme] instance given the build context.
  static BottomAppBarTheme of(BuildContext context) {
    return Theme.of(context).bottomAppBarTheme;
  }

  /// Linearly interpolate between two BAB themes.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static BottomAppBarTheme lerp(BottomAppBarTheme a, BottomAppBarTheme b, double t) {
    assert(t != null);
    return BottomAppBarTheme(
      color: Color.lerp(a?.color, b?.color, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: t < 0.5 ? a?.shape : b?.shape,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      color,
      elevation,
      shape,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final BottomAppBarTheme typedOther = other;
    return typedOther.color == color
        && typedOther.elevation == elevation
        && typedOther.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const double defaultElevation = 8.0;
    properties.add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: defaultElevation));
    properties.add(DiagnosticsProperty<NotchedShape>('shape', shape, defaultValue: null));
  }
}
