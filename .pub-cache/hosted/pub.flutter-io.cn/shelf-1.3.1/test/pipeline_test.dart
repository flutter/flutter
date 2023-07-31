// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  var accessLocation = 0;

  setUp(() {
    accessLocation = 0;
  });

  Handler middlewareA(Handler innerHandler) => (request) {
        expect(accessLocation, 0);
        accessLocation = 1;
        final response = innerHandler(request);
        expect(accessLocation, 4);
        accessLocation = 5;
        return response;
      };

  Handler middlewareB(Handler innerHandler) => (request) {
        expect(accessLocation, 1);
        accessLocation = 2;
        final response = innerHandler(request);
        expect(accessLocation, 3);
        accessLocation = 4;
        return response;
      };

  Response innerHandler(Request request) {
    expect(accessLocation, 2);
    accessLocation = 3;
    return syncHandler(request);
  }

  test('compose middleware with Pipeline', () async {
    var handler = const Pipeline()
        .addMiddleware(middlewareA)
        .addMiddleware(middlewareB)
        .addHandler(innerHandler);

    final response = await makeSimpleRequest(handler);
    expect(response, isNotNull);
    expect(accessLocation, 5);
  });

  test('extensions for composition', () async {
    var handler =
        middlewareA.addMiddleware(middlewareB).addHandler(innerHandler);

    final response = await makeSimpleRequest(handler);
    expect(response, isNotNull);
    expect(accessLocation, 5);
  });

  test('Pipeline can be used as middleware', () async {
    var innerPipeline =
        const Pipeline().addMiddleware(middlewareA).addMiddleware(middlewareB);

    var handler = const Pipeline()
        .addMiddleware(innerPipeline.middleware)
        .addHandler(innerHandler);

    final response = await makeSimpleRequest(handler);
    expect(response, isNotNull);
    expect(accessLocation, 5);
  });
}
