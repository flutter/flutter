// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/painting/_network_image_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

import '../image_data.dart';

void runTests() {
  tearDown(() {
    debugRestoreHttpRequestFactory();
  });

  testWidgets('loads an image from the network with headers',
      (WidgetTester tester) async {
    final TestHttpRequest testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', createDomEvent('Event', 'test error'))
      ..response = (Uint8List.fromList(kTransparentImage)).buffer;

    httpRequestFactory = () {
      return testHttpRequest.toJS() as DomXMLHttpRequest;
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
      ..mockEvent = MockEvent('error', createDomEvent('Event', 'test error'));


    httpRequestFactory = () {
      return testHttpRequest.toJS() as DomXMLHttpRequest;
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
    expect((tester.takeException() as DomProgressEvent).type, 'test error');
  });

  testWidgets('loads an image from the network with empty response',
      (WidgetTester tester) async {
    final TestHttpRequest testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', createDomEvent('Event', 'test error'))
      ..response = (Uint8List.fromList(<int>[])).buffer;

    httpRequestFactory = () {
      return testHttpRequest.toJS() as DomXMLHttpRequest;
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

@JS()
@staticInterop
class DomDocument {}

extension DomDocumentExtension on DomDocument {
  external DomEvent createEvent(String eventType);
}

@JS('window.document')
external DomDocument get domDocument;

DomEvent createDomEvent(String type, String name) {
  final DomEvent event = domDocument.createEvent(type);
  event.initEvent(name, true, true);
  return event;
}

@JS('Object.defineProperty')
external void objectDefineProperty(Object o, String symbol, dynamic desc);

@JS()
@staticInterop
@anonymous
class DomXMLHttpRequestMock {
  external factory DomXMLHttpRequestMock(
      {void Function(String method, String url, bool async)? open,
        String responseType = 'invalid',
        int timeout = 10,
        bool withCredentials = false,
        void Function()? send,
        void Function(String name, String value)? setRequestHeader,
        void Function(String type, DomEventListener listener) addEventListener});
}

class TestHttpRequest {
  TestHttpRequest() {
    _mock = DomXMLHttpRequestMock(
        open: allowInterop(open),
        send: allowInterop(send),
        setRequestHeader: allowInterop(setRequestHeader),
        addEventListener: allowInterop(addEventListener),
    );
    createGetter('headers', () => headers);
    createGetter('responseHeaders', () => responseHeaders);
    createGetter('status', () => status);
    createGetter('response', () => response);
  }

  late DomXMLHttpRequestMock _mock;
  MockEvent? mockEvent;
  Map<String, String> headers = <String, String>{};
  int status = -1;
  dynamic response;

  void createGetter<T>(String key, T Function() get) {
    objectDefineProperty(
        _mock,
        key,
        js_util.jsify(
            <dynamic, dynamic>{
              'get': allowInterop(() => get())
            }
        ));
  }

  Map<String, String> get responseHeaders => headers;
  void open(String method, String url, bool async) {}
  void send() {}
  void setRequestHeader(String name, String value) {
    headers[name] = value;
  }

  void addEventListener(String type, DomEventListener listener) {
    if (type == mockEvent?.type) {
      listener(mockEvent!.event);
    }
  }

  DomXMLHttpRequestMock toJS() => _mock;
}

class MockEvent {
  MockEvent(this.type, this.event);

  final String type;
  final DomEvent event;
}
