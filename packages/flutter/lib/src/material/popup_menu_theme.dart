// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Defines default property values for [PopupMenuEntry] widgets.
///
/// Descendant widgets obtain the current [PopupMenuEntryThemeData] object
/// using `Theme.of(context).popupMenuTheme`. Instances of
/// [PopupMenuEntryThemeData] can be customized with
/// [PopupMenuEntryThemeData.copyWith].
///
/// Typically a [PopupMenuEntryThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.popupMenuTheme].
///
/// All [PopupMenuEntryThemeData] properties are `null` by default.
/// When null, the [PopupMenuEntry] will provide its own defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
class PopupMenuThemeData extends Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.popupMenuTheme].
  const PopupMenuThemeData({
    this.color,
    this.shape,
    this.elevation,
    this.textStyle,
  });

  /// Default value for [_PopupMenuRoute.color].
  final Color color;

  /// Default value for [_PopupMenuRoute.shape].
  final ShapeBorder shape;

  /// Default value for [_PopupMenuRoute.elevation].
  final double elevation;

  /// Default value for [PopupMenuItem.textStyle].
  final TextStyle textStyle;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  PopupMenuThemeData copyWith({
    Color color,
    ShapeBorder shape,
    double elevation,
    TextStyle textStyle,
  }) {
    return PopupMenuThemeData(
      color: color ?? this.color,
      shape: shape ?? this.shape,
      elevation: elevation ?? this.elevation,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  /// Linearly interpolate between two popup menu entry themes.
  ///
  /// If both arguments are null then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static PopupMenuThemeData lerp(PopupMenuThemeData a, PopupMenuThemeData b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    return PopupMenuThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      color,
      shape,
      elevation,
      textStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final PopupMenuThemeData typedOther = other;
    return typedOther.elevation == elevation
        && typedOther.color == color
        && typedOther.shape == shape
        && typedOther.textStyle == textStyle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('text style', textStyle, defaultValue: null));
  }
}
