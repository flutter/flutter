// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late ClientController controller;

  setUp(() => controller = ClientController());

  test('sends a message and returns the response', () {
    controller.expectRequest((request) {
      expect(
          request,
          allOf([
            containsPair('jsonrpc', '2.0'),
            containsPair('method', 'foo'),
            containsPair('params', {'param': 'value'})
          ]));

      return {'jsonrpc': '2.0', 'result': 'bar', 'id': request['id']};
    });

    expect(controller.client.sendRequest('foo', {'param': 'value'}),
        completion(equals('bar')));
  });

  test('sends a message and returns the response with String id', () {
    controller.expectRequest((request) {
      expect(
          request,
          allOf([
            containsPair('jsonrpc', '2.0'),
            containsPair('method', 'foo'),
            containsPair('params', {'param': 'value'})
          ]));

      return {
        'jsonrpc': '2.0',
        'result': 'bar',
        'id': request['id'].toString()
      };
    });

    expect(controller.client.sendRequest('foo', {'param': 'value'}),
        completion(equals('bar')));
  });

  test('sends a notification and expects no response', () {
    controller.expectRequest((request) {
      expect(
          request,
          equals({
            'jsonrpc': '2.0',
            'method': 'foo',
            'params': {'param': 'value'}
          }));
    });

    controller.client.sendNotification('foo', {'param': 'value'});
  });

  test('sends a notification with positional parameters', () {
    controller.expectRequest((request) {
      expect(
          request,
          equals({
            'jsonrpc': '2.0',
            'method': 'foo',
            'params': ['value1', 'value2']
          }));
    });

    controller.client.sendNotification('foo', ['value1', 'value2']);
  });

  test('sends a notification with no parameters', () {
    controller.expectRequest((request) {
      expect(request, equals({'jsonrpc': '2.0', 'method': 'foo'}));
    });

    controller.client.sendNotification('foo');
  });

  test('sends a synchronous batch of requests', () {
    controller.expectRequest((request) {
      expect(request, TypeMatcher<List>());
      expect(request, hasLength(3));
      expect(request[0], equals({'jsonrpc': '2.0', 'method': 'foo'}));
      expect(
          request[1],
          allOf([
            containsPair('jsonrpc', '2.0'),
            containsPair('method', 'bar'),
            containsPair('params', {'param': 'value'})
          ]));
      expect(
          request[2],
          allOf(
              [containsPair('jsonrpc', '2.0'), containsPair('method', 'baz')]));

      return [
        {'jsonrpc': '2.0', 'result': 'baz response', 'id': request[2]['id']},
        {'jsonrpc': '2.0', 'result': 'bar response', 'id': request[1]['id']}
      ];
    });

    controller.client.withBatch(() {
      controller.client.sendNotification('foo');
      expect(controller.client.sendRequest('bar', {'param': 'value'}),
          completion(equals('bar response')));
      expect(controller.client.sendRequest('baz'),
          completion(equals('baz response')));
    });
  });

  test('sends an asynchronous batch of requests', () {
    controller.expectRequest((request) {
      expect(request, TypeMatcher<List>());
      expect(request, hasLength(3));
      expect(request[0], equals({'jsonrpc': '2.0', 'method': 'foo'}));
      expect(
          request[1],
          allOf([
            containsPair('jsonrpc', '2.0'),
            containsPair('method', 'bar'),
            containsPair('params', {'param': 'value'})
          ]));
      expect(
          request[2],
          allOf(
              [containsPair('jsonrpc', '2.0'), containsPair('method', 'baz')]));

      return [
        {'jsonrpc': '2.0', 'result': 'baz response', 'id': request[2]['id']},
        {'jsonrpc': '2.0', 'result': 'bar response', 'id': request[1]['id']}
      ];
    });

    controller.client.withBatch(() {
      return Future.value().then((_) {
        controller.client.sendNotification('foo');
        return Future.value();
      }).then((_) {
        expect(controller.client.sendRequest('bar', {'param': 'value'}),
            completion(equals('bar response')));
        return Future.value();
      }).then((_) {
        expect(controller.client.sendRequest('baz'),
            completion(equals('baz response')));
      });
    });
  });

  test('reports an error from the server', () {
    controller.expectRequest((request) {
      expect(
          request,
          allOf(
              [containsPair('jsonrpc', '2.0'), containsPair('method', 'foo')]));

      return {
        'jsonrpc': '2.0',
        'error': {
          'code': error_code.SERVER_ERROR,
          'message': 'you are bad at requests',
          'data': 'some junk'
        },
        'id': request['id']
      };
    });

    expect(
        controller.client.sendRequest('foo', {'param': 'value'}),
        throwsA(TypeMatcher<json_rpc.RpcException>()
            .having((e) => e.code, 'code', error_code.SERVER_ERROR)
            .having((e) => e.message, 'message', 'you are bad at requests')
            .having((e) => e.data, 'data', 'some junk')));
  });

  test('requests throw StateErrors if the client is closed', () {
    controller.client.close();
    expect(() => controller.client.sendRequest('foo'), throwsStateError);
    expect(() => controller.client.sendNotification('foo'), throwsStateError);
  });

  test('ignores bogus responses', () {
    // Make a request so we have something to respond to.
    controller.expectRequest((request) {
      controller.sendJsonResponse('{invalid');
      controller.sendResponse('not a map');
      controller.sendResponse(
          {'jsonrpc': 'wrong version', 'result': 'wrong', 'id': request['id']});
      controller.sendResponse({'jsonrpc': '2.0', 'result': 'wrong'});
      controller.sendResponse({'jsonrpc': '2.0', 'id': request['id']});
      controller.sendResponse(
          {'jsonrpc': '2.0', 'error': 'not a map', 'id': request['id']});
      controller.sendResponse({
        'jsonrpc': '2.0',
        'error': {'code': 'not an int', 'message': 'dang yo'},
        'id': request['id']
      });
      controller.sendResponse({
        'jsonrpc': '2.0',
        'error': {'code': 123, 'message': 0xDEADBEEF},
        'id': request['id']
      });

      return pumpEventQueue().then(
          (_) => {'jsonrpc': '2.0', 'result': 'right', 'id': request['id']});
    });

    expect(controller.client.sendRequest('foo'), completion(equals('right')));
  });
}
