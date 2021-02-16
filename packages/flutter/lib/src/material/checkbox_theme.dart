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
    this.mouseCursor,
    this.fillColor,
    this.checkColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.shape,
    this.side,
  });

  /// {@macro flutter.material.checkbox.mouseCursor}
  ///
  /// If specified, overrides the default value of [Checkbox.mouseCursor].
  final MaterialStateProperty<MouseCursor?>? mouseCursor;

  /// {@macro flutter.material.checkbox.fillColor}
  ///
  /// If specified, overrides the default value of [Checkbox.fillColor].
  final MaterialStateProperty<Color?>? fillColor;

  /// {@macro flutter.material.checkbox.checkColor}
  ///
  /// Resolves in the following states:
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.disabled].
  ///
  /// If specified, overrides the default value of [Checkbox.checkColor].
  final MaterialStateProperty<Color?>? checkColor;

  /// {@macro flutter.material.checkbox.overlayColor}
  ///
  /// If specified, overrides the default value of [Checkbox.overlayColor].
  final MaterialStateProperty<Color?>? overlayColor;

  /// {@macro flutter.material.checkbox.splashRadius}
  ///
  /// If specified, overrides the default value of [Checkbox.splashRadius].
  final double? splashRadius;

  /// {@macro flutter.material.checkbox.materialTapTargetSize}
  ///
  /// If specified, overrides the default value of
  /// [Checkbox.materialTapTargetSize].
  final MaterialTapTargetSize? materialTapTargetSize;

  /// {@macro flutter.material.checkbox.visualDensity}
  ///
  /// If specified, overrides the default value of [Checkbox.visualDensity].
  final VisualDensity? visualDensity;

  /// {@macro flutter.material.checkbox.shape}
  ///
  /// If specified, overrides the default value of [Checkbox.shape].
  final OutlinedBorder? shape;

  /// {@macro flutter.material.checkbox.side}
  ///
  /// If specified, overrides the default value of [Checkbox.side].
  final BorderSide? side;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  CheckboxThemeData copyWith({
    MaterialStateProperty<MouseCursor?>? mouseCursor,
    MaterialStateProperty<Color?>? fillColor,
    MaterialStateProperty<Color?>? checkColor,
    MaterialStateProperty<Color?>? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    OutlinedBorder? shape,
    BorderSide? side,
  }) {
    return CheckboxThemeData(
      mouseCursor: mouseCursor ?? this.mouseCursor,
      fillColor: fillColor ?? this.fillColor,
      checkColor: checkColor ?? this.checkColor,
      overlayColor: overlayColor ?? this.overlayColor,
      splashRadius: splashRadius ?? this.splashRadius,
      materialTapTargetSize: materialTapTargetSize ?? this.materialTapTargetSize,
      visualDensity: visualDensity ?? this.visualDensity,
      shape: shape ?? this.shape,
      side: side ?? this.side,
    );
  }

  /// Linearly interpolate between two [CheckboxThemeData]s.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static CheckboxThemeData lerp(CheckboxThemeData? a, CheckboxThemeData? b, double t) {
    return CheckboxThemeData(
      mouseCursor: t < 0.5 ? a?.mouseCursor : b?.mouseCursor,
      fillColor: _lerpProperties<Color?>(a?.fillColor, b?.fillColor, t, Color.lerp),
      checkColor: _lerpProperties<Color?>(a?.checkColor, b?.checkColor, t, Color.lerp),
      overlayColor: _lerpProperties<Color?>(a?.overlayColor, b?.overlayColor, t, Color.lerp),
      splashRadius: lerpDouble(a?.splashRadius, b?.splashRadius, t),
      materialTapTargetSize: t < 0.5 ? a?.materialTapTargetSize : b?.materialTapTargetSize,
      visualDensity: t < 0.5 ? a?.visualDensity : b?.visualDensity,
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t) as OutlinedBorder?,
      side: _lerpSides(a?.side, b?.side, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      mouseCursor,
      fillColor,
      checkColor,
      overlayColor,
      splashRadius,
      materialTapTargetSize,
      visualDensity,
      shape,
      side,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is CheckboxThemeData
      && other.mouseCursor == mouseCursor
      && other.fillColor == fillColor
      && other.checkColor == checkColor
      && other.overlayColor == overlayColor
      && other.splashRadius == splashRadius
      && other.materialTapTargetSize == materialTapTargetSize
      && other.visualDensity == visualDensity
      && other.shape == shape
      && other.side == side;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MaterialStateProperty<MouseCursor?>>('mouseCursor', mouseCursor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('fillColor', fillColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('checkColor', checkColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('overlayColor', overlayColor, defaultValue: null));
    properties.add(DoubleProperty('splashRadius', splashRadius, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialTapTargetSize>('materialTapTargetSize', materialTapTargetSize, defaultValue: null));
    properties.add(DiagnosticsProperty<VisualDensity>('visualDensity', visualDensity, defaultValue: null));
    properties.add(DiagnosticsProperty<OutlinedBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<BorderSide>('side', side, defaultValue: null));
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

  // Special case because BorderSide.lerp() doesn't support null arguments
  static BorderSide? _lerpSides(BorderSide? a, BorderSide? b, double t) {
    if (a == null && b == null)
      return null;
    return BorderSide.lerp(a!, b!, t);
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
