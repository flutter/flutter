// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';

import '../stream_channel.dart';

/// Allows the caller to force a channel to disconnect.
///
/// When [disconnect] is called, the channel (or channels) transformed by this
/// transformer will act as though the remote end had disconnected—the stream
/// will emit a done event, and the sink will ignore future inputs. The inner
/// sink will also be closed to notify the remote end of the disconnection.
///
/// If a channel is transformed after the [disconnect] has been called, it will
/// be disconnected immediately.
class Disconnector<T> implements StreamChannelTransformer<T, T> {
  /// Whether [disconnect] has been called.
  bool get isDisconnected => _disconnectMemo.hasRun;

  /// The sinks for transformed channels.
  ///
  /// Note that we assume that transformed channels provide the stream channel
  /// guarantees. This allows us to only track sinks, because we know closing
  /// the underlying sink will cause the stream to emit a done event.
  final _sinks = <_DisconnectorSink<T>>[];

  /// Disconnects all channels that have been transformed.
  ///
  /// Returns a future that completes when all inner sinks' [StreamSink.close]
  /// futures have completed. Note that a [StreamController]'s sink won't close
  /// until the corresponding stream has a listener.
  Future<void> disconnect() => _disconnectMemo.runOnce(() {
        var futures = _sinks.map((sink) => sink._disconnect()).toList();
        _sinks.clear();
        return Future.wait(futures, eagerError: true);
      });
  final _disconnectMemo = AsyncMemoizer();

  @override
  StreamChannel<T> bind(StreamChannel<T> channel) {
    return channel.changeSink((innerSink) {
      var sink = _DisconnectorSink<T>(innerSink);

      if (isDisconnected) {
        // Ignore errors here, because otherwise there would be no way for the
        // user to handle them gracefully.
        sink._disconnect().catchError((_) {});
      } else {
        _sinks.add(sink);
      }

      return sink;
    });
  }
}

/// A sink wrapper that can force a disconnection.
class _DisconnectorSink<T> implements StreamSink<T> {
  /// The inner sink.
  final StreamSink<T> _inner;

  @override
  Future<void> get done => _inner.done;

  /// Whether [Disconnector.disconnect] has been called.
  var _isDisconnected = false;

  /// Whether the user has called [close].
  var _closed = false;

  /// The subscription to the stream passed to [addStream], if a stream is
  /// currently being added.
  StreamSubscription<T>? _addStreamSubscription;

  /// The completer for the future returned by [addStream], if a stream is
  /// currently being added.
  Completer? _addStreamCompleter;

  /// Whether we're currently adding a stream with [addStream].
  bool get _inAddStream => _addStreamSubscription != null;

  _DisconnectorSink(this._inner);

  @override
  void add(T data) {
    if (_closed) throw StateError('Cannot add event after closing.');
    if (_inAddStream) {
      throw StateError('Cannot add event while adding stream.');
    }
    if (_isDisconnected) return;

    _inner.add(data);
  }

  @override
  void addError(error, [StackTrace? stackTrace]) {
    if (_closed) throw StateError('Cannot add event after closing.');
    if (_inAddStream) {
      throw StateError('Cannot add event while adding stream.');
    }
    if (_isDisconnected) return;

    _inner.addError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<T> stream) {
    if (_closed) throw StateError('Cannot add stream after closing.');
    if (_inAddStream) {
      throw StateError('Cannot add stream while adding stream.');
    }
    if (_isDisconnected) return Future.value();

    _addStreamCompleter = Completer.sync();
    _addStreamSubscription = stream.listen(_inner.add,
        onError: _inner.addError, onDone: _addStreamCompleter!.complete);
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

    _closed = true;
    return _inner.close();
  }

  /// Disconnects this sink.
  ///
  /// This closes the underlying sink and stops forwarding events. It returns
  /// the [StreamSink.close] future for the underlying sink.
  Future<void> _disconnect() {
    _isDisconnected = true;
    var future = _inner.close();

    if (_inAddStream) {
      _addStreamCompleter!.complete(_addStreamSubscription!.cancel());
      _addStreamCompleter = null;
      _addStreamSubscription = null;
    }

    return future;
  }
}
