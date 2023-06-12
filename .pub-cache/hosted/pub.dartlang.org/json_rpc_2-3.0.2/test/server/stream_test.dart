// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  late StreamController requestController;
  late StreamController responseController;
  late json_rpc.Server server;

  setUp(() {
    requestController = StreamController();
    responseController = StreamController();
    server = json_rpc.Server.withoutJson(
        StreamChannel(requestController.stream, responseController.sink));
  });

  test('.withoutJson supports decoded stream and sink', () {
    server.listen();

    server.registerMethod('foo', (params) {
      return {'params': params.value};
    });

    requestController.add({
      'jsonrpc': '2.0',
      'method': 'foo',
      'params': {'param': 'value'},
      'id': 1234
    });

    expect(
        responseController.stream.first,
        completion(equals({
          'jsonrpc': '2.0',
          'result': {
            'params': {'param': 'value'}
          },
          'id': 1234
        })));
  });

  test('.listen returns when the controller is closed', () {
    var hasListenCompeted = false;
    expect(server.listen().then((_) => hasListenCompeted = true), completes);

    return pumpEventQueue().then((_) {
      expect(hasListenCompeted, isFalse);

      // This should cause listen to complete.
      return requestController.close();
    });
  });

  test('.listen returns a stream error', () {
    expect(server.listen(), throwsA('oh no'));
    requestController.addError('oh no');
  });

  test('.listen can\'t be called twice', () {
    server.listen();

    expect(() => server.listen(), throwsStateError);
  });

  test('.close cancels the stream subscription and closes the sink', () {
    // Work around sdk#19095.
    responseController.stream.listen(null);

    expect(server.listen(), completes);

    expect(server.isClosed, isFalse);
    expect(server.close(), completes);
    expect(server.isClosed, isTrue);

    expect(() => requestController.stream.listen((_) {}), throwsStateError);
    expect(responseController.isClosed, isTrue);
  });
}
