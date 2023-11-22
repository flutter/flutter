// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Defines a new property on an Object.
@JS('Object.defineProperty')
external void objectDefineProperty(JSAny o, String symbol, JSAny desc);

void createGetter(JSAny mock, String key, JSAny? Function() get) {
  objectDefineProperty(
    mock,
    key,
    <String, JSFunction>{
      'get': (() => get()).toJS,
    }.jsify()!,
  );
}

@JS()
@staticInterop
@anonymous
class DomXMLHttpRequestMock {
  external factory DomXMLHttpRequestMock({
    JSFunction? open,
    JSString responseType,
    JSNumber timeout,
    JSBoolean withCredentials,
    JSFunction? send,
    JSFunction? setRequestHeader,
    JSFunction addEventListener,
  });
}

typedef _DartDomEventListener = JSVoid Function(web.Event event);

class TestHttpRequest {
  TestHttpRequest() {
    _mock = DomXMLHttpRequestMock(
        open: open.toJS,
        send: send.toJS,
        setRequestHeader: setRequestHeader.toJS,
        addEventListener: addEventListener.toJS,
    );
    final JSAny mock = _mock as JSAny;
    createGetter(mock, 'headers', () => headers.jsify());
    createGetter(mock,
        'responseHeaders', () => responseHeaders.jsify());
    createGetter(mock, 'status', () => status.toJS);
    createGetter(mock, 'response', () => response.jsify());
  }

  late DomXMLHttpRequestMock _mock;
  MockEvent? mockEvent;
  Map<String, String> headers = <String, String>{};
  int status = -1;
  Object? response;

  Map<String, String> get responseHeaders => headers;
  JSVoid open(String method, String url, bool async) {}
  JSVoid send() {}
  JSVoid setRequestHeader(String name, String value) {
    headers[name] = value;
  }

  JSVoid addEventListener(String type, web.EventListener listener) {
    if (type == mockEvent?.type) {
      final _DartDomEventListener dartListener =
          (listener as JSExportedDartFunction).toDart as _DartDomEventListener;
      dartListener(mockEvent!.event);
    }
  }

  web.XMLHttpRequest getMock() => _mock as web.XMLHttpRequest;
}

class MockEvent {
  MockEvent(this.type, this.event);

  final String type;
  final web.Event event;
}
