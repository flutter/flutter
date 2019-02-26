import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// TODO(clocksmith): dartdoc
class FloatingActionButtonThemeData extends Diagnosticable {
  /// TODO(clocksmith): dartdoc
  const FloatingActionButtonThemeData({
    this.backgroundColor,
    this.elevation,
    this.foregroundColor,
    this.highlightElevation,
    this.shape,
  });

  /// TODO(clocksmith): dartdoc
  factory FloatingActionButtonThemeData.fromDefaults({
//    Brightness brightness,
    Color primaryColor,
    Color onPrimaryColor,
  }) {
    return FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
    );
}

  /// Color to be used for the unselected, enabled floating action buttons's
  /// background.
  final Color backgroundColor;

  /// The z-coordinate to be used for the unselected, enabled floating action \
  /// buttons's elevation foreground. .
  final double elevation;

  /// Color to be used for the unselected, enabled floating action buttons's
  /// foreground.
  final Color foregroundColor;

  /// The z-coordinate to be used for the selected, enabled floating action
  /// buttons's elevation foreground. .
  final double highlightElevation;

  /// The shape to be used for the floating action button's [Material].
  final ShapeBorder shape;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  FloatingActionButtonThemeData copyWith({
    Color backgroundColor,
    double elevation,
    Color foregroundColor,
    double highlightElevation,
    ShapeBorder shape,
  }) {
    return FloatingActionButtonThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      foregroundColor: foregroundColor ?? this.foregroundColor,
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
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      highlightElevation: lerpDouble(a?.highlightElevation, b?.highlightElevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
    );
  }
  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      elevation,
      foregroundColor,
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
        && otherData.elevation == elevation
        && otherData.foregroundColor == foregroundColor
        && otherData.highlightElevation == highlightElevation
        && otherData.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final ThemeData defaultTheme = ThemeData.fallback();
    final FloatingActionButtonThemeData defaultData = FloatingActionButtonThemeData.fromDefaults(
//      brightness: defaultTheme.brightness,
      onPrimaryColor: Colors.white, // This is wrong
      primaryColor: defaultTheme.primaryColor,
    );
    properties.add(DiagnosticsProperty<Color>('backgroundColor', backgroundColor, defaultValue: defaultData.backgroundColor));
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: defaultData.elevation));
    properties.add(DiagnosticsProperty<Color>('foregroundColor', foregroundColor, defaultValue: defaultData.foregroundColor));
    properties.add(DiagnosticsProperty<double>('highlightElevation', highlightElevation, defaultValue: defaultData.highlightElevation));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: defaultData.shape));
  }
}