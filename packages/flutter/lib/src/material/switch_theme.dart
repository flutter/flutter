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

/// Defines default property values for descendant [Switch] widgets.
///
/// Descendant widgets obtain the current [SwitchThemeData] object using
/// `SwitchTheme.of(context)`. Instances of [SwitchThemeData] can be customized
/// with [SwitchThemeData.copyWith].
///
/// Typically a [SwitchThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.switchTheme].
///
/// All [SwitchThemeData] properties are `null` by default. When null, the
/// [Switch] will use the values from [ThemeData] if they exist, otherwise it
/// will provide its own defaults based on the overall [Theme]'s colorScheme.
/// See the individual [Switch] properties for details.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class SwitchThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.switchTheme].
  const SwitchThemeData({
    this.thumbColor,
    this.trackColor,
    this.materialTapTargetSize,
    this.mouseCursor,
    this.overlayColor,
    this.splashRadius,
  });

  /// {@macro flutter.material.switch.thumbColor}
  ///
  /// If specified, overrides the default value of [Switch.thumbColor].
  final MaterialStateProperty<Color?>? thumbColor;

  /// {@macro flutter.material.switch.trackColor}
  ///
  /// If specified, overrides the default value of [Switch.trackColor].
  final MaterialStateProperty<Color?>? trackColor;

  /// {@macro flutter.material.switch.materialTapTargetSize}
  ///
  /// If specified, overrides the default value of
  /// [Switch.materialTapTargetSize].
  final MaterialTapTargetSize? materialTapTargetSize;

  /// {@macro flutter.material.switch.mouseCursor}
  ///
  /// If specified, overrides the default value of [Switch.mouseCursor].
  final MaterialStateProperty<MouseCursor?>? mouseCursor;

  /// {@macro flutter.material.switch.overlayColor}
  ///
  /// If specified, overrides the default value of [Switch.overlayColor].
  final MaterialStateProperty<Color?>? overlayColor;

  /// {@macro flutter.material.switch.splashRadius}
  ///
  /// If specified, overrides the default value of [Switch.splashRadius].
  final double? splashRadius;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  SwitchThemeData copyWith({
    MaterialStateProperty<Color?>? thumbColor,
    MaterialStateProperty<Color?>? trackColor,
    MaterialTapTargetSize? materialTapTargetSize,
    MaterialStateProperty<MouseCursor?>? mouseCursor,
    MaterialStateProperty<Color?>? overlayColor,
    double? splashRadius,
  }) {
    return SwitchThemeData(
      thumbColor: thumbColor ?? this.thumbColor,
      trackColor: trackColor ?? this.trackColor,
      materialTapTargetSize: materialTapTargetSize ?? this.materialTapTargetSize,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      overlayColor: overlayColor ?? this.overlayColor,
      splashRadius: splashRadius ?? this.splashRadius,
    );
  }

  /// Linearly interpolate between two [SwitchThemeData]s.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static SwitchThemeData lerp(SwitchThemeData? a, SwitchThemeData? b, double t) {
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.lerp<Color?>(a?.thumbColor, b?.thumbColor, t, Color.lerp),
      trackColor: MaterialStateProperty.lerp<Color?>(a?.trackColor, b?.trackColor, t, Color.lerp),
      materialTapTargetSize: t < 0.5 ? a?.materialTapTargetSize : b?.materialTapTargetSize,
      mouseCursor: t < 0.5 ? a?.mouseCursor : b?.mouseCursor,
      overlayColor: MaterialStateProperty.lerp<Color?>(a?.overlayColor, b?.overlayColor, t, Color.lerp),
      splashRadius: lerpDouble(a?.splashRadius, b?.splashRadius, t),
    );
  }

  @override
  int get hashCode => Object.hash(
    thumbColor,
    trackColor,
    materialTapTargetSize,
    mouseCursor,
    overlayColor,
    splashRadius,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SwitchThemeData
      && other.thumbColor == thumbColor
      && other.trackColor == trackColor
      && other.materialTapTargetSize == materialTapTargetSize
      && other.mouseCursor == mouseCursor
      && other.overlayColor == overlayColor
      && other.splashRadius == splashRadius;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('thumbColor', thumbColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('trackColor', trackColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialTapTargetSize>('materialTapTargetSize', materialTapTargetSize, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<MouseCursor?>>('mouseCursor', mouseCursor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('overlayColor', overlayColor, defaultValue: null));
    properties.add(DoubleProperty('splashRadius', splashRadius, defaultValue: null));
  }
}

/// Applies a switch theme to descendant [Switch] widgets.
///
/// Descendant widgets obtain the current theme's [SwitchTheme] object using
/// [SwitchTheme.of]. When a widget uses [SwitchTheme.of], it is automatically
/// rebuilt if the theme later changes.
///
/// A switch theme can be specified as part of the overall Material theme using
/// [ThemeData.switchTheme].
///
/// See also:
///
///  * [SwitchThemeData], which describes the actual configuration of a switch
///    theme.
class SwitchTheme extends InheritedWidget {
  /// Constructs a switch theme that configures all descendant [Switch] widgets.
  const SwitchTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The properties used for all descendant [Switch] widgets.
  final SwitchThemeData data;

  /// Returns the configuration [data] from the closest [SwitchTheme] ancestor.
  /// If there is no ancestor, it returns [ThemeData.switchTheme].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// SwitchThemeData theme = SwitchTheme.of(context);
  /// ```
  static SwitchThemeData of(BuildContext context) {
    final SwitchTheme? switchTheme = context.dependOnInheritedWidgetOfExactType<SwitchTheme>();
    return switchTheme?.data ?? Theme.of(context).switchTheme;
  }

  @override
  bool updateShouldNotify(SwitchTheme oldWidget) => data != oldWidget.data;
}
