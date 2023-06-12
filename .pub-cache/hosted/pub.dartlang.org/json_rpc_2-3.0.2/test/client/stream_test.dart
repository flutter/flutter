// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  late StreamController responseController;
  late StreamController requestController;
  late json_rpc.Client client;

  setUp(() {
    responseController = StreamController();
    requestController = StreamController();
    client = json_rpc.Client.withoutJson(
        StreamChannel(responseController.stream, requestController.sink));
  });

  test('.withoutJson supports decoded stream and sink', () {
    client.listen();

    expect(requestController.stream.first.then((request) {
      expect(
          request,
          allOf(
              [containsPair('jsonrpc', '2.0'), containsPair('method', 'foo')]));

      responseController
          .add({'jsonrpc': '2.0', 'result': 'bar', 'id': request['id']});
    }), completes);

    client.sendRequest('foo');
  });

  test('.listen returns when the controller is closed', () {
    var hasListenCompeted = false;
    expect(client.listen().then((_) => hasListenCompeted = true), completes);

    return pumpEventQueue().then((_) {
      expect(hasListenCompeted, isFalse);

      // This should cause listen to complete.
      return responseController.close();
    });
  });

  test('.listen returns a stream error', () {
    expect(client.listen(), throwsA('oh no'));
    responseController.addError('oh no');
  });

  test('.listen can\'t be called twice', () {
    client.listen();
    expect(() => client.listen(), throwsStateError);
  });

  test('.close cancels the stream subscription and closes the sink', () {
    // Work around sdk#19095.
    requestController.stream.listen(null);

    expect(client.listen(), completes);

    expect(client.isClosed, isFalse);
    expect(client.close(), completes);
    expect(client.isClosed, isTrue);

    expect(() => responseController.stream.listen((_) {}), throwsStateError);
    expect(requestController.isClosed, isTrue);
  });

  group('a stream error', () {
    test('is reported through .done', () {
      expect(client.listen(), throwsA('oh no!'));
      expect(client.done, throwsA('oh no!'));
      responseController.addError('oh no!');
    });

    test('cause a pending request to throw a StateError', () {
      expect(client.listen(), throwsA('oh no!'));
      expect(client.sendRequest('foo'), throwsStateError);
      responseController.addError('oh no!');
    });

    test('causes future requests to throw StateErrors', () async {
      expect(client.listen(), throwsA('oh no!'));
      responseController.addError('oh no!');
      await pumpEventQueue();

      expect(() => client.sendRequest('foo'), throwsStateError);
      expect(() => client.sendNotification('foo'), throwsStateError);
    });
  });
}
