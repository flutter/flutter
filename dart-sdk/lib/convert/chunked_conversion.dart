// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/// A [ChunkedConversionSink] is used to transmit data more efficiently between
/// two converters during chunked conversions.
///
/// The basic `ChunkedConversionSink` is just a [Sink], and converters should
/// work with a plain `Sink`, but may work more efficiently with certain
/// specialized types of `ChunkedConversionSink`.
abstract interface class ChunkedConversionSink<T> implements Sink<T> {
  ChunkedConversionSink();
  factory ChunkedConversionSink.withCallback(
      void callback(List<T> accumulated)) = _SimpleCallbackSink<T>;

  /// Adds chunked data to this sink.
  ///
  /// This method is also used when converters are used as [StreamTransformer]s.
  void add(T chunk);

  /// Closes the sink.
  ///
  /// This signals the end of the chunked conversion. This method is called
  /// when converters are used as [StreamTransformer]'s.
  void close();
}

/// This class accumulates all chunks and invokes a callback with a list of
/// the chunks when the sink is closed.
///
/// This class can be used to terminate a chunked conversion.
class _SimpleCallbackSink<T> implements ChunkedConversionSink<T> {
  final void Function(List<T>) _callback;
  final List<T> _accumulated = <T>[];

  _SimpleCallbackSink(this._callback);

  void add(T chunk) {
    _accumulated.add(chunk);
  }

  void close() {
    _callback(_accumulated);
  }
}

/// This class implements the logic for a chunked conversion as a
/// stream transformer.
///
/// It is used as strategy in the [EventTransformStream].
///
/// It also implements the [ChunkedConversionSink] interface so that it
/// can be used as output sink in a chunked conversion.
class _ConverterStreamEventSink<S, T> implements EventSink<S> {
  /// The output sink for the converter.
  final EventSink<T> _eventSink;

  /// The input sink for new data. All data that is received with
  /// [handleData] is added into this sink.
  final Sink<S> _chunkedSink;

  _ConverterStreamEventSink(Converter<S, T> converter, EventSink<T> sink)
      : _eventSink = sink,
        _chunkedSink = converter.startChunkedConversion(sink);

  void add(S o) {
    _chunkedSink.add(o);
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    checkNotNullable(error, "error");
    _eventSink.addError(error, stackTrace);
  }

  void close() {
    _chunkedSink.close();
  }
}
