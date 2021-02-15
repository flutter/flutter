// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'animation.dart';

/// An interface for other animation strategies. You can imagine that this class sort of
/// tells someone what to do when depending on the current animation status.
@immutable
abstract class AnimationStrategy<T> implements MovingAnimationStrategy<T> {
  const AnimationStrategy({ 
    required this.dismissed,
    required this.forward,
    required this.completed,
    required this.reverse,
  });

  final T dismissed;
  final T forward;
  final T completed;
  final T reverse;

  /// Decides what to do based on current animation status.
  /// todo: macros
  T ask(Animation<Object> animation) {
    return decide(animation.status);
  }

  /// Decides what to do based on [status].
  T decide(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        return dismissed;
      case AnimationStatus.forward:
        return forward;
      case AnimationStatus.completed:
        return completed;
      case AnimationStatus.reverse:
        return reverse;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is AnimationStrategy 
        && other.dismissed == dismissed
        && other.forward == forward
        && other.completed == completed
        && other.reverse == reverse;
  }

  @override
  int get hashCode => hashValues(dismissed, forward, completed, reverse);
}

/// An interface for other animation strategies. You can imagine that this class sort of
/// tells someone what to do when animation status is either [AnimationStatus.forward], or [AnimationStatus.reverse].
@immutable
abstract class MovingAnimationStrategy<T> {
  const MovingAnimationStrategy({ 
    required this.forward,
    required this.reverse,
  });

  final T forward;
  final T reverse;

  /// Decides what to do based on current animation status.
  ///
  /// Will return null if the status is not moving, which is
  /// [AnimationStatus.dismissed], or [AnimationStatus.completed].
  T? ask(Animation<Object> animation) {
    return decide(animation.status);
  }

  /// Decides what to do based on [status].
  ///
  /// Will return null if the status is not moving, which is
  /// [AnimationStatus.dismissed], or [AnimationStatus.completed].
  T? decide(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward:
        return forward;
      case AnimationStatus.reverse:
        return reverse;
      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is AnimationStrategy 
        && other.forward == forward
        && other.reverse == reverse;
  }

  @override
  int get hashCode => hashValues(forward, reverse);
}

/// Describes what [HitTestBehavior] should be applied, depending on [AnimationStatus].
class HitTestBehaviorStrategy extends AnimationStrategy<HitTestBehavior> {
  const HitTestBehaviorStrategy({
    HitTestBehavior dismissed = HitTestBehavior.deferToChild,
    HitTestBehavior forward = HitTestBehavior.deferToChild,
    HitTestBehavior reverse = HitTestBehavior.deferToChild,
    HitTestBehavior completed = HitTestBehavior.deferToChild,
  }) : super(dismissed: dismissed, forward: forward, reverse: reverse, completed: completed);

  const HitTestBehaviorStrategy.translucent({
    HitTestBehavior dismissed = HitTestBehavior.translucent,
    HitTestBehavior forward = HitTestBehavior.translucent,
    HitTestBehavior reverse = HitTestBehavior.translucent,
    HitTestBehavior completed = HitTestBehavior.translucent,
  }) : super(dismissed: dismissed, forward: forward, reverse: reverse, completed: completed);

  const HitTestBehaviorStrategy.opaque({
    HitTestBehavior dismissed = HitTestBehavior.opaque,
    HitTestBehavior forward = HitTestBehavior.opaque,
    HitTestBehavior reverse = HitTestBehavior.opaque,
    HitTestBehavior completed = HitTestBehavior.opaque,
  }) : super(dismissed: dismissed, forward: forward, reverse: reverse, completed: completed);
}

/// Describes when the [IgnoringPointer] should be applied, depending on [AnimationStatus].
class IgnoringStrategy extends AnimationStrategy<bool> {
  const IgnoringStrategy({
    bool dismissed = false,
    bool forward = false,
    bool reverse = false,
    bool completed = false,
  }) : super(dismissed: dismissed, forward: forward, reverse: reverse, completed: completed);

  /// Ignore in any [AnimationStatus].
  const IgnoringStrategy.all() : super(dismissed: true, forward: true, reverse: true, completed: true);

  /// Will evaluate to a single bool condition from the [animation] status.
  bool evaluate(Animation<Object> animation) {
    return evaluateStatus(animation.status);
  }

  /// Will evaluate to a single bool condition from the [status].
  bool evaluateStatus(AnimationStatus status) {
    return dismissed && status == AnimationStatus.dismissed ||
           forward && status == AnimationStatus.forward ||
           reverse && status == AnimationStatus.reverse ||
           completed && status == AnimationStatus.completed;
  }
}

/// Describes when the [IgnoringPointer] should be applied, if animation is moving.
///
/// See also:
/// * [IgnoringStrategy] to also respect dismissed and completed animation statues
class MovingIgnoringStrategy extends MovingAnimationStrategy<bool> {
  const MovingIgnoringStrategy({
    bool forward = false,
    bool reverse = false,
  }) : super(forward: forward, reverse: reverse);

  /// Ignore in any [AnimationStatus].
  const MovingIgnoringStrategy.all() : super(forward: true, reverse: true);

  /// Will evaluate to a single bool condition from the [animation] status.
  bool evaluate(Animation<Object> animation) {
    return evaluateStatus(animation.status);
  }

  /// Will evaluate to a single bool condition from the [status].
  bool evaluateStatus(AnimationStatus status) {
    return forward && status == AnimationStatus.forward ||
           reverse && status == AnimationStatus.reverse;
  }
}
