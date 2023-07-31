// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late ServerController controller;
  setUp(() => controller = ServerController());

  test('a non-Array/Object request is invalid', () {
    expectErrorResponse(controller, 'foo', error_code.INVALID_REQUEST,
        'Request must be an Array or an Object.');
  });

  test('requests must have a jsonrpc key', () {
    expectErrorResponse(controller, {'method': 'foo', 'id': 1234},
        error_code.INVALID_REQUEST, 'Request must contain a "jsonrpc" key.');
  });

  test('the jsonrpc version must be 2.0', () {
    expectErrorResponse(
        controller,
        {'jsonrpc': '1.0', 'method': 'foo', 'id': 1234},
        error_code.INVALID_REQUEST,
        'Invalid JSON-RPC version "1.0", expected "2.0".');
  });

  test('requests must have a method key', () {
    expectErrorResponse(controller, {'jsonrpc': '2.0', 'id': 1234},
        error_code.INVALID_REQUEST, 'Request must contain a "method" key.');
  });

  test('request method must be a string', () {
    expectErrorResponse(
        controller,
        {'jsonrpc': '2.0', 'method': 1234, 'id': 1234},
        error_code.INVALID_REQUEST,
        'Request method must be a string, but was 1234.');
  });

  test('request params must be an Array or Object', () {
    expectErrorResponse(
        controller,
        {'jsonrpc': '2.0', 'method': 'foo', 'params': 1234, 'id': 1234},
        error_code.INVALID_REQUEST,
        'Request params must be an Array or an Object, but was 1234.');
  });

  test('request id may not be an Array or Object', () {
    expect(
        controller.handleRequest({
          'jsonrpc': '2.0',
          'method': 'foo',
          'id': {'bad': 'id'}
        }),
        completion(equals({
          'jsonrpc': '2.0',
          'id': null,
          'error': {
            'code': error_code.INVALID_REQUEST,
            'message': 'Request id must be a string, number, or null, but was '
                '{"bad":"id"}.',
            'data': {
              'request': {
                'jsonrpc': '2.0',
                'method': 'foo',
                'id': {'bad': 'id'}
              }
            }
          }
        })));
  });

  group('strict protocol checks disabled', () {
    setUp(() => controller = ServerController(strictProtocolChecks: false));

    test('and no jsonrpc param', () {
      expectErrorResponse(controller, {'method': 'foo', 'id': 1234},
          error_code.METHOD_NOT_FOUND, 'Unknown method "foo".');
    });

    test('the jsonrpc version must be 2.0', () {
      expectErrorResponse(
          controller,
          {'jsonrpc': '1.0', 'method': 'foo', 'id': 1234},
          error_code.INVALID_REQUEST,
          'Invalid JSON-RPC version "1.0", expected "2.0".');
    });
  });
}
