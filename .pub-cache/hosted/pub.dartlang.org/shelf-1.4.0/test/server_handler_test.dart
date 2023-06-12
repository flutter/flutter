// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  test('passes the URL to the server', () {
    var serverHandler = ServerHandler(localhostUri);
    expect(serverHandler.server.url, equals(localhostUri));
  });

  test('pipes a request from ServerHandler.handler to a mounted handler',
      () async {
    var serverHandler = ServerHandler(localhostUri);
    serverHandler.server.mount(asyncHandler);

    var response = await makeSimpleRequest(serverHandler.handler);
    expect(response.statusCode, equals(200));
    expect(response.readAsString(), completion(equals('Hello from /')));
  });

  test("waits until the server's handler is mounted to service a request",
      () async {
    var serverHandler = ServerHandler(localhostUri);
    var future = makeSimpleRequest(serverHandler.handler);
    await Future<void>.delayed(Duration.zero);

    serverHandler.server.mount(syncHandler);
    var response = await future;
    expect(response.statusCode, equals(200));
    expect(response.readAsString(), completion(equals('Hello from /')));
  });

  test('stops servicing requests after Server.close is called', () {
    var serverHandler = ServerHandler(localhostUri);
    serverHandler.server.mount(
      expectAsync1((_) => Response.internalServerError(), count: 0),
    );
    serverHandler.server.close();

    expect(makeSimpleRequest(serverHandler.handler), throwsStateError);
  });

  test('calls onClose when Server.close is called', () async {
    var onCloseCalled = false;
    var completer = Completer<void>();
    var serverHandler = ServerHandler(localhostUri, onClose: () {
      onCloseCalled = true;
      return completer.future;
    });

    var closeDone = false;
    unawaited(serverHandler.server.close().then((_) {
      closeDone = true;
    }));
    expect(onCloseCalled, isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(closeDone, isFalse);
    completer.complete();
    await Future<void>.delayed(Duration.zero);

    expect(closeDone, isTrue);
  });

  test("doesn't allow Server.mount to be called multiple times", () {
    var serverHandler = ServerHandler(localhostUri);
    serverHandler.server.mount((_) => throw UnimplementedError());
    expect(
      () => serverHandler.server.mount((_) => throw UnimplementedError()),
      throwsStateError,
    );
    expect(
      () => serverHandler.server.mount((_) => throw UnimplementedError()),
      throwsStateError,
    );
  });
}
