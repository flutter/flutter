// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "async_patch.dart";

@patch
class Timer {
  @patch
  static Timer _createTimer(Duration duration, void callback()) {
    final factory = VMLibraryHooks.timerFactory;
    if (factory == null) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return factory(milliseconds, (_) {
      callback();
    }, false);
  }

  @patch
  static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
    final factory = VMLibraryHooks.timerFactory;
    if (factory == null) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return factory(milliseconds, callback, true);
  }
}
