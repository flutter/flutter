// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';

import 'src/guarantee_channel.dart';
import 'src/close_guarantee_channel.dart';
import 'src/stream_channel_transformer.dart';

export 'src/delegating_stream_channel.dart';
export 'src/disconnector.dart';
export 'src/json_document_transformer.dart';
export 'src/multi_channel.dart';
export 'src/stream_channel_completer.dart';
export 'src/stream_channel_controller.dart';
export 'src/stream_channel_transformer.dart';

/// An abstract class representing a two-way communication channel.
///
/// Users should consider the [stream] emitting a "done" event to be the
/// canonical indicator that the channel has closed. If they wish to close the
/// channel, they should close the [sink]—canceling the stream subscription is
/// not sufficient. Protocol errors may be emitted through the stream or through
/// [sink].done, depending on their underlying cause. Note that the sink may
/// silently drop events if the channel closes before [sink].close is called.
///
/// Implementations are strongly encouraged to mix in or extend
/// [StreamChannelMixin] to get default implementations of the various instance
/// methods. Adding new methods to this interface will not be considered a
/// breaking change if implementations are also added to [StreamChannelMixin].
///
/// Implementations must provide the following guarantees:
///
/// * The stream is single-subscription, and must follow all the guarantees of
///   single-subscription streams.
///
/// * Closing the sink causes the stream to close before it emits any more
///   events.
///
/// * After the stream closes, the sink is automatically closed. If this
///   happens, sink methods should silently drop their arguments until
///   [sink].close is called.
///
/// * If the stream closes before it has a listener, the sink should silently
///   drop events if possible.
///
/// * Canceling the stream's subscription has no effect on the sink. The channel
///   must still be able to respond to the other endpoint closing the channel
///   even after the subscription has been canceled.
///
/// * The sink *either* forwards errors to the other endpoint *or* closes as
///   soon as an error is added and forwards that error to the [sink].done
///   future.
///
/// These guarantees allow users to interact uniformly with all implementations,
/// and ensure that either endpoint closing the stream produces consistent
/// behavior.
abstract class StreamChannel<T> {
  /// The single-subscription stream that emits values from the other endpoint.
  Stream<T> get stream;

  /// The sink for sending values to the other endpoint.
  StreamSink<T> get sink;

  /// Creates a new [StreamChannel] that communicates over [stream] and [sink].
  ///
  /// Note that this stream/sink pair must provide the guarantees listed in the
  /// [StreamChannel] documentation. If they don't do so natively,
  /// [StreamChannel.withGuarantees] should be used instead.
  factory StreamChannel(Stream<T> stream, StreamSink<T> sink) =>
      _StreamChannel<T>(stream, sink);

  /// Creates a new [StreamChannel] that communicates over [stream] and [sink].
  ///
  /// Unlike [new StreamChannel], this enforces the guarantees listed in the
  /// [StreamChannel] documentation. This makes it somewhat less efficient than
  /// just wrapping a stream and a sink directly, so [new StreamChannel] should
  /// be used when the guarantees are provided natively.
  ///
  /// If [allowSinkErrors] is `false`, errors are not allowed to be passed to
  /// [sink]. If any are, the connection will close and the error will be
  /// forwarded to [sink].done.
  factory StreamChannel.withGuarantees(Stream<T> stream, StreamSink<T> sink,
          {bool allowSinkErrors = true}) =>
      GuaranteeChannel(stream, sink, allowSinkErrors: allowSinkErrors);

  /// Creates a new [StreamChannel] that communicates over [stream] and [sink].
  ///
  /// This specifically enforces the second guarantee: closing the sink causes
  /// the stream to close before it emits any more events. This guarantee is
  /// invalidated when an asynchronous gap is added between the original
  /// stream's event dispatch and the returned stream's, for example by
  /// transforming it with a [StreamTransformer]. This is a lighter-weight way
  /// of preserving that guarantee in particular than
  /// [StreamChannel.withGuarantees].
  factory StreamChannel.withCloseGuarantee(
          Stream<T> stream, StreamSink<T> sink) =>
      CloseGuaranteeChannel(stream, sink);

  /// Connects this to [other], so that any values emitted by either are sent
  /// directly to the other.
  void pipe(StreamChannel<T> other);

  /// Transforms this using [transformer].
  ///
  /// This is identical to calling `transformer.bind(channel)`.
  StreamChannel<S> transform<S>(StreamChannelTransformer<S, T> transformer);

  /// Transforms only the [stream] component of this using [transformer].
  StreamChannel<T> transformStream(StreamTransformer<T, T> transformer);

  /// Transforms only the [sink] component of this using [transformer].
  StreamChannel<T> transformSink(StreamSinkTransformer<T, T> transformer);

  /// Returns a copy of this with [stream] replaced by [change]'s return
  /// value.
  StreamChannel<T> changeStream(Stream<T> Function(Stream<T>) change);

  /// Returns a copy of this with [sink] replaced by [change]'s return
  /// value.
  StreamChannel<T> changeSink(StreamSink<T> Function(StreamSink<T>) change);

  /// Returns a copy of this with the generic type coerced to [S].
  ///
  /// If any events emitted by [stream] aren't of type [S], they're converted
  /// into [TypeError] events (`CastError` on some SDK versions). Similarly, if
  /// any events are added to [sink] that aren't of type [S], a [TypeError] is
  /// thrown.
  StreamChannel<S> cast<S>();
}

/// An implementation of [StreamChannel] that simply takes a stream and a sink
/// as parameters.
///
/// This is distinct from [StreamChannel] so that it can use
/// [StreamChannelMixin].
class _StreamChannel<T> extends StreamChannelMixin<T> {
  @override
  final Stream<T> stream;
  @override
  final StreamSink<T> sink;

  _StreamChannel(this.stream, this.sink);
}

/// A mixin that implements the instance methods of [StreamChannel] in terms of
/// [stream] and [sink].
abstract class StreamChannelMixin<T> implements StreamChannel<T> {
  @override
  void pipe(StreamChannel<T> other) {
    stream.pipe(other.sink);
    other.stream.pipe(sink);
  }

  @override
  StreamChannel<S> transform<S>(StreamChannelTransformer<S, T> transformer) =>
      transformer.bind(this);

  @override
  StreamChannel<T> transformStream(StreamTransformer<T, T> transformer) =>
      changeStream(transformer.bind);

  @override
  StreamChannel<T> transformSink(StreamSinkTransformer<T, T> transformer) =>
      changeSink(transformer.bind);

  @override
  StreamChannel<T> changeStream(Stream<T> Function(Stream<T>) change) =>
      StreamChannel.withCloseGuarantee(change(stream), sink);

  @override
  StreamChannel<T> changeSink(StreamSink<T> Function(StreamSink<T>) change) =>
      StreamChannel.withCloseGuarantee(stream, change(sink));

  @override
  StreamChannel<S> cast<S>() => StreamChannel(
      stream.cast(), StreamController(sync: true)..stream.cast<T>().pipe(sink));
}
