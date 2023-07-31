// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';

/// Simple socket server which immediately closes the first connection and
/// shuts down. This causes the HTTP request to the server to fail with a
/// WebSocketChannelException: connection closed before full header was
/// received failure, which should be caught and surfaced in a
/// [DartDevelopmentServiceException].
Future<Uri> startTestServer() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((Socket request) async {
    request.destroy();
    await server.close();
  });
  return Uri(scheme: 'http', host: server.address.host, port: server.port);
}

/// Reproduction case for https://github.com/flutter/flutter/issues/69433
void main() async {
  test('Handle connection closed before full header received', () async {
    final uri = await startTestServer();
    try {
      await DartDevelopmentService.startDartDevelopmentService(uri);
      fail('Unexpected successful connection.');
    } on DartDevelopmentServiceException catch (e) {
      expect(e.errorCode, DartDevelopmentServiceException.connectionError);
      expect(e.toString().contains('WebSocketChannelException'), true);
    }
  });
}
