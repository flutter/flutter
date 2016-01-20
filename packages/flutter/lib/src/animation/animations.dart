// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show VoidCallback;

import 'animated_value.dart';
import 'listener_helpers.dart';
import 'tween.dart';

class AlwaysCompleteAnimation extends Animated<double> {
  const AlwaysCompleteAnimation();

  void addListener(VoidCallback listener) { }
  void removeListener(VoidCallback listener) { }
  void addStatusListener(PerformanceStatusListener listener) { }
  void removeStatusListener(PerformanceStatusListener listener) { }
  PerformanceStatus get status => PerformanceStatus.completed;
  AnimationDirection get direction => AnimationDirection.forward;
  double get value => 1.0;
}

const AlwaysCompleteAnimation kAlwaysCompleteAnimation = const AlwaysCompleteAnimation();

class AlwaysDismissedAnimation extends Animated<double> {
  const AlwaysDismissedAnimation();

  void addListener(VoidCallback listener) { }
  void removeListener(VoidCallback listener) { }
  void addStatusListener(PerformanceStatusListener listener) { }
  void removeStatusListener(PerformanceStatusListener listener) { }
  PerformanceStatus get status => PerformanceStatus.dismissed;
  AnimationDirection get direction => AnimationDirection.forward;
  double get value => 0.0;
}

const AlwaysDismissedAnimation kAlwaysDismissedAnimation = const AlwaysDismissedAnimation();

class ProxyAnimation extends Animated<double>
  with LazyListenerMixin, LocalPerformanceListenersMixin, LocalPerformanceStatusListenersMixin {
  ProxyAnimation([Animated<double> animation]) {
    _masterAnimation = animation;
    if (_masterAnimation == null) {
      _status = PerformanceStatus.dismissed;
      _direction = AnimationDirection.forward;
      _value = 0.0;
    }
  }

  PerformanceStatus _status;
  AnimationDirection _direction;
  double _value;

  Animated<double> get masterAnimation => _masterAnimation;
  Animated<double> _masterAnimation;
  void set masterAnimation(Animated<double> value) {
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

  PerformanceStatus get status => _masterAnimation != null ? _masterAnimation.status : _status;
  AnimationDirection get direction => _masterAnimation != null ? _masterAnimation.direction : _direction;
  double get value => _masterAnimation != null ? _masterAnimation.value : _value;
}

class ReverseAnimation extends Animated<double>
  with LazyListenerMixin, LocalPerformanceStatusListenersMixin {
  ReverseAnimation(this.masterAnimation);

  final Animated<double> masterAnimation;

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

  void _statusChangeHandler(PerformanceStatus status) {
    notifyStatusListeners(_reverseStatus(status));
  }

  PerformanceStatus get status => _reverseStatus(masterAnimation.status);
  AnimationDirection get direction => _reverseDirection(masterAnimation.direction);
  double get value => 1.0 - masterAnimation.value;

  PerformanceStatus _reverseStatus(PerformanceStatus status) {
    switch (status) {
      case PerformanceStatus.forward: return PerformanceStatus.reverse;
      case PerformanceStatus.reverse: return PerformanceStatus.forward;
      case PerformanceStatus.completed: return PerformanceStatus.dismissed;
      case PerformanceStatus.dismissed: return PerformanceStatus.completed;
    }
  }

  AnimationDirection _reverseDirection(AnimationDirection direction) {
    switch (direction) {
      case AnimationDirection.forward: return AnimationDirection.reverse;
      case AnimationDirection.reverse: return AnimationDirection.forward;
    }
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
class TrainHoppingAnimation extends Animated<double>
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

  Animated<double> get currentTrain => _currentTrain;
  Animated<double> _currentTrain;
  Animated<double> _nextTrain;
  _TrainHoppingMode _mode;

  VoidCallback onSwitchedTrain;

  PerformanceStatus _lastStatus;
  void _statusChangeHandler(PerformanceStatus status) {
    assert(_currentTrain != null);
    if (status != _lastStatus) {
      notifyListeners();
      _lastStatus = status;
    }
    assert(_lastStatus != null);
  }

  PerformanceStatus get status => _currentTrain.status;
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
