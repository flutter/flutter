// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The following code is copied from sdk/lib/io/io_sink.dart. The "dart:io"
// implementation isn't used directly to support non-"dart:io" applications.
//
// Because it's copied directly, only modifications necessary to support the
// desired public API and to remove "dart:io" dependencies have been made.
//
// This is up-to-date as of sdk revision
// 365f7b5a8b6ef900a5ee23913b7203569b81b175.

import 'dart:async';

class StreamSinkImpl<T> implements StreamSink<T> {
  final StreamConsumer<T> _target;
  final Completer _doneCompleter = Completer();
  StreamController<T>? _controllerInstance;
  Completer? _controllerCompleter;
  bool _isClosed = false;
  bool _isBound = false;
  bool _hasError = false;

  StreamSinkImpl(this._target);

  // The _reportClosedSink method has been deleted for web_socket_channel. This
  // method did nothing but print to stderr, which is unavailable here.

  @override
  void add(T data) {
    if (_isClosed) {
      return;
    }
    _controller.add(data);
  }

  @override
  void addError(error, [StackTrace? stackTrace]) {
    if (_isClosed) {
      return;
    }
    _controller.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<T> stream) {
    if (_isBound) {
      throw StateError('StreamSink is already bound to a stream');
    }
    if (_hasError) return done;

    _isBound = true;
    final future = _controllerCompleter == null
        ? _target.addStream(stream)
        : _controllerCompleter!.future.then((_) => _target.addStream(stream));
    _controllerInstance?.close();

    // Wait for any pending events in [_controller] to be dispatched before
    // adding [stream].
    return future.whenComplete(() {
      _isBound = false;
    });
  }

  Future flush() {
    if (_isBound) {
      throw StateError('StreamSink is bound to a stream');
    }
    if (_controllerInstance == null) return Future.value(this);
    // Adding an empty stream-controller will return a future that will complete
    // when all data is done.
    _isBound = true;
    final future = _controllerCompleter!.future;
    _controllerInstance!.close();
    return future.whenComplete(() {
      _isBound = false;
    });
  }

  @override
  Future close() {
    if (_isBound) {
      throw StateError('StreamSink is bound to a stream');
    }
    if (!_isClosed) {
      _isClosed = true;
      if (_controllerInstance != null) {
        _controllerInstance!.close();
      } else {
        _closeTarget();
      }
    }
    return done;
  }

  void _closeTarget() {
    _target.close().then(_completeDoneValue, onError: _completeDoneError);
  }

  @override
  Future get done => _doneCompleter.future;

  void _completeDoneValue(value) {
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete(value);
    }
  }

  void _completeDoneError(Object error, StackTrace stackTrace) {
    if (!_doneCompleter.isCompleted) {
      _hasError = true;
      _doneCompleter.completeError(error, stackTrace);
    }
  }

  StreamController<T> get _controller {
    if (_isBound) {
      throw StateError('StreamSink is bound to a stream');
    }
    if (_isClosed) {
      throw StateError('StreamSink is closed');
    }
    if (_controllerInstance == null) {
      _controllerInstance = StreamController<T>(sync: true);
      _controllerCompleter = Completer();
      _target.addStream(_controller.stream).then((_) {
        if (_isBound) {
          // A new stream takes over - forward values to that stream.
          _controllerCompleter!.complete(this);
          _controllerCompleter = null;
          _controllerInstance = null;
        } else {
          // No new stream, .close was called. Close _target.
          _closeTarget();
        }
      }, onError: (Object error, StackTrace stackTrace) {
        if (_isBound) {
          // A new stream takes over - forward errors to that stream.
          _controllerCompleter!.completeError(error, stackTrace);
          _controllerCompleter = null;
          _controllerInstance = null;
        } else {
          // No new stream. No need to close target, as it has already
          // failed.
          _completeDoneError(error, stackTrace);
        }
      });
    }
    return _controllerInstance!;
  }
}
