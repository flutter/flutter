// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


/// Overrides the default properties values for descendant [Badge] widgets.
///
/// Widgets obtain the current [AnimationThemeData] object
/// using `AnimationTheme.of(context)`. Instances of [AnimationThemeData] can
/// be customized with [AnimationThemeData.copyWith].
///
/// Typically a [AnimationThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.animationTheme].
///
/// All [AnimationThemeData] properties have values by default,
/// and can be changed by using [ThemeData.animationTheme].
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.

@immutable
class AnimationThemeData with Diagnosticable {
  /// Creates the set of color, style, and size properties used to configure [Badge].
  const AnimationThemeData({
    this.animationCurve = Curves.easeInOut,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  /// Set value for [animationCurve],
  /// defaults to [Curves.easeInOut].
  final Curve animationCurve;

  /// Set value for [animationDuration],
  /// defaults to 250 milliseconds.
  final Duration animationDuration;


  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  AnimationThemeData copyWith({
    Curve? animationCurve,
    Duration? animationDuration
  }) {
    return AnimationThemeData(
      animationCurve: animationCurve ?? this.animationCurve,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }
//
  /// Linearly interpolate between two [Badge] themes.
  /// TODO: work on lerp
  static AnimationThemeData lerp(AnimationThemeData? a, AnimationThemeData? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return AnimationThemeData(
      animationCurve: a!.animationCurve,
      animationDuration: a.animationDuration,
    );
  }

  @override
  int get hashCode => Object.hash(
      animationCurve,
      animationDuration
  );
//
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AnimationThemeData
        && other.animationCurve == animationCurve
        && other.animationDuration == animationDuration;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Curve>('animationCurve', animationCurve, defaultValue: Curves.easeInOut));
    properties.add(DiagnosticsProperty<Duration>('animationDuration', animationDuration, defaultValue: const Duration(milliseconds: 250)));
  }
}
//
/// An inherited widget that overrides the default animation
/// parameters for [Animation]s in this widget's subtree.
///
class AnimationTheme extends InheritedTheme {
  /// Creates a theme that overrides the default color parameters for [Badge]s
  /// in this widget's subtree.
  const AnimationTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// Specifies the default animationDuration and animationCurve
  /// overrides for descendant [Animation] widgets.
  final AnimationThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [AnimationThemeData] widget, then
  /// [ThemeData.animationTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// AnimationThemeData theme = AnimationTheme.of(context);
  /// ```
  static AnimationThemeData of(BuildContext context) {
    final AnimationTheme? animationTheme = context.dependOnInheritedWidgetOfExactType<AnimationTheme>();
    return animationTheme?.data ?? Theme.of(context).animationTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return AnimationTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(AnimationTheme oldWidget) => data != oldWidget.data;
}
