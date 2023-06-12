// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';

import '../stream_channel.dart';

/// A [channel] where the source and destination are provided later.
///
/// The [channel] is a normal channel that can be listened to and that events
/// can be added to immediately, but until [setChannel] is called it won't emit
/// any events and all events added to it will be buffered.
class StreamChannelCompleter<T> {
  /// The completer for this channel's stream.
  final _streamCompleter = StreamCompleter<T>();

  /// The completer for this channel's sink.
  final _sinkCompleter = StreamSinkCompleter<T>();

  /// The channel for this completer.
  StreamChannel<T> get channel => _channel;
  late final StreamChannel<T> _channel;

  /// Whether [setChannel] has been called.
  bool _set = false;

  /// Convert a `Future<StreamChannel>` to a `StreamChannel`.
  ///
  /// This creates a channel using a channel completer, and sets the source
  /// channel to the result of the future when the future completes.
  ///
  /// If the future completes with an error, the returned channel's stream will
  /// instead contain just that error. The sink will silently discard all
  /// events.
  static StreamChannel fromFuture(Future<StreamChannel> channelFuture) {
    var completer = StreamChannelCompleter();
    channelFuture.then(completer.setChannel, onError: completer.setError);
    return completer.channel;
  }

  StreamChannelCompleter() {
    _channel = StreamChannel<T>(_streamCompleter.stream, _sinkCompleter.sink);
  }

  /// Set a channel as the source and destination for [channel].
  ///
  /// A channel may be set at most once.
  ///
  /// Either [setChannel] or [setError] may be called at most once. Trying to
  /// call either of them again will fail.
  void setChannel(StreamChannel<T> channel) {
    if (_set) throw StateError('The channel has already been set.');
    _set = true;

    _streamCompleter.setSourceStream(channel.stream);
    _sinkCompleter.setDestinationSink(channel.sink);
  }

  /// Indicates that there was an error connecting the channel.
  ///
  /// This makes the stream emit [error] and close. It makes the sink discard
  /// all its events.
  ///
  /// Either [setChannel] or [setError] may be called at most once. Trying to
  /// call either of them again will fail.
  void setError(Object error, [StackTrace? stackTrace]) {
    if (_set) throw StateError('The channel has already been set.');
    _set = true;

    _streamCompleter.setError(error, stackTrace);
    _sinkCompleter.setDestinationSink(NullStreamSink());
  }
}
