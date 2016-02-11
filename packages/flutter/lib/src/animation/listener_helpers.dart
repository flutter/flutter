// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show VoidCallback;

import 'animation.dart';

abstract class _ListenerMixin {
  void didRegisterListener();
  void didUnregisterListener();
}

/// A mixin that helps listen to another object only when this object has registered listeners.
abstract class AnimationLazyListenerMixin implements _ListenerMixin {
  int _listenerCounter = 0;
  void didRegisterListener() {
    assert(_listenerCounter >= 0);
    if (_listenerCounter == 0)
      didStartListening();
    _listenerCounter += 1;
  }
  void didUnregisterListener() {
    assert(_listenerCounter >= 1);
    _listenerCounter -= 1;
    if (_listenerCounter == 0)
      didStopListening();
  }
  void didStartListening();
  void didStopListening();
  bool get isListening => _listenerCounter > 0;
}

/// A mixin that replaces the didRegisterListener/didUnregisterListener contract
/// with a dispose contract.
abstract class AnimationEagerListenerMixin implements _ListenerMixin {
  void didRegisterListener() { }
  void didUnregisterListener() { }

  /// Release any resources used by this object.
  void dispose();
}

/// A mixin that implements the addListener/removeListener protocol and notifies
/// all the registered listeners when notifyListeners is invoked.
abstract class AnimationLocalListenersMixin extends _ListenerMixin {
  final List<VoidCallback> _listeners = <VoidCallback>[];
  void addListener(VoidCallback listener) {
    didRegisterListener();
    _listeners.add(listener);
  }
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    didUnregisterListener();
  }
  void notifyListeners() {
    List<VoidCallback> localListeners = new List<VoidCallback>.from(_listeners);
    for (VoidCallback listener in localListeners)
      listener();
  }
}

/// A mixin that implements the addStatusListener/removeStatusListener protocol
/// and notifies all the registered listeners when notifyStatusListeners is
/// invoked.
abstract class AnimationLocalStatusListenersMixin extends _ListenerMixin {
  final List<AnimationStatusListener> _statusListeners = <AnimationStatusListener>[];
  void addStatusListener(AnimationStatusListener listener) {
    didRegisterListener();
    _statusListeners.add(listener);
  }
  void removeStatusListener(AnimationStatusListener listener) {
    _statusListeners.remove(listener);
    didUnregisterListener();
  }
  void notifyStatusListeners(AnimationStatus status) {
    List<AnimationStatusListener> localListeners = new List<AnimationStatusListener>.from(_statusListeners);
    for (AnimationStatusListener listener in localListeners)
      listener(status);
  }
}
