// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

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
    this.backgroundColor,
    this.color,
  });

  /// The color of the [ProgressIndicator]'s track.
  ///
  /// This color is interpreted differently depending on the type of
  /// indicator:
  ///
  /// For a [LinearProgressIndicator] it is the background color of the
  /// track that the indicator is filling up. If this is null, then it
  /// will use [ColorScheme.background] of the ambient [ThemeData.colorScheme].
  ///
  /// For a [CircularProgressIndicator] it is the color of the circular
  /// track that the indicator is filling up. If this is null, then no
  /// track will be painted by default.
  ///
  /// For a [RefreshIndicator] it is the color of the background circle
  /// behind the indicator. If this is null, then the ambient
  /// [ThemeData.canvasColor] will be used.
  final Color? backgroundColor;

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

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  ProgressIndicatorThemeData copyWith({
    Color? backgroundColor,
    Color? color,
  }) {
    return ProgressIndicatorThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      color: color ?? this.color,
    );
  }

  /// Linearly interpolate between two progress indicator themes.
  ///
  /// If both arguments are null, then null is returned.
  static ProgressIndicatorThemeData? lerp(ProgressIndicatorThemeData? a, ProgressIndicatorThemeData? b, double t) {
    if (a == null && b == null)
      return null;
    assert(t != null);
    return ProgressIndicatorThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      color: Color.lerp(a?.color, b?.color, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      color,
    );
  }

  @override
  bool operator==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is ProgressIndicatorThemeData
        && other.backgroundColor == backgroundColor
        && other.color == color;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(ColorProperty('color', color, defaultValue: null));
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
/// color with a slightly transparent red for the background track color.
///
/// ```dart
/// ProgressIndicatorTheme(
///   data: ProgressIndicatorThemeData(
///     color: Colors.red,
///     backgroundColor: Colors.red.withOpacity(0.25),
///   ),
///   child: LinearProgressIndicator()
/// ),
/// ```
/// {@end-tool}
class ProgressIndicatorTheme extends InheritedTheme {
  /// Creates a theme that controls the configurations for [ProgressIndicator]
  /// widgets.
  const ProgressIndicatorTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : assert(data != null), super(key: key, child: child);

  /// The properties for descendant [ProgressIndicator] widgets.
  final ProgressIndicatorThemeData data;

  /// Returns the [data] from the closest [ProgressIndicatorTheme] ancestor. If
  /// there is no ancestor, it returns [ThemeData.progressIndicatorTheme].
  /// Applications can assume that the returned value will not be null.
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
    final ProgressIndicatorTheme? ancestorTheme = context.findAncestorWidgetOfExactType<ProgressIndicatorTheme>();
    return identical(this, ancestorTheme) ? child : ProgressIndicatorTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(ProgressIndicatorTheme oldWidget) => data != oldWidget.data;
}
