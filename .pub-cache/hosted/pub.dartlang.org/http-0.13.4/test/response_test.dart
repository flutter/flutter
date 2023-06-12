// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('()', () {
    test('sets body', () {
      var response = http.Response('Hello, world!', 200);
      expect(response.body, equals('Hello, world!'));
    });

    test('sets bodyBytes', () {
      var response = http.Response('Hello, world!', 200);
      expect(
          response.bodyBytes,
          equals(
              [72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33]));
    });

    test('respects the inferred encoding', () {
      var response = http.Response('föøbãr', 200,
          headers: {'content-type': 'text/plain; charset=iso-8859-1'});
      expect(response.bodyBytes, equals([102, 246, 248, 98, 227, 114]));
    });
  });

  group('.bytes()', () {
    test('sets body', () {
      var response = http.Response.bytes([104, 101, 108, 108, 111], 200);
      expect(response.body, equals('hello'));
    });

    test('sets bodyBytes', () {
      var response = http.Response.bytes([104, 101, 108, 108, 111], 200);
      expect(response.bodyBytes, equals([104, 101, 108, 108, 111]));
    });

    test('respects the inferred encoding', () {
      var response = http.Response.bytes([102, 246, 248, 98, 227, 114], 200,
          headers: {'content-type': 'text/plain; charset=iso-8859-1'});
      expect(response.body, equals('föøbãr'));
    });
  });

  group('.fromStream()', () {
    test('sets body', () async {
      var controller = StreamController<List<int>>(sync: true);
      var streamResponse =
          http.StreamedResponse(controller.stream, 200, contentLength: 13);
      controller
        ..add([72, 101, 108, 108, 111, 44, 32])
        ..add([119, 111, 114, 108, 100, 33]);
      unawaited(controller.close());
      var response = await http.Response.fromStream(streamResponse);
      expect(response.body, equals('Hello, world!'));
    });

    test('sets bodyBytes', () async {
      var controller = StreamController<List<int>>(sync: true);
      var streamResponse =
          http.StreamedResponse(controller.stream, 200, contentLength: 5);
      controller.add([104, 101, 108, 108, 111]);
      unawaited(controller.close());
      var response = await http.Response.fromStream(streamResponse);
      expect(response.bodyBytes, equals([104, 101, 108, 108, 111]));
    });
  });
}
