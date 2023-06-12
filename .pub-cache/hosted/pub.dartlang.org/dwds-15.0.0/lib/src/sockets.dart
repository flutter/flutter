// Copyright 2021 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sse/client/sse_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class SocketClient {
  StreamSink<dynamic> get sink;
  Stream<String> get stream;
  void close();
}

class SseSocketClient extends SocketClient {
  final SseClient _client;
  SseSocketClient(this._client);

  @override
  StreamSink<dynamic> get sink => _client.sink;

  @override
  Stream<String> get stream => _client.stream;

  @override
  void close() => _client.close();
}

class WebSocketClient extends SocketClient {
  final WebSocketChannel _channel;

  WebSocketClient(this._channel);

  @override
  StreamSink<dynamic> get sink => _channel.sink;
  @override
  Stream<String> get stream => _channel.stream.map((dynamic o) => o.toString());

  @override
  void close() => _channel.sink.close();
}
