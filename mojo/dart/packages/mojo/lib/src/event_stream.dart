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

  Future close({bool immediate: false}) => _close(immediate: immediate);

  void subscribe(void handler(int event)) {
    if (_isSubscribed) {
      throw new MojoApiError("subscribe() has already been called: $this.");
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
    _handle.close();
    _handle = null;
    if (_receivePort != null) {
      _receivePort.close();
      _receivePort = null;
    }
  }

  bool get readyRead => _handle.readyRead;
  bool get readyWrite => _handle.readyWrite;
  int get signals => _signals;

  String toString() => "$_handle";
}

typedef void ErrorHandler(Object e);

class MojoEventHandler {
  ErrorHandler onError;

  MojoMessagePipeEndpoint _endpoint;
  MojoEventSubscription _eventSubscription;
  bool _isOpen = false;
  bool _isInHandler = false;
  bool _isPeerClosed = false;

  MojoEventHandler.fromEndpoint(MojoMessagePipeEndpoint endpoint)
      : _endpoint = endpoint,
        _eventSubscription = new MojoEventSubscription(endpoint.handle) {
    beginHandlingEvents();
  }

  MojoEventHandler.fromHandle(MojoHandle handle)
      : _endpoint = new MojoMessagePipeEndpoint(handle),
        _eventSubscription = new MojoEventSubscription(handle) {
    beginHandlingEvents();
  }

  MojoEventHandler.unbound();

  void bind(MojoMessagePipeEndpoint endpoint) {
    if (isBound) {
      throw new MojoApiError("MojoEventStreamListener is already bound.");
    }
    _endpoint = endpoint;
    _eventSubscription = new MojoEventSubscription(endpoint.handle);
    _isOpen = false;
    _isInHandler = false;
    _isPeerClosed = false;
  }

  void bindFromHandle(MojoHandle handle) {
    if (isBound) {
      throw new MojoApiError("MojoEventStreamListener is already bound.");
    }
    _endpoint = new MojoMessagePipeEndpoint(handle);
    _eventSubscription = new MojoEventSubscription(handle);
    _isOpen = false;
    _isInHandler = false;
    _isPeerClosed = false;
  }

  void beginHandlingEvents() {
    if (!isBound) {
      throw new MojoApiError("MojoEventHandler is unbound.");
    }
    _isOpen = true;
    _eventSubscription.subscribe((int event) {
      try {
        _handleEvent(event);
      } catch (e) {
        close(immediate: true).then((_) {
          if (onError != null) {
            onError(e);
          }
        });
      }
    });
  }

  Future close({bool immediate: false}) {
    var result;
    _isOpen = false;
    _endpoint = null;
    if (_eventSubscription != null) {
      result = _eventSubscription
          ._close(immediate: immediate, local: _isPeerClosed)
          .then((_) {
        _eventSubscription = null;
      });
    }
    return result != null ? result : new Future.value(null);
  }

  void _handleEvent(int signalsReceived) {
    if (!_isOpen) {
      // The actual close of the underlying stream happens asynchronously
      // after the call to close. However, we start to ignore incoming events
      // immediately.
      return;
    }
    _isInHandler = true;
    if (MojoHandleSignals.isReadable(signalsReceived)) {
      assert(_eventSubscription.readyRead);
      handleRead();
    }
    if (MojoHandleSignals.isWritable(signalsReceived)) {
      assert(_eventSubscription.readyWrite);
      handleWrite();
    }
    _isPeerClosed = MojoHandleSignals.isPeerClosed(signalsReceived) ||
        !_eventSubscription.enableSignals();
    _isInHandler = false;
    if (_isPeerClosed) {
      close().then((_) {
        if (onError != null) {
          onError(null);
        }
      });
    }
  }

  void handleRead() {}
  void handleWrite() {}

  MojoMessagePipeEndpoint get endpoint => _endpoint;
  bool get isOpen => _isOpen;
  bool get isInHandler => _isInHandler;
  bool get isBound => _endpoint != null;
  bool get isPeerClosed => _isPeerClosed;

  String toString() => "MojoEventHandler("
      "isOpen: $isOpen, isBound: $isBound, endpoint: $_endpoint)";
}
