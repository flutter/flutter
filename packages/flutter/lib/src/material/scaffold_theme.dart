// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';


// Examples can assume:
// late BuildContext context;

/// Overrides the default properties values for descendant [Scaffold] widgets.
///
/// Descendant widgets obtain the current [ScaffoldThemeData] object
/// using `ScaffoldTheme.of(context)`. Instances of [ScaffoldThemeData] can
/// be customized with [ScaffoldThemeData.copyWith].
///
/// Typically a [ScaffoldThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.scaffoldTheme].
///
/// All [ScaffoldThemeData] properties are `null` by default.
/// When null, the [Scaffold] will use the values from [ThemeData]
/// if they exist, otherwise it will provide its own defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class ScaffoldThemeData with Diagnosticable {
  /// Creates the set of properties used to configure [Scaffold].
  const ScaffoldThemeData({
    this.backgroundColor,
    this.drawerScrimColor,
  });

  /// Overrides the default value for [Scaffold.backgroundColor].
  final Color? backgroundColor;

  /// Overrides the default value for [Scaffold.drawerScrimColor].
  final Color? drawerScrimColor;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  ScaffoldThemeData copyWith({
    Color? backgroundColor,
    Color? drawerScrimColor,
  }) {
    return ScaffoldThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      drawerScrimColor: drawerScrimColor ?? this.drawerScrimColor,
    );
  }

  /// Linearly interpolate between two [Scaffold] themes.
  static ScaffoldThemeData lerp(ScaffoldThemeData? a, ScaffoldThemeData? b, double t) {
    return ScaffoldThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      drawerScrimColor: Color.lerp(a?.drawerScrimColor, b?.drawerScrimColor, t),
    );
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    drawerScrimColor,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ScaffoldThemeData
      && other.backgroundColor == backgroundColor
      && other.drawerScrimColor == drawerScrimColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(ColorProperty('drawerScrimColor', drawerScrimColor, defaultValue: null));
  }
}

/// An inherited widget that overrides the default parameters for [Scaffold]s
/// in this widget's subtree.
///
/// Values specified here override the defaults for [Scaffold] properties which
/// are not given an explicit non-null value.
class ScaffoldTheme extends InheritedTheme {
  /// Creates a theme that overrides the default parameters for [Scaffold]s
  /// in this widget's subtree.
  const ScaffoldTheme({
    super.key,
    required this.data,
    required super.child,
  }) : assert(data != null);

  /// Specifies the default color and size overrides for descendant [Scaffold] widgets.
  final ScaffoldThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [ScaffoldTheme] widget, then
  /// [ThemeData.scaffoldTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ScaffoldThemeData theme = ScaffoldTheme.of(context);
  /// ```
  static ScaffoldThemeData of(BuildContext context) {
    final ScaffoldTheme? scaffoldTheme = context.dependOnInheritedWidgetOfExactType<ScaffoldTheme>();
    return scaffoldTheme?.data ?? Theme.of(context).scaffoldTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return ScaffoldTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(ScaffoldTheme oldWidget) => data != oldWidget.data;
}
