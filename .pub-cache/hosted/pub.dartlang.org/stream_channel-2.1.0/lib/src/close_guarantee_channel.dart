// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';

import '../stream_channel.dart';

/// A [StreamChannel] that specifically enforces the stream channel guarantee
/// that closing the sink causes the stream to close before it emits any more
/// events
///
/// This is exposed via [new StreamChannel.withCloseGuarantee].
class CloseGuaranteeChannel<T> extends StreamChannelMixin<T> {
  @override
  Stream<T> get stream => _stream;
  late final _CloseGuaranteeStream<T> _stream;

  @override
  StreamSink<T> get sink => _sink;
  late final _CloseGuaranteeSink<T> _sink;

  /// The subscription to the inner stream.
  StreamSubscription<T>? _subscription;

  /// Whether the sink has closed, causing the underlying channel to disconnect.
  bool _disconnected = false;

  CloseGuaranteeChannel(Stream<T> innerStream, StreamSink<T> innerSink) {
    _sink = _CloseGuaranteeSink<T>(innerSink, this);
    _stream = _CloseGuaranteeStream<T>(innerStream, this);
  }
}

/// The stream for [CloseGuaranteeChannel].
///
/// This wraps the inner stream to save the subscription on the channel when
/// [listen] is called.
class _CloseGuaranteeStream<T> extends Stream<T> {
  /// The inner stream this is delegating to.
  final Stream<T> _inner;

  /// The [CloseGuaranteeChannel] this belongs to.
  final CloseGuaranteeChannel<T> _channel;

  _CloseGuaranteeStream(this._inner, this._channel);

  @override
  StreamSubscription<T> listen(void Function(T)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    // If the channel is already disconnected, we shouldn't dispatch anything
    // but a done event.
    if (_channel._disconnected) {
      onData = null;
      onError = null;
    }

    var subscription = _inner.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    if (!_channel._disconnected) {
      _channel._subscription = subscription;
    }
    return subscription;
  }
}

/// The sink for [CloseGuaranteeChannel].
///
/// This wraps the inner sink to cancel the stream subscription when the sink is
/// canceled.
class _CloseGuaranteeSink<T> extends DelegatingStreamSink<T> {
  /// The [CloseGuaranteeChannel] this belongs to.
  final CloseGuaranteeChannel<T> _channel;

  _CloseGuaranteeSink(StreamSink<T> inner, this._channel) : super(inner);

  @override
  Future<void> close() {
    var done = super.close();
    _channel._disconnected = true;
    var subscription = _channel._subscription;
    if (subscription != null) {
      // Don't dispatch anything but a done event.
      subscription.onData(null);
      subscription.onError(null);
    }
    return done;
  }
}
