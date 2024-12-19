// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show TickerProvider;

import 'curves.dart';
import 'tween.dart';

/// Used to override the default parameters of an animation.
///
/// Currently, this class is used by the following widgets:
/// - [ExpansionTile]
/// - [MaterialApp]
/// - [PopupMenuButton]
/// - [ScaffoldMessengerState.showSnackBar]
/// - [showBottomSheet]
/// - [showModalBottomSheet]
///
/// If [duration] and [reverseDuration] are set to [Duration.zero], the
/// corresponding animation will be disabled.
///
/// All of the parameters are optional. If no parameters are specified,
/// the default animation will be used.
@immutable
class AnimationStyle with Diagnosticable {
  /// Creates an instance of Animation Style class.
  const AnimationStyle({
    this.curve,
    this.duration,
    this.reverseCurve,
    this.reverseDuration,
  });

  /// Creates an instance of Animation Style class with no animation.
  static const AnimationStyle noAnimation = AnimationStyle(
    duration: Duration.zero,
    reverseDuration: Duration.zero,
  );

  /// When specified, the animation will use this curve.
  final Curve? curve;

  /// When specified, the animation will use this duration.
  final Duration? duration;

  /// When specified, the reverse animation will use this curve.
  final Curve? reverseCurve;

  /// When specified, the reverse animation will use this duration.
  final Duration? reverseDuration;

  /// Widgets that interface with [DefaultAnimationStyle] can
  /// use this value if a [Duration] is not present in the current scope.
  static const Duration fallbackDuration = Duration(milliseconds: 300);

  /// Widgets that interface with [DefaultAnimationStyle] can
  /// use this value if a [Curve] is not present in the current scope.
  static const Curve fallbackCurve = Curves.linear;

  /// Creates a new [AnimationStyle] based on the current selection, with the
  /// provided parameters overridden.
  AnimationStyle copyWith({
    final Curve? curve,
    final Duration? duration,
    final Curve? reverseCurve,
    final Duration? reverseDuration,
  }) {
    return AnimationStyle(
      curve: curve ?? this.curve,
      duration: duration ?? this.duration,
      reverseCurve: reverseCurve ?? this.reverseCurve,
      reverseDuration: reverseDuration ?? this.reverseDuration,
    );
  }

  /// Returns a modified version of the [other] style, where its `null` properties
  /// are filled in with the non-null properties of this style, where applicable.
  ///
  /// If a `null` argument is passed, returns this text style.
  AnimationStyle merge(AnimationStyle? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      curve: other.curve,
      duration: other.duration,
      reverseCurve: other.reverseCurve,
      reverseDuration: other.reverseDuration,
    );
  }

  /// Linearly interpolate between two animation styles.
  static AnimationStyle? lerp(AnimationStyle? a, AnimationStyle? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    return t < 0.5 ? a : b;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AnimationStyle
      && other.curve == curve
      && other.duration == duration
      && other.reverseCurve == reverseCurve
      && other.reverseDuration == reverseDuration;
  }

  @override
  int get hashCode => Object.hash(
    curve,
    duration,
    reverseCurve,
    reverseDuration,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Curve>('curve', curve, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('duration', duration, defaultValue: null));
    properties.add(DiagnosticsProperty<Curve>('reverseCurve', reverseCurve, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('reverseDuration', reverseDuration, defaultValue: null));
  }
}

/// An animation that can delegate its configuration to an [AnimationStyle].
///
/// Typically, this class interfaces with an [AnimationProvider],
/// allowing animations to inherit fallback [Duration] and [Curve] values
/// from the ambient [DefaultAnimationStyle].
abstract interface class StyledAnimation<T> implements Animation<T> {
  /// Called when the associated [AnimationProvider] is updated
  /// with a new [AnimationStyle].
  void updateStyle(AnimationStyle newStyle);
}

/// A [TickerProvider] that can also provide a relevant [AnimationStyle].
///
/// Any [StyledAnimation]s registered via [registerAnimation] will be given
/// fallback [Duration] and [Curve] values, typically from the ambient
/// [DefaultAnimationStyle].
abstract interface class AnimationProvider implements TickerProvider {
  /// Registers the [StyledAnimation] object with this provider.
  ///
  /// [StyledAnimation.updateStyle] is called immediately, and then called again
  /// each time there's a relevant change.
  void registerAnimation(StyledAnimation<Object?> animation);
}
