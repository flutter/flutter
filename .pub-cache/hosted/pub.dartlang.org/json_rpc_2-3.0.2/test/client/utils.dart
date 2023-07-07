// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

/// A controller used to test a [json_rpc.Client].
class ClientController {
  /// The controller for the client's response stream.
  final _responseController = StreamController<String>();

  /// The controller for the client's request sink.
  final _requestController = StreamController<String>();

  /// The client.
  late final json_rpc.Client client;

  ClientController() {
    client = json_rpc.Client(
        StreamChannel(_responseController.stream, _requestController.sink));
    client.listen();
  }

  /// Expects that the client will send a request.
  ///
  /// The request is passed to [callback], which can return a response. If it
  /// returns a String, that's sent as the response directly. If it returns
  /// null, no response is sent. Otherwise, the return value is encoded and sent
  /// as the response.
  void expectRequest(Function(dynamic) callback) {
    expect(
        _requestController.stream.first.then((request) {
          return callback(jsonDecode(request));
        }).then((response) {
          if (response == null) return;
          if (response is! String) response = jsonEncode(response);
          _responseController.add(response);
        }),
        completes);
  }

  /// Sends [response], a decoded response, to [client].
  void sendResponse(response) {
    sendJsonResponse(jsonEncode(response));
  }

  /// Sends [response], a JSON-encoded response, to [client].
  void sendJsonResponse(String request) {
    _responseController.add(request);
  }
}
