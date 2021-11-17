// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Used with [CardTheme] to define default property values for
/// descendant [Card] widgets.
///
/// Descendant widgets obtain the current [CardThemeData] object
/// using `CardTheme.of(context)`. Instances of
/// [CardThemeData] can be customized with
/// [CardThemeData.copyWith].
///
/// A [CardThemeData] is often specified as part of the
/// overall [Theme] with [ThemeData.cardTheme].
///
/// All [CardThemeData] properties are `null` by default.
/// When a theme property is null, the [Card] will provide its own
/// default based on the overall [Theme]'s textTheme and
/// colorScheme. See the individual [Card] properties for details.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class CardThemeData with Diagnosticable {
  /// Creates a card theme configuration that can be used for [ThemeData.cardTheme]
  /// or [CardTheme].
  ///
  /// The [elevation] must be null or non-negative.
  const CardThemeData({
    this.clipBehavior,
    this.color,
    this.shadowColor,
    this.elevation,
    this.margin,
    this.shape,
  }) : assert(elevation == null || elevation >= 0.0);

  /// Overrides the default value for [Card.clipBehavior].
  final Clip? clipBehavior;

  /// Overrides the default value for [Card.color].
  final Color? color;

  /// Overrides the default value for [Card.shadowColor].
  final Color? shadowColor;

  /// Overrides the default value for [Card.elevation].
  final double? elevation;

  /// Overrides the default value for [Card.margin].
  final EdgeInsetsGeometry? margin;

  /// Overrides the default value for [Card.shape].
  final ShapeBorder? shape;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  CardThemeData copyWith({
    Clip? clipBehavior,
    Color? color,
    Color? shadowColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    ShapeBorder? shape,
  }) {
    return CardThemeData(
      clipBehavior: clipBehavior ?? this.clipBehavior,
      color: color ?? this.color,
      shadowColor: shadowColor ?? this.shadowColor,
      elevation: elevation ?? this.elevation,
      margin: margin ?? this.margin,
      shape: shape ?? this.shape,
    );
  }

  /// Linearly interpolate between two CardThemeData objects.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static CardThemeData lerp(CardThemeData? a, CardThemeData? b, double t) {
    assert(t != null);
    return CardThemeData(
      clipBehavior: t < 0.5 ? a?.clipBehavior : b?.clipBehavior,
      color: Color.lerp(a?.color, b?.color, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      margin: EdgeInsetsGeometry.lerp(a?.margin, b?.margin, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      clipBehavior,
      color,
      shadowColor,
      elevation,
      margin,
      shape,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is CardThemeData
        && other.clipBehavior == clipBehavior
        && other.color == color
        && other.shadowColor == shadowColor
        && other.elevation == elevation
        && other.margin == margin
        && other.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Clip>('clipBehavior', clipBehavior, defaultValue: null));
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(ColorProperty('shadowColor', shadowColor, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}

/// Defines default property values for descendant [Card] widgets.
///
/// Values specified here are used for [Card] properties that are not given
/// an explicit non-null value.
///
/// Descendant widgets obtain the current [CardThemeData] object using
/// `CardTheme.of(context)`. Instances of [CardThemeData] can be
/// customized with [CardThemeData.copyWith].
///
/// Typically a [CardThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.cardTheme].
///
/// All [CardThemeData] properties are `null` by default. When null,
/// the [Card] will use the values from [ThemeData.cardTheme] if they
/// are non-null, otherwise it will provide its own defaults.
@immutable
class CardTheme extends InheritedTheme {
  /// Creates a card theme that defines the color and style parameters for
  /// descendant [Card]s.
  ///
  /// Only the [data] parameter should be used. The other parameters are
  /// redundant (are now obsolete) and will be deprecated in a future update.
  const CardTheme({
    Key? key,
    CardThemeData? data,
    Clip? clipBehavior,
    Color? color,
    Color? shadowColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    ShapeBorder? shape,
    Widget? child,
  }) : assert(
         data == null ||
         (clipBehavior ??
          color ??
          shadowColor ??
          elevation ??
          margin ??
          shape) == null),
        assert(elevation == null || elevation >= 0.0),
        _data = data,
        _clipBehavior = clipBehavior,
        _color = color,
        _shadowColor = shadowColor,
        _elevation = elevation,
        _margin = margin,
        _shape = shape,
        super(key: key, child: child ?? const SizedBox());

  final CardThemeData? _data;
  final Clip? _clipBehavior;
  final Color? _color;
  final Color? _shadowColor;
  final double? _elevation;
  final EdgeInsetsGeometry? _margin;
  final ShapeBorder? _shape;

  /// The configuration of this theme.
  CardThemeData get data {
    return _data ?? CardThemeData(
      clipBehavior: _clipBehavior,
      color: _color,
      shadowColor: _shadowColor,
      elevation: _elevation,
      margin: _margin,
      shape: _shape,
    );
  }

  /// Overrides the default value for [Card.clipBehavior].
  ///
  /// This property is obsolete: please use the [data]
  /// [CardThemeData.clipBehavior] property instead.
  Clip? get clipBehavior => _data != null ? _data!.clipBehavior : _clipBehavior;

  /// Overrides the default value for [Card.color].
  ///
  /// This property is obsolete: please use the [data]
  /// [CardThemeData.color] property instead.
  Color? get color => _data != null ? _data!.color : _color;

  /// Overrides the default value for [Card.shadowColor].
  ///
  /// This property is obsolete: please use the [data]
  /// [CardThemeData.shadowColor] property instead.
  Color? get shadowColor => _data != null ? _data!.shadowColor : _shadowColor;

  /// Overrides the default value for [Card.elevation].
  ///
  /// This property is obsolete: please use the [data]
  /// [CardThemeData.elevation] property instead.
  double? get elevation => _data != null ? _data!.elevation : _elevation;

  /// Overrides the default value for [Card.margin].
  ///
  /// This property is obsolete: please use the [data]
  /// [CardThemeData.margin] property instead.
  EdgeInsetsGeometry? get margin => _data != null ? _data!.margin : _margin;

  /// Overrides the default value for [Card.shape].
  ///
  /// This property is obsolete: please use the [data]
  /// [CardThemeData.shape] property instead.
  ShapeBorder? get shape => _data != null ? _data!.shape : _shape;


  /// The [data] property of the closest instance of this class that
  /// encloses the given context.
  ///
  /// If there is no enclosing [CardTheme] widget, then
  /// [ThemeData.cardTheme] is used (see [Theme.of]).
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// CardThemeData theme = CardTheme.of(context);
  /// ```
  static CardThemeData of(BuildContext context) {
    final CardTheme? result = context.dependOnInheritedWidgetOfExactType<CardTheme>();
    return result?.data ?? Theme.of(context).cardTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return CardTheme(
      data: CardThemeData(
        clipBehavior: clipBehavior,
        color: color,
        shadowColor: shadowColor,
        elevation: elevation,
        margin: margin,
        shape: shape,
      ),
    );
  }

  @override
  bool updateShouldNotify(CardTheme oldWidget) => data != oldWidget.data;
}
