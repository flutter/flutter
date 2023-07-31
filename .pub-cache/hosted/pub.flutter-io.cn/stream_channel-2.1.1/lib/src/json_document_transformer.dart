// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:async/async.dart';

import '../stream_channel.dart';

/// A [StreamChannelTransformer] that transforms JSON documents—strings that
/// contain individual objects encoded as JSON—into decoded Dart objects.
///
/// This decodes JSON that's emitted by the transformed channel's stream, and
/// encodes objects so that JSON is passed to the transformed channel's sink.
///
/// If the transformed channel emits invalid JSON, this emits a
/// [FormatException]. If an unencodable object is added to the sink, it
/// synchronously throws a [JsonUnsupportedObjectError].
final StreamChannelTransformer<Object?, String> jsonDocument =
    const _JsonDocument();

class _JsonDocument implements StreamChannelTransformer<Object?, String> {
  const _JsonDocument();

  @override
  StreamChannel<Object?> bind(StreamChannel<String> channel) {
    var stream = channel.stream.map(jsonDecode);
    var sink = StreamSinkTransformer<Object, String>.fromHandlers(
        handleData: (data, sink) {
      sink.add(jsonEncode(data));
    }).bind(channel.sink);
    return StreamChannel.withCloseGuarantee(stream, sink);
  }
}
