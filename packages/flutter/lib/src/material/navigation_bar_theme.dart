// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';
import 'navigation_bar.dart';
import 'theme.dart';

/// Defines default property values for descendant [NavigationBar]
/// widgets.
///
/// Descendant widgets obtain the current [NavigationBarThemeData] object
/// using `NavigationBarTheme.of(context)`. Instances of
/// [NavigationBarThemeData] can be customized with
/// [NavigationBarThemeData.copyWith].
///
/// Typically a [NavigationBarThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.navigationBarTheme]. Alternatively, a
/// [NavigationBarTheme] inherited widget can be used to theme [NavigationBar]s
/// in a subtree of widgets.
///
/// All [NavigationBarThemeData] properties are `null` by default.
/// When null, the [NavigationBar] will provide its own defaults based on the
/// overall [Theme]'s textTheme and colorScheme. See the individual
/// [NavigationBar] properties for details.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class NavigationBarThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.navigationBarTheme] and
  /// [NavigationBarTheme].
  const NavigationBarThemeData({
    this.height,
    this.backgroundColor,
    this.indicatorColor,
    this.labelTextStyle,
    this.iconTheme,
    this.labelBehavior,
  });

  /// Overrides the default value of [NavigationBar.height].
  final double? height;

  /// Overrides the default value of [NavigationBar.backgroundColor].
  final Color? backgroundColor;

  /// Overrides the default value of [NavigationBar]'s selection indicator.
  final Color? indicatorColor;

  /// The style to merge with the default text style for
  /// [NavigationDestination] labels.
  ///
  /// You can use this to specify a different style when the label is selected.
  final MaterialStateProperty<TextStyle?>? labelTextStyle;

  /// The theme to merge with the default icon theme for
  /// [NavigationDestination] icons.
  ///
  /// You can use this to specify a different icon theme when the icon is
  /// selected.
  final MaterialStateProperty<IconThemeData?>? iconTheme;

  /// Overrides the default value of [NavigationBar.labelBehavior].
  final NavigationDestinationLabelBehavior? labelBehavior;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  NavigationBarThemeData copyWith({
    double? height,
    Color? backgroundColor,
    Color? indicatorColor,
    MaterialStateProperty<TextStyle?>? labelTextStyle,
    MaterialStateProperty<IconThemeData?>? iconTheme,
    NavigationDestinationLabelBehavior? labelBehavior,
  }) {
    return NavigationBarThemeData(
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      iconTheme: iconTheme ?? this.iconTheme,
      labelBehavior: labelBehavior ?? this.labelBehavior,
    );
  }

  /// Linearly interpolate between two navigation rail themes.
  ///
  /// If both arguments are null then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static NavigationBarThemeData? lerp(NavigationBarThemeData? a, NavigationBarThemeData? b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    return NavigationBarThemeData(
      height: lerpDouble(a?.height, b?.height, t),
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      indicatorColor: Color.lerp(a?.indicatorColor, b?.indicatorColor, t),
      labelTextStyle: _lerpProperties<TextStyle?>(a?.labelTextStyle, b?.labelTextStyle, t, TextStyle.lerp),
      iconTheme: _lerpProperties<IconThemeData?>(a?.iconTheme, b?.iconTheme, t, IconThemeData.lerp),
      labelBehavior: t < 0.5 ? a?.labelBehavior : b?.labelBehavior,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      height,
      backgroundColor,
      indicatorColor,
      labelTextStyle,
      iconTheme,
      labelBehavior,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is NavigationBarThemeData
        && other.height == height
        && other.backgroundColor == backgroundColor
        && other.indicatorColor == indicatorColor
        && other.labelTextStyle == labelTextStyle
        && other.iconTheme == iconTheme
        && other.labelBehavior == labelBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(ColorProperty('indicatorColor', indicatorColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<TextStyle?>>('labelTextStyle', labelTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<IconThemeData?>>('iconTheme', iconTheme, defaultValue: null));
    properties.add(DiagnosticsProperty<NavigationDestinationLabelBehavior>('labelBehavior', labelBehavior, defaultValue: null));
  }

  static MaterialStateProperty<T>? _lerpProperties<T>(
    MaterialStateProperty<T>? a,
    MaterialStateProperty<T>? b,
    double t,
    T Function(T?, T?, double) lerpFunction,
  ) {
    // Avoid creating a _LerpProperties object for a common case.
    if (a == null && b == null)
      return null;
    return _LerpProperties<T>(a, b, t, lerpFunction);
  }
}

class _LerpProperties<T> implements MaterialStateProperty<T> {
  const _LerpProperties(this.a, this.b, this.t, this.lerpFunction);

  final MaterialStateProperty<T>? a;
  final MaterialStateProperty<T>? b;
  final double t;
  final T Function(T?, T?, double) lerpFunction;

  @override
  T resolve(Set<MaterialState> states) {
    final T? resolvedA = a?.resolve(states);
    final T? resolvedB = b?.resolve(states);
    return lerpFunction(resolvedA, resolvedB, t);
  }
}

/// An inherited widget that defines visual properties for [NavigationBar]s and
/// [NavigationDestination]s in this widget's subtree.
///
/// Values specified here are used for [NavigationBar] properties that are not
/// given an explicit non-null value.
///
/// See also:
///
///  * [ThemeData.navigationBarTheme], which describes the
///    [NavigationBarThemeData] in the overall theme for the application.
class NavigationBarTheme extends InheritedTheme {
  /// Creates a navigation rail theme that controls the
  /// [NavigationBarThemeData] properties for a [NavigationBar].
  ///
  /// The data argument must not be null.
  const NavigationBarTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : assert(data != null), super(key: key, child: child);

  /// Specifies the background color, label text style, icon theme, and label
  /// type values for descendant [NavigationBar] widgets.
  final NavigationBarThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [NavigationBarTheme] widget, then
  /// [ThemeData.navigationBarTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// NavigationBarTheme theme = NavigationBarTheme.of(context);
  /// ```
  static NavigationBarThemeData of(BuildContext context) {
    final NavigationBarTheme? navigationBarTheme = context.dependOnInheritedWidgetOfExactType<NavigationBarTheme>();
    return navigationBarTheme?.data ?? Theme.of(context).navigationBarTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return NavigationBarTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(NavigationBarTheme oldWidget) => data != oldWidget.data;
}
