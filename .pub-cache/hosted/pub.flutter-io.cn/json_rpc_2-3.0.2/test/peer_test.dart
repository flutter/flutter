// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  late StreamSink incoming;
  late Stream outgoing;
  late json_rpc.Peer peer;

  setUp(() {
    var incomingController = StreamController();
    incoming = incomingController.sink;
    var outgoingController = StreamController();
    outgoing = outgoingController.stream;
    peer = json_rpc.Peer.withoutJson(
        StreamChannel(incomingController.stream, outgoingController));
  });

  group('like a client,', () {
    test('can send a message and receive a response', () {
      expect(outgoing.first.then((request) {
        expect(
            request,
            equals({
              'jsonrpc': '2.0',
              'method': 'foo',
              'params': {'bar': 'baz'},
              'id': 0
            }));
        incoming.add({'jsonrpc': '2.0', 'result': 'qux', 'id': 0});
      }), completes);

      peer.listen();
      expect(
          peer.sendRequest('foo', {'bar': 'baz'}), completion(equals('qux')));
    });

    test('can send a batch of messages and receive a batch of responses', () {
      expect(outgoing.first.then((request) {
        expect(
            request,
            equals([
              {
                'jsonrpc': '2.0',
                'method': 'foo',
                'params': {'bar': 'baz'},
                'id': 0
              },
              {
                'jsonrpc': '2.0',
                'method': 'a',
                'params': {'b': 'c'},
                'id': 1
              },
              {
                'jsonrpc': '2.0',
                'method': 'w',
                'params': {'x': 'y'},
                'id': 2
              }
            ]));

        incoming.add([
          {'jsonrpc': '2.0', 'result': 'qux', 'id': 0},
          {'jsonrpc': '2.0', 'result': 'd', 'id': 1},
          {'jsonrpc': '2.0', 'result': 'z', 'id': 2}
        ]);
      }), completes);

      peer.listen();

      peer.withBatch(() {
        expect(
            peer.sendRequest('foo', {'bar': 'baz'}), completion(equals('qux')));
        expect(peer.sendRequest('a', {'b': 'c'}), completion(equals('d')));
        expect(peer.sendRequest('w', {'x': 'y'}), completion(equals('z')));
      });
    });

    test('requests terminates when the channel is closed', () async {
      var incomingController = StreamController();
      var channel = StreamChannel.withGuarantees(
        incomingController.stream,
        StreamController(),
      );
      var peer = json_rpc.Peer.withoutJson(channel);
      unawaited(peer.listen());

      var response = peer.sendRequest('foo');
      await incomingController.close();

      expect(response, throwsStateError);
    });
  });

  test('can be closed', () async {
    var incomingController = StreamController();
    var channel = StreamChannel.withGuarantees(
      incomingController.stream,
      StreamController(),
    );
    var peer = json_rpc.Peer.withoutJson(channel);
    unawaited(peer.listen());
    await peer.close();
  });

  test('considered closed with misbehaving StreamChannel', () async {
    // If a StreamChannel does not enforce the guarantees stated in it's
    // contract - specifically that "Closing the sink causes the stream to close
    // before it emits any more events." - The `Peer` should still understand
    // when it has been closed manually.
    var channel = StreamChannel(
      StreamController().stream,
      StreamController(),
    );
    var peer = json_rpc.Peer.withoutJson(channel);
    unawaited(peer.listen());
    unawaited(peer.close());
    expect(peer.isClosed, true);
  });

  group('like a server,', () {
    test('can receive a call and return a response', () {
      expect(outgoing.first,
          completion(equals({'jsonrpc': '2.0', 'result': 'qux', 'id': 0})));

      peer.registerMethod('foo', (_) => 'qux');
      peer.listen();

      incoming.add({
        'jsonrpc': '2.0',
        'method': 'foo',
        'params': {'bar': 'baz'},
        'id': 0
      });
    });

    test('can receive a batch of calls and return a batch of responses', () {
      expect(
          outgoing.first,
          completion(equals([
            {'jsonrpc': '2.0', 'result': 'qux', 'id': 0},
            {'jsonrpc': '2.0', 'result': 'd', 'id': 1},
            {'jsonrpc': '2.0', 'result': 'z', 'id': 2}
          ])));

      peer.registerMethod('foo', (_) => 'qux');
      peer.registerMethod('a', (_) => 'd');
      peer.registerMethod('w', (_) => 'z');
      peer.listen();

      incoming.add([
        {
          'jsonrpc': '2.0',
          'method': 'foo',
          'params': {'bar': 'baz'},
          'id': 0
        },
        {
          'jsonrpc': '2.0',
          'method': 'a',
          'params': {'b': 'c'},
          'id': 1
        },
        {
          'jsonrpc': '2.0',
          'method': 'w',
          'params': {'x': 'y'},
          'id': 2
        }
      ]);
    });

    test('returns a response for malformed JSON', () {
      var incomingController = StreamController<String>();
      var outgoingController = StreamController<String>();
      var jsonPeer = json_rpc.Peer(
          StreamChannel(incomingController.stream, outgoingController));

      expect(
          outgoingController.stream.first.then(jsonDecode),
          completion({
            'jsonrpc': '2.0',
            'error': {
              'code': error_code.PARSE_ERROR,
              'message': startsWith('Invalid JSON: '),
              // TODO(nweiz): Always expect the source when sdk#25655 is fixed.
              'data': {
                'request': anyOf([isNull, '{invalid'])
              }
            },
            'id': null
          }));

      jsonPeer.listen();

      incomingController.add('{invalid');
    });

    test('returns a response for incorrectly-structured JSON', () {
      expect(
          outgoing.first,
          completion({
            'jsonrpc': '2.0',
            'error': {
              'code': error_code.INVALID_REQUEST,
              'message': 'Request must contain a "jsonrpc" key.',
              'data': {
                'request': {'completely': 'wrong'}
              }
            },
            'id': null
          }));

      peer.listen();

      incoming.add({'completely': 'wrong'});
    });
  });

  test('can notify on unhandled errors for if the method throws', () async {
    var exception = Exception('test exception');
    var incomingController = StreamController();
    var outgoingController = StreamController();
    final completer = Completer<Exception>();
    peer = json_rpc.Peer.withoutJson(
      StreamChannel(incomingController.stream, outgoingController),
      onUnhandledError: (error, stack) {
        completer.complete(error);
      },
    );
    peer
      ..registerMethod('foo', () => throw exception)
      // ignore: unawaited_futures
      ..listen();

    incomingController.add({'jsonrpc': '2.0', 'method': 'foo'});
    var receivedException = await completer.future;
    expect(receivedException, equals(exception));
  });
}
