// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show VoidCallback;

import 'package:flutter/foundation.dart';

import 'animation.dart';

abstract class _ListenerMixin {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory _ListenerMixin._() => null;

  void didRegisterListener();
  void didUnregisterListener();
}

/// A mixin that helps listen to another object only when this object has registered listeners.
abstract class AnimationLazyListenerMixin extends _ListenerMixin {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory AnimationLazyListenerMixin._() => null;

  int _listenerCounter = 0;

  @override
  void didRegisterListener() {
    assert(_listenerCounter >= 0);
    if (_listenerCounter == 0)
      didStartListening();
    _listenerCounter += 1;
  }

  @override
  void didUnregisterListener() {
    assert(_listenerCounter >= 1);
    _listenerCounter -= 1;
    if (_listenerCounter == 0)
      didStopListening();
  }

  /// Called when the number of listeners changes from zero to one.
  @protected
  void didStartListening();

  /// Called when the number of listeners changes from one to zero.
  @protected
  void didStopListening();

  /// Whether there are any listeners.
  bool get isListening => _listenerCounter > 0;
}

/// A mixin that replaces the didRegisterListener/didUnregisterListener contract
/// with a dispose contract.
abstract class AnimationEagerListenerMixin extends _ListenerMixin {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory AnimationEagerListenerMixin._() => null;

  @override
  void didRegisterListener() { }

  @override
  void didUnregisterListener() { }

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  @mustCallSuper
  void dispose() { }
}

/// A mixin that implements the [addListener]/[removeListener] protocol and notifies
/// all the registered listeners when [notifyListeners] is called.
abstract class AnimationLocalListenersMixin extends _ListenerMixin {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory AnimationLocalListenersMixin._() => null;

  final ObserverList<VoidCallback> _listeners = new ObserverList<VoidCallback>();

  /// Calls the listener every time the value of the animation changes.
  ///
  /// Listeners can be removed with [removeListener].
  void addListener(VoidCallback listener) {
    didRegisterListener();
    _listeners.add(listener);
  }

  /// Stop calling the listener every time the value of the animation changes.
  ///
  /// Listeners can be added with [addListener].
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    didUnregisterListener();
  }

  /// Calls all the listeners.
  ///
  /// If listeners are added or removed during this function, the modifications
  /// will not change which listeners are called during this iteration.
  void notifyListeners() {
    final List<VoidCallback> localListeners = new List<VoidCallback>.from(_listeners);
    for (VoidCallback listener in localListeners) {
      try {
        if (_listeners.contains(listener))
          listener();
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'animation library',
          context: 'while notifying listeners for $runtimeType',
          informationCollector: (StringBuffer information) {
            information.writeln('The $runtimeType notifying listeners was:');
            information.write('  $this');
          }
        ));
      }
    }
  }
}

/// A mixin that implements the addStatusListener/removeStatusListener protocol
/// and notifies all the registered listeners when notifyStatusListeners is
/// called.
abstract class AnimationLocalStatusListenersMixin extends _ListenerMixin {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory AnimationLocalStatusListenersMixin._() => null;

  final ObserverList<AnimationStatusListener> _statusListeners = new ObserverList<AnimationStatusListener>();

  /// Calls listener every time the status of the animation changes.
  ///
  /// Listeners can be removed with [removeStatusListener].
  void addStatusListener(AnimationStatusListener listener) {
    didRegisterListener();
    _statusListeners.add(listener);
  }

  /// Stops calling the listener every time the status of the animation changes.
  ///
  /// Listeners can be added with [addStatusListener].
  void removeStatusListener(AnimationStatusListener listener) {
    _statusListeners.remove(listener);
    didUnregisterListener();
  }

  /// Calls all the status listeners.
  ///
  /// If listeners are added or removed during this function, the modifications
  /// will not change which listeners are called during this iteration.
  void notifyStatusListeners(AnimationStatus status) {
    final List<AnimationStatusListener> localListeners = new List<AnimationStatusListener>.from(_statusListeners);
    for (AnimationStatusListener listener in localListeners) {
      try {
        if (_statusListeners.contains(listener))
          listener(status);
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'animation library',
          context: 'while notifying status listeners for $runtimeType',
          informationCollector: (StringBuffer information) {
            information.writeln('The $runtimeType notifying status listeners was:');
            information.write('  $this');
          }
        ));
      }
    }
  }
}
