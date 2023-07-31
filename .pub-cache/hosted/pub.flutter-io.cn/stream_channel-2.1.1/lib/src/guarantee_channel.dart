// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';

import '../stream_channel.dart';

/// A [StreamChannel] that enforces the stream channel guarantees.
///
/// This is exposed via [new StreamChannel.withGuarantees].
class GuaranteeChannel<T> extends StreamChannelMixin<T> {
  @override
  Stream<T> get stream => _streamController.stream;

  @override
  StreamSink<T> get sink => _sink;
  late final _GuaranteeSink<T> _sink;

  /// The controller for [stream].
  ///
  /// This intermediate controller allows us to continue listening for a done
  /// event even after the user has canceled their subscription, and to send our
  /// own done event when the sink is closed.
  late final StreamController<T> _streamController;

  /// The subscription to the inner stream.
  StreamSubscription<T>? _subscription;

  /// Whether the sink has closed, causing the underlying channel to disconnect.
  bool _disconnected = false;

  GuaranteeChannel(Stream<T> innerStream, StreamSink<T> innerSink,
      {bool allowSinkErrors = true}) {
    _sink = _GuaranteeSink<T>(innerSink, this, allowErrors: allowSinkErrors);

    // Enforce the single-subscription guarantee by changing a broadcast stream
    // to single-subscription.
    if (innerStream.isBroadcast) {
      innerStream =
          innerStream.transform(SingleSubscriptionTransformer<T, T>());
    }

    _streamController = StreamController<T>(
        onListen: () {
          // If the sink has disconnected, we've already called
          // [_streamController.close].
          if (_disconnected) return;

          _subscription = innerStream.listen(_streamController.add,
              onError: _streamController.addError, onDone: () {
            _sink._onStreamDisconnected();
            _streamController.close();
          });
        },
        sync: true);
  }

  /// Called by [_GuaranteeSink] when the user closes it.
  ///
  /// The sink closing indicates that the connection is closed, so the stream
  /// should stop emitting events.
  void _onSinkDisconnected() {
    _disconnected = true;
    var subscription = _subscription;
    if (subscription != null) subscription.cancel();
    _streamController.close();
  }
}

/// The sink for [GuaranteeChannel].
///
/// This wraps the inner sink to ignore events and cancel any in-progress
/// [addStream] calls when the underlying channel closes.
class _GuaranteeSink<T> implements StreamSink<T> {
  /// The inner sink being wrapped.
  final StreamSink<T> _inner;

  /// The [GuaranteeChannel] this belongs to.
  final GuaranteeChannel<T> _channel;

  @override
  Future<void> get done => _doneCompleter.future;
  final _doneCompleter = Completer();

  /// Whether connection is disconnected.
  ///
  /// This can happen because the stream has emitted a done event, or because
  /// the user added an error when [_allowErrors] is `false`.
  bool _disconnected = false;

  /// Whether the user has called [close].
  bool _closed = false;

  /// The subscription to the stream passed to [addStream], if a stream is
  /// currently being added.
  StreamSubscription<T>? _addStreamSubscription;

  /// The completer for the future returned by [addStream], if a stream is
  /// currently being added.
  Completer? _addStreamCompleter;

  /// Whether we're currently adding a stream with [addStream].
  bool get _inAddStream => _addStreamSubscription != null;

  /// Whether errors are passed on to the underlying sink.
  ///
  /// If this is `false`, any error passed to the sink is piped to [done] and
  /// the underlying sink is closed.
  final bool _allowErrors;

  _GuaranteeSink(this._inner, this._channel, {bool allowErrors = true})
      : _allowErrors = allowErrors;

  @override
  void add(T data) {
    if (_closed) throw StateError('Cannot add event after closing.');
    if (_inAddStream) {
      throw StateError('Cannot add event while adding stream.');
    }
    if (_disconnected) return;

    _inner.add(data);
  }

  @override
  void addError(error, [StackTrace? stackTrace]) {
    if (_closed) throw StateError('Cannot add event after closing.');
    if (_inAddStream) {
      throw StateError('Cannot add event while adding stream.');
    }
    if (_disconnected) return;

    _addError(error, stackTrace);
  }

  /// Like [addError], but doesn't check to ensure that an error can be added.
  ///
  /// This is called from [addStream], so it shouldn't fail if a stream is being
  /// added.
  void _addError(Object error, [StackTrace? stackTrace]) {
    if (_allowErrors) {
      _inner.addError(error, stackTrace);
      return;
    }

    _doneCompleter.completeError(error, stackTrace);

    // Treat an error like both the stream and sink disconnecting.
    _onStreamDisconnected();
    _channel._onSinkDisconnected();

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
    if (_disconnected) return Future.value();

    _addStreamCompleter = Completer.sync();
    _addStreamSubscription = stream.listen(_inner.add,
        onError: _addError, onDone: _addStreamCompleter!.complete);
    return _addStreamCompleter!.future.then((_) {
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

    if (!_disconnected) {
      _channel._onSinkDisconnected();
      _doneCompleter.complete(_inner.close());
    }

    return done;
  }

  /// Called by [GuaranteeChannel] when the stream emits a done event.
  ///
  /// The stream being done indicates that the connection is closed, so the
  /// sink should stop forwarding events.
  void _onStreamDisconnected() {
    _disconnected = true;
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();

    if (!_inAddStream) return;
    _addStreamCompleter!.complete(_addStreamSubscription!.cancel());
    _addStreamCompleter = null;
    _addStreamSubscription = null;
  }
}
