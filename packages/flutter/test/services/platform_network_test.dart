// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Note that these tests would not work on a mobile device as opening up an
// [HttpServer] is not allowed. They are meant for hosts only.
Future<void> _testHttp(Future<void> testCode(HttpClient client, Uri uri)) async {
  final httpClient = new HttpClient();
  final server = await HttpServer.bind(Platform.localHostname, 0);
  final uri = Uri(scheme: 'http', host: Platform.localHostname, port: server.port);
  try {
    await testCode(httpClient, uri);
  } finally {
    httpClient.close(force: true);
    await server.close();
  }
}

void main() {
  test('allowHttp allows HTTP', () async {
    await _testHttp((httpClient, uri) async {
      final HttpClientRequest result = await allowHttp(() => httpClient.getUrl(uri));
      expect(result, isNotNull);
    });
  });

  // This test ensures the zone variable used in Dart SDK does not change.
  //
  // If this symbol changes, then update [allowHttp] function as well.
  test('Zone variable can override HTTP behavior', () async {
    await _testHttp((httpClient, uri) async {
    expect(() => runZoned(
        () async => await httpClient.getUrl(uri),
        zoneValues: {#dart.library.io.allow_http: false}), throwsA(isA<StateError>()));
    });
  });
}
