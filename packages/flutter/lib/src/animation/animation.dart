// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show VoidCallback;

import 'package:flutter/foundation.dart';

/// The status of an animation
enum AnimationStatus {
  /// The animation is stopped at the beginning
  dismissed,

  /// The animation is running from beginning to end
  forward,

  /// The animation is running backwards, from end to beginning
  reverse,

  /// The animation is stopped at the end
  completed,
}

/// Signature for listeners attached using [Animation.addStatusListener].
typedef void AnimationStatusListener(AnimationStatus status);

/// An animation with a value of type `T`.
///
/// An animation consists of a value (of type `T`) together with a status. The
/// status indicates whether the animation is conceptually running from
/// beginning to end or from the end back to the beginning, although the actual
/// value of the animation might not change monotonically (e.g., if the
/// animation uses a curve that bounces).
///
/// Animations also let other objects listen for changes to either their value
/// or their status. These callbacks are called during the "animation" phase of
/// the pipeline, just prior to rebuilding widgets.
///
/// To create a new animation that you can run forward and backward, consider
/// using [AnimationController].
abstract class Animation<T> extends Listenable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Animation();

  // keep these next five dartdocs in sync with the dartdocs in AnimationWithParentMixin<T>

  /// Calls the listener every time the value of the animation changes.
  ///
  /// Listeners can be removed with [removeListener].
  @override
  void addListener(VoidCallback listener);

  /// Stop calling the listener every time the value of the animation changes.
  ///
  /// Listeners can be added with [addListener].
  @override
  void removeListener(VoidCallback listener);

  /// Calls listener every time the status of the animation changes.
  ///
  /// Listeners can be removed with [removeStatusListener].
  void addStatusListener(AnimationStatusListener listener);

  /// Stops calling the listener every time the status of the animation changes.
  ///
  /// Listeners can be added with [addStatusListener].
  void removeStatusListener(AnimationStatusListener listener);

  /// The current status of this animation.
  AnimationStatus get status;

  /// The current value of the animation.
  T get value;

  /// Whether this animation is stopped at the beginning.
  bool get isDismissed => status == AnimationStatus.dismissed;

  /// Whether this animation is stopped at the end.
  bool get isCompleted => status == AnimationStatus.completed;

  @override
  String toString() {
    return '$runtimeType#$hashCode(${toStringDetails()})';
  }

  /// Provides a string describing the status of this object, but not including
  /// information about the object itself.
  ///
  /// This function is used by [Animation.toString] so that [Animation]
  /// subclasses can provide additional details while ensuring all [Animation]
  /// subclasses have a consistent [toString] style.
  ///
  /// The result of this function includes an icon describing the status of this
  /// [Animation] object:
  ///
  /// * "&#x25B6;": [AnimationStatus.forward] ([value] increasing)
  /// * "&#x25C0;": [AnimationStatus.reverse] ([value] decreasing)
  /// * "&#x23ED;": [AnimationStatus.completed] ([value] == 1.0)
  /// * "&#x23EE;": [AnimationStatus.dismissed] ([value] == 0.0)
  String toStringDetails() {
    assert(status != null);
    String icon;
    switch (status) {
      case AnimationStatus.forward:
        icon = '\u25B6'; // >
        break;
      case AnimationStatus.reverse:
        icon = '\u25C0'; // <
        break;
      case AnimationStatus.completed:
        icon = '\u23ED'; // >>|
        break;
      case AnimationStatus.dismissed:
        icon = '\u23EE'; // |<<
        break;
    }
    assert(icon != null);
    return '$icon';
  }
}
