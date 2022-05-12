// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines default property values for descendant [BottomAppBar] widgets.
///
/// Descendant widgets obtain the current [BottomAppBarTheme] object using
/// `BottomAppBarTheme.of(context)`. Instances of [BottomAppBarTheme] can be
/// customized with [BottomAppBarTheme.copyWith].
///
/// Typically a [BottomAppBarTheme] is specified as part of the overall [Theme]
/// with [ThemeData.bottomAppBarTheme].
///
/// All [BottomAppBarTheme] properties are `null` by default. When null, the
/// [BottomAppBar] constructor provides defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class BottomAppBarTheme with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.bottomAppBarTheme].
  const BottomAppBarTheme({
    this.color,
    this.elevation,
    this.shape,
  });

  /// Default value for [BottomAppBar.color].
  ///
  /// If null, [BottomAppBar] uses [ThemeData.bottomAppBarColor].
  final Color? color;

  /// Default value for [BottomAppBar.elevation].
  final double? elevation;

  /// Default value for [BottomAppBar.shape].
  final NotchedShape? shape;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  BottomAppBarTheme copyWith({
    Color? color,
    double? elevation,
    NotchedShape? shape,
  }) {
    return BottomAppBarTheme(
      color: color ?? this.color,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
    );
  }

  /// The [ThemeData.bottomAppBarTheme] property of the ambient [Theme].
  static BottomAppBarTheme of(BuildContext context) {
    return Theme.of(context).bottomAppBarTheme;
  }

  /// Linearly interpolate between two BAB themes.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static BottomAppBarTheme lerp(BottomAppBarTheme? a, BottomAppBarTheme? b, double t) {
    assert(t != null);
    return BottomAppBarTheme(
      color: Color.lerp(a?.color, b?.color, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: t < 0.5 ? a?.shape : b?.shape,
    );
  }

  @override
  int get hashCode => Object.hash(
    color,
    elevation,
    shape,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is BottomAppBarTheme
        && other.color == color
        && other.elevation == elevation
        && other.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<NotchedShape>('shape', shape, defaultValue: null));
  }
}
