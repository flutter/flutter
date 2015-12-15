// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

/// Prints a message to the console, which you can access using the "flutter"
/// tool's "logs" command ("flutter logs").
///
/// This function very crudely attempts to throttle the rate at which messages
/// are sent to avoid data loss on Android. This means that interleaving calls
/// to this function (directly or indirectly via [debugDumpRenderTree] or
/// [debugDumpApp]) and to the Dart [print] method can result in out-of-order
/// messages in the logs.
void debugPrint(String message) {
  _debugPrintBuffer.addAll(message.split('\n'));
  if (!_debugPrintScheduled)
    _debugPrintTask();
}
int _debugPrintedCharacters = 0;
int _kDebugPrintCapacity = 16 * 1024;
Duration _kDebugPrintPauseTime = const Duration(seconds: 1);
Queue<String> _debugPrintBuffer = new Queue<String>();
Stopwatch _debugPrintStopwatch = new Stopwatch();
bool _debugPrintScheduled = false;
void _debugPrintTask() {
  _debugPrintScheduled = false;
  if (_debugPrintStopwatch.elapsed > _kDebugPrintPauseTime) {
    _debugPrintStopwatch.stop();
    _debugPrintStopwatch.reset();
    _debugPrintedCharacters = 0;
  }
  while (_debugPrintedCharacters < _kDebugPrintCapacity && _debugPrintBuffer.length > 0) {
    String line = _debugPrintBuffer.removeFirst();
    _debugPrintedCharacters += line.length; // TODO(ianh): Use the UTF-8 byte length instead
    print(line);
  }
  if (_debugPrintBuffer.length > 0) {
    _debugPrintScheduled = true;
    _debugPrintedCharacters = 0;
    new Timer(_kDebugPrintPauseTime, _debugPrintTask);
  } else {
    _debugPrintStopwatch.start();
  }
}
