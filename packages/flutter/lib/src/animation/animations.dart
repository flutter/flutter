// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show VoidCallback;

import 'animation.dart';
import 'curves.dart';
import 'listener_helpers.dart';

class _AlwaysCompleteAnimation extends Animation<double> {
  const _AlwaysCompleteAnimation();

  @override
  void addListener(VoidCallback listener) { }

  @override
  void removeListener(VoidCallback listener) { }

  @override
  void addStatusListener(AnimationStatusListener listener) { }

  @override
  void removeStatusListener(AnimationStatusListener listener) { }

  @override
  AnimationStatus get status => AnimationStatus.completed;

  @override
  double get value => 1.0;

  @override
  String toString() => 'kAlwaysCompleteAnimation';
}

/// An animation that is always complete.
///
/// Using this constant involves less overhead than building an
/// [AnimationController] with an initial value of 1.0. This is useful when an
/// API expects an animation but you don't actually want to animate anything.
const Animation<double> kAlwaysCompleteAnimation = const _AlwaysCompleteAnimation();

class _AlwaysDismissedAnimation extends Animation<double> {
  const _AlwaysDismissedAnimation();

  @override
  void addListener(VoidCallback listener) { }

  @override
  void removeListener(VoidCallback listener) { }

  @override
  void addStatusListener(AnimationStatusListener listener) { }

  @override
  void removeStatusListener(AnimationStatusListener listener) { }

  @override
  AnimationStatus get status => AnimationStatus.dismissed;

  @override
  double get value => 0.0;

  @override
  String toString() => 'kAlwaysDismissedAnimation';
}

/// An animation that is always dismissed.
///
/// Using this constant involves less overhead than building an
/// [AnimationController] with an initial value of 0.0. This is useful when an
/// API expects an animation but you don't actually want to animate anything.
const Animation<double> kAlwaysDismissedAnimation = const _AlwaysDismissedAnimation();

/// An animation that is always stopped at a given value.
///
/// The [status] is always [AnimationStatus.forward].
class AlwaysStoppedAnimation<T> extends Animation<T> {
  /// Creates an [AlwaysStoppedAnimation] with the given value.
  ///
  /// Since the [value] and [status] of an [AlwaysStoppedAnimation] can never
  /// change, the listeners can never be invoked. It is therefore safe to reuse
  /// an [AlwaysStoppedAnimation] instance in multiple places. If the [value] to
  /// be used is known at compile time, the constructor should be invoked as a
  /// `const` constructor.
  const AlwaysStoppedAnimation(this.value);

  @override
  final T value;

  @override
  void addListener(VoidCallback listener) { }

  @override
  void removeListener(VoidCallback listener) { }

  @override
  void addStatusListener(AnimationStatusListener listener) { }

  @override
  void removeStatusListener(AnimationStatusListener listener) { }

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  String toStringDetails() {
    return '${super.toStringDetails()} $value; paused';
  }
}

/// Implements most of the [Animation] interface, by deferring its behavior to a
/// given [parent] Animation. To implement an [Animation] that proxies to a
/// parent, this class plus implementing "T get value" is all that is necessary.
abstract class AnimationWithParentMixin<T> {
  /// The animation whose value this animation will proxy.
  ///
  /// This animation must remain the same for the lifetime of this object. If
  /// you wish to proxy a different animation at different times, consider using
  /// [ProxyAnimation].
  Animation<T> get parent;

  // keep these next five dartdocs in sync with the dartdocs in Animation<T>

  /// Calls the listener every time the value of the animation changes.
  ///
  /// Listeners can be removed with [removeListener].
  void addListener(VoidCallback listener) => parent.addListener(listener);

  /// Stop calling the listener every time the value of the animation changes.
  ///
  /// Listeners can be added with [addListener].
  void removeListener(VoidCallback listener) => parent.removeListener(listener);

  /// Calls listener every time the status of the animation changes.
  ///
  /// Listeners can be removed with [removeStatusListener].
  void addStatusListener(AnimationStatusListener listener) => parent.addStatusListener(listener);

  /// Stops calling the listener every time the status of the animation changes.
  ///
  /// Listeners can be added with [addStatusListener].
  void removeStatusListener(AnimationStatusListener listener) => parent.removeStatusListener(listener);

  /// The current status of this animation.
  AnimationStatus get status => parent.status;
}

/// An animation that is a proxy for another animation.
///
/// A proxy animation is useful because the parent animation can be mutated. For
/// example, one object can create a proxy animation, hand the proxy to another
/// object, and then later change the animation from which the proxy receieves
/// its value.
class ProxyAnimation extends Animation<double>
  with AnimationLazyListenerMixin, AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {

  /// Creates a proxy animation.
  ///
  /// If the animation argument is omitted, the proxy animation will have the
  /// status [AnimationStatus.dismissed] and a value of 0.0.
  ProxyAnimation([Animation<double> animation]) {
    _parent = animation;
    if (_parent == null) {
      _status = AnimationStatus.dismissed;
      _value = 0.0;
    }
  }

  AnimationStatus _status;
  double _value;

  /// The animation whose value this animation will proxy.
  ///
  /// This value is mutable. When mutated, the listeners on the proxy animation
  /// will be transparently updated to be listening to the new parent animation.
  Animation<double> get parent => _parent;
  Animation<double> _parent;
  set parent(Animation<double> value) {
    if (value == _parent)
      return;
    if (_parent != null) {
      _status = _parent.status;
      _value = _parent.value;
      if (isListening)
        didStopListening();
    }
    _parent = value;
    if (_parent != null) {
      if (isListening)
        didStartListening();
      if (_value != _parent.value)
        notifyListeners();
      if (_status != _parent.status)
        notifyStatusListeners(_parent.status);
      _status = null;
      _value = null;
    }
  }

  @override
  void didStartListening() {
    if (_parent != null) {
      _parent.addListener(notifyListeners);
      _parent.addStatusListener(notifyStatusListeners);
    }
  }

  @override
  void didStopListening() {
    if (_parent != null) {
      _parent.removeListener(notifyListeners);
      _parent.removeStatusListener(notifyStatusListeners);
    }
  }

  @override
  AnimationStatus get status => _parent != null ? _parent.status : _status;

  @override
  double get value => _parent != null ? _parent.value : _value;

  @override
  String toString() {
    if (parent == null)
      return '$runtimeType(null; ${super.toStringDetails()} ${value.toStringAsFixed(3)})';
    return '$parent\u27A9$runtimeType';
  }
}

/// An animation that is the reverse of another animation.
///
/// If the parent animation is running forward from 0.0 to 1.0, this animation
/// is running in reverse from 1.0 to 0.0. Notice that using a ReverseAnimation
/// is different from simply using a [Tween] with a begin of 1.0 and an end of
/// 0.0 because the tween does not change the status or direction of the
/// animation.
class ReverseAnimation extends Animation<double>
  with AnimationLazyListenerMixin, AnimationLocalStatusListenersMixin {

  /// Creates a reverse animation.
  ///
  /// The parent argument must not be null.
  ReverseAnimation(this.parent) {
    assert(parent != null);
  }

  /// The animation whose value and direction this animation is reversing.
  final Animation<double> parent;

  @override
  void addListener(VoidCallback listener) {
    didRegisterListener();
    parent.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    parent.removeListener(listener);
    didUnregisterListener();
  }

  @override
  void didStartListening() {
    parent.addStatusListener(_statusChangeHandler);
  }

  @override
  void didStopListening() {
    parent.removeStatusListener(_statusChangeHandler);
  }

  void _statusChangeHandler(AnimationStatus status) {
    notifyStatusListeners(_reverseStatus(status));
  }

  @override
  AnimationStatus get status => _reverseStatus(parent.status);

  @override
  double get value => 1.0 - parent.value;

  AnimationStatus _reverseStatus(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward: return AnimationStatus.reverse;
      case AnimationStatus.reverse: return AnimationStatus.forward;
      case AnimationStatus.completed: return AnimationStatus.dismissed;
      case AnimationStatus.dismissed: return AnimationStatus.completed;
    }
  }

  @override
  String toString() {
    return '$parent\u27AA$runtimeType';
  }
}

/// An animation that applies a curve to another animation.
///
/// [CurvedAnimation] is useful when you want to apply a non-linear [Curve] to
/// an animation object wrapped in the [CurvedAnimation].
///
/// For example, the following code snippet shows how you can apply a curve to a linear animation
/// produced by an [AnimationController]:
///
/// ``` dart
///     final AnimationController controller =
///         new AnimationController(duration: const Duration(milliseconds: 500));
///     final CurvedAnimation animation =
///         new CurvedAnimation(parent: controller, curve: Curves.ease);
///```
/// Depending on the given curve, the output of the [CurvedAnimation] could have a wider range
/// than its input. For example, elastic curves such as [Curves.elasticIn] will significantly
/// overshoot or undershoot the default range of 0.0 to 1.0.
///
/// If you want to apply a [Curve] to a [Tween], consider using [CurveTween].
class CurvedAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  /// Creates a curved animation.
  ///
  /// The parent and curve arguments must not be null.
  CurvedAnimation({
    this.parent,
    this.curve,
    this.reverseCurve
  }) {
    assert(parent != null);
    assert(curve != null);
    parent.addStatusListener(_handleStatusChanged);
  }

  /// The animation to which this animation applies a curve.
  @override
  final Animation<double> parent;

  /// The curve to use in the forward direction.
  Curve curve;

  /// The curve to use in the reverse direction.
  ///
  /// If this field is null, uses [curve] in both directions.
  Curve reverseCurve;

  /// The direction used to select the current curve.
  ///
  /// The curve direction is only reset when we hit the beginning or the end of
  /// the timeline to avoid discontinuities in the value of any variables this
  /// a animation is used to animate.
  AnimationStatus _curveDirection;

  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        _curveDirection = null;
        break;
      case AnimationStatus.forward:
        _curveDirection ??= AnimationStatus.forward;
        break;
      case AnimationStatus.reverse:
        _curveDirection ??= AnimationStatus.reverse;
        break;
    }
  }

  bool get _useForwardCurve {
    return reverseCurve == null || (_curveDirection ?? parent.status) != AnimationStatus.reverse;
  }

  @override
  double get value {
    Curve activeCurve = _useForwardCurve ? curve : reverseCurve;

    double t = parent.value;
    if (activeCurve == null)
      return t;
    if (t == 0.0 || t == 1.0) {
      assert(activeCurve.transform(t).round() == t);
      return t;
    }
    return activeCurve.transform(t);
  }

  @override
  String toString() {
    if (reverseCurve == null)
      return '$parent\u27A9$curve';
    if (_useForwardCurve)
     return '$parent\u27A9$curve\u2092\u2099/$reverseCurve';
    return '$parent\u27A9$curve/$reverseCurve\u2092\u2099';
  }
}

enum _TrainHoppingMode { minimize, maximize }

/// This animation starts by proxying one animation, but can be given a
/// second animation. When their times cross (either because the second is
/// going in the opposite direction, or because the one overtakes the other),
/// the animation hops over to proxying the second animation, and the second
/// animation becomes the new "first" performance.
///
/// Since this object must track the two animations even when it has no
/// listeners of its own, instead of shutting down when all its listeners are
/// removed, it exposes a [dispose()] method. Call this method to shut this
/// object down.
class TrainHoppingAnimation extends Animation<double>
  with AnimationEagerListenerMixin, AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {

  /// Creates a train-hopping animation.
  ///
  /// The current train argument must not be null but the next train argument
  /// can be null.
  TrainHoppingAnimation(this._currentTrain, this._nextTrain, { this.onSwitchedTrain }) {
    assert(_currentTrain != null);
    if (_nextTrain != null) {
      if (_currentTrain.value > _nextTrain.value) {
        _mode = _TrainHoppingMode.maximize;
      } else {
        _mode = _TrainHoppingMode.minimize;
        if (_currentTrain.value == _nextTrain.value) {
          _currentTrain = _nextTrain;
          _nextTrain = null;
        }
      }
    }
    _currentTrain.addStatusListener(_statusChangeHandler);
    _currentTrain.addListener(_valueChangeHandler);
    if (_nextTrain != null)
      _nextTrain.addListener(_valueChangeHandler);
    assert(_mode != null);
  }

  /// The animation that is current driving this animation.
  Animation<double> get currentTrain => _currentTrain;
  Animation<double> _currentTrain;
  Animation<double> _nextTrain;
  _TrainHoppingMode _mode;

  /// Called when this animation switches to be driven by a different animation.
  VoidCallback onSwitchedTrain;

  AnimationStatus _lastStatus;
  void _statusChangeHandler(AnimationStatus status) {
    assert(_currentTrain != null);
    if (status != _lastStatus) {
      notifyListeners();
      _lastStatus = status;
    }
    assert(_lastStatus != null);
  }

  @override
  AnimationStatus get status => _currentTrain.status;

  double _lastValue;
  void _valueChangeHandler() {
    assert(_currentTrain != null);
    bool hop = false;
    if (_nextTrain != null) {
      switch (_mode) {
        case _TrainHoppingMode.minimize:
          hop = _nextTrain.value <= _currentTrain.value;
          break;
        case _TrainHoppingMode.maximize:
          hop = _nextTrain.value >= _currentTrain.value;
          break;
      }
      if (hop) {
        _currentTrain.removeStatusListener(_statusChangeHandler);
        _currentTrain.removeListener(_valueChangeHandler);
        _currentTrain = _nextTrain;
        // TODO(hixie): This should be setting a status listener on the next
        // train, not a value listener, and it should pass in _statusChangeHandler,
        // not _valueChangeHandler
        _nextTrain.addListener(_valueChangeHandler);
        _statusChangeHandler(_nextTrain.status);
      }
    }
    double newValue = value;
    if (newValue != _lastValue) {
      notifyListeners();
      _lastValue = newValue;
    }
    assert(_lastValue != null);
    if (hop && onSwitchedTrain != null)
      onSwitchedTrain();
  }

  @override
  double get value => _currentTrain.value;

  /// Frees all the resources used by this performance.
  /// After this is called, this object is no longer usable.
  @override
  void dispose() {
    assert(_currentTrain != null);
    _currentTrain.removeStatusListener(_statusChangeHandler);
    _currentTrain.removeListener(_valueChangeHandler);
    _currentTrain = null;
    if (_nextTrain != null) {
      _nextTrain.removeListener(_valueChangeHandler);
      _nextTrain = null;
    }
  }

  @override
  String toString() {
    if (_nextTrain != null)
      return '$currentTrain\u27A9$runtimeType(next: $_nextTrain)';
    return '$currentTrain\u27A9$runtimeType(no next)';
  }
}
