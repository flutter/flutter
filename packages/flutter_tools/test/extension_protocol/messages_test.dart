// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/extension_protocol/messages.dart';
import 'package:test/test.dart';

void main() {
  group('Request', () {
    test('toMap() and fromMap() roundtrip', () {
      final original = Request(
        id: 42,
        method: 'foo.bar',
        params: const <String, Object?>{'key': 'value', 'num': 123},
      );

      final Map<String, Object?> map = original.toMap();
      expect(map['id'], 42);
      expect(map['method'], 'foo.bar');
      expect(map['params'], const <String, Object?>{'key': 'value', 'num': 123});

      final Message parsed = Message.fromMap(map);
      expect(parsed, isA<Request>());
      final request = parsed as Request;
      expect(request.id, 42);
      expect(request.method, 'foo.bar');
      expect(request.params, const <String, Object?>{'key': 'value', 'num': 123});
    });

    test('fromMap() throws FormatException on invalid input', () {
      expect(
        () => Request.fromMap(const <String, Object?>{'method': 'foo'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Request.fromMap(const <String, Object?>{'id': 1, 'method': 123}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Request.fromMap(const <String, Object?>{
          'id': 1,
          'method': 'foo',
          'params': 'not-a-map',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Notification', () {
    test('toMap() and fromMap() roundtrip', () {
      final original = Notification(
        method: 'foo.event',
        params: const <String, Object?>{'event_data': true},
      );

      final Map<String, Object?> map = original.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['method'], 'foo.event');
      expect(map['params'], const <String, Object?>{'event_data': true});

      final Message parsed = Message.fromMap(map);
      expect(parsed, isA<Notification>());
      final notification = parsed as Notification;
      expect(notification.id, isNull);
      expect(notification.method, 'foo.event');
      expect(notification.params, const <String, Object?>{'event_data': true});
    });

    test('fromMap() throws FormatException on invalid input', () {
      expect(
        () => Notification.fromMap(const <String, Object?>{'method': 123}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Notification.fromMap(const <String, Object?>{'method': 'foo', 'params': 123}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Response', () {
    test('toMap() and fromMap() roundtrip - success with non-null result', () {
      const original = Response.result(
        id: 'request-123',
        result: <String, Object?>{'status': 'ok'},
      );

      final Map<String, Object?> map = original.toMap();
      expect(map['id'], 'request-123');
      expect(map['result'], const <String, Object?>{'status': 'ok'});
      expect(map.containsKey('error'), isFalse);

      final Message parsed = Message.fromMap(map);
      expect(parsed, isA<Response>());
      final response = parsed as Response;
      expect(response.id, 'request-123');
      expect(response.result, const <String, Object?>{'status': 'ok'});
      expect(response.error, isNull);
    });

    test('toMap() and fromMap() roundtrip - success with null result', () {
      const original = Response.result(id: 'request-123', result: null);

      final Map<String, Object?> map = original.toMap();
      expect(map['id'], 'request-123');
      expect(map.containsKey('result'), isTrue);
      expect(map['result'], isNull);
      expect(map.containsKey('error'), isFalse);

      final Message parsed = Message.fromMap(map);
      expect(parsed, isA<Response>());
      final response = parsed as Response;
      expect(response.id, 'request-123');
      expect(response.result, isNull);
      expect(response.error, isNull);
    });

    test('toMap() and fromMap() roundtrip - error', () {
      const original = Response.error(
        id: 'request-123',
        error: RpcError(code: -32601, message: 'Method not found', data: 'some detail'),
      );

      final Map<String, Object?> map = original.toMap();
      expect(map['id'], 'request-123');
      expect(map.containsKey('result'), isFalse);
      expect(map['error'], isA<Map<String, Object?>>());
      final errMap = map['error']! as Map<String, Object?>;
      expect(errMap['code'], -32601);
      expect(errMap['message'], 'Method not found');
      expect(errMap['data'], 'some detail');

      final Message parsed = Message.fromMap(map);
      expect(parsed, isA<Response>());
      final response = parsed as Response;
      expect(response.id, 'request-123');
      expect(response.result, isNull);
      expect(response.error, isNotNull);
      expect(response.error!.code, -32601);
      expect(response.error!.message, 'Method not found');
      expect(response.error!.data, 'some detail');
    });

    test('fromMap() throws FormatException on invalid input', () {
      // Missing id
      expect(
        () => Response.fromMap(const <String, Object?>{'result': 'ok'}),
        throwsA(isA<FormatException>()),
      );
      // Error is not a map
      expect(
        () => Response.fromMap(const <String, Object?>{'id': 1, 'error': 'not-a-map'}),
        throwsA(isA<FormatException>()),
      );
      // Both result and error present
      expect(
        () => Response.fromMap(const <String, Object?>{
          'id': 1,
          'result': 'ok',
          'error': <String, Object?>{'code': 1, 'message': 'err'},
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains("cannot contain both 'result' and 'error'"),
          ),
        ),
      );
      // Neither result nor error present
      expect(
        () => Response.fromMap(const <String, Object?>{'id': 1}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains("must contain either 'result' or 'error'"),
          ),
        ),
      );
    });
  });

  group('RpcError', () {
    test('named constructors produce expected messages and codes', () {
      const parseError = RpcError.parse(error: 'invalid JSON', data: 'foo');
      expect(parseError.code, -32700);
      expect(parseError.message, 'Parse error: invalid JSON');
      expect(parseError.data, 'foo');

      const invalidRequest = RpcError.invalidRequest(details: 'missing method', data: 'bar');
      expect(invalidRequest.code, -32600);
      expect(invalidRequest.message, 'Invalid request: missing method');
      expect(invalidRequest.data, 'bar');

      const methodNotFound = RpcError.methodNotFound(method: 'foo.bar', data: 'baz');
      expect(methodNotFound.code, -32601);
      expect(methodNotFound.message, 'Method not found: foo.bar');
      expect(methodNotFound.data, 'baz');

      const invalidParams = RpcError.invalidParams(parameter: 'id', data: 'qux');
      expect(invalidParams.code, -32602);
      expect(invalidParams.message, 'Invalid params: id');
      expect(invalidParams.data, 'qux');

      const internalError = RpcError.internal(error: 'crash', data: 'quux');
      expect(internalError.code, -32603);
      expect(internalError.message, 'Internal error: crash');
      expect(internalError.data, 'quux');
    });

    test('fromMap() throws FormatException on invalid input', () {
      // Missing code
      expect(
        () => RpcError.fromMap(const <String, Object?>{'message': 'msg'}),
        throwsA(isA<FormatException>()),
      );
      // Message not a string
      expect(
        () => RpcError.fromMap(const <String, Object?>{'code': 1, 'message': 123}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Message.fromMap routing', () {
    test('throws FormatException on unknown message types', () {
      expect(() => Message.fromMap(const <String, Object?>{}), throwsA(isA<FormatException>()));
      expect(
        () => Message.fromMap(const <String, Object?>{'foo': 'bar'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
