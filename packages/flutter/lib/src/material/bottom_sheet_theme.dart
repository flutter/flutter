// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Defines default property values for [BottomSheet]'s [Material].
///
/// Descendant widgets obtain the current [BottomSheetThemeData] object
/// using `Theme.of(context).bottomSheetTheme`. Instances of
/// [BottomSheetThemeData] can be customized with
/// [BottomSheetThemeData.copyWith].
///
/// Typically a [BottomSheetThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.bottomSheetTheme].
///
/// All [BottomSheetThemeData] properties are `null` by default.
/// When null, the [BottomSheet] will provide its own defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class BottomSheetThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.bottomSheetTheme].
  const BottomSheetThemeData({
    this.backgroundColor,
    this.surfaceTintColor,
    this.elevation,
    this.modalBackgroundColor,
    this.modalBarrierColor,
    this.modalElevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
  });

  /// Overrides the default value for [BottomSheet.backgroundColor].
  ///
  /// If null, [BottomSheet] defaults to [Material]'s default.
  final Color? backgroundColor;

  /// Overrides the default value for surfaceTintColor.
  ///
  /// If null, [BottomSheet] will not display an overlay color.
  ///
  /// See [Material.surfaceTintColor] for more details.
  final Color? surfaceTintColor;

  /// Overrides the default value for [BottomSheet.elevation].
  ///
  /// {@macro flutter.material.material.elevation}
  ///
  /// If null, [BottomSheet] defaults to 0.0.
  final double? elevation;

  /// Value for [BottomSheet.backgroundColor] when the Bottom sheet is presented
  /// as a modal bottom sheet.
  final Color? modalBackgroundColor;

  /// Overrides the default value for barrier color when the Bottom sheet is presented as
  /// a modal bottom sheet.
  final Color? modalBarrierColor;

  /// Value for [BottomSheet.elevation] when the Bottom sheet is presented as a
  /// modal bottom sheet.
  final double? modalElevation;

  /// Overrides the default value for [BottomSheet.shape].
  ///
  /// If null, no overriding shape is specified for [BottomSheet], so the
  /// [BottomSheet] is rectangular.
  final ShapeBorder? shape;

  /// Overrides the default value for [BottomSheet.clipBehavior].
  ///
  /// If null, [BottomSheet] uses [Clip.none].
  final Clip? clipBehavior;

  /// Constrains the size of the [BottomSheet].
  ///
  /// If null, the bottom sheet's size will be unconstrained.
  final BoxConstraints? constraints;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  BottomSheetThemeData copyWith({
    Color? backgroundColor,
    Color? surfaceTintColor,
    double? elevation,
    Color? modalBackgroundColor,
    Color? modalBarrierColor,
    double? modalElevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
  }) {
    return BottomSheetThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      elevation: elevation ?? this.elevation,
      modalBackgroundColor: modalBackgroundColor ?? this.modalBackgroundColor,
      modalBarrierColor: modalBarrierColor ?? this.modalBarrierColor,
      modalElevation: modalElevation ?? this.modalElevation,
      shape: shape ?? this.shape,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      constraints: constraints ?? this.constraints,
    );
  }

  /// Linearly interpolate between two bottom sheet themes.
  ///
  /// If both arguments are null then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static BottomSheetThemeData? lerp(BottomSheetThemeData? a, BottomSheetThemeData? b, double t) {
    assert(t != null);
    if (a == null && b == null) {
      return null;
    }
    return BottomSheetThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      surfaceTintColor: Color.lerp(a?.surfaceTintColor, b?.surfaceTintColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      modalBackgroundColor: Color.lerp(a?.modalBackgroundColor, b?.modalBackgroundColor, t),
      modalBarrierColor: Color.lerp(a?.modalBarrierColor, b?.modalBarrierColor, t),
      modalElevation: lerpDouble(a?.modalElevation, b?.modalElevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      clipBehavior: t < 0.5 ? a?.clipBehavior : b?.clipBehavior,
      constraints: BoxConstraints.lerp(a?.constraints, b?.constraints, t),
    );
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    surfaceTintColor,
    elevation,
    modalBackgroundColor,
    modalBarrierColor,
    modalElevation,
    shape,
    clipBehavior,
    constraints,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is BottomSheetThemeData
        && other.backgroundColor == backgroundColor
        && other.surfaceTintColor == surfaceTintColor
        && other.elevation == elevation
        && other.modalBackgroundColor == modalBackgroundColor
        && other.modalBarrierColor == modalBarrierColor
        && other.modalElevation == modalElevation
        && other.shape == shape
        && other.clipBehavior == clipBehavior
        && other.constraints == constraints;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(ColorProperty('surfaceTintColor', surfaceTintColor, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties.add(ColorProperty('modalBackgroundColor', modalBackgroundColor, defaultValue: null));
    properties.add(ColorProperty('modalBarrierColor', modalBarrierColor, defaultValue: null));
    properties.add(DoubleProperty('modalElevation', modalElevation, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<Clip>('clipBehavior', clipBehavior, defaultValue: null));
    properties.add(DiagnosticsProperty<BoxConstraints>('constraints', constraints, defaultValue: null));
  }
}
