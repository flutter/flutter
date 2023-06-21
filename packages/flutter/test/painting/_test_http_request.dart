// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:flutter/src/services/dom.dart';

/// Defines a new property on an Object.
@JS('Object.defineProperty')
external JSVoid objectDefineProperty(JSAny o, JSString symbol, JSAny desc);

void createGetter(JSAny mock, String key, JSAny? Function() get) {
  objectDefineProperty(
    mock,
    key.toJS,
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

class TestHttpRequest {
  TestHttpRequest() {
    _mock = DomXMLHttpRequestMock(
        open: open.toJS,
        send: send.toJS,
        setRequestHeader: setRequestHeader.toJS,
        addEventListener: addEventListener.toJS,
    );
    // TODO(srujzs): This is needed for when we reify JS types. Right now, JSAny
    // is a typedef for Object?, but when we reify, it'll be its own type.
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
  JSVoid open(JSString method, JSString url, JSBoolean async) {}
  JSVoid send() {}
  JSVoid setRequestHeader(JSString name, JSString value) {
    headers[name.toDart] = value.toDart;
  }

  JSVoid addEventListener(JSString type, DomEventListener listener) {
    if (type.toDart == mockEvent?.type) {
      final DartDomEventListener dartListener =
        (listener as JSExportedDartFunction).toDart as DartDomEventListener;
      dartListener(mockEvent!.event);
    }
  }

  DomXMLHttpRequest getMock() => _mock as DomXMLHttpRequest;
}

class MockEvent {
  MockEvent(this.type, this.event);

  final String type;
  final DomEvent event;
}
