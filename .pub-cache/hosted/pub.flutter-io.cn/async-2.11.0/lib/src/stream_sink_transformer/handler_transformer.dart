// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../delegate/stream_sink.dart';
import '../stream_sink_transformer.dart';

/// The type of the callback for handling data events.
typedef HandleData<S, T> = void Function(S data, EventSink<T> sink);

/// The type of the callback for handling error events.
typedef HandleError<T> = void Function(Object error, StackTrace, EventSink<T>);

/// The type of the callback for handling done events.
typedef HandleDone<T> = void Function(EventSink<T> sink);

/// A [StreamSinkTransformer] that delegates events to the given handlers.
class HandlerTransformer<S, T> implements StreamSinkTransformer<S, T> {
  /// The handler for data events.
  final HandleData<S, T>? _handleData;

  /// The handler for error events.
  final HandleError<T>? _handleError;

  /// The handler for done events.
  final HandleDone<T>? _handleDone;

  HandlerTransformer(this._handleData, this._handleError, this._handleDone);

  @override
  StreamSink<S> bind(StreamSink<T> sink) => _HandlerSink<S, T>(this, sink);
}

/// A sink created by [HandlerTransformer].
class _HandlerSink<S, T> implements StreamSink<S> {
  /// The transformer that created this sink.
  final HandlerTransformer<S, T> _transformer;

  /// The original sink that's being transformed.
  final StreamSink<T> _inner;

  /// The wrapper for [_inner] whose [StreamSink.close] method can't emit
  /// errors.
  final StreamSink<T> _safeCloseInner;

  @override
  Future get done => _inner.done;

  _HandlerSink(this._transformer, StreamSink<T> inner)
      : _inner = inner,
        _safeCloseInner = _SafeCloseSink<T>(inner);

  @override
  void add(S event) {
    var handleData = _transformer._handleData;
    if (handleData == null) {
      _inner.add(event as T);
    } else {
      handleData(event, _safeCloseInner);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    var handleError = _transformer._handleError;
    if (handleError == null) {
      _inner.addError(error, stackTrace);
    } else {
      handleError(error, stackTrace ?? AsyncError.defaultStackTrace(error),
          _safeCloseInner);
    }
  }

  @override
  Future addStream(Stream<S> stream) {
    return _inner.addStream(stream.transform(
        StreamTransformer<S, T>.fromHandlers(
            handleData: _transformer._handleData,
            handleError: _transformer._handleError,
            handleDone: _closeSink)));
  }

  @override
  Future close() {
    var handleDone = _transformer._handleDone;
    if (handleDone == null) return _inner.close();

    handleDone(_safeCloseInner);
    return _inner.done;
  }
}

/// A wrapper for [StreamSink]s that swallows any errors returned by [close].
///
/// [HandlerTransformer] passes this to its handlers to ensure that when they
/// call [close], they don't leave any dangling [Future]s behind that might emit
/// unhandleable errors.
class _SafeCloseSink<T> extends DelegatingStreamSink<T> {
  _SafeCloseSink(super.inner);

  @override
  Future close() => super.close().catchError((_) {});
}

/// A function to pass as a [StreamTransformer]'s `handleDone` callback.
void _closeSink(EventSink sink) {
  sink.close();
}
