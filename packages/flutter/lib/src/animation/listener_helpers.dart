// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show VoidCallback;

/// The status of an animation
enum PerformanceStatus {
  /// The animation is stopped at the beginning
  dismissed,

  /// The animation is running from beginning to end
  forward,

  /// The animation is running backwards, from end to beginning
  reverse,

  /// The animation is stopped at the end
  completed,
}

typedef void PerformanceStatusListener(PerformanceStatus status);

abstract class _ListenerMixin {
  void didRegisterListener();
  void didUnregisterListener();
}

abstract class LazyListenerMixin implements _ListenerMixin {
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

abstract class EagerListenerMixin implements _ListenerMixin {
  void didRegisterListener() { }
  void didUnregisterListener() { }

  /// Release any resources used by this object.
  void dispose();
}

abstract class LocalPerformanceListenersMixin extends _ListenerMixin {
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

abstract class LocalPerformanceStatusListenersMixin extends _ListenerMixin {
  final List<PerformanceStatusListener> _statusListeners = <PerformanceStatusListener>[];
  void addStatusListener(PerformanceStatusListener listener) {
    didRegisterListener();
    _statusListeners.add(listener);
  }
  void removeStatusListener(PerformanceStatusListener listener) {
    _statusListeners.remove(listener);
    didUnregisterListener();
  }
  void notifyStatusListeners(PerformanceStatus status) {
    List<PerformanceStatusListener> localListeners = new List<PerformanceStatusListener>.from(_statusListeners);
    for (PerformanceStatusListener listener in localListeners)
      listener(status);
  }
}
