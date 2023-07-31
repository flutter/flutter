// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'stream_sink_transformer/handler_transformer.dart';
import 'stream_sink_transformer/stream_transformer_wrapper.dart';
import 'stream_sink_transformer/typed.dart';

/// A [StreamSinkTransformer] transforms the events being passed to a sink.
///
/// This works on the same principle as a [StreamTransformer]. Each transformer
/// defines a [bind] method that takes in the original [StreamSink] and returns
/// the transformed version. However, where a [StreamTransformer] transforms
/// events after they leave the stream, this transforms them before they enter
/// the sink.
///
/// Transformers must be able to have `bind` called used multiple times.
abstract class StreamSinkTransformer<S, T> {
  /// Creates a [StreamSinkTransformer] that transforms events and errors
  /// using [transformer].
  ///
  /// This is equivalent to piping all events from the outer sink through a
  /// stream transformed by [transformer] and from there into the inner sink.
  const factory StreamSinkTransformer.fromStreamTransformer(
      StreamTransformer<S, T> transformer) = StreamTransformerWrapper<S, T>;

  /// Creates a [StreamSinkTransformer] that delegates events to the given
  /// handlers.
  ///
  /// The handlers work exactly as they do for [StreamTransformer.fromHandlers].
  /// They're called for each incoming event, and any actions on the sink
  /// they're passed are forwarded to the inner sink. If a handler is omitted,
  /// the event is passed through unaltered.
  factory StreamSinkTransformer.fromHandlers(
      {void Function(S, EventSink<T>)? handleData,
      void Function(Object, StackTrace, EventSink<T>)? handleError,
      void Function(EventSink<T>)? handleDone}) {
    return HandlerTransformer<S, T>(handleData, handleError, handleDone);
  }

  /// Transforms the events passed to [sink].
  ///
  /// Creates a new sink. When events are passed to the returned sink, it will
  /// transform them and pass the transformed versions to [sink].
  StreamSink<S> bind(StreamSink<T> sink);

  /// Creates a wrapper that coerces the type of [transformer].
  ///
  /// This soundly converts a [StreamSinkTransformer] to a
  /// `StreamSinkTransformer<S, T>`, regardless of its original generic type.
  /// This means that calls to [StreamSink.add] on the returned sink may throw a
  /// [TypeError] if the argument type doesn't match the reified type of the
  /// sink.
  @Deprecated('Will be removed in future version')
  // TODO remove TypeSafeStreamSinkTransformer
  static StreamSinkTransformer<S, T> typed<S, T>(
          StreamSinkTransformer transformer) =>
      transformer is StreamSinkTransformer<S, T>
          ? transformer
          : TypeSafeStreamSinkTransformer(transformer);
}
