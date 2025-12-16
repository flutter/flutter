// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'constants.dart';
/// @docImport 'radio.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'theme_data.dart';

// Examples can assume:
// late BuildContext context;

/// Defines default property values for descendant [Radio] widgets.
///
/// Descendant widgets obtain the current [RadioThemeData] object using
/// [RadioTheme.of]. Instances of [RadioThemeData] can be customized
/// with [RadioThemeData.copyWith].
///
/// Typically a [RadioThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.radioTheme].
///
/// All [RadioThemeData] properties are `null` by default. When null, the
/// [Radio] will use the values from [ThemeData] if they exist, otherwise it
/// will provide its own defaults based on the overall [Theme]'s colorScheme.
/// See the individual [Radio] properties for details.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
///  * [RadioTheme], which is used by descendants to obtain the
///    [RadioThemeData].
@immutable
class RadioThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.radioTheme].
  const RadioThemeData({
    this.mouseCursor,
    this.fillColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.backgroundColor,
    this.side,
    this.innerRadius,
  });

  /// {@macro flutter.widget.RawRadio.mouseCursor}
  ///
  /// If specified, overrides the default value of [Radio.mouseCursor]. The
  /// default value is [WidgetStateMouseCursor.clickable].
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// {@macro flutter.material.radio.fillColor}
  ///
  /// If specified, overrides the default value of [Radio.fillColor].
  final WidgetStateProperty<Color?>? fillColor;

  /// {@macro flutter.material.radio.overlayColor}
  ///
  /// If specified, overrides the default value of [Radio.overlayColor].
  final WidgetStateProperty<Color?>? overlayColor;

  /// {@macro flutter.material.radio.splashRadius}
  ///
  /// If specified, overrides the default value of [Radio.splashRadius]. The
  /// default value is [kRadialReactionRadius].
  final double? splashRadius;

  /// {@macro flutter.material.radio.materialTapTargetSize}
  ///
  /// If specified, overrides the default value of
  /// [Radio.materialTapTargetSize]. The default value is the value of
  /// [ThemeData.materialTapTargetSize].
  final MaterialTapTargetSize? materialTapTargetSize;

  /// {@macro flutter.material.radio.visualDensity}
  ///
  /// If specified, overrides the default value of [Radio.visualDensity]. The
  /// default value is the value of [ThemeData.visualDensity].
  final VisualDensity? visualDensity;

  /// {@macro flutter.material.Radio.backgroundColor}
  ///
  /// If specified, overrides the default value of [Radio.backgroundColor]. The
  /// default value is transparent in all states.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// {@macro flutter.material.Radio.side}
  ///
  /// If specified, overrides the default value of [Radio.side]. The default
  /// value is a border using the fill color.
  final BorderSide? side;

  /// {@macro flutter.material.Radio.innerRadius}
  ///
  /// If specified, overrides the default value of [Radio.innerRadius]. The
  /// default value is `4.5` in all states.
  final WidgetStateProperty<double?>? innerRadius;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  RadioThemeData copyWith({
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    WidgetStateProperty<Color?>? backgroundColor,
    BorderSide? side,
    WidgetStateProperty<double?>? innerRadius,
  }) {
    return RadioThemeData(
      mouseCursor: mouseCursor ?? this.mouseCursor,
      fillColor: fillColor ?? this.fillColor,
      overlayColor: overlayColor ?? this.overlayColor,
      splashRadius: splashRadius ?? this.splashRadius,
      materialTapTargetSize: materialTapTargetSize ?? this.materialTapTargetSize,
      visualDensity: visualDensity ?? this.visualDensity,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      side: side ?? this.side,
      innerRadius: innerRadius ?? this.innerRadius,
    );
  }

  // Special case because BorderSide.lerp() doesn't support null arguments.
  static BorderSide? _lerpSides(BorderSide? a, BorderSide? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    if (a is WidgetStateBorderSide) {
      a = a.resolve(const <WidgetState>{});
    }
    if (b is WidgetStateBorderSide) {
      b = b.resolve(const <WidgetState>{});
    }
    a ??= BorderSide(width: 0, color: b!.color.withAlpha(0));
    b ??= BorderSide(width: 0, color: a.color.withAlpha(0));

    return BorderSide.lerp(a, b, t);
  }

  /// Linearly interpolate between two [RadioThemeData]s.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static RadioThemeData lerp(RadioThemeData? a, RadioThemeData? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return RadioThemeData(
      mouseCursor: t < 0.5 ? a?.mouseCursor : b?.mouseCursor,
      fillColor: WidgetStateProperty.lerp<Color?>(a?.fillColor, b?.fillColor, t, Color.lerp),
      materialTapTargetSize: t < 0.5 ? a?.materialTapTargetSize : b?.materialTapTargetSize,
      overlayColor: WidgetStateProperty.lerp<Color?>(
        a?.overlayColor,
        b?.overlayColor,
        t,
        Color.lerp,
      ),
      splashRadius: lerpDouble(a?.splashRadius, b?.splashRadius, t),
      visualDensity: t < 0.5 ? a?.visualDensity : b?.visualDensity,
      backgroundColor: WidgetStateProperty.lerp<Color?>(
        a?.backgroundColor,
        b?.backgroundColor,
        t,
        Color.lerp,
      ),
      side: _lerpSides(a?.side, b?.side, t),
      innerRadius: WidgetStateProperty.lerp<double?>(a?.innerRadius, b?.innerRadius, t, lerpDouble),
    );
  }

  @override
  int get hashCode => Object.hash(
    mouseCursor,
    fillColor,
    overlayColor,
    splashRadius,
    materialTapTargetSize,
    visualDensity,
    backgroundColor,
    side,
    innerRadius,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is RadioThemeData &&
        other.mouseCursor == mouseCursor &&
        other.fillColor == fillColor &&
        other.overlayColor == overlayColor &&
        other.splashRadius == splashRadius &&
        other.materialTapTargetSize == materialTapTargetSize &&
        other.visualDensity == visualDensity &&
        other.backgroundColor == backgroundColor &&
        other.side == side &&
        other.innerRadius == innerRadius;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<MouseCursor?>>(
        'mouseCursor',
        mouseCursor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>('fillColor', fillColor, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'overlayColor',
        overlayColor,
        defaultValue: null,
      ),
    );
    properties.add(DoubleProperty('splashRadius', splashRadius, defaultValue: null));
    properties.add(
      DiagnosticsProperty<MaterialTapTargetSize>(
        'materialTapTargetSize',
        materialTapTargetSize,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<VisualDensity>('visualDensity', visualDensity, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'backgroundColor',
        backgroundColor,
        defaultValue: null,
      ),
    );
    properties.add(DiagnosticsProperty<BorderSide>('side', side, defaultValue: null));
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<double?>>(
        'innerRadius',
        innerRadius,
        defaultValue: null,
      ),
    );
  }
}

/// Applies a radio theme to descendant [Radio] widgets.
///
/// Descendant widgets obtain the current theme's [RadioTheme] object using
/// [RadioTheme.of]. When a widget uses [RadioTheme.of], it is automatically
/// rebuilt if the theme later changes.
///
/// A radio theme can be specified as part of the overall Material theme using
/// [ThemeData.radioTheme].
///
/// See also:
///
///  * [RadioThemeData], which describes the actual configuration of a radio
///    theme.
class RadioTheme extends InheritedWidget {
  /// Constructs a radio theme that configures all descendant [Radio] widgets.
  const RadioTheme({super.key, required this.data, required super.child});

  /// The properties used for all descendant [Radio] widgets.
  final RadioThemeData data;

  /// Returns the configuration [data] from the closest [RadioTheme] ancestor.
  /// If there is no ancestor, it returns [ThemeData.radioTheme].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// RadioThemeData theme = RadioTheme.of(context);
  /// ```
  static RadioThemeData of(BuildContext context) {
    final RadioTheme? radioTheme = context.dependOnInheritedWidgetOfExactType<RadioTheme>();
    return radioTheme?.data ?? Theme.of(context).radioTheme;
  }

  @override
  bool updateShouldNotify(RadioTheme oldWidget) => data != oldWidget.data;
}
