// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'curves.dart';

/// Used to override the default parameters of an animation.
///
/// Currently, this class is used by the following widgets:
/// - [ExpansionTile]
/// - [MaterialApp]
/// - [PopupMenuButton]
///
/// If [duration] and [reverseDuration] are set to [Duration.zero], the
/// corresponding animation will be disabled.
///
/// All of the parameters are optional. If no parameters are specified,
/// the default animation will be used.
class AnimationStyle {
  /// Creates an instance of Animation Style class.
  AnimationStyle({
    this.curve,
    this.duration,
    this.reverseCurve,
    this.reverseDuration,
  });

  /// Creates an instance of Animation Style class with no animation.
  static AnimationStyle noAnimation = AnimationStyle(
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
}
