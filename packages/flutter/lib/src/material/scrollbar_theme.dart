// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Overrides the default values of visual properties for descendant
/// [Scrollbar] widgets.
///
/// Descendant widgets obtain the current [ScrollbarTheme] object with
/// `ScrollbarTheme.of(context)`. Instances of [ScrollbarTheme] can be customized
/// with [ScrollbarTheme.copyWith].
///
/// Typically a [ScrollbarTheme] is specified as part of the overall [Theme] with
/// [ThemeData.scrollbarTheme].
///
/// All [ScrollbarTheme] properties are `null` by default. When null, the [Scrollbar]
/// computes its own default values, typically based on the overall theme's
/// [ThemeData.colorScheme].
@immutable
class ScrollbarTheme with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.scrollbarTheme].
  const ScrollbarTheme({
    this.thickness,
    this.hoverThickness,
    this.showTrackOnHover,
    this.radius,
    this.thumbDragColor,
    this.thumbHoverColor,
    this.thumbIdleColor,
    this.trackColor,
    this.trackBorderColor,
    this.crossAxisMargin,
    this.mainAxisMargin,
    this.minThumbLength,
  });

  /// Overrides the default value of [Scrollbar.thickness] in all
  /// descendant [Scrollbar] widgets.
  ///
  /// See also:
  ///
  ///  * [hoverThickness], which overrides the default value of
  ///    [Scrollbar.hoverThickness] in all descendant [Scrollbar] widgets.
  final double? thickness;

  /// Overrides the default value of [Scrollbar.hoverThickness] in all
  /// descendant [Scrollbar] widgets.
  ///
  /// See also:
  ///
  ///  * [thickness], which overrides the default value of
  ///    [Scrollbar.thickness] in all descendant [Scrollbar] widgets.
  final double? hoverThickness;

  /// Overrides the default value of [Scrollbar.showTrackOnHover] in all
  /// descendant [Scrollbar] widgets.
  final bool? showTrackOnHover;


  /// Overrides the default value of [Scrollbar.radius] in all
  /// descendant widgets.
  final Radius? radius;

  /// Overrides the default [Color] of the [Scrollbar] thumb during drag in all
  /// descendant [Scrollbar] widgets.
  final Color? thumbDragColor;

  /// Overrides the default [Color] of the [Scrollbar] thumb during hover in all
  /// descendant [Scrollbar] widgets.
  final Color? thumbHoverColor;

  /// Overrides the default [Color] of the [Scrollbar] thumb during rest in all
  /// descendant [Scrollbar] widgets.
  final Color? thumbIdleColor;

  /// Overrides the default [Color] of the [Scrollbar] track when
  /// [showTrackOnHover] is true in all descendant [Scrollbar] widgets.
  final Color? trackColor;

  /// Overrides the default [Color] of the [Scrollbar] track border when
  /// [showTrackOnHover] is true in all descendant [Scrollbar] widgets.
  final Color? trackBorderColor;

  /// Overrides the default value of the [ScrollbarPainter.crossAxisMargin]
  /// property in all descendant [Scrollbar] widgets.
  ///
  /// See also:
  ///
  ///  * [ScrollbarPainter.crossAxisMargin], which sets the distance from the
  ///    scrollbar's side to the nearest edge in logical pixels.
  final double? crossAxisMargin;

  /// Overrides the default value of the [ScrollbarPainter.mainAxisMargin]
  /// property in all descendant [Scrollbar] widgets.
  ///
  /// See also:
  ///
  ///  * [ScrollbarPainter.mainAxisMargin], which sets the distance from the
  ///    scrollbar's start and end to the edge of the viewport in logical pixels.
  final double? mainAxisMargin;

  /// Overrides the default value of the [ScrollbarPainter.minLength]
  /// property in all descendant [Scrollbar] widgets.
  ///
  /// See also:
  ///
  ///  * [ScrollbarPainter.minLength], which sets the preferred smallest size
  ///    the scrollbar can shrink to when the total scrollable extent is large,
  ///    the current visible viewport is small, and the viewport is not
  ///    overscrolled.
  final double? minThumbLength;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  ScrollbarTheme copyWith({
    double? thickness,
    double? hoverThickness,
    bool? showTrackOnHover,
    Radius? radius,
    Color? thumbDragColor,
    Color? thumbHoverColor,
    Color? thumbIdleColor,
    Color? trackColor,
    Color? trackBorderColor,
    double? crossAxisMargin,
    double? mainAxisMargin,
    double? minThumbLength,
  }) {
    return ScrollbarTheme(
      thickness: thickness ?? this.thickness,
      hoverThickness: hoverThickness ?? this.hoverThickness,
      showTrackOnHover: showTrackOnHover ?? this.showTrackOnHover,
      radius: radius ?? this.radius,
      thumbDragColor: thumbDragColor ?? this.thumbDragColor,
      thumbHoverColor: thumbHoverColor ?? this.thumbHoverColor,
      thumbIdleColor: thumbIdleColor ?? this.thumbIdleColor,
      trackColor: trackColor ?? this.trackColor,
      trackBorderColor: trackBorderColor ?? this.trackBorderColor,
      crossAxisMargin: crossAxisMargin ?? this.crossAxisMargin,
      mainAxisMargin: mainAxisMargin ?? this.mainAxisMargin,
      minThumbLength: minThumbLength ?? this.minThumbLength,
    );
  }

  /// The [ThemeData.scrollbarTheme] property of the ambient [Theme].
  static ScrollbarTheme of(BuildContext context) {
    return Theme.of(context).scrollbarTheme;
  }

  /// Linearly interpolate between two Scrollbar themes.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static ScrollbarTheme lerp(ScrollbarTheme? a, ScrollbarTheme? b, double t) {
    assert(t != null);
    return ScrollbarTheme(
      thickness: lerpDouble(a?.thickness, b?.thickness, t),
      hoverThickness: lerpDouble(a?.hoverThickness, b?.hoverThickness, t),
      showTrackOnHover: t < 0.5 ? a?.showTrackOnHover : b?.showTrackOnHover,
      radius: Radius.lerp(a?.radius, b?.radius, t),
      thumbDragColor: Color.lerp(a?.thumbDragColor, b?.thumbDragColor, t),
      thumbHoverColor: Color.lerp(a?.thumbHoverColor, b?.thumbHoverColor, t),
      thumbIdleColor: Color.lerp(a?.thumbIdleColor, b?.thumbIdleColor, t),
      trackColor: Color.lerp(a?.trackColor, b?.trackColor, t),
      trackBorderColor: Color.lerp(a?.trackBorderColor, b?.trackBorderColor, t),
      crossAxisMargin: lerpDouble(a?.crossAxisMargin, b?.crossAxisMargin, t),
      mainAxisMargin: lerpDouble(a?.mainAxisMargin, b?.mainAxisMargin, t),
      minThumbLength: lerpDouble(a?.minThumbLength, b?.minThumbLength, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      thickness,
      hoverThickness,
      showTrackOnHover,
      radius,
      thumbDragColor,
      thumbHoverColor,
      thumbIdleColor,
      trackColor,
      trackBorderColor,
      crossAxisMargin,
      mainAxisMargin,
      minThumbLength,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is ScrollbarTheme
      && other.thickness == thickness
      && other.hoverThickness == hoverThickness
      && other.showTrackOnHover == showTrackOnHover
      && other.radius == radius
      && other.thumbDragColor == thumbDragColor
      && other.thumbHoverColor == thumbHoverColor
      && other.thumbIdleColor == thumbIdleColor
      && other.trackColor == trackColor
      && other.trackBorderColor == trackBorderColor
      && other.crossAxisMargin == crossAxisMargin
      && other.mainAxisMargin == mainAxisMargin
      && other.minThumbLength == minThumbLength;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<double>('thickness', thickness, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('hoverThickness', hoverThickness, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('showTrackOnHover', showTrackOnHover, defaultValue: null));
    properties.add(DiagnosticsProperty<Radius>('radius', radius, defaultValue: null));
    properties.add(ColorProperty('thumbDragColor', thumbDragColor, defaultValue: null));
    properties.add(ColorProperty('thumbHoverColor', thumbHoverColor, defaultValue: null));
    properties.add(ColorProperty('thumbIdleColor', thumbIdleColor, defaultValue: null));
    properties.add(ColorProperty('trackColor', trackColor, defaultValue: null));
    properties.add(ColorProperty('trackBorderColor', trackBorderColor, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('crossAxisMargin', crossAxisMargin, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('mainAxisMargin', mainAxisMargin, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('minThumbLength', minThumbLength, defaultValue: null));

  }
}
