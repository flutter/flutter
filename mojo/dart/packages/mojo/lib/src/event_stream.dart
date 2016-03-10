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

  bool get readyRead => _handle.readyRead;
  bool get readyWrite => _handle.readyWrite;
  int get signals => _signals;

  String toString() => "$_handle";
}

/// Object returned to pipe's error handlers containing both the thrown error
/// and the associated stack trace.
class MojoHandlerError {
  final Object error;
  final StackTrace stacktrace;

  MojoHandlerError(this.error, this.stacktrace);

  String toString() => error.toString();
}

typedef void ErrorHandler(MojoHandlerError e);

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
      throw new MojoApiError("MojoEventHandler is already bound.");
    }
    _endpoint = endpoint;
    _eventSubscription = new MojoEventSubscription(endpoint.handle);
    _isOpen = false;
    _isInHandler = false;
    _isPeerClosed = false;
  }

  void bindFromHandle(MojoHandle handle) {
    if (isBound) {
      throw new MojoApiError("MojoEventHandler is already bound.");
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
    if (_isOpen) {
      throw new MojoApiError("MojoEventHandler is already handling events");
    }
    _isOpen = true;
    _eventSubscription.subscribe(_tryHandleEvent);
  }

  /// [endHandlineEvents] unsubscribes from the underlying
  /// [MojoEventSubscription].
  void endHandlingEvents() {
    if (!isBound || !_isOpen || _isInHandler) {
      throw new MojoApiError(
          "MojoEventHandler was not handling events when instructed to end");
    }
    if (_isInHandler) {
      throw new MojoApiError(
          "Cannot end handling events from inside a callback");
    }
    _isOpen = false;
    _eventSubscription.unsubscribe();
  }

  /// [unbind] stops handling events, and returns the underlying
  /// [MojoMessagePipe]. The pipe can then be rebound to the same or different
  /// [MojoEventHandler], or closed. [unbind] cannot be called from within
  /// [handleRead] or [handleWrite].
  MojoMessagePipeEndpoint unbind() {
    if (!isBound) {
      throw new MojoApiError(
          "MojoEventHandler was not bound in call in unbind()");
    }
    if (_isOpen) {
      endHandlingEvents();
    }
    if (_isInHandler) {
      throw new MojoApiError(
          "Cannot unbind a MojoEventHandler from inside a callback.");
    }
    var boundEndpoint = _endpoint;
    _endpoint = null;
    _eventSubscription = null;
    return boundEndpoint;
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

  void _tryHandleEvent(int event) {
    // This callback is running in the handler for a RawReceivePort. All
    // exceptions rethrown or not caught here will be unhandled exceptions in
    // the root zone, bringing down the whole app. An app should rather have an
    // opportunity to handle exceptions coming from Mojo, like the
    // MojoCodecError.
    // TODO(zra): Rather than hard-coding a list of exceptions that bypass the
    // onError callback and are rethrown, investigate allowing an implementer to
    // provide a filter function (possibly initialized with a sensible default).
    try {
      _handleEvent(event);
    } on Error catch (_) {
      // An Error exception from the core libraries is probably a programming
      // error that can't be handled. We rethrow the error so that
      // MojoEventHandlers can't swallow it by mistake.
      rethrow;
    } catch (e, s) {
      close(immediate: true).then((_) {
        if (onError != null) {
          onError(new MojoHandlerError(e, s));
        }
      });
    }
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
      handleRead();
    }
    if (MojoHandleSignals.isWritable(signalsReceived)) {
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

  /// The event handler calls the [handleRead] method when the underlying Mojo
  /// message pipe endpoint has a message available to be read. Implementers
  /// should read, decode, and handle the message. If [handleRead] throws
  /// an exception derived from [Error], the exception will be thrown into the
  /// root zone, and the application will end. Otherwise, the exception object
  /// will be passed to [onError] if it has been set, and the exception will
  /// not be propagated to the root zone.
  void handleRead() {}

  /// Like [handleRead] but indicating that the underlying message pipe endpoint
  /// is ready for writing.
  void handleWrite() {}

  MojoMessagePipeEndpoint get endpoint => _endpoint;
  bool get isOpen => _isOpen;
  bool get isInHandler => _isInHandler;
  bool get isBound => _endpoint != null;
  bool get isPeerClosed => _isPeerClosed;

  String toString() => "MojoEventHandler("
      "isOpen: $_isOpen, isBound: $isBound, endpoint: $_endpoint)";
}
