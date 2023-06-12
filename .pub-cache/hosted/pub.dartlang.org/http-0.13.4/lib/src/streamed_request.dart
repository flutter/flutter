// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'base_client.dart';
import 'base_request.dart';
import 'byte_stream.dart';

/// An HTTP request where the request body is sent asynchronously after the
/// connection has been established and the headers have been sent.
///
/// When the request is sent via [BaseClient.send], only the headers and
/// whatever data has already been written to [StreamedRequest.sink] will be
/// sent immediately. More data will be sent as soon as it's written to
/// [StreamedRequest.sink], and when the sink is closed the request will end.
class StreamedRequest extends BaseRequest {
  /// The sink to which to write data that will be sent as the request body.
  ///
  /// This may be safely written to before the request is sent; the data will be
  /// buffered.
  ///
  /// Closing this signals the end of the request.
  EventSink<List<int>> get sink => _controller.sink;

  /// The controller for [sink], from which [BaseRequest] will read data for
  /// [finalize].
  final StreamController<List<int>> _controller;

  /// Creates a new streaming request.
  StreamedRequest(String method, Uri url)
      : _controller = StreamController<List<int>>(sync: true),
        super(method, url);

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// that emits the data being written to [sink].
  @override
  ByteStream finalize() {
    super.finalize();
    return ByteStream(_controller.stream);
  }
}
