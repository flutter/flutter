// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import '../web.dart' as web;

/// Dumps error messages to the console.
class ErrorToConsoleDumper {
  static final List<void Function(String message)> _listeners = <void Function(String message)>[];

  /// Dumps the given error [message] to the console.
  static void dump(String message) {
    web.console.error(message.toJS);
    _notifyListeners(message);
  }

  static void _notifyListeners(String message) {
    for (final void Function(String message) listener in _listeners) {
      listener(message);
    }
  }

  /// Adds a listener that captures error messages being dumped on the web.
  static void addWebDumpListener(void Function(String message) listener) {
    _listeners.add(listener);
  }

  /// Clears all listeners that capture error messages being dumped on the web.
  static void clearWebDumpListeners() {
    _listeners.clear();
  }
}
