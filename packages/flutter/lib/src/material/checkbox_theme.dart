// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';
import 'theme.dart';
import 'theme_data.dart';

/// Defines default property values for descendant [Checkbox] widgets.
///
/// Descendant widgets obtain the current [CheckboxThemeData] object using
/// `CheckboxTheme.of(context)`. Instances of [CheckboxThemeData] can be
/// customized with [CheckboxThemeData.copyWith].
///
/// Typically a [CheckboxThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.checkboxTheme].
///
/// All [CheckboxThemeData] properties are `null` by default. When null, the
/// [Checkbox] will use the values from [ThemeData] if they exist, otherwise it
/// will provide its own defaults based on the overall [Theme]'s colorScheme.
/// See the individual [Checkbox] properties for details.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class CheckboxThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.checkboxTheme].
  const CheckboxThemeData({
    this.fillColor,
    this.mouseCursor,
    this.checkColor,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusColor,
    this.hoverColor,
    this.splashRadius,
  });

  /// {@macro flutter.material.checkbox.fillColor}
  ///
  /// If specified, overrides the default value of [Checkbox.fillColor].
  final MaterialStateProperty<Color?>? fillColor;

  /// {@macro flutter.material.checkbox.mouseCursor}
  ///
  /// If specified, overrides the default value of [Checkbox.mouseCursor].
  final MouseCursor? mouseCursor;

  /// {@macro flutter.material.checkbox.checkColor}
  ///
  /// If specified, overrides the default value of [Checkbox.checkColor].
  final Color? checkColor;

  /// {@macro flutter.material.checkbox.materialTapTargetSize}
  ///
  /// If specified, overrides the default value of
  /// [Checkbox.materialTapTargetSize].
  final MaterialTapTargetSize? materialTapTargetSize;

  /// {@macro flutter.material.checkbox.visualDensity}
  ///
  /// If specified, overrides the default value of [Checkbox.visualDensity].
  final VisualDensity? visualDensity;

  /// {@macro flutter.material.checkbox.focusColor}
  ///
  /// If specified, overrides the default value of [Checkbox.focusColor].
  final Color? focusColor;

  /// {@macro flutter.material.checkbox.hoverColor}
  ///
  /// If specified, overrides the default value of [Checkbox.hoverColor].
  final Color? hoverColor;

  /// {@macro flutter.material.checkbox.splashRadius}
  ///
  /// If specified, overrides the default value of [Checkbox.splashRadius].
  final double? splashRadius;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  CheckboxThemeData copyWith({
    MaterialStateProperty<Color?>? fillColor,
    MouseCursor? mouseCursor,
    Color? checkColor,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    Color? focusColor,
    Color? hoverColor,
    double? splashRadius,
  }) {
    return CheckboxThemeData(
      fillColor: fillColor ?? this.fillColor,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      checkColor: checkColor ?? this.checkColor,
      materialTapTargetSize: materialTapTargetSize ?? this.materialTapTargetSize,
      visualDensity: visualDensity ?? this.visualDensity,
      focusColor: focusColor ?? this.focusColor,
      hoverColor: hoverColor ?? this.hoverColor,
      splashRadius: splashRadius ?? this.splashRadius,
    );
  }

  /// Linearly interpolate between two [CheckboxThemeData]s.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static CheckboxThemeData lerp(CheckboxThemeData? a, CheckboxThemeData? b, double t) {
    return CheckboxThemeData(
      fillColor: _lerpProperties<Color?>(a?.fillColor, b?.fillColor, t, Color.lerp),
      mouseCursor: t < 0.5 ? a?.mouseCursor : b?.mouseCursor,
      checkColor: Color.lerp(a?.checkColor, b?.checkColor, t),
      materialTapTargetSize: t < 0.5 ? a?.materialTapTargetSize : b?.materialTapTargetSize,
      visualDensity: t < 0.5 ? a?.visualDensity : b?.visualDensity,
      focusColor: Color.lerp(a?.focusColor, b?.focusColor, t),
      hoverColor: Color.lerp(a?.hoverColor, b?.hoverColor, t),
      splashRadius: lerpDouble(a?.splashRadius, b?.splashRadius, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      fillColor,
      mouseCursor,
      checkColor,
      materialTapTargetSize,
      visualDensity,
      focusColor,
      hoverColor,
      splashRadius,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is CheckboxThemeData
      && other.fillColor == fillColor
      && other.mouseCursor == mouseCursor
      && other.checkColor == checkColor
      && other.materialTapTargetSize == materialTapTargetSize
      && other.visualDensity == visualDensity
      && other.focusColor == focusColor
      && other.hoverColor == hoverColor
      && other.splashRadius == splashRadius;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('fillColor', fillColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MouseCursor>('mouseCursor', mouseCursor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('checkColor', checkColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialTapTargetSize>('materialTapTargetSize', materialTapTargetSize, defaultValue: null));
    properties.add(DiagnosticsProperty<VisualDensity>('visualDensity', visualDensity, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('focusColor', focusColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('hoverColor', hoverColor, defaultValue: null));
    properties.add(DoubleProperty('splashRadius', splashRadius, defaultValue: null));
  }

  static MaterialStateProperty<T>? _lerpProperties<T>(
    MaterialStateProperty<T>? a,
    MaterialStateProperty<T>? b,
    double t,
    T Function(T?, T?, double) lerpFunction,
  ) {
    // Avoid creating a _LerpProperties object for a common case.
    if (a == null && b == null)
      return null;
    return _LerpProperties<T>(a, b, t, lerpFunction);
  }
}

class _LerpProperties<T> implements MaterialStateProperty<T> {
  const _LerpProperties(this.a, this.b, this.t, this.lerpFunction);

  final MaterialStateProperty<T>? a;
  final MaterialStateProperty<T>? b;
  final double t;
  final T Function(T?, T?, double) lerpFunction;

  @override
  T resolve(Set<MaterialState> states) {
    final T? resolvedA = a?.resolve(states);
    final T? resolvedB = b?.resolve(states);
    return lerpFunction(resolvedA, resolvedB, t);
  }
}

/// Applies a checkbox theme to descendant [Checkbox] widgets.
///
/// Descendant widgets obtain the current theme's [CheckboxTheme] object using
/// [CheckboxTheme.of]. When a widget uses [CheckboxTheme.of], it is
/// automatically rebuilt if the theme later changes.
///
/// A checkbox theme can be specified as part of the overall Material theme
/// using [ThemeData.checkboxTheme].
///
/// See also:
///
///  * [CheckboxThemeData], which describes the actual configuration of a
///  checkbox theme.
class CheckboxTheme extends InheritedWidget {
  /// Constructs a checkbox theme that configures all descendant [Checkbox]
  /// widgets.
  const CheckboxTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  /// The properties used for all descendant [Checkbox] widgets.
  final CheckboxThemeData data;

  /// Returns the configuration [data] from the closest [CheckboxTheme]
  /// ancestor. If there is no ancestor, it returns [ThemeData.checkboxTheme].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// CheckboxThemeData theme = CheckboxTheme.of(context);
  /// ```
  static CheckboxThemeData of(BuildContext context) {
    final CheckboxTheme? checkboxTheme = context.dependOnInheritedWidgetOfExactType<CheckboxTheme>();
    return checkboxTheme?.data ?? Theme.of(context).checkboxTheme;
  }

  @override
  bool updateShouldNotify(CheckboxTheme oldWidget) => data != oldWidget.data;
}
