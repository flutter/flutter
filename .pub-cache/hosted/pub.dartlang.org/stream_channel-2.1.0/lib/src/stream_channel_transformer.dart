// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';

import '../stream_channel.dart';

/// A [StreamChannelTransformer] transforms the events being passed to and
/// emitted by a [StreamChannel].
///
/// This works on the same principle as [StreamTransformer] and
/// [StreamSinkTransformer]. Each transformer defines a [bind] method that takes
/// in the original [StreamChannel] and returns the transformed version.
///
/// Transformers must be able to have [bind] called multiple times. If a
/// subclass implements [bind] explicitly, it should be sure that the returned
/// stream follows the second stream channel guarantee: closing the sink causes
/// the stream to close before it emits any more events. This guarantee is
/// invalidated when an asynchronous gap is added between the original stream's
/// event dispatch and the returned stream's, for example by transforming it
/// with a [StreamTransformer]. The guarantee can be easily preserved using
/// [StreamChannel.withCloseGuarantee].
class StreamChannelTransformer<S, T> {
  /// The transformer to use on the channel's stream.
  final StreamTransformer<T, S> _streamTransformer;

  /// The transformer to use on the channel's sink.
  final StreamSinkTransformer<S, T> _sinkTransformer;

  /// Creates a [StreamChannelTransformer] from existing stream and sink
  /// transformers.
  const StreamChannelTransformer(
      this._streamTransformer, this._sinkTransformer);

  /// Creates a [StreamChannelTransformer] from a codec's encoder and decoder.
  ///
  /// All input to the inner channel's sink is encoded using [Codec.encoder],
  /// and all output from its stream is decoded using [Codec.decoder].
  StreamChannelTransformer.fromCodec(Codec<S, T> codec)
      : this(codec.decoder,
            StreamSinkTransformer.fromStreamTransformer(codec.encoder));

  /// Transforms the events sent to and emitted by [channel].
  ///
  /// Creates a new channel. When events are passed to the returned channel's
  /// sink, the transformer will transform them and pass the transformed
  /// versions to `channel.sink`. When events are emitted from the
  /// `channel.straem`, the transformer will transform them and pass the
  /// transformed versions to the returned channel's stream.
  StreamChannel<S> bind(StreamChannel<T> channel) =>
      StreamChannel<S>.withCloseGuarantee(
          channel.stream.transform(_streamTransformer),
          _sinkTransformer.bind(channel.sink));
}
