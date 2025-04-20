// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'carousel.dart';
import 'material.dart';
import 'theme.dart';

/// Defines default property values for descendant [CarouselView] widgets.
///
/// Descendant widgets obtain the current [CarouselViewThemeData] object using
/// `CarouselViewTheme.of(context)`. Instances of [CarouselViewThemeData] can be
/// customized with [CarouselViewThemeData.copyWith].
///
/// Typically a [CarouselViewThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.carouselViewTheme].
///
/// All [CarouselViewThemeData] properties are `null` by default. When null, the [CarouselView]
/// will provide its own defaults.
///
/// See also:
///
///  * [CarouselViewTheme], an [InheritedWidget] that propagates the theme to its descendants.
///  * [ThemeData], which describes the overall theme information for the application.
@immutable
class CarouselViewThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.carouselViewTheme].
  const CarouselViewThemeData({
    this.elevation,
    this.backgroundColor,
    this.overlayColor,
    this.shape,
    this.padding,
  });

  /// The amount of space to surround each carousel item with.
  ///
  /// Overrides the default value for [CarouselView.padding].
  final EdgeInsets? padding;

  /// The background color for each carousel item.
  ///
  /// Overrides the default value for [CarouselView.backgroundColor].
  final Color? backgroundColor;

  /// The z-coordinate of each carousel item.
  ///
  /// This controls the size of the shadow below the carousel.
  ///
  /// Overrides the default value for [CarouselView.elevation].
  final double? elevation;

  /// The shape of the carousel item's [Material].
  ///
  /// Overrides the default value for [CarouselView.shape].
  final OutlinedBorder? shape;

  /// The highlight color to indicate the carousel items are in pressed, hovered
  /// or focused states.
  ///
  /// Overrides the default value for [CarouselView.overlayColor].
  final WidgetStateProperty<Color?>? overlayColor;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  CarouselViewThemeData copyWith({
    Color? backgroundColor,
    double? elevation,
    OutlinedBorder? shape,
    WidgetStateProperty<Color?>? overlayColor,
    EdgeInsets? padding,
  }) {
    return CarouselViewThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
      overlayColor: overlayColor ?? this.overlayColor,
      padding: padding ?? this.padding,
    );
  }

  /// Linearly interpolate between two carousel themes.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static CarouselViewThemeData lerp(CarouselViewThemeData? a, CarouselViewThemeData? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return CarouselViewThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t) as OutlinedBorder?,
      overlayColor: WidgetStateProperty.lerp<Color?>(
        a?.overlayColor,
        b?.overlayColor,
        t,
        Color.lerp,
      ),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
    );
  }

  @override
  int get hashCode => Object.hash(backgroundColor, elevation, shape, overlayColor, padding);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CarouselViewThemeData &&
        other.backgroundColor == backgroundColor &&
        other.elevation == elevation &&
        other.shape == shape &&
        other.overlayColor == overlayColor &&
        other.padding == padding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<OutlinedBorder>('shape', shape, defaultValue: null));
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'overlayColor',
        overlayColor,
        defaultValue: null,
      ),
    );
    properties.add(DiagnosticsProperty<EdgeInsets>('padding', padding, defaultValue: null));
  }
}

/// Applies a carousel theme to descendant [CarouselView] widgets.
///
/// Descendant widgets obtain the current theme's [CarouselViewThemeData] using
/// [CarouselViewTheme.of]. When a widget uses [CarouselViewTheme.of], it is automatically
/// rebuilt if the theme later changes.
///
/// A carousel theme can be specified as part of the overall Material theme using
/// [ThemeData.carouselViewTheme].
///
/// See also:
///
///  * [CarouselViewThemeData], which describes the actual configuration of a carousel
///    theme.
///  * [Theme], which controls the overall theme inheritance.
class CarouselViewTheme extends InheritedTheme {
  /// Creates a carousel theme that configures all descendant [CarouselView] widgets.
  const CarouselViewTheme({super.key, required this.data, required super.child});

  /// The properties for descendant carousel widgets.
  final CarouselViewThemeData data;

  /// Returns the configuration [data] from the closest [CarouselViewTheme] ancestor.
  ///
  /// If there is no ancestor, it returns [ThemeData.carouselViewTheme].
  static CarouselViewThemeData of(BuildContext context) {
    final CarouselViewTheme? inheritedTheme =
        context.dependOnInheritedWidgetOfExactType<CarouselViewTheme>();
    return inheritedTheme?.data ?? Theme.of(context).carouselViewTheme;
  }

  /// Wraps the given [child] with a [CarouselViewTheme] containing the [data].
  @override
  Widget wrap(BuildContext context, Widget child) {
    return CarouselViewTheme(data: data, child: child);
  }

  /// Returns true if the [data] fields of the two themes are different.
  @override
  bool updateShouldNotify(CarouselViewTheme oldWidget) => data != oldWidget.data;
}
