// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/src/message.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  group('Request', () {
    _testChange(({
      body,
      Map<String, Object>? headers,
      Map<String, Object>? context,
    }) {
      return Request(
        'GET',
        localhostUri,
        body: body,
        headers: headers,
        context: context,
      );
    });
  });

  group('Response', () {
    _testChange(({
      body,
      Map<String, Object>? headers,
      Map<String, Object>? context,
    }) {
      return Response.ok(
        body,
        headers: headers,
        context: context,
      );
    });
  });
}

/// Shared test method used by [Request] and [Response] tests to validate
/// the behavior of `change` with different `headers` and `context` values.
void _testChange(
    Message Function({
  dynamic body,
  Map<String, String> headers,
  Map<String, Object> context,
})
        factory) {
  group('body', () {
    test('with String', () async {
      var request = factory(body: 'Hello, world');
      var copy = request.change(body: 'Goodbye, world');

      var newBody = await copy.readAsString();

      expect(newBody, equals('Goodbye, world'));
    });

    test('with Stream', () async {
      var request = factory(body: 'Hello, world');
      var copy = request.change(
          body:
              Stream.fromIterable(['Goodbye, world']).transform(utf8.encoder));

      var newBody = await copy.readAsString();

      expect(newBody, equals('Goodbye, world'));
    });
  });

  test('with empty headers returns identical instance', () {
    var request = factory(headers: {'header1': 'header value 1'});
    var copy = request.change(headers: {});

    expect(copy.headers, same(request.headers));
    expect(copy.headersAll, same(request.headersAll));
  });

  test('with empty context returns identical instance', () {
    var request = factory(context: {'context1': 'context value 1'});
    var copy = request.change(context: {});

    expect(copy.context, same(request.context));
  });

  test('new header values are added', () {
    var request = factory(headers: {'test': 'test value'});
    var copy = request.change(headers: {'test2': 'test2 value'});

    expect(copy.headers,
        {'test': 'test value', 'test2': 'test2 value', 'content-length': '0'});
  });

  test('existing header values are overwritten', () {
    var request = factory(headers: {'test': 'test value'});
    var copy = request.change(headers: {'test': 'new test value'});

    expect(copy.headers, {'test': 'new test value', 'content-length': '0'});
  });

  test('new context values are added', () {
    var request = factory(context: {'test': 'test value'});
    var copy = request.change(context: {'test2': 'test2 value'});

    expect(copy.context, {'test': 'test value', 'test2': 'test2 value'});
  });

  test('existing context values are overwritten', () {
    var request = factory(context: {'test': 'test value'});
    var copy = request.change(context: {'test': 'new test value'});

    expect(copy.context, {'test': 'new test value'});
  });
}
