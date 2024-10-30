// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'color_scheme.dart';
/// @docImport 'progress_indicator.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

// Examples can assume:
// late BuildContext context;

@immutable
/// Defines the visual properties of [ProgressIndicator] widgets.
///
/// Used by [ProgressIndicatorTheme] to control the visual properties of
/// progress indicators in a widget subtree.
///
/// To obtain this configuration, use [ProgressIndicatorTheme.of] to access
/// the closest ancestor [ProgressIndicatorTheme] of the current [BuildContext].
///
/// See also:
///
///  * [ProgressIndicatorTheme], an [InheritedWidget] that propagates the
///    theme down its subtree.
///  * [ThemeData.progressIndicatorTheme], which describes the defaults for
///    any progress indicators as part of the application's [ThemeData].
class ProgressIndicatorThemeData with Diagnosticable {
  /// Creates the set of properties used to configure [ProgressIndicator] widgets.
  const ProgressIndicatorThemeData({
    this.color,
    this.linearTrackColor,
    this.linearMinHeight,
    this.circularTrackColor,
    this.refreshBackgroundColor,
    this.borderRadius,
    this.stopIndicatorColor,
    this.stopIndicatorRadius,
    this.trackGap,
  });

  /// The color of the [ProgressIndicator]'s indicator.
  ///
  /// If null, then it will use [ColorScheme.primary] of the ambient
  /// [ThemeData.colorScheme].
  ///
  /// See also:
  ///
  ///  * [ProgressIndicator.color], which specifies the indicator color for a
  ///    specific progress indicator.
  ///  * [ProgressIndicator.valueColor], which specifies the indicator color
  ///    a an animated color.
  final Color? color;

  /// {@macro flutter.material.LinearProgressIndicator.trackColor}
  final Color? linearTrackColor;

  /// {@macro flutter.material.LinearProgressIndicator.minHeight}
  final double? linearMinHeight;

  /// {@macro flutter.material.CircularProgressIndicator.trackColor}
  final Color? circularTrackColor;

  /// {@macro flutter.material.RefreshProgressIndicator.backgroundColor}
  final Color? refreshBackgroundColor;

  /// Overrides the border radius of the [ProgressIndicator].
  final BorderRadiusGeometry? borderRadius;

  /// Overrides the stop indicator color of the [LinearProgressIndicator].
  ///
  /// If [LinearProgressIndicator.year2023] is false or [ThemeData.useMaterial3]
  /// is false, then no stop indicator will be drawn.
  final Color? stopIndicatorColor;

  /// Overrides the stop indicator radius of the [LinearProgressIndicator].
  ///
  /// If [LinearProgressIndicator.year2023] is false or [ThemeData.useMaterial3]
  /// is false, then no stop indicator will be drawn.
  final double? stopIndicatorRadius;

  /// Overrides the gap between the [LinearProgressIndicator].
  ///
  /// If [LinearProgressIndicator.year2023] is false or [ThemeData.useMaterial3]
  /// is false, then no track gap will be drawn.
  final double? trackGap;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  ProgressIndicatorThemeData copyWith({
    Color? color,
    Color? linearTrackColor,
    double? linearMinHeight,
    Color? circularTrackColor,
    Color? refreshBackgroundColor,
    BorderRadiusGeometry? borderRadius,
    Color? stopIndicatorColor,
    double? stopIndicatorRadius,
    double? trackGap,
  }) {
    return ProgressIndicatorThemeData(
      color: color ?? this.color,
      linearTrackColor : linearTrackColor ?? this.linearTrackColor,
      linearMinHeight : linearMinHeight ?? this.linearMinHeight,
      circularTrackColor : circularTrackColor ?? this.circularTrackColor,
      refreshBackgroundColor : refreshBackgroundColor ?? this.refreshBackgroundColor,
      borderRadius : borderRadius ?? this.borderRadius,
      stopIndicatorColor : stopIndicatorColor ?? this.stopIndicatorColor,
      stopIndicatorRadius : stopIndicatorRadius ?? this.stopIndicatorRadius,
      trackGap : trackGap ?? this.trackGap,
    );
  }

  /// Linearly interpolate between two progress indicator themes.
  ///
  /// If both arguments are null, then null is returned.
  static ProgressIndicatorThemeData? lerp(ProgressIndicatorThemeData? a, ProgressIndicatorThemeData? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    return ProgressIndicatorThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      linearTrackColor : Color.lerp(a?.linearTrackColor, b?.linearTrackColor, t),
      linearMinHeight : lerpDouble(a?.linearMinHeight, b?.linearMinHeight, t),
      circularTrackColor : Color.lerp(a?.circularTrackColor, b?.circularTrackColor, t),
      refreshBackgroundColor : Color.lerp(a?.refreshBackgroundColor, b?.refreshBackgroundColor, t),
      borderRadius : BorderRadiusGeometry.lerp(a?.borderRadius, b?.borderRadius, t),
      stopIndicatorColor : Color.lerp(a?.stopIndicatorColor, b?.stopIndicatorColor, t),
      stopIndicatorRadius : lerpDouble(a?.stopIndicatorRadius, b?.stopIndicatorRadius, t),
      trackGap : lerpDouble(a?.trackGap, b?.trackGap, t),
    );
  }

  @override
  int get hashCode => Object.hash(
    color,
    linearTrackColor,
    linearMinHeight,
    circularTrackColor,
    refreshBackgroundColor,
    borderRadius,
    stopIndicatorColor,
    stopIndicatorRadius,
    trackGap,
  );

  @override
  bool operator==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ProgressIndicatorThemeData
      && other.color == color
      && other.linearTrackColor == linearTrackColor
      && other.linearMinHeight == linearMinHeight
      && other.circularTrackColor == circularTrackColor
      && other.refreshBackgroundColor == refreshBackgroundColor
      && other.borderRadius == borderRadius
      && other.stopIndicatorColor == stopIndicatorColor
      && other.stopIndicatorRadius == stopIndicatorRadius
      && other.trackGap == trackGap;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(ColorProperty('linearTrackColor', linearTrackColor, defaultValue: null));
    properties.add(DoubleProperty('linearMinHeight', linearMinHeight, defaultValue: null));
    properties.add(ColorProperty('circularTrackColor', circularTrackColor, defaultValue: null));
    properties.add(ColorProperty('refreshBackgroundColor', refreshBackgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<BorderRadiusGeometry>('borderRadius', borderRadius, defaultValue: null));
    properties.add(ColorProperty('stopIndicatorColor', stopIndicatorColor, defaultValue: null));
    properties.add(DoubleProperty('stopIndicatorRadius', stopIndicatorRadius, defaultValue: null));
    properties.add(DoubleProperty('trackGap', trackGap, defaultValue: null));
  }
}

/// An inherited widget that defines the configuration for
/// [ProgressIndicator]s in this widget's subtree.
///
/// Values specified here are used for [ProgressIndicator] properties that are not
/// given an explicit non-null value.
///
/// {@tool snippet}
///
/// Here is an example of a progress indicator theme that applies a red indicator
/// color.
///
/// ```dart
/// const ProgressIndicatorTheme(
///   data: ProgressIndicatorThemeData(
///     color: Colors.red,
///   ),
///   child: LinearProgressIndicator()
/// )
/// ```
/// {@end-tool}
class ProgressIndicatorTheme extends InheritedTheme {
  /// Creates a theme that controls the configurations for [ProgressIndicator]
  /// widgets.
  const ProgressIndicatorTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The properties for descendant [ProgressIndicator] widgets.
  final ProgressIndicatorThemeData data;

  /// Returns the [data] from the closest [ProgressIndicatorTheme] ancestor. If
  /// there is no ancestor, it returns [ThemeData.progressIndicatorTheme].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ProgressIndicatorThemeData theme = ProgressIndicatorTheme.of(context);
  /// ```
  static ProgressIndicatorThemeData of(BuildContext context) {
    final ProgressIndicatorTheme? progressIndicatorTheme = context.dependOnInheritedWidgetOfExactType<ProgressIndicatorTheme>();
    return progressIndicatorTheme?.data ?? Theme.of(context).progressIndicatorTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return ProgressIndicatorTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(ProgressIndicatorTheme oldWidget) => data != oldWidget.data;
}
