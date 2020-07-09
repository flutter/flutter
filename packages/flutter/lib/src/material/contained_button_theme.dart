// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'theme.dart';

/// A [ButtonStyle] that overrides the default appearance of
/// [ContainedButton]s when it's used with [ContainedButtonTheme] or with the
/// overall [Theme]'s [ThemeData.containedButtonTheme].
///
/// The [style]'s properties override [ContainedButton]'s default style,
/// i.e.  the [ButtonStyle] returned by [ContainedButton.defaultStyleOf]. Only
/// the style's non-null property values or resolved non-null
/// [MaterialStateProperty] values are used.
///
/// See also:
///
///  * [ContainedButtonTheme], the theme which is configured with this class.
///  * [ContainedButton.defaultStyleOf], which returns the default [ButtonStyle]
///    for text buttons.
///  * [ContainedButton.styleOf], which converts simple values into a
///    [ButtonStyle] that's consistent with [ContainedButton]'s defaults.
///  * [MaterialStateProperty.resolve], "resolve" a material state property
///    to a simple value based on a set of [MaterialState]s.
///  * [ThemeData.containedButtonTheme], which can be used to override the default
///    [ButtonStyle] for [ContainedButton]s below the overall [Theme].
@immutable
class ContainedButtonThemeData with Diagnosticable {
  /// Creates a [ContainedButtonThemeData].
  ///
  /// The [style] may be null.
  const ContainedButtonThemeData({ this.style });

  /// Overrides for [ContainedButton]'s default style.
  ///
  /// Non-null properties or non-null resolved [MaterialStateProperty]
  /// values override the [ButtonStyle] returned by
  /// [ContainedButton.defaultStyleOf].
  ///
  /// If [style] is null, then this theme doesn't override anything.
  final ButtonStyle style;

  /// Linearly interpolate between two contained button themes.
  static ContainedButtonThemeData lerp(ContainedButtonThemeData a, ContainedButtonThemeData b, double t) {
    assert (t != null);
    if (a == null && b == null)
      return null;
    return ContainedButtonThemeData(
      style: ButtonStyle.lerp(a?.style, b?.style, t),
    );
  }

  @override
  int get hashCode {
    return style.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is ContainedButtonThemeData && other.style == style;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ButtonStyle>('style', style, defaultValue: null));
  }
}

/// Overrides the default [ButtonStyle] of its [ContainedButton] descendants.
///
/// See also:
///
///  * [ContainedButtonThemeData], which is used to configure this theme.
///  * [ContainedButton.defaultStyleOf], which returns the default [ButtonStyle]
///    for text buttons.
///  * [ContainedButton.styleOf], which converts simple values into a
///    [ButtonStyle] that's consistent with [ContainedButton]'s defaults.
///  * [ThemeData.containedButtonTheme], which can be used to override the default
///    [ButtonStyle] for [ContainedButton]s below the overall [Theme].
class ContainedButtonTheme extends InheritedTheme {
  /// Create a [ContainedButtonTheme].
  ///
  /// The [data] parameter must not be null.
  const ContainedButtonTheme({
    Key key,
    @required this.data,
    Widget child,
  }) : assert(data != null), super(key: key, child: child);

  /// The configuration of this theme.
  final ContainedButtonThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [ContainedButtonsTheme] widget, then
  /// [ThemeData.containedButtonTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ContainedButtonTheme theme = ContainedButtonTheme.of(context);
  /// ```
  static ContainedButtonThemeData of(BuildContext context) {
    final ContainedButtonTheme buttonTheme = context.dependOnInheritedWidgetOfExactType<ContainedButtonTheme>();
    return buttonTheme?.data ?? Theme.of(context).containedButtonTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final ContainedButtonTheme ancestorTheme = context.findAncestorWidgetOfExactType<ContainedButtonTheme>();
    return identical(this, ancestorTheme) ? child : ContainedButtonTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(ContainedButtonTheme oldWidget) => data != oldWidget.data;
}
