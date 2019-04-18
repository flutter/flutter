// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Configures whether [SnackBar] should be fixed to the bottom or floating
/// like described in the Material Design spec.
enum SnackBarBehavior {
  /// Fixed the [SnackBar] position to the bottom of the [Scaffold] when
  /// possible. One of the possible scenarios where [SnackBar] will be shown
  /// above another widget is above a [BottomNavigationBar]. Other than that
  /// [SnackBar] will cause other non-fixed widgets inside [Scaffold] to be
  /// pushed above (e.g. [FloatingActionButton]).
  fixed,

  /// Change the design and behavior of [SnackBar] to float as described in
  /// <https://material.io/design/components/snackbars.html>.
  /// This behavior will cause [SnackBar] to be shown on top of other non-fixed
  /// widgets, such as [FloatingActionButton], rather than pushing it above
  /// [SnackBar].
  floating
}

/// Defines default property values for [SnackBar] widgets.
///
/// Descendant widgets obtain the current [SnackBarThemeData] object using
/// `Theme.of(context).snackBarTheme`. Instances of [SnackBarThemeData] can be
/// customized with [SnackBarThemeData.copyWith].
///
/// Typically a [SnackBarThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.snackBarTheme].
///
/// All [SnackBarThemeData] properties are `null` by default. When null, the
/// [SnackBar] will provide its own defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
class SnackBarThemeData extends Diagnosticable {

  /// Creates a theme that can be used for [ThemeData.snackBarTheme].
  ///
  /// The [elevation] must be null or non-negative.
  const SnackBarThemeData({
    this.backgroundColor,
    this.actionTextColor,
    this.disabledActionTextColor,
    this.elevation,
    this.shape,
    this.snackBarBehavior = SnackBarBehavior.fixed,
  }) : assert(elevation == null || elevation >= 0.0);

  /// Default value for [SnackBar.backgroundColor].
  ///
  /// If null, [SnackBar] provides a default value.
  final Color backgroundColor;

  /// Default value for [SnackBarAction.textColor].
  ///
  /// If null, [SnackBarAction] defaults to [ThemeData.accentColor].
  final Color actionTextColor;

  /// Default value for [SnackBarAction.disabledTextColor].
  ///
  /// If null, [SnackBarAction] defaults to [ColorScheme.onSurface] with its
  /// opacity set to 0.30 if [Brightness] is dark, 0.38 otherwise.
  final Color disabledActionTextColor;

  /// Default value for [SnackBar.elevation].
  ///
  /// If null, [SnackBar] uses a default of 6.0.
  final double elevation;

  /// Default value for [SnackBar.shape].
  ///
  /// If null, [SnackBar] provides different defaults depending on the
  /// [SnackBarBehavior]. For [SnackBarBehavior.fixed], it uses null. For
  /// [SnackBarBehavior.floating], it uses a [RoundedRectangleBorder] with a
  /// circular corner radius of 4.0.
  final ShapeBorder shape;

  /// Default value for [SnackBar.snackBarBehavior].
  ///
  /// If null, [SnackBar] will default to [SnackBarBehavior.fixed].
  final SnackBarBehavior snackBarBehavior;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  SnackBarThemeData copyWith({
    Color backgroundColor,
    Color actionTextColor,
    Color disabledActionTextColor,
    double elevation,
    ShapeBorder shape,
    SnackBarBehavior snackBarBehavior,
  }) {
    return SnackBarThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      actionTextColor: actionTextColor ?? this.actionTextColor,
      disabledActionTextColor: disabledActionTextColor ?? this.disabledActionTextColor,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
      snackBarBehavior: snackBarBehavior ?? this.snackBarBehavior,
    );
  }

  /// Linearly interpolate between two SnackBar Themes.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static SnackBarThemeData lerp(SnackBarThemeData a, SnackBarThemeData b, double t) {
    assert(t != null);
    return SnackBarThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      actionTextColor: Color.lerp(a?.actionTextColor, b?.actionTextColor, t),
      disabledActionTextColor: Color.lerp(a?.disabledActionTextColor, b?.disabledActionTextColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      snackBarBehavior: t < 0.5 ? a.snackBarBehavior : b.snackBarBehavior,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      actionTextColor,
      disabledActionTextColor,
      elevation,
      shape,
      snackBarBehavior,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final SnackBarThemeData typedOther = other;
    return typedOther.backgroundColor == backgroundColor
        && typedOther.actionTextColor == actionTextColor
        && typedOther.disabledActionTextColor == disabledActionTextColor
        && typedOther.elevation == elevation
        && typedOther.shape == shape
        && typedOther.snackBarBehavior == snackBarBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Color>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('actionTextColor', actionTextColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('disabledActionTextColor', disabledActionTextColor, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<SnackBarBehavior>('snackBarBehavior', snackBarBehavior, defaultValue: null));
  }
}
