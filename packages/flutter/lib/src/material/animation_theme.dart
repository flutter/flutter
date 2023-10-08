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
/// All [AnimationThemeData] properties are null by default,
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
    this.animationCurve,
    this.animationDuration,
    this.reverseAnimationDuration,
    this.sizeCurve,
    this.crossFadeFirstCurve,
    this.crossFadeSecondCurve,
    this.switchInCurve,
    this.switchOutCurve,
  });

  /// Set curve for widgets such as [AnimatedContainer], [AnimatedPadding], and
  /// other [ImplicitlyAnimatedWidget]s.
  final Curve? animationCurve;

  /// Set value for forward animation [Duration].
  /// This parameter is used by [AnimatedContainer], [AnimatedPadding],
  /// [AnimatedOpacity] and other [ImplicitlyAnimatedWidget]s as their duration.
  ///
  /// Widgets such as [AnimatedCrossFade] and [AnimatedSwitcher] use this
  /// parameter as forward animation duration.
  final Duration? animationDuration;

  /// Set value for reverse animation [Duration].
  /// Used by [AnimatedCrossFade] to switch between it's children.
  final Duration? reverseAnimationDuration;

  /// Set curve for size transition used by [AnimatedCrossFade].
  final Curve? sizeCurve;

  /// Set fade curve to be used by [AnimatedCrossFade]'s first child.
  final Curve? crossFadeFirstCurve;

  /// Set fade curve to be used by [AnimatedCrossFade]'s second child.
  final Curve? crossFadeSecondCurve;

  /// Set in curve to be used by [AnimatedSwitcher].
  final Curve? switchInCurve;

  /// Set out curve to be used by [AnimatedSwitcher].
  final Curve? switchOutCurve;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  AnimationThemeData copyWith({
    Curve? animationCurve,
    Duration? animationDuration,
    Duration? reverseAnimationDuration,
    Curve? sizeCurve,
    Curve? crossFadeFirstCurve,
    Curve? crossFadeSecondCurve,
    Curve? switchInCurve,
    Curve? switchOutCurve,
  }) {
    return AnimationThemeData(
      animationCurve: animationCurve ?? this.animationCurve,
      animationDuration: animationDuration ?? this.animationDuration,
      reverseAnimationDuration: reverseAnimationDuration ?? this.reverseAnimationDuration,
      sizeCurve: sizeCurve ?? this.sizeCurve,
      crossFadeFirstCurve: crossFadeFirstCurve ?? this.crossFadeFirstCurve,
      crossFadeSecondCurve: crossFadeSecondCurve ?? this.crossFadeSecondCurve,
      switchInCurve: switchInCurve ?? this.switchInCurve,
      switchOutCurve: switchOutCurve ?? this.switchOutCurve
    );
  }

  /// Linearly interpolate between two [AnimationTheme].
  static AnimationThemeData lerp(
    AnimationThemeData? a,
    AnimationThemeData? b,
    double t,
  ) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return AnimationThemeData(
      animationCurve: t < 0.5 ? a?.animationCurve : b?.animationCurve,
      animationDuration: t < 0.5 ? a?.animationDuration : b?.animationDuration,
      reverseAnimationDuration: t < 0.5 ? a?.reverseAnimationDuration : b?.reverseAnimationDuration,
      sizeCurve: t < 0.5 ? a?.sizeCurve : b?.sizeCurve,
      crossFadeFirstCurve: t < 0.5 ? a?.crossFadeFirstCurve : b?.crossFadeFirstCurve,
      crossFadeSecondCurve: t < 0.5 ? a?.crossFadeSecondCurve : b?.crossFadeSecondCurve,
      switchInCurve: t < 0.5 ? a?.switchInCurve : b?.switchInCurve,
      switchOutCurve: t < 0.5 ? a?.switchOutCurve : b?.switchOutCurve,
    );
  }

  @override
  int get hashCode => Object.hash(
    animationCurve,
    animationDuration,
    reverseAnimationDuration,
    sizeCurve,
    crossFadeFirstCurve,
    crossFadeSecondCurve,
    switchInCurve,
    switchOutCurve,
  );

  @override
  bool operator == (Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AnimationThemeData &&
        other.animationCurve == animationCurve &&
        other.animationDuration == animationDuration &&
        other.reverseAnimationDuration == reverseAnimationDuration &&
        other.sizeCurve == sizeCurve &&
        other.crossFadeFirstCurve == crossFadeFirstCurve &&
        other.crossFadeSecondCurve == crossFadeSecondCurve &&
        other.switchInCurve == switchInCurve &&
        other.switchOutCurve == switchOutCurve;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Curve>(
      'animationCurve',
      animationCurve,
    ));
    properties.add(DiagnosticsProperty<Duration>(
      'animationDuration',
      animationDuration,
    ));
    properties.add(DiagnosticsProperty<Duration>(
      'reverseAnimationDuration',
      reverseAnimationDuration,
    ));
    properties.add(DiagnosticsProperty<Curve>(
      'sizeCurve',
      sizeCurve,
    ));
    properties.add(DiagnosticsProperty<Curve>(
      'crossFadeFirstCurve',
      crossFadeFirstCurve,
    ));
    properties.add(DiagnosticsProperty<Curve>(
      'crossFadeSecondCurve',
      crossFadeSecondCurve,
    ));
    properties.add(DiagnosticsProperty<Curve>(
      'switchInCurve',
      switchInCurve,
    ));
    properties.add(DiagnosticsProperty<Curve>(
      'switchOutCurve',
      switchOutCurve,
    ));
  }
}

//
/// An inherited widget that overrides the default animation
/// parameters for [Animation]s in this widget's subtree.
///
class AnimationTheme extends InheritedTheme {
  /// Creates a theme that overrides the default parameters
  /// in this widget's subtree.
  const AnimationTheme({
    super.key,
    required this.data,
    required super.child,
  });


  /// The properties used for all descendant [AnimationTheme] widgets.
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
    final AnimationTheme? animationTheme =
        context.dependOnInheritedWidgetOfExactType<AnimationTheme>();
    return animationTheme?.data ?? Theme.of(context).animationTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return AnimationTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(AnimationTheme oldWidget) => data != oldWidget.data;
}
