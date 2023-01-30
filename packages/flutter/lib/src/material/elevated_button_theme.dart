// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'theme.dart';

// Examples can assume:
// late BuildContext context;

/// A [ButtonStyle] that overrides the default appearance of
/// [ElevatedButton]s when it's used with [ElevatedButtonTheme] or with the
/// overall [Theme]'s [ThemeData.elevatedButtonTheme].
///
/// The [style]'s properties override [ElevatedButton]'s default style,
/// i.e. the [ButtonStyle] returned by [ElevatedButton.defaultStyleOf]. Only
/// the style's non-null property values or resolved non-null
/// [MaterialStateProperty] values are used.
///
/// See also:
///
///  * [ElevatedButtonTheme], the theme which is configured with this class.
///  * [ElevatedButton.defaultStyleOf], which returns the default [ButtonStyle]
///    for text buttons.
///  * [ElevatedButton.styleFrom], which converts simple values into a
///    [ButtonStyle] that's consistent with [ElevatedButton]'s defaults.
///  * [MaterialStateProperty.resolve], "resolve" a material state property
///    to a simple value based on a set of [MaterialState]s.
///  * [ThemeData.elevatedButtonTheme], which can be used to override the default
///    [ButtonStyle] for [ElevatedButton]s below the overall [Theme].
@immutable
class ElevatedButtonThemeData with Diagnosticable {
  /// Creates an [ElevatedButtonThemeData].
  ///
  /// The [style] may be null.
  const ElevatedButtonThemeData({ this.style });

  /// Overrides for [ElevatedButton]'s default style.
  ///
  /// Non-null properties or non-null resolved [MaterialStateProperty]
  /// values override the [ButtonStyle] returned by
  /// [ElevatedButton.defaultStyleOf].
  ///
  /// If [style] is null, then this theme doesn't override anything.
  final ButtonStyle? style;

  /// Linearly interpolate between two elevated button themes.
  static ElevatedButtonThemeData? lerp(ElevatedButtonThemeData? a, ElevatedButtonThemeData? b, double t) {
    assert (t != null);
    if (a == null && b == null) {
      return null;
    }
    return ElevatedButtonThemeData(
      style: ButtonStyle.lerp(a?.style, b?.style, t),
    );
  }

  @override
  int get hashCode => style.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ElevatedButtonThemeData && other.style == style;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ButtonStyle>('style', style, defaultValue: null));
  }
}

/// Overrides the default [ButtonStyle] of its [ElevatedButton] descendants.
///
/// See also:
///
///  * [ElevatedButtonThemeData], which is used to configure this theme.
///  * [ElevatedButton.defaultStyleOf], which returns the default [ButtonStyle]
///    for elevated buttons.
///  * [ElevatedButton.styleFrom], which converts simple values into a
///    [ButtonStyle] that's consistent with [ElevatedButton]'s defaults.
///  * [ThemeData.elevatedButtonTheme], which can be used to override the default
///    [ButtonStyle] for [ElevatedButton]s below the overall [Theme].
class ElevatedButtonTheme extends InheritedTheme {
  /// Create a [ElevatedButtonTheme].
  ///
  /// The [data] parameter must not be null.
  const ElevatedButtonTheme({
    super.key,
    required this.data,
    required super.child,
  }) : assert(data != null);

  /// The configuration of this theme.
  final ElevatedButtonThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [ElevatedButtonTheme] widget, then
  /// [ThemeData.elevatedButtonTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ElevatedButtonThemeData theme = ElevatedButtonTheme.of(context);
  /// ```
  static ElevatedButtonThemeData of(BuildContext context) {
    final ElevatedButtonTheme? buttonTheme = context.dependOnInheritedWidgetOfExactType<ElevatedButtonTheme>();
    return buttonTheme?.data ?? Theme.of(context).elevatedButtonTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return ElevatedButtonTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(ElevatedButtonTheme oldWidget) => data != oldWidget.data;
}
