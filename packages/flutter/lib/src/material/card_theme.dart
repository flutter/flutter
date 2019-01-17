// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines default property values for descendant [Card] widgets.
///
/// Descendant widgets obtain the current [CardTheme] object using
/// `CardTheme.of(context)`. Instances of [CardTheme] can be
/// customized with [CardTheme.copyWith].
///
/// Typically a [CardTheme] is specified as part of the overall [Theme]
/// with [ThemeData.cardTheme].
///
/// All [CardTheme] properties are `null` by default. When null, the
/// [Card] constructor provides defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
class CardTheme extends Diagnosticable {

  /// Creates a theme that can be used for [ThemeData.cardTheme].
  const CardTheme({
    this.clipBehavior,
    this.color,
    this.elevation,
    this.shape,
  });

  /// Default value for [Card.clipBehavior].
  final Clip clipBehavior;

  /// Default value for [Card.color].
  ///
  /// If null, [Card] uses [ThemeData.cardColor].
  final Color color;

  /// Default value for [Card.elevation].
  final double elevation;

  /// Default value for [Card.shape].
  final NotchedShape shape;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  CardTheme copyWith({
    Clip clipBehavior,
    Color color,
    double elevation,
    NotchedShape shape,
  }) {
    return CardTheme(
      clipBehavior: clipBehavior ?? this.clipBehavior,
      color: color ?? this.color,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
    );
  }

  /// The [ThemeData.cardTheme] property of the ambient [Theme].
  static CardTheme of(BuildContext context) {
    return Theme.of(context).cardTheme;
  }

  /// Linearly interpolate between two BAB themes.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static CardTheme lerp(CardTheme a, CardTheme b, double t) {
    assert(t != null);
    return CardTheme(
      clipBehavior: t < 0.5 ? a?.clipBehavior : b?.clipBehavior,
      color: Color.lerp(a?.color, b?.color, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: t < 0.5 ? a?.shape : b?.shape,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      clipBehavior,
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
    final CardTheme typedOther = other;
    return typedOther.clipBehavior == clipBehavior
        && typedOther.color == color
        && typedOther.elevation == elevation
        && typedOther.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Clip>('clipBehavior', clipBehavior, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<NotchedShape>('shape', shape, defaultValue: null));
  }
}
