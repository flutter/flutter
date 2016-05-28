// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of internal;

class MojoHandleWatcher {
  // Control commands.
  static const int _ADD = 0;
  static const int _REMOVE = 1;
  static const int _CLOSE = 2;
  static const int _TIMER = 3;
  static const int _SHUTDOWN = 4;

  static const int _kMojoHandleInvalid = 0;
  static const int _kMojoResultFailedPrecondition = 9;

  static int mojoControlHandle;

  static int _sendControlData(int command,
                              int handleOrDeadline,
                              SendPort port,
                              int signals) {
    int controlHandle = mojoControlHandle;
    if (controlHandle == _kMojoHandleInvalid) {
      return _kMojoResultFailedPrecondition;
    }
    var result = _MojoHandleWatcherNatives.sendControlData(
        controlHandle, command, handleOrDeadline, port, signals);
    return result;
  }

  static Future<int> close(int handleToken, {bool wait: false}) {
    if (!wait) {
      return new Future.value(_sendControlData(_CLOSE, handleToken, null, 0));
    }
    int result;
    var completer = new Completer();
    var rawPort = new RawReceivePort((_) {
      completer.complete(result);
    });
    result = _sendControlData(_CLOSE, handleToken, rawPort.sendPort, 0);
    return completer.future.then((r) {
      rawPort.close();
      return r;
    });
  }

  static int add(int handleToken, SendPort port, int signals) {
    return _sendControlData(_ADD, handleToken, port, signals);
  }

  static int remove(int handleToken) {
    return _sendControlData(_REMOVE, handleToken, null, 0);
  }

  static int timer(Object ignored, SendPort port, int deadline) {
    // The deadline will be unwrapped before sending to the handle watcher.
    return _sendControlData(_TIMER, deadline, port, 0);
  }
}
