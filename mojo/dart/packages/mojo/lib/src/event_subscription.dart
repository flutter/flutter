// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class MojoEventSubscription {
  // The underlying Mojo handle.
  MojoHandle _handle;

  // The send port that we give to the handle watcher to notify us of handle
  // events.
  SendPort _sendPort;

  // The receive port on which we listen and receive events from the handle
  // watcher.
  RawReceivePort _receivePort;

  // The signals on this handle that we're interested in.
  int _signals;

  // Whether subscribe() has been called.
  bool _isSubscribed;

  MojoEventSubscription(MojoHandle handle,
      [int signals = MojoHandleSignals.kPeerClosedReadable])
      : _handle = handle,
        _signals = signals,
        _isSubscribed = false {
    if (!MojoHandle.registerFinalizer(this)) {
      throw new MojoInternalError("Failed to register the MojoHandle.");
    }
  }

  bool get readyRead => _handle.readyRead;
  bool get readyWrite => _handle.readyWrite;
  int get signals => _signals;

  Future close({bool immediate: false}) => _close(immediate: immediate);

  void subscribe(void handler(int event)) {
    if (_isSubscribed) {
      throw new MojoApiError("Already subscribed: $this.");
    }
    _receivePort = new RawReceivePort(handler);
    _sendPort = _receivePort.sendPort;

    if (_signals != MojoHandleSignals.kNone) {
      int res = MojoHandleWatcher.add(_handle.h, _sendPort, _signals);
      if (res != MojoResult.kOk) {
        throw new MojoInternalError("MojoHandleWatcher add failed: $res");
      }
    }
    _isSubscribed = true;
  }

  bool enableSignals([int signals]) {
    if (signals != null) {
      _signals = signals;
    }
    if (_isSubscribed) {
      return MojoHandleWatcher.add(_handle.h, _sendPort, _signals) ==
          MojoResult.kOk;
    }
    return false;
  }

  bool enableReadEvents() =>
      enableSignals(MojoHandleSignals.kPeerClosedReadable);
  bool enableWriteEvents() => enableSignals(MojoHandleSignals.kWritable);
  bool enableAllEvents() => enableSignals(MojoHandleSignals.kReadWrite);

  /// End the subscription by removing the handle from the handle watcher and
  /// closing the Dart port, but do not close the underlying handle. The handle
  /// can then be reused, or closed at a later time.
  void unsubscribe({bool immediate: false}) {
    if ((_handle == null) || !_isSubscribed || (_receivePort == null)) {
      throw new MojoApiError("Cannont unsubscribe from a MojoEventSubscription "
                             "that has not been subscribed to");
    }
    MojoHandleWatcher.remove(_handle.h);
    _receivePort.close();
    _receivePort = null;
    _sendPort = null;
    _isSubscribed = false;
  }

  @override
  String toString() => "$_handle";

  Future _close({bool immediate: false, bool local: false}) {
    if (_handle != null) {
      if (_isSubscribed && !local) {
        return _handleWatcherClose(immediate: immediate).then((result) {
          // If the handle watcher is gone, then close the handle ourselves.
          if (result != MojoResult.kOk) {
            _localClose();
          }
        });
      } else {
        _localClose();
      }
    }
    return new Future.value(null);
  }

  Future _handleWatcherClose({bool immediate: false}) {
    assert(_handle != null);
    MojoHandleNatives.removeOpenHandle(_handle.h);
    return MojoHandleWatcher.close(_handle.h, wait: !immediate).then((r) {
      if (_receivePort != null) {
        _receivePort.close();
        _receivePort = null;
      }
      return r;
    });
  }

  void _localClose() {
    if (_handle != null) {
      _handle.close();
      _handle = null;
    }
    if (_receivePort != null) {
      _receivePort.close();
      _receivePort = null;
    }
  }
}
