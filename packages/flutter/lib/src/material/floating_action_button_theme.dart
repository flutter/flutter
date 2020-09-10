// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Defines default property values for descendant [FloatingActionButton]
/// widgets.
///
/// Descendant widgets obtain the current [FloatingActionButtonThemeData] object
/// using `Theme.of(context).floatingActionButtonTheme`. Instances of
/// [FloatingActionButtonThemeData] can be customized with
/// [FloatingActionButtonThemeData.copyWith].
///
/// Typically a [FloatingActionButtonThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.floatingActionButtonTheme].
///
/// All [FloatingActionButtonThemeData] properties are `null` by default.
/// When null, the [FloatingActionButton] will use the values from [ThemeData]
/// if they exist, otherwise it will provide its own defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class FloatingActionButtonThemeData with Diagnosticable {
  /// Creates a theme that can be used for
  /// [ThemeData.floatingActionButtonTheme].
  const FloatingActionButtonThemeData({
    this.foregroundColor,
    this.backgroundColor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.disabledElevation,
    this.highlightElevation,
    this.shape,
  });

  /// Color to be used for the unselected, enabled [FloatingActionButton]'s
  /// foreground.
  final Color? foregroundColor;

  /// Color to be used for the unselected, enabled [FloatingActionButton]'s
  /// background.
  final Color? backgroundColor;

  /// The color to use for filling the button when the button has input focus.
  final Color? focusColor;

  /// The color to use for filling the button when the button has a pointer
  /// hovering over it.
  final Color? hoverColor;

  /// The splash color for this [FloatingActionButton]'s [InkWell].
  final Color? splashColor;

  /// The z-coordinate to be used for the unselected, enabled
  /// [FloatingActionButton]'s elevation foreground.
  final double? elevation;

  /// The z-coordinate at which to place this button relative to its parent when
  /// the button has the input focus.
  ///
  /// This controls the size of the shadow below the floating action button.
  final double? focusElevation;

  /// The z-coordinate at which to place this button relative to its parent when
  /// the button is enabled and has a pointer hovering over it.
  ///
  /// This controls the size of the shadow below the floating action button.
  final double? hoverElevation;

  /// The z-coordinate to be used for the disabled [FloatingActionButton]'s
  /// elevation foreground.
  final double? disabledElevation;

  /// The z-coordinate to be used for the selected, enabled
  /// [FloatingActionButton]'s elevation foreground.
  final double? highlightElevation;

  /// The shape to be used for the floating action button's [Material].
  final ShapeBorder? shape;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  FloatingActionButtonThemeData copyWith({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? focusColor,
    Color? hoverColor,
    Color? splashColor,
    double? elevation,
    double? focusElevation,
    double? hoverElevation,
    double? disabledElevation,
    double? highlightElevation,
    ShapeBorder? shape,
  }) {
    return FloatingActionButtonThemeData(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      focusColor: focusColor ?? this.focusColor,
      hoverColor: hoverColor ?? this.hoverColor,
      splashColor: splashColor ?? this.splashColor,
      elevation: elevation ?? this.elevation,
      focusElevation: focusElevation ?? this.focusElevation,
      hoverElevation: hoverElevation ?? this.hoverElevation,
      disabledElevation: disabledElevation ?? this.disabledElevation,
      highlightElevation: highlightElevation ?? this.highlightElevation,
      shape: shape ?? this.shape,
    );
  }

  /// Linearly interpolate between two floating action button themes.
  ///
  /// If both arguments are null then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static FloatingActionButtonThemeData? lerp(FloatingActionButtonThemeData? a, FloatingActionButtonThemeData? b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    return FloatingActionButtonThemeData(
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      focusColor: Color.lerp(a?.focusColor, b?.focusColor, t),
      hoverColor: Color.lerp(a?.hoverColor, b?.hoverColor, t),
      splashColor: Color.lerp(a?.splashColor, b?.splashColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      focusElevation: lerpDouble(a?.focusElevation, b?.focusElevation, t),
      hoverElevation: lerpDouble(a?.hoverElevation, b?.hoverElevation, t),
      disabledElevation: lerpDouble(a?.disabledElevation, b?.disabledElevation, t),
      highlightElevation: lerpDouble(a?.highlightElevation, b?.highlightElevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      foregroundColor,
      backgroundColor,
      focusColor,
      hoverColor,
      splashColor,
      elevation,
      focusElevation,
      hoverElevation,
      disabledElevation,
      highlightElevation,
      shape,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is FloatingActionButtonThemeData
        && other.foregroundColor == foregroundColor
        && other.backgroundColor == backgroundColor
        && other.focusColor == focusColor
        && other.hoverColor == hoverColor
        && other.splashColor == splashColor
        && other.elevation == elevation
        && other.focusElevation == focusElevation
        && other.hoverElevation == hoverElevation
        && other.disabledElevation == disabledElevation
        && other.highlightElevation == highlightElevation
        && other.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const FloatingActionButtonThemeData defaultData = FloatingActionButtonThemeData();

    properties.add(ColorProperty('foregroundColor', foregroundColor, defaultValue: defaultData.foregroundColor));
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: defaultData.backgroundColor));
    properties.add(ColorProperty('focusColor', focusColor, defaultValue: defaultData.focusColor));
    properties.add(ColorProperty('hoverColor', hoverColor, defaultValue: defaultData.hoverColor));
    properties.add(ColorProperty('splashColor', splashColor, defaultValue: defaultData.splashColor));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: defaultData.elevation));
    properties.add(DoubleProperty('focusElevation', focusElevation, defaultValue: defaultData.focusElevation));
    properties.add(DoubleProperty('hoverElevation', hoverElevation, defaultValue: defaultData.hoverElevation));
    properties.add(DoubleProperty('disabledElevation', disabledElevation, defaultValue: defaultData.disabledElevation));
    properties.add(DoubleProperty('highlightElevation', highlightElevation, defaultValue: defaultData.highlightElevation));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: defaultData.shape));
  }
}
