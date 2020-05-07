// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'scaffold.dart';

// TODO(hmuller): should be device dependent.
/// The margin that a [FloatingActionButton] should leave between it and the
/// edge of the screen.
///
/// [FloatingActionButtonLocation.endFloat] uses this to set the appropriate margin
/// between the [FloatingActionButton] and the end of the screen.
const double kFloatingActionButtonMargin = 16.0;

/// The amount of time the [FloatingActionButton] takes to transition in or out.
///
/// The [Scaffold] uses this to set the duration of [FloatingActionButton]
/// motion, entrance, and exit animations.
const Duration kFloatingActionButtonSegue = Duration(milliseconds: 200);

/// The fraction of a circle the [FloatingActionButton] should turn when it enters.
///
/// Its value corresponds to 0.125 of a full circle, equivalent to 45 degrees or pi/4 radians.
const double kFloatingActionButtonTurnInterval = 0.125;

/// An object that defines a position for the [FloatingActionButton]
/// based on the [Scaffold]'s [ScaffoldPrelayoutGeometry].
///
/// Flutter provides [FloatingActionButtonLocation]s for the common
/// [FloatingActionButton] placements in Material Design applications. These
/// locations are available as static members of this class.
///
/// See also:
///
///  * [FloatingActionButton], which is a circular button typically shown in the
///    bottom right corner of the app.
///  * [FloatingActionButtonAnimator], which is used to animate the
///    [Scaffold.floatingActionButton] from one [FloatingActionButtonLocation] to
///    another.
///  * [ScaffoldPrelayoutGeometry], the geometry that
///    [FloatingActionButtonLocation]s use to position the [FloatingActionButton].
abstract class FloatingActionButtonLocation {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const FloatingActionButtonLocation();

  /// End-aligned [FloatingActionButton], floating at the bottom of the screen.
  ///
  /// This is the default alignment of [FloatingActionButton]s in Material applications.
  static const FloatingActionButtonLocation endFloat = _EndFloatFloatingActionButtonLocation();

  /// Centered [FloatingActionButton], floating at the bottom of the screen.
  static const FloatingActionButtonLocation centerFloat = _CenterFloatFloatingActionButtonLocation();

  /// End-aligned [FloatingActionButton], floating over the
  /// [Scaffold.bottomNavigationBar] so that the center of the floating
  /// action button lines up with the top of the bottom navigation bar.
  ///
  /// If the value of [Scaffold.bottomNavigationBar] is a [BottomAppBar],
  /// the bottom app bar can include a "notch" in its shape that accommodates
  /// the overlapping floating action button.
  ///
  /// This is unlikely to be a useful location for apps that lack a bottom
  /// navigation bar.
  static const FloatingActionButtonLocation endDocked = _EndDockedFloatingActionButtonLocation();

  /// Center-aligned [FloatingActionButton], floating over the
  /// [Scaffold.bottomNavigationBar] so that the center of the floating
  /// action button lines up with the top of the bottom navigation bar.
  ///
  /// If the value of [Scaffold.bottomNavigationBar] is a [BottomAppBar],
  /// the bottom app bar can include a "notch" in its shape that accommodates
  /// the overlapping floating action button.
  ///
  /// This is unlikely to be a useful location for apps that lack a bottom
  /// navigation bar.
  static const FloatingActionButtonLocation centerDocked = _CenterDockedFloatingActionButtonLocation();

  /// Start-aligned [FloatingActionButton], floating over the transition between
  /// the [Scaffold.appBar] and the [Scaffold.body].
  ///
  /// To align a floating action button with [FloatingActionButton.mini] set to
  /// true with [CircleAvatar]s in the [ListTile.leading] slots of [ListTile]s
  /// in a [ListView] in the [Scaffold.body], consider using [miniStartTop].
  ///
  /// This is unlikely to be a useful location for apps that lack a top [AppBar]
  /// or that use a [SliverAppBar] in the scaffold body itself.
  static const FloatingActionButtonLocation startTop = _StartTopFloatingActionButtonLocation();

  /// Start-aligned [FloatingActionButton], floating over the transition between
  /// the [Scaffold.appBar] and the [Scaffold.body], optimized for mini floating
  /// action buttons.
  ///
  /// This is intended to be used with [FloatingActionButton.mini] set to true,
  /// so that the floating action button appears to align with [CircleAvatar]s
  /// in the [ListTile.leading] slot of a [ListTile] in a [ListView] in the
  /// [Scaffold.body].
  ///
  /// This is unlikely to be a useful location for apps that lack a top [AppBar]
  /// or that use a [SliverAppBar] in the scaffold body itself.
  static const FloatingActionButtonLocation miniStartTop = _MiniStartTopFloatingActionButtonLocation();

  /// End-aligned [FloatingActionButton], floating over the transition between
  /// the [Scaffold.appBar] and the [Scaffold.body].
  ///
  /// This is unlikely to be a useful location for apps that lack a top [AppBar]
  /// or that use a [SliverAppBar] in the scaffold body itself.
  static const FloatingActionButtonLocation endTop = _EndTopFloatingActionButtonLocation();

  /// Places the [FloatingActionButton] based on the [Scaffold]'s layout.
  ///
  /// This uses a [ScaffoldPrelayoutGeometry], which the [Scaffold] constructs
  /// during its layout phase after it has laid out every widget it can lay out
  /// except the [FloatingActionButton]. The [Scaffold] uses the [Offset]
  /// returned from this method to position the [FloatingActionButton] and
  /// complete its layout.
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry);

  @override
  String toString() => objectRuntimeType(this, 'FloatingActionButtonLocation');
}

double _leftOffset(ScaffoldPrelayoutGeometry scaffoldGeometry, { double offset = 0.0 }) {
  return kFloatingActionButtonMargin
       + scaffoldGeometry.minInsets.left
       - offset;
}

double _rightOffset(ScaffoldPrelayoutGeometry scaffoldGeometry, { double offset = 0.0 }) {
  return scaffoldGeometry.scaffoldSize.width
       - kFloatingActionButtonMargin
       - scaffoldGeometry.minInsets.right
       - scaffoldGeometry.floatingActionButtonSize.width
       + offset;
}

double _endOffset(ScaffoldPrelayoutGeometry scaffoldGeometry, { double offset = 0.0 }) {
  assert(scaffoldGeometry.textDirection != null);
  switch (scaffoldGeometry.textDirection) {
    case TextDirection.rtl:
      return _leftOffset(scaffoldGeometry, offset: offset);
    case TextDirection.ltr:
      return _rightOffset(scaffoldGeometry, offset: offset);
  }
  return null;
}

double _startOffset(ScaffoldPrelayoutGeometry scaffoldGeometry, { double offset = 0.0 }) {
  assert(scaffoldGeometry.textDirection != null);
  switch (scaffoldGeometry.textDirection) {
    case TextDirection.rtl:
      return _rightOffset(scaffoldGeometry, offset: offset);
    case TextDirection.ltr:
      return _leftOffset(scaffoldGeometry, offset: offset);
  }
  return null;
}

class _CenterFloatFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _CenterFloatFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Compute the x-axis offset.
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;

    // Compute the y-axis offset.
    final double contentBottom = scaffoldGeometry.contentBottom;
    final double bottomSheetHeight = scaffoldGeometry.bottomSheetSize.height;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;
    double fabY = contentBottom - fabHeight - kFloatingActionButtonMargin;
    if (snackBarHeight > 0.0)
      fabY = math.min(fabY, contentBottom - snackBarHeight - fabHeight - kFloatingActionButtonMargin);
    if (bottomSheetHeight > 0.0)
      fabY = math.min(fabY, contentBottom - bottomSheetHeight - fabHeight / 2.0);

    return Offset(fabX, fabY);
  }

  @override
  String toString() => 'FloatingActionButtonLocation.centerFloat';
}

class _EndFloatFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _EndFloatFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Compute the x-axis offset.
    final double fabX = _endOffset(scaffoldGeometry);

    // Compute the y-axis offset.
    final double contentBottom = scaffoldGeometry.contentBottom;
    final double bottomSheetHeight = scaffoldGeometry.bottomSheetSize.height;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;

    double fabY = contentBottom - fabHeight - kFloatingActionButtonMargin;
    if (snackBarHeight > 0.0)
      fabY = math.min(fabY, contentBottom - snackBarHeight - fabHeight - kFloatingActionButtonMargin);
    if (bottomSheetHeight > 0.0)
      fabY = math.min(fabY, contentBottom - bottomSheetHeight - fabHeight / 2.0);

    return Offset(fabX, fabY);
  }

  @override
  String toString() => 'FloatingActionButtonLocation.endFloat';
}

// Provider of common logic for [FloatingActionButtonLocation]s that
// dock to the [BottomAppBar].
abstract class _DockedFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _DockedFloatingActionButtonLocation();

  // Positions the Y coordinate of the [FloatingActionButton] at a height
  // where it docks to the [BottomAppBar].
  @protected
  double getDockedY(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double contentBottom = scaffoldGeometry.contentBottom;
    final double bottomSheetHeight = scaffoldGeometry.bottomSheetSize.height;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;

    double fabY = contentBottom - fabHeight / 2.0;
    // The FAB should sit with a margin between it and the snack bar.
    if (snackBarHeight > 0.0)
      fabY = math.min(fabY, contentBottom - snackBarHeight - fabHeight - kFloatingActionButtonMargin);
    // The FAB should sit with its center in front of the top of the bottom sheet.
    if (bottomSheetHeight > 0.0)
      fabY = math.min(fabY, contentBottom - bottomSheetHeight - fabHeight / 2.0);

    final double maxFabY = scaffoldGeometry.scaffoldSize.height - fabHeight;
    return math.min(maxFabY, fabY);
  }
}

class _EndDockedFloatingActionButtonLocation extends _DockedFloatingActionButtonLocation {
  const _EndDockedFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = _endOffset(scaffoldGeometry);
    return Offset(fabX, getDockedY(scaffoldGeometry));
  }

  @override
  String toString() => 'FloatingActionButtonLocation.endDocked';
}

class _CenterDockedFloatingActionButtonLocation extends _DockedFloatingActionButtonLocation {
  const _CenterDockedFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;
    return Offset(fabX, getDockedY(scaffoldGeometry));
  }

  @override
  String toString() => 'FloatingActionButtonLocation.centerDocked';
}

double _straddleAppBar(ScaffoldPrelayoutGeometry scaffoldGeometry) {
  final double fabHalfHeight = scaffoldGeometry.floatingActionButtonSize.height / 2.0;
  return scaffoldGeometry.contentTop - fabHalfHeight;
}

class _StartTopFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _StartTopFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return Offset(_startOffset(scaffoldGeometry), _straddleAppBar(scaffoldGeometry));
  }

  @override
  String toString() => 'FloatingActionButtonLocation.startTop';
}

class _MiniStartTopFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _MiniStartTopFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // We have to offset the FAB by four pixels because the FAB itself _adds_
    // four pixels in every direction in order to have a hit target area of 48
    // pixels in each dimension, despite being a circle of radius 40.
    return Offset(_startOffset(scaffoldGeometry, offset: 4.0), _straddleAppBar(scaffoldGeometry));
  }

  @override
  String toString() => 'FloatingActionButtonLocation.miniStartTop';
}

class _EndTopFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _EndTopFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return Offset(_endOffset(scaffoldGeometry), _straddleAppBar(scaffoldGeometry));
  }

  @override
  String toString() => 'FloatingActionButtonLocation.endTop';
}

/// Provider of animations to move the [FloatingActionButton] between [FloatingActionButtonLocation]s.
///
/// The [Scaffold] uses [Scaffold.floatingActionButtonAnimator] to define:
///
///  * The [Offset] of the [FloatingActionButton] between the old and new
///    [FloatingActionButtonLocation]s as part of the transition animation.
///  * An [Animation] to scale the [FloatingActionButton] during the transition.
///  * An [Animation] to rotate the [FloatingActionButton] during the transition.
///  * Where to start a new animation from if an animation is interrupted.
///
/// See also:
///
///  * [FloatingActionButton], which is a circular button typically shown in the
///    bottom right corner of the app.
///  * [FloatingActionButtonLocation], which the [Scaffold] uses to place the
///    [Scaffold.floatingActionButton] within the [Scaffold]'s layout.
abstract class FloatingActionButtonAnimator {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const FloatingActionButtonAnimator();

  /// Moves the [FloatingActionButton] by scaling out and then in at a new
  /// [FloatingActionButtonLocation].
  ///
  /// This animator shrinks the [FloatingActionButton] down until it disappears, then
  /// grows it back to full size at its new [FloatingActionButtonLocation].
  ///
  /// This is the default [FloatingActionButton] motion animation.
  static const FloatingActionButtonAnimator scaling = _ScalingFabMotionAnimator();

  /// Gets the [FloatingActionButton]'s position relative to the origin of the
  /// [Scaffold] based on [progress].
  ///
  /// [begin] is the [Offset] provided by the previous
  /// [FloatingActionButtonLocation].
  ///
  /// [end] is the [Offset] provided by the new
  /// [FloatingActionButtonLocation].
  ///
  /// [progress] is the current progress of the transition animation.
  /// When [progress] is 0.0, the returned [Offset] should be equal to [begin].
  /// when [progress] is 1.0, the returned [Offset] should be equal to [end].
  Offset getOffset({ @required Offset begin, @required Offset end, @required double progress });

  /// Animates the scale of the [FloatingActionButton].
  ///
  /// The animation should both start and end with a value of 1.0.
  ///
  /// For example, to create an animation that linearly scales out and then back in,
  /// you could join animations that pass each other:
  ///
  /// ```dart
  ///   @override
  ///   Animation<double> getScaleAnimation({@required Animation<double> parent}) {
  ///     // The animations will cross at value 0, and the train will return to 1.0.
  ///     return TrainHoppingAnimation(
  ///       Tween<double>(begin: 1.0, end: -1.0).animate(parent),
  ///       Tween<double>(begin: -1.0, end: 1.0).animate(parent),
  ///     );
  ///   }
  /// ```
  Animation<double> getScaleAnimation({ @required Animation<double> parent });

  /// Animates the rotation of [Scaffold.floatingActionButton].
  ///
  /// The animation should both start and end with a value of 0.0 or 1.0.
  ///
  /// The animation values are a fraction of a full circle, with 0.0 and 1.0
  /// corresponding to 0 and 360 degrees, while 0.5 corresponds to 180 degrees.
  ///
  /// For example, to create a rotation animation that rotates the
  /// [FloatingActionButton] through a full circle:
  ///
  /// ```dart
  /// @override
  /// Animation<double> getRotationAnimation({@required Animation<double> parent}) {
  ///   return Tween<double>(begin: 0.0, end: 1.0).animate(parent);
  /// }
  /// ```
  Animation<double> getRotationAnimation({ @required Animation<double> parent });

  /// Gets the progress value to restart a motion animation from when the animation is interrupted.
  ///
  /// [previousValue] is the value of the animation before it was interrupted.
  ///
  /// The restart of the animation will affect all three parts of the motion animation:
  /// offset animation, scale animation, and rotation animation.
  ///
  /// An interruption triggers if the [Scaffold] is given a new [FloatingActionButtonLocation]
  /// while it is still animating a transition between two previous [FloatingActionButtonLocation]s.
  ///
  /// A sensible default is usually 0.0, which is the same as restarting
  /// the animation from the beginning, regardless of the original state of the animation.
  double getAnimationRestart(double previousValue) => 0.0;

  @override
  String toString() => objectRuntimeType(this, 'FloatingActionButtonAnimator');
}

class _ScalingFabMotionAnimator extends FloatingActionButtonAnimator {
  const _ScalingFabMotionAnimator();

  @override
  Offset getOffset({ Offset begin, Offset end, double progress }) {
    if (progress < 0.5) {
      return begin;
    } else {
      return end;
    }
  }

  @override
  Animation<double> getScaleAnimation({ Animation<double> parent }) {
    // Animate the scale down from 1 to 0 in the first half of the animation
    // then from 0 back to 1 in the second half.
    const Curve curve = Interval(0.5, 1.0, curve: Curves.ease);
    return _AnimationSwap<double>(
      ReverseAnimation(parent.drive(CurveTween(curve: curve.flipped))),
      parent.drive(CurveTween(curve: curve)),
      parent,
      0.5,
    );
  }

  // Because we only see the last half of the rotation tween,
  // it needs to go twice as far.
  static final Animatable<double> _rotationTween = Tween<double>(
    begin: 1.0 - kFloatingActionButtonTurnInterval * 2.0,
    end: 1.0,
  );

  static final Animatable<double> _thresholdCenterTween = CurveTween(curve: const Threshold(0.5));

  @override
  Animation<double> getRotationAnimation({ Animation<double> parent }) {
    // This rotation will turn on the way in, but not on the way out.
    return _AnimationSwap<double>(
      parent.drive(_rotationTween),
      ReverseAnimation(parent.drive(_thresholdCenterTween)),
      parent,
      0.5,
    );
  }

  // If the animation was just starting, we'll continue from where we left off.
  // If the animation was finishing, we'll treat it as if we were starting at that point in reverse.
  // This avoids a size jump during the animation.
  @override
  double getAnimationRestart(double previousValue) => math.min(1.0 - previousValue, previousValue);
}

/// An animation that swaps from one animation to the next when the [parent] passes [swapThreshold].
///
/// The [value] of this animation is the value of [first] when [parent.value] < [swapThreshold]
/// and the value of [next] otherwise.
class _AnimationSwap<T> extends CompoundAnimation<T> {
  /// Creates an [_AnimationSwap].
  ///
  /// Both arguments must be non-null. Either can be an [_AnimationSwap] itself
  /// to combine multiple animations.
  _AnimationSwap(Animation<T> first, Animation<T> next, this.parent, this.swapThreshold) : super(first: first, next: next);

  final Animation<double> parent;
  final double swapThreshold;

  @override
  T get value => parent.value < swapThreshold ? first.value : next.value;
}
