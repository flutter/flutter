// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of internal;

// The MojoHandleWatcher sends a stream of events to application isolates that
// register Mojo handles with it. Application isolates make the following calls:
//
// add(handle, port, signals) - Instructs the MojoHandleWatcher isolate to add
//     'handle' to the set of handles it watches, and to notify the calling
//     isolate only for the events specified by 'signals' using the send port
//     'port'
//
// remove(handle) - Instructs the MojoHandleWatcher isolate to remove 'handle'
//     from the set of handles it watches. This allows the application isolate
//     to, e.g., pause the stream of events.
//
// close(handle) - Notifies the HandleWatcherIsolate that a handle it is
//     watching should be removed from its set and closed.
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
    var result = MojoHandleWatcherNatives.sendControlData(
        controlHandle, command, handleOrDeadline, port, signals);
    return result;
  }

  // If wait is true, returns a future that resolves only after the handle
  // has actually been closed by the handle watcher. Otherwise, returns a
  // future that resolves immediately.
  static Future<int> close(int mojoHandle, {bool wait: false}) {
    if (!wait) {
      return new Future.value(_sendControlData(_CLOSE, mojoHandle, null, 0));
    }
    int result;
    var completer = new Completer();
    var rawPort = new RawReceivePort((_) {
      completer.complete(result);
    });
    result = _sendControlData(_CLOSE, mojoHandle, rawPort.sendPort, 0);
    return completer.future.then((r) {
      rawPort.close();
      return r;
    });
  }

  static int add(int mojoHandle, SendPort port, int signals) {
    return _sendControlData(_ADD, mojoHandle, port, signals);
  }

  static int remove(int mojoHandle) {
    return _sendControlData(_REMOVE, mojoHandle, null, 0);
  }

  static int timer(Object ignored, SendPort port, int deadline) {
    // The deadline will be unwrapped before sending to the handle watcher.
    return _sendControlData(_TIMER, deadline, port, 0);
  }
}
