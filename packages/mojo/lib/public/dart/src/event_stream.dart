// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class MojoEventStream extends Stream<List<int>> {
  // The underlying Mojo handle.
  MojoHandle _handle;

  // Providing our own stream controller allows us to take custom actions when
  // listeners pause/resume/etc. their StreamSubscription.
  StreamController _controller;

  // The send port that we give to the handle watcher to notify us of handle
  // events.
  SendPort _sendPort;

  // The receive port on which we listen and receive events from the handle
  // watcher.
  ReceivePort _receivePort;

  // The signals on this handle that we're interested in.
  MojoHandleSignals _signals;

  // Whether listen has been called.
  bool _isListening;

  MojoEventStream(MojoHandle handle,
      [MojoHandleSignals signals = MojoHandleSignals.PEER_CLOSED_READABLE])
      : _handle = handle,
        _signals = signals,
        _isListening = false {
    MojoResult result = MojoHandle.register(this);
    if (!result.isOk) {
      throw "Failed to register the MojoHandle: $result.";
    }
  }

  Future close() {
    if (_handle != null) {
      if (_isListening) {
        return _handleWatcherClose();
      } else {
        _localClose();
        return new Future.value(null);
      }
    }
  }

  StreamSubscription<List<int>> listen(void onData(List event),
      {Function onError, void onDone(), bool cancelOnError}) {
    if (_isListening) {
      throw "Listen has already been called: $_handle.";
    }
    _receivePort = new ReceivePort();
    _sendPort = _receivePort.sendPort;
    _controller = new StreamController(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onCancel: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange);
    _controller.addStream(_receivePort).whenComplete(_controller.close);

    if (_signals != MojoHandleSignals.NONE) {
      var res = MojoHandleWatcher.add(_handle, _sendPort, _signals.value);
      if (!res.isOk) {
        throw "MojoHandleWatcher add failed: $res";
      }
    }

    _isListening = true;
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  void enableSignals(MojoHandleSignals signals) {
    _signals = signals;
    if (_isListening) {
      var res = MojoHandleWatcher.add(_handle, _sendPort, signals.value);
      if (!res.isOk) {
        throw "MojoHandleWatcher add failed: $res";
      }
    }
  }

  void enableReadEvents() =>
      enableSignals(MojoHandleSignals.PEER_CLOSED_READABLE);
  void enableWriteEvents() => enableSignals(MojoHandleSignals.WRITABLE);
  void enableAllEvents() => enableSignals(MojoHandleSignals.READWRITE);

  Future _handleWatcherClose() {
    assert(_handle != null);
    return MojoHandleWatcher.close(_handle, wait: true).then((_) {
      if (_receivePort != null) {
        _receivePort.close();
        _receivePort = null;
      }
    });
  }

  void _localClose() {
    assert(_handle != null);
    _handle.close();
    _handle = null;
    if (_receivePort != null) {
      _receivePort.close();
      _receivePort = null;
    }
  }

  void _onSubscriptionStateChange() {
    if (!_controller.hasListener) {
      close();
    }
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      var res = MojoHandleWatcher.remove(_handle);
      if (!res.isOk) {
        throw "MojoHandleWatcher add failed: $res";
      }
    } else {
      var res = MojoHandleWatcher.add(_handle, _sendPort, _signals.value);
      if (!res.isOk) {
        throw "MojoHandleWatcher add failed: $res";
      }
    }
  }

  bool get readyRead => _handle.readyRead;
  bool get readyWrite => _handle.readyWrite;

  String toString() => "$_handle";
}

typedef void ErrorHandler();

class MojoEventStreamListener {
  MojoMessagePipeEndpoint _endpoint;
  MojoEventStream _eventStream;
  bool _isOpen = false;
  bool _isInHandler = false;
  StreamSubscription subscription;
  ErrorHandler onError;

  MojoEventStreamListener.fromEndpoint(MojoMessagePipeEndpoint endpoint)
      : _endpoint = endpoint,
        _eventStream = new MojoEventStream(endpoint.handle),
        _isOpen = false {
    listen();
  }

  MojoEventStreamListener.fromHandle(MojoHandle handle) {
    _endpoint = new MojoMessagePipeEndpoint(handle);
    _eventStream = new MojoEventStream(handle);
    _isOpen = false;
    listen();
  }

  MojoEventStreamListener.unbound()
      : _endpoint = null,
        _eventStream = null,
        _isOpen = false;

  void bind(MojoMessagePipeEndpoint endpoint) {
    assert(!isBound);
    _endpoint = endpoint;
    _eventStream = new MojoEventStream(endpoint.handle);
    _isOpen = false;
  }

  void bindFromHandle(MojoHandle handle) {
    assert(!isBound);
    _endpoint = new MojoMessagePipeEndpoint(handle);
    _eventStream = new MojoEventStream(handle);
    _isOpen = false;
  }

  StreamSubscription<List<int>> listen() {
    assert(isBound && (subscription == null));
    _isOpen = true;
    subscription = _eventStream.listen((List<int> event) {
      if (!_isOpen) {
        // The actual close of the underlying stream happens asynchronously
        // after the call to close. However, we start to ignore incoming events
        // immediately.
        return;
      }
      var signalsWatched = new MojoHandleSignals(event[0]);
      var signalsReceived = new MojoHandleSignals(event[1]);
      _isInHandler = true;
      if (signalsReceived.isReadable) {
        assert(_eventStream.readyRead);
        handleRead();
      }
      if (signalsReceived.isWritable) {
        assert(_eventStream.readyWrite);
        handleWrite();
      }
      if (_isOpen) {
        _eventStream.enableSignals(signalsWatched);
      }
      _isInHandler = false;
      if (signalsReceived.isPeerClosed) {
        if (onError != null) {
          onError();
        }
        close();
      }
    }, onDone: close);
    return subscription;
  }

  Future close() {
    var result;
    _isOpen = false;
    _endpoint = null;
    subscription = null;
    if (_eventStream != null) {
      result = _eventStream.close().then((_) {
        _eventStream = null;
      });
    }
    return result != null ? result : new Future.value(null);
  }

  void handleRead() {}
  void handleWrite() {}

  MojoMessagePipeEndpoint get endpoint => _endpoint;
  bool get isOpen => _isOpen;
  bool get isInHandler => _isInHandler;
  bool get isBound => _endpoint != null;

  String toString() => "MojoEventStreamListener("
      "isOpen: $isOpen, isBound: $isBound, endpoint: $_endpoint)";
}
