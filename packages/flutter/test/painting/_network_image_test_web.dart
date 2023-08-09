// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/painting/_network_image_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

import '../image_data.dart';
import '_test_http_request.dart';

void runTests() {
  tearDown(() {
    debugRestoreHttpRequestFactory();
  });

  testWidgets('loads an image from the network with headers',
      (WidgetTester tester) async {
    final TestHttpRequest testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', web.Event('test error'))
      ..response = (Uint8List.fromList(kTransparentImage)).buffer;

    httpRequestFactory = () {
      return testHttpRequest.getMock();
    };

    const Map<String, String> headers = <String, String>{
      'flutter': 'flutter',
      'second': 'second',
    };

    final Image image = Image.network(
      'https://www.example.com/images/frame.png',
      headers: headers,
    );

    await tester.pumpWidget(image);

    assert(mapEquals(testHttpRequest.responseHeaders, headers), true);
  });

  testWidgets('loads an image from the network with unsuccessful HTTP code',
      (WidgetTester tester) async {
    final TestHttpRequest testHttpRequest = TestHttpRequest()
      ..status = 404
      ..mockEvent = MockEvent('error', web.Event('test error'));


    httpRequestFactory = () {
      return testHttpRequest.getMock();
    };

    const Map<String, String> headers = <String, String>{
      'flutter': 'flutter',
      'second': 'second',
    };

    final Image image = Image.network(
      'https://www.example.com/images/frame2.png',
      headers: headers,
    );

    await tester.pumpWidget(image);
    expect((tester.takeException() as web.ProgressEvent).type, 'test error');
  });

  testWidgets('loads an image from the network with empty response',
      (WidgetTester tester) async {
    final TestHttpRequest testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', web.Event('test error'))
      ..response = (Uint8List.fromList(<int>[])).buffer;

    httpRequestFactory = () {
      return testHttpRequest.getMock();
    };

    const Map<String, String> headers = <String, String>{
      'flutter': 'flutter',
      'second': 'second',
    };

    final Image image = Image.network(
      'https://www.example.com/images/frame3.png',
      headers: headers,
    );

    await tester.pumpWidget(image);
    expect(tester.takeException().toString(),
        'HTTP request failed, statusCode: 200, https://www.example.com/images/frame3.png');
  });
}
