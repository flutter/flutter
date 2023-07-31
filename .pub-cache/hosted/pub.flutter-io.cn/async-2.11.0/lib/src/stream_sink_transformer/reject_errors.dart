// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A [StreamSink] wrapper that rejects all errors passed into the sink.
class RejectErrorsSink<T> implements StreamSink<T> {
  /// The target sink.
  final StreamSink<T> _inner;

  @override
  Future<void> get done => _doneCompleter.future;
  final _doneCompleter = Completer<void>();

  /// Whether the user has called [close].
  ///
  /// If [_closed] is true, [_canceled] must be true and [_inAddStream] must be
  /// false.
  bool _closed = false;

  /// The subscription to the stream passed to [addStream], if a stream is
  /// currently being added.
  StreamSubscription<T>? _addStreamSubscription;

  /// The completer for the future returned by [addStream], if a stream is
  /// currently being added.
  Completer<void>? _addStreamCompleter;

  /// Whether we're currently adding a stream with [addStream].
  bool get _inAddStream => _addStreamSubscription != null;

  RejectErrorsSink(this._inner) {
    _inner.done.then((value) {
      _cancelAddStream();
      if (!_canceled) _doneCompleter.complete(value);
    }).onError<Object>((error, stackTrace) {
      _cancelAddStream();
      if (!_canceled) _doneCompleter.completeError(error, stackTrace);
    });
  }

  /// Whether the underlying sink is no longer receiving events.
  ///
  /// This can happen if:
  ///
  /// * [close] has been called,
  /// * an error has been passed,
  /// * or the underlying [StreamSink.done] has completed.
  ///
  /// If [_canceled] is true, [_inAddStream] must be false.
  bool get _canceled => _doneCompleter.isCompleted;

  @override
  void add(T data) {
    if (_closed) throw StateError('Cannot add event after closing.');
    if (_inAddStream) {
      throw StateError('Cannot add event while adding stream.');
    }
    if (_canceled) return;

    _inner.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_closed) throw StateError('Cannot add event after closing.');
    if (_inAddStream) {
      throw StateError('Cannot add event while adding stream.');
    }
    if (_canceled) return;

    _addError(error, stackTrace);
  }

  /// Like [addError], but doesn't check to ensure that an error can be added.
  ///
  /// This is called from [addStream], so it shouldn't fail if a stream is being
  /// added.
  void _addError(Object error, [StackTrace? stackTrace]) {
    _cancelAddStream();
    _doneCompleter.completeError(error, stackTrace);

    // Ignore errors from the inner sink. We're already surfacing one error, and
    // if the user handles it we don't want them to have another top-level.
    _inner.close().catchError((_) {});
  }

  @override
  Future<void> addStream(Stream<T> stream) {
    if (_closed) throw StateError('Cannot add stream after closing.');
    if (_inAddStream) {
      throw StateError('Cannot add stream while adding stream.');
    }
    if (_canceled) return Future.value();

    var addStreamCompleter = _addStreamCompleter = Completer.sync();
    _addStreamSubscription = stream.listen(_inner.add,
        onError: _addError, onDone: addStreamCompleter.complete);
    return addStreamCompleter.future.then((_) {
      _addStreamCompleter = null;
      _addStreamSubscription = null;
    });
  }

  @override
  Future<void> close() {
    if (_inAddStream) {
      throw StateError('Cannot close sink while adding stream.');
    }

    if (_closed) return done;
    _closed = true;

    if (!_canceled) {
      // ignore: void_checks
      _doneCompleter.complete(_inner.close());
    }
    return done;
  }

  /// If an [addStream] call is active, cancel its subscription and complete its
  /// completer.
  void _cancelAddStream() {
    if (!_inAddStream) return;
    _addStreamCompleter!.complete(_addStreamSubscription!.cancel());
    _addStreamCompleter = null;
    _addStreamSubscription = null;
  }
}
