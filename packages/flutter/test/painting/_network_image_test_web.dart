// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/painting/_network_image_web.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';

void runTests() {
  tearDown(() {
    debugRestoreHttpRequestFactory();
  });

  testWidgets('loads an image from the network with headers',
      (WidgetTester tester) async {
    final TestHttpRequest testHttpRequest = TestHttpRequest()
      ..status = 200
      ..onLoad = Stream<html.ProgressEvent>.fromIterable(<html.ProgressEvent>[
        html.ProgressEvent('test error'),
      ])
      ..response = (Uint8List.fromList(kTransparentImage)).buffer;

    httpRequestFactory = () {
      return testHttpRequest;
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
      ..onError = Stream<html.ProgressEvent>.fromIterable(<html.ProgressEvent>[
        html.ProgressEvent('test error'),
      ]);

    httpRequestFactory = () {
      return testHttpRequest;
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
    expect((tester.takeException() as html.ProgressEvent).type, 'test error');
  });

  testWidgets('loads an image from the network with empty response',
      (WidgetTester tester) async {
    final TestHttpRequest testHttpRequest = TestHttpRequest()
      ..status = 200
      ..onLoad = Stream<html.ProgressEvent>.fromIterable(<html.ProgressEvent>[
        html.ProgressEvent('test error'),
      ])
      ..response = (Uint8List.fromList(<int>[])).buffer;

    httpRequestFactory = () {
      return testHttpRequest;
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

// ignore: avoid_implementing_value_types
class TestHttpRequest implements html.HttpRequest {
  @override
  String responseType = 'invalid';

  @override
  int? timeout = 10;

  @override
  bool? withCredentials = false;

  @override
  void abort() {
    throw UnimplementedError();
  }

  @override
  void addEventListener(String type, html.EventListener? listener,
      [bool? useCapture]) {
    throw UnimplementedError();
  }

  @override
  bool dispatchEvent(html.Event event) {
    throw UnimplementedError();
  }

  @override
  String getAllResponseHeaders() {
    throw UnimplementedError();
  }

  @override
  String getResponseHeader(String name) {
    throw UnimplementedError();
  }

  @override
  html.Events get on => throw UnimplementedError();

  @override
  Stream<html.ProgressEvent> get onAbort => throw UnimplementedError();

  @override
  Stream<html.ProgressEvent> onError =
      Stream<html.ProgressEvent>.fromIterable(<html.ProgressEvent>[]);

  @override
  Stream<html.ProgressEvent> onLoad =
      Stream<html.ProgressEvent>.fromIterable(<html.ProgressEvent>[]);

  @override
  Stream<html.ProgressEvent> get onLoadEnd => throw UnimplementedError();

  @override
  Stream<html.ProgressEvent> get onLoadStart => throw UnimplementedError();

  @override
  Stream<html.ProgressEvent> get onProgress => throw UnimplementedError();

  @override
  Stream<html.Event> get onReadyStateChange => throw UnimplementedError();

  @override
  Stream<html.ProgressEvent> get onTimeout => throw UnimplementedError();

  @override
  void open(String method, String url,
      {bool? async, String? user, String? password}) {}

  @override
  void overrideMimeType(String mime) {
    throw UnimplementedError();
  }

  @override
  int get readyState => throw UnimplementedError();

  @override
  void removeEventListener(String type, html.EventListener? listener,
      [bool? useCapture]) {
    throw UnimplementedError();
  }

  @override
  dynamic response;

  Map<String, String> headers = <String, String>{};

  @override
  Map<String, String> get responseHeaders => headers;

  @override
  String get responseText => throw UnimplementedError();

  @override
  String get responseUrl => throw UnimplementedError();

  @override
  html.Document get responseXml => throw UnimplementedError();

  @override
  void send([dynamic bodyOrData]) {}

  @override
  void setRequestHeader(String name, String value) {
    headers[name] = value;
  }

  @override
  int status = -1;

  @override
  String get statusText => throw UnimplementedError();

  @override
  html.HttpRequestUpload get upload => throw UnimplementedError();
}
