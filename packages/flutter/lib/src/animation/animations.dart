// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show VoidCallback;

import 'animation.dart';
import 'curves.dart';
import 'listener_helpers.dart';

class AlwaysCompleteAnimation extends Animation<double> {
  const AlwaysCompleteAnimation();

  void addListener(VoidCallback listener) { }
  void removeListener(VoidCallback listener) { }
  void addStatusListener(AnimationStatusListener listener) { }
  void removeStatusListener(AnimationStatusListener listener) { }
  AnimationStatus get status => AnimationStatus.completed;
  AnimationDirection get direction => AnimationDirection.forward;
  double get value => 1.0;
}

const AlwaysCompleteAnimation kAlwaysCompleteAnimation = const AlwaysCompleteAnimation();

class AlwaysDismissedAnimation extends Animation<double> {
  const AlwaysDismissedAnimation();

  void addListener(VoidCallback listener) { }
  void removeListener(VoidCallback listener) { }
  void addStatusListener(AnimationStatusListener listener) { }
  void removeStatusListener(AnimationStatusListener listener) { }
  AnimationStatus get status => AnimationStatus.dismissed;
  AnimationDirection get direction => AnimationDirection.forward;
  double get value => 0.0;
}

const AlwaysDismissedAnimation kAlwaysDismissedAnimation = const AlwaysDismissedAnimation();

class AlwaysStoppedAnimation extends Animation<double> {
  const AlwaysStoppedAnimation(this.value);

  final double value;

  void addListener(VoidCallback listener) { }
  void removeListener(VoidCallback listener) { }
  void addStatusListener(AnimationStatusListener listener) { }
  void removeStatusListener(AnimationStatusListener listener) { }
  AnimationStatus get status => AnimationStatus.forward;
  AnimationDirection get direction => AnimationDirection.forward;
}

abstract class ProxyAnimatedMixin {
  Animation<double> get parent;

  void addListener(VoidCallback listener) => parent.addListener(listener);
  void removeListener(VoidCallback listener) => parent.removeListener(listener);
  void addStatusListener(AnimationStatusListener listener) => parent.addStatusListener(listener);
  void removeStatusListener(AnimationStatusListener listener) => parent.removeStatusListener(listener);

  AnimationStatus get status => parent.status;
  AnimationDirection get direction => parent.direction;
}

class ProxyAnimation extends Animation<double>
  with LazyListenerMixin, LocalPerformanceListenersMixin, LocalPerformanceStatusListenersMixin {
  ProxyAnimation([Animation<double> animation]) {
    _masterAnimation = animation;
    if (_masterAnimation == null) {
      _status = AnimationStatus.dismissed;
      _direction = AnimationDirection.forward;
      _value = 0.0;
    }
  }

  AnimationStatus _status;
  AnimationDirection _direction;
  double _value;

  Animation<double> get masterAnimation => _masterAnimation;
  Animation<double> _masterAnimation;
  void set masterAnimation(Animation<double> value) {
    if (value == _masterAnimation)
      return;
    if (_masterAnimation != null) {
      _status = _masterAnimation.status;
      _direction = _masterAnimation.direction;
      _value = _masterAnimation.value;
      if (isListening)
        didStopListening();
    }
    _masterAnimation = value;
    if (_masterAnimation != null) {
      if (isListening)
        didStartListening();
      if (_value != _masterAnimation.value)
        notifyListeners();
      if (_status != _masterAnimation.status)
        notifyStatusListeners(_masterAnimation.status);
      _status = null;
      _direction = null;
      _value = null;
    }
  }

  void didStartListening() {
    if (_masterAnimation != null) {
      _masterAnimation.addListener(notifyListeners);
      _masterAnimation.addStatusListener(notifyStatusListeners);
    }
  }

  void didStopListening() {
    if (_masterAnimation != null) {
      _masterAnimation.removeListener(notifyListeners);
      _masterAnimation.removeStatusListener(notifyStatusListeners);
    }
  }

  AnimationStatus get status => _masterAnimation != null ? _masterAnimation.status : _status;
  AnimationDirection get direction => _masterAnimation != null ? _masterAnimation.direction : _direction;
  double get value => _masterAnimation != null ? _masterAnimation.value : _value;
}

class ReverseAnimation extends Animation<double>
  with LazyListenerMixin, LocalPerformanceStatusListenersMixin {
  ReverseAnimation(this.masterAnimation);

  final Animation<double> masterAnimation;

  void addListener(VoidCallback listener) {
    didRegisterListener();
    masterAnimation.addListener(listener);
  }
  void removeListener(VoidCallback listener) {
    masterAnimation.removeListener(listener);
    didUnregisterListener();
  }

  void didStartListening() {
    masterAnimation.addStatusListener(_statusChangeHandler);
  }

  void didStopListening() {
    masterAnimation.removeStatusListener(_statusChangeHandler);
  }

  void _statusChangeHandler(AnimationStatus status) {
    notifyStatusListeners(_reverseStatus(status));
  }

  AnimationStatus get status => _reverseStatus(masterAnimation.status);
  AnimationDirection get direction => _reverseDirection(masterAnimation.direction);
  double get value => 1.0 - masterAnimation.value;

  AnimationStatus _reverseStatus(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward: return AnimationStatus.reverse;
      case AnimationStatus.reverse: return AnimationStatus.forward;
      case AnimationStatus.completed: return AnimationStatus.dismissed;
      case AnimationStatus.dismissed: return AnimationStatus.completed;
    }
  }

  AnimationDirection _reverseDirection(AnimationDirection direction) {
    switch (direction) {
      case AnimationDirection.forward: return AnimationDirection.reverse;
      case AnimationDirection.reverse: return AnimationDirection.forward;
    }
  }
}

class CurvedAnimation extends Animation<double> with ProxyAnimatedMixin {
  CurvedAnimation({
    this.parent,
    this.curve: Curves.linear,
    this.reverseCurve
  }) {
    assert(parent != null);
    assert(curve != null);
    parent.addStatusListener(_handleStatusChanged);
  }

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
  AnimationDirection _curveDirection;

  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        _curveDirection = null;
        break;
      case AnimationStatus.forward:
        _curveDirection ??= AnimationDirection.forward;
        break;
      case AnimationStatus.reverse:
        _curveDirection ??= AnimationDirection.reverse;
        break;
    }
  }

  double get value {
    final bool useForwardCurve = reverseCurve == null || (_curveDirection ?? parent.direction) == AnimationDirection.forward;
    Curve activeCurve = useForwardCurve ? curve : reverseCurve;

    double t = parent.value;
    if (activeCurve == null)
      return t;
    if (t == 0.0 || t == 1.0) {
      assert(activeCurve.transform(t).round() == t);
      return t;
    }
    return activeCurve.transform(t);
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
  with EagerListenerMixin, LocalPerformanceListenersMixin, LocalPerformanceStatusListenersMixin {
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

  Animation<double> get currentTrain => _currentTrain;
  Animation<double> _currentTrain;
  Animation<double> _nextTrain;
  _TrainHoppingMode _mode;

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

  AnimationStatus get status => _currentTrain.status;
  AnimationDirection get direction => _currentTrain.direction;

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

  double get value => _currentTrain.value;

  /// Frees all the resources used by this performance.
  /// After this is called, this object is no longer usable.
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
}
