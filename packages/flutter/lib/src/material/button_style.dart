// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';
import 'theme_data.dart';

/// The visual properties that most buttons have in common.
///
/// Buttons and their themes have a ButtonStyle property which defines the visual
/// properties whose default values are to be overidden. The default values are
/// defined by the invidual button widgets and are typically based on overall
/// theme's [ThemeData.colorScheme] and [ThemeData.textTheme].
///
/// All of the ButtonStyle properties are null by default.
///
/// Many of the ButtonStyle properties are [MaterialStateProperty] objects which
/// resolve to different values depending on the button's state. For example
/// the [Color] properties are defined with `MaterialStateProperty<Color>` and
/// can resolve to different colors depending on if the button is pressed,
/// hovered, focused, disabled, etc.
///
/// These properties can override the default value for just one state or all of
/// them. For example to create a [ContainedButton] whose background color is the
/// color scheme’s primary color with 50% opacity, but only when the button is
/// pressed, one could write:
///
/// ```dart
/// ContainedButton(
///   style: ButtonStyle(
///     backgroundColor: MaterialStateProperty.resolveWith<Color>(
///       (Set<MaterialState> states) {
///         if (states.contains(MaterialState.pressed))
///           return Theme.of(context).colorScheme.primary.withOpacity(0.5);
///         return null; // Use the component's default.
///       },
///     ),
///   ),
/// )
///```
///
/// In this case the background color for all other button states would fallback
/// to the ContainedButton’s default values. To unconditionally set the button's
/// [backgroundColor] for all states one could write:
///
/// ```dart
/// ContainedButton(
///   style: ButtonStyle(
///     backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
///   ),
/// )
///```
///
/// Configuring a ButtonStyle directly makes it possible to very
/// precisely control the button’s visual attributes for all states.
/// This level of control is typically required when a custom
/// “branded” look and feel is desirable.  However, in many cases it’s
/// useful to make relatively sweeping changes based on a few initial
/// parameters with simple values. The button styleFrom() methods
/// enable such sweeping changes. See for example:
/// [TextButton.styleFrom], [ContainedButton.styleFrom],
/// [OutlinedButton.styleFrom].
///
/// For example, to override the default text and icon colors for a
/// [TextButton], as well as its overlay color, with all of the
/// standard opacity adjustments for the pressed, focused, and
/// hovered states, one could write:
///
/// ```dart
/// TextButton(
///   style: TextButton.styleFrom(primary: Colors.green),
/// )
///```
///
/// To configure all of the application's text buttons in the same
/// way, specify the overall theme's `textButtonTheme`:
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     textButtonTheme: TextButtonThemeData(
///       style: TextButton.styleFrom(primary: Colors.green),
///     ),
///   ),
///   home: MyAppHome(),
/// )
///```
/// See also:
///
///  * [TextButtonTheme], the theme for [TextButton]s.
///  * [ContainedButtonTheme], the theme for [ContainedButton]s.
///  * [OutlinedButtonTheme], the theme for [OutlinedButton]s.
@immutable
class ButtonStyle with Diagnosticable {
  /// Create a [ButtonStyle].
  const ButtonStyle({
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.overlayColor,
    this.shadowColor,
    this.elevation,
    this.padding,
    this.minimumSize,
    this.side,
    this.shape,
    this.mouseCursor,
    this.visualDensity,
    this.tapTargetSize,
    this.animationDuration,
    this.enableFeedback,
  });

  /// The style for a button's [Text] widget descendants.
  ///
  /// The color of the [textStyle] is typically not used directly, the
  /// [foreground] color is used instead.
  final MaterialStateProperty<TextStyle> textStyle;

  /// The button's background fill color.
  final MaterialStateProperty<Color> backgroundColor;

  /// The color for the button's [Text] and [Icon] widget descendants.
  ///
  /// This color is typically used instead of the color of the [textStyle]. All
  /// of the components that compute defaults from [ButtonStyle] values
  /// compute a default [foregroundColor] and use that instead of the
  /// [textStyle]'s color.
  final MaterialStateProperty<Color> foregroundColor;

  /// The highlight color that's typically used to indicate that
  /// the button is focused, hovered, or pressed.
  final MaterialStateProperty<Color> overlayColor;

  /// The shadow color of the button's [Material].
  ///
  /// The material's elevation shadow can be difficult to see for
  /// dark themes, so by default the button classes add a
  /// semi-transparent overlay to indicate elevation. See
  /// [ThemeData.applyElevationOverlayColor].
  final MaterialStateProperty<Color> shadowColor;

  /// The elevation of the button's [Material].
  final MaterialStateProperty<double> elevation;

  /// The padding between the button's boundary and its child.
  final MaterialStateProperty<EdgeInsetsGeometry> padding;

  /// The minimum size of the button itself.
  ///
  /// The size of the rectangle the button lies within may be larger
  /// per [tapTargetSize].
  final MaterialStateProperty<Size> minimumSize;

  /// The color and weight of the button's outline.
  ///
  /// This value is combined with [shape] to create a shape decorated
  /// with an outline.
  final MaterialStateProperty<BorderSide> side;

  /// The shape of the button's underlying [Material].
  ///
  /// This shape is combined with [side] to create a shape decorated
  /// with an outline.
  final MaterialStateProperty<OutlinedBorder> shape;

  /// The cursor for a mouse pointer when it enters or is hovering over
  /// this button's [InkWell].
  final MaterialStateProperty<MouseCursor> mouseCursor;

  /// Defines how compact the button's layout will be.
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  ///
  /// See also:
  ///
  ///  * [ThemeData.visualDensity], which specifies the [visualDensity] for all widgets
  ///    within a [Theme].
  final VisualDensity visualDensity;

  /// Configures the minimum size of the area within which the button may be pressed.
  ///
  /// If the [tapTargetSize] is larger than [minimumSize], the button will include
  /// a transparent margin that responds to taps.
  ///
  /// Always defaults to [ThemeData.materialTapTargetSize].
  final MaterialTapTargetSize tapTargetSize;

  /// Defines the duration of animated changes for [shape] and [elevation].
  ///
  /// Typically the component default value is [kThemeChangeDuration].
  final Duration animationDuration;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// Typically the component default value is true.
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool enableFeedback;

  /// Returns a copy of this ButtonStyle with the given fields replaced with
  /// the new values.
  ButtonStyle copyWith({
    MaterialStateProperty<TextStyle> textStyle,
    MaterialStateProperty<Color> backgroundColor,
    MaterialStateProperty<Color> foregroundColor,
    MaterialStateProperty<Color> overlayColor,
    MaterialStateProperty<Color> shadowColor,
    MaterialStateProperty<double> elevation,
    MaterialStateProperty<EdgeInsetsGeometry> padding,
    MaterialStateProperty<Size> minimumSize,
    MaterialStateProperty<BorderSide> side,
    MaterialStateProperty<OutlinedBorder> shape,
    MaterialStateProperty<MouseCursor> mouseCursor,
    VisualDensity visualDensity,
    MaterialTapTargetSize tapTargetSize,
    Duration animationDuration,
    bool enableFeedback,
  }) {
    return ButtonStyle(
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      overlayColor: overlayColor ?? this.overlayColor,
      shadowColor: shadowColor ?? this.shadowColor,
      elevation: elevation ?? this.elevation,
      padding: padding ?? this.padding,
      minimumSize: minimumSize ?? this.minimumSize,
      side: side ?? this.side,
      shape: shape ?? this.shape,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      visualDensity: visualDensity ?? this.visualDensity,
      tapTargetSize: tapTargetSize ?? this.tapTargetSize,
      animationDuration: animationDuration ?? this.animationDuration,
      enableFeedback: enableFeedback ?? this.enableFeedback,
    );
  }

  /// Returns a copy of this ButtonStyle where the non-null fields in [style]
  /// have replaced the corresponding null fields in this ButtonStyle.
  ///
  /// In other words, [style] is used to fill in unspecified (null) fields
  /// this ButtonStyle.
  ButtonStyle merge(ButtonStyle style) {
    if (style == null)
      return this;
    return copyWith(
      textStyle: textStyle ?? style.textStyle,
      backgroundColor: backgroundColor ?? style.backgroundColor,
      foregroundColor: foregroundColor ?? style.foregroundColor,
      overlayColor: overlayColor ?? style.overlayColor,
      shadowColor: shadowColor ?? style.shadowColor,
      elevation: elevation ?? style.elevation,
      padding: padding ?? style.padding,
      minimumSize: minimumSize ?? style.minimumSize,
      side: side ?? style.side,
      shape: shape ?? style.shape,
      mouseCursor: mouseCursor ?? style.mouseCursor,
      visualDensity: visualDensity ?? style.visualDensity,
      tapTargetSize: tapTargetSize ?? style.tapTargetSize,
      animationDuration: animationDuration ?? style.animationDuration,
      enableFeedback: enableFeedback ?? style.enableFeedback,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      textStyle,
      backgroundColor,
      foregroundColor,
      overlayColor,
      shadowColor,
      elevation,
      padding,
      minimumSize,
      side,
      shape,
      mouseCursor,
      visualDensity,
      tapTargetSize,
      animationDuration,
      enableFeedback,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is ButtonStyle
        && other.textStyle == textStyle
        && other.backgroundColor == backgroundColor
        && other.foregroundColor == foregroundColor
        && other.overlayColor == overlayColor
        && other.shadowColor == shadowColor
        && other.elevation == elevation
        && other.padding == padding
        && other.minimumSize == minimumSize
        && other.side == side
        && other.shape == shape
        && other.mouseCursor == mouseCursor
        && other.visualDensity == visualDensity
        && other.tapTargetSize == tapTargetSize
        && other.animationDuration == animationDuration
        && other.enableFeedback == enableFeedback;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MaterialStateProperty<TextStyle>>('textStyle', textStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color>>('foregroundColor', foregroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color>>('overlayColor', overlayColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color>>('shadowColor', shadowColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<double>>('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<EdgeInsetsGeometry>>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Size>>('minimumSize', minimumSize, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<BorderSide>>('side', side, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<OutlinedBorder>>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<MouseCursor>>('mouseCursor', mouseCursor, defaultValue: null));
    properties.add(DiagnosticsProperty<VisualDensity>('visualDensity', visualDensity, defaultValue: null));
    properties.add(EnumProperty<MaterialTapTargetSize>('tapTargetSize', tapTargetSize, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('animationDuration', animationDuration, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('enableFeedback', enableFeedback, defaultValue: null));
  }

  /// Linearly interpolate between two [ButtonStyle]s.
  static ButtonStyle lerp(ButtonStyle a, ButtonStyle b, double t) {
    assert (t != null);
    if (a == null && b == null)
      return null;
    return ButtonStyle(
      textStyle: _lerpTextStyles(a?.textStyle, b?.textStyle, t),
      backgroundColor: _lerpColors(a?.backgroundColor, b?.backgroundColor, t),
      foregroundColor: _lerpColors(a?.foregroundColor, b?.foregroundColor, t),
      overlayColor: _lerpColors(a?.overlayColor, b?.overlayColor, t),
      shadowColor: _lerpColors(a?.shadowColor, b?.shadowColor, t),
      elevation: _lerpDoubles(a?.elevation, b?.elevation, t),
      padding: _lerpInsets(a?.padding, b?.padding, t),
      minimumSize: _lerpSizes(a?.minimumSize, b?.minimumSize, t),
      side: _lerpSides(a?.side, b?.side, t),
      shape: _lerpShapes(a?.shape, b?.shape, t),
      mouseCursor: t < 0.5 ? a.mouseCursor : b.mouseCursor,
      visualDensity: t < 0.5 ? a.visualDensity : b.visualDensity,
      tapTargetSize: t < 0.5 ? a.tapTargetSize : b.tapTargetSize,
      animationDuration: t < 0.5 ? a.animationDuration : b.animationDuration,
      enableFeedback: t < 0.5 ? a.enableFeedback : b.enableFeedback,
    );
  }

  static MaterialStateProperty<TextStyle> _lerpTextStyles(MaterialStateProperty<TextStyle> a, MaterialStateProperty<TextStyle> b, double t) {
    if (a == null && b == null)
      return null;
    return _LerpTextStyles(a, b, t);
  }

  static MaterialStateProperty<Color> _lerpColors(MaterialStateProperty<Color> a, MaterialStateProperty<Color> b, double t) {
    if (a == null && b == null)
      return null;
    return _LerpColors(a, b, t);
  }

  static MaterialStateProperty<double> _lerpDoubles(MaterialStateProperty<double> a, MaterialStateProperty<double> b, double t) {
    if (a == null && b == null)
      return null;
    return _LerpDoubles(a, b, t);
  }

  static MaterialStateProperty<EdgeInsetsGeometry> _lerpInsets(MaterialStateProperty<EdgeInsetsGeometry> a, MaterialStateProperty<EdgeInsetsGeometry> b, double t) {
    if (a == null && b == null)
      return null;
    return _LerpInsets(a, b, t);
  }

  static MaterialStateProperty<Size> _lerpSizes(MaterialStateProperty<Size> a, MaterialStateProperty<Size> b, double t) {
    if (a == null && b == null)
      return null;
    return _LerpSizes(a, b, t);
  }

  static MaterialStateProperty<BorderSide> _lerpSides(MaterialStateProperty<BorderSide> a, MaterialStateProperty<BorderSide> b, double t) {
    if (a == null && b == null)
      return null;
    return _LerpSides(a, b, t);
  }

  static MaterialStateProperty<OutlinedBorder> _lerpShapes(MaterialStateProperty<OutlinedBorder> a, MaterialStateProperty<OutlinedBorder> b, double t) {
    if (a == null && b == null)
      return null;
    return _LerpShapes(a, b, t);
  }
}

class _LerpTextStyles implements MaterialStateProperty<TextStyle> {
  const _LerpTextStyles(this.a, this.b, this.t);

  final MaterialStateProperty<TextStyle> a;
  final MaterialStateProperty<TextStyle> b;
  final double t;

  @override
  TextStyle resolve(Set<MaterialState> states) {
    final TextStyle resolvedA = a?.resolve(states);
    final TextStyle resolvedB = b?.resolve(states);
    return TextStyle.lerp(resolvedA, resolvedB, t);
  }
}

class _LerpColors implements MaterialStateProperty<Color> {
  const _LerpColors(this.a, this.b, this.t);

  final MaterialStateProperty<Color> a;
  final MaterialStateProperty<Color> b;
  final double t;

  @override
  Color resolve(Set<MaterialState> states) {
    final Color resolvedA = a?.resolve(states);
    final Color resolvedB = b?.resolve(states);
    return Color.lerp(resolvedA, resolvedB, t);
  }
}

class _LerpDoubles implements MaterialStateProperty<double> {
  const _LerpDoubles(this.a, this.b, this.t);

  final MaterialStateProperty<double> a;
  final MaterialStateProperty<double> b;
  final double t;

  @override
  double resolve(Set<MaterialState> states) {
    final double resolvedA = a?.resolve(states);
    final double resolvedB = b?.resolve(states);
    return lerpDouble(resolvedA, resolvedB, t);
  }
}

class _LerpInsets implements MaterialStateProperty<EdgeInsetsGeometry> {
  const _LerpInsets(this.a, this.b, this.t);

  final MaterialStateProperty<EdgeInsetsGeometry> a;
  final MaterialStateProperty<EdgeInsetsGeometry> b;
  final double t;

  @override
  EdgeInsetsGeometry resolve(Set<MaterialState> states) {
    final EdgeInsetsGeometry resolvedA = a?.resolve(states);
    final EdgeInsetsGeometry resolvedB = b?.resolve(states);
    return EdgeInsetsGeometry.lerp(resolvedA, resolvedB, t);
  }
}

class _LerpSizes implements MaterialStateProperty<Size> {
  const _LerpSizes(this.a, this.b, this.t);

  final MaterialStateProperty<Size> a;
  final MaterialStateProperty<Size> b;
  final double t;

  @override
  Size resolve(Set<MaterialState> states) {
    final Size resolvedA = a?.resolve(states);
    final Size resolvedB = b?.resolve(states);
    return Size.lerp(resolvedA, resolvedB, t);
  }
}

class _LerpSides implements MaterialStateProperty<BorderSide> {
  const _LerpSides(this.a, this.b, this.t);

  final MaterialStateProperty<BorderSide> a;
  final MaterialStateProperty<BorderSide> b;
  final double t;

  @override
  BorderSide resolve(Set<MaterialState> states) {
    final BorderSide resolvedA = a?.resolve(states);
    final BorderSide resolvedB = b?.resolve(states);
    return BorderSide.lerp(resolvedA, resolvedB, t);
  }
}

class _LerpShapes implements MaterialStateProperty<OutlinedBorder> {
  const _LerpShapes(this.a, this.b, this.t);

  final MaterialStateProperty<OutlinedBorder> a;
  final MaterialStateProperty<OutlinedBorder> b;
  final double t;

  @override
  OutlinedBorder resolve(Set<MaterialState> states) {
    final OutlinedBorder resolvedA = a?.resolve(states);
    final OutlinedBorder resolvedB = b?.resolve(states);
    return ShapeBorder.lerp(resolvedA, resolvedB, t) as OutlinedBorder;
  }
}
