// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

typedef void ShutdownListener();

class _Lifecycle {
  _Lifecycle() {
    ui.lifecycleHooks.onShutdown = _handleShutdown;
  }

  final List<ShutdownListener> _shutdownListeners = new List<ShutdownListener>();

  void _handleShutdown() {
    for (ShutdownListener listener in _shutdownListeners)
      listener();
  }

  /// Calls listener before app shutdown.
  void addShutdownListener(ShutdownListener listener) {
    _shutdownListeners.add(listener);
  }

  /// Stops calling listener before app shutdown.
  bool removeShutdownListener(ShutdownListener listener) {
    _shutdownListeners.remove(listener);
  }
}

final _Lifecycle lifecycle = new _Lifecycle();
