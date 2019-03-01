import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines default property values for descendant [FloatingActionButton]
/// widgets.
///
/// Descendant widgets obtain the current [FloatingActionButtonThemeData] object
/// using `FloatingActionButtonThemeData.of(context)`. Instances of
/// [FloatingActionButtonThemeData] can be customized with
/// [FloatingActionButtonThemeData.copyWith].
///
/// Typically an [FloatingActionButtonThemeData] is specified as part of the
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
class FloatingActionButtonThemeData extends Diagnosticable {
  /// Creates a theme that can be used for
  /// [ThemeData.floatingActionButtonTheme].
  const FloatingActionButtonThemeData({
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.highlightElevation,
    this.shape,
  });

  /// Color to be used for the unselected, enabled floating action buttons's
  /// background.
  final Color backgroundColor;

  /// Color to be used for the unselected, enabled floating action buttons's
  /// foreground.
  final Color foregroundColor;

  /// The z-coordinate to be used for the unselected, enabled floating action \
  /// buttons's elevation foreground. .
  final double elevation;

  /// The z-coordinate to be used for the selected, enabled floating action
  /// buttons's elevation foreground. .
  final double highlightElevation;

  /// The shape to be used for the floating action button's [Material].
  final ShapeBorder shape;

  /// The [ThemeData.floatingActionButtonTheme] property of the ambient [Theme].
  static FloatingActionButtonThemeData of(BuildContext context) {
    return Theme.of(context).floatingActionButtonTheme;
  }

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  FloatingActionButtonThemeData copyWith({
    Color backgroundColor,
    Color foregroundColor,
    double elevation,
    double highlightElevation,
    ShapeBorder shape,
  }) {
    return FloatingActionButtonThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      elevation: elevation ?? this.elevation,
      highlightElevation: highlightElevation ?? this.highlightElevation,
      shape: shape ?? this.shape,
    );
  }

  static FloatingActionButtonThemeData lerp(FloatingActionButtonThemeData a, FloatingActionButtonThemeData b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    return FloatingActionButtonThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      highlightElevation: lerpDouble(a?.highlightElevation, b?.highlightElevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
    );
  }
  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      foregroundColor,
      elevation,
      highlightElevation,
      shape,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final FloatingActionButtonThemeData otherData = other;
    return otherData.backgroundColor == backgroundColor
        && otherData.foregroundColor == foregroundColor
        && otherData.elevation == elevation
        && otherData.highlightElevation == highlightElevation
        && otherData.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final FloatingActionButtonThemeData defaultData = FloatingActionButtonThemeData();

    properties.add(DiagnosticsProperty<Color>('backgroundColor', backgroundColor, defaultValue: defaultData.backgroundColor));
    properties.add(DiagnosticsProperty<Color>('foregroundColor', foregroundColor, defaultValue: defaultData.foregroundColor));
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: defaultData.elevation));
    properties.add(DiagnosticsProperty<double>('highlightElevation', highlightElevation, defaultValue: defaultData.highlightElevation));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: defaultData.shape));
  }
}