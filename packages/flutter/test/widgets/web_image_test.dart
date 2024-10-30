// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser') // This file contains web-only library.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/src/painting/_network_image_web.dart';
import 'package:flutter/src/web.dart' as web_shim;
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

import '../image_data.dart';
import '../painting/_test_http_request.dart';

void main() {
  tearDown(() {
    debugRestoreHttpRequestFactory();
  });

  group('WebImage', () {
    testWidgets('defaults to Image.network if src is same origin',
        (WidgetTester tester) async {
      final TestHttpRequest testHttpRequest = TestHttpRequest()
        ..status = 200
        ..mockEvent = MockEvent('load', web.Event('test error'))
        ..response = (Uint8List.fromList(kTransparentImage)).buffer;

      httpRequestFactory = () {
        return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
      };

      final String imageUrl = '${web_shim.window.origin}/images/image.jpg';

      await tester.pumpWidget(WebImage.network(imageUrl));
      await tester.pumpAndSettle();

      // Since the request for the bytes succeeds, this should put an
      // Image.network (which resolves to a RawImage) in the widget tree.
      expect(find.byType(RawImage), findsOneWidget);
    });

    testWidgets('defaults to Image.network if src bytes can be fetched',
        (WidgetTester tester) async {
      final TestHttpRequest testHttpRequest = TestHttpRequest()
        ..status = 200
        ..mockEvent = MockEvent('load', web.Event('test error'))
        ..response = (Uint8List.fromList(kTransparentImage)).buffer;

      httpRequestFactory = () {
        return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
      };

      await tester.pumpWidget(
          WebImage.network('https://www.example.com/images/frame.png'));
      await tester.pumpAndSettle();

      // Since the request for the bytes succeeds, this should put an
      // Image.network (which resolves to a RawImage) in the widget tree.
      expect(find.byType(RawImage), findsOneWidget);
    });

    testWidgets('defaults to HtmlElementView if src bytes cannot be fetched',
        (WidgetTester tester) async {
      final TestHttpRequest testHttpRequest = TestHttpRequest()
        ..status = 500
        ..mockEvent = MockEvent('load', web.Event('test error'))
        ..response = (Uint8List.fromList(kTransparentImage)).buffer;

      httpRequestFactory = () {
        return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
      };

      await tester.pumpWidget(
          WebImage.network('https://www.example.com/images/frame.png'));
      await tester.pumpAndSettle();

      // Since the request for the bytes succeeds, this should put an
      // Image.network (which resolves to a RawImage) in the widget tree.
      expect(find.byType(HtmlElementView), findsOneWidget);
    });
  });
}
