// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of internal;

/// This class contains static methods to send a stream of events to application
/// isolates that register Mojo handles with it.
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

  /// Stops watching and closes the given [handleToken].
  ///
  /// Returns an integer, encoding the result as specified in the [MojoResult]
  /// class. In particular, a successful operation returns [MojoResult.kOk].
  ///
  /// Notifies the HandleWatcherIsolate that a handle it is
  /// watching should be removed from its set and closed.
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  ///
  /// If [wait] is true, returns a future that resolves only after the handle
  // has actually been closed by the handle watcher. Otherwise, returns a
  // future that resolves immediately.
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

  /// Starts watching for events on the given [handleToken].
  ///
  /// Returns an integer, encoding the result as specified in the [MojoResult]
  /// class. In particular, a successful operation returns [MojoResult.kOk].
  ///
  /// Instructs the MojoHandleWatcher isolate to add [handleToken] to the set of
  /// handles it watches, and to notify the calling isolate only for the events
  /// specified by [signals] using the send port [port].
  // TODO(floitsch): what does "MojoHandleWatcher isolate" mean?
  // TODO(floitsch): what is the calling isolate?
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  ///
  /// The filtering [signals] are encoded as specified in the
  /// [MojoHandleSignals] class. For example, setting [signals] to
  /// [MojoHandleSignals.kPeerClosedReadable] instructs the handle watcher to
  /// notify the caller, when the handle becomes readable (that is, has data
  /// available for reading), or when it is closed.
  static int add(int handleToken, SendPort port, int signals) {
    return _sendControlData(_ADD, handleToken, port, signals);
  }

  /// Stops watching the given [handleToken].
  ///
  /// Returns an integer, encoding the result as specified in the [MojoResult]
  /// class. In particular, a successful operation returns [MojoResult.kOk].
  ///
  /// Instructs the MojoHandleWatcher isolate to remove [handleToken] from the
  /// set of handles it watches. This allows the application isolate
  /// to, for example, pause the stream of events.
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  static int remove(int handleToken) {
    return _sendControlData(_REMOVE, handleToken, null, 0);
  }

  /// Requests a notification on the given [port] at [deadline].
  ///
  /// Returns an integer, encoding the result as specified in the [MojoResult]
  /// class. In particular, a successful operation returns [MojoResult.kOk].
  ///
  /// The [deadline] is in milliseconds, with
  /// [MojoCoreNatives.timerMillisecondClock] as reference.
  ///
  /// If the given [port] was already registered for a timer (in any isolate),
  /// then the old value is discarded.
  ///
  /// A negative [deadline] is used to remove a port. That is, a negative value
  /// is ignored after any existing value for the port has been discarded.
  static int timer(Object ignored, SendPort port, int deadline) {
    // The deadline will be unwrapped before sending to the handle watcher.
    return _sendControlData(_TIMER, deadline, port, 0);
  }
}
