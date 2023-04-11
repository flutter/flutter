// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:flutter/src/services/dom.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

/// Defines a new property on an Object.
@JS('Object.defineProperty')
external JSVoid objectDefineProperty(JSAny o, JSString symbol, JSAny desc);

void createGetter(JSAny mock, String key, JSAny? Function() get) {
  objectDefineProperty(
      mock,
      key.toJS,
      js_util.jsify(
          <String, Object>{
            'get': () { return get(); }.toJS
          }
      ) as JSAny);
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
    createGetter(_mock, 'headers', () => js_util.jsify(headers) as JSAny);
    createGetter(_mock,
        'responseHeaders', () => js_util.jsify(responseHeaders) as JSAny);
    createGetter(_mock, 'status', () => status.toJS);
    createGetter(_mock, 'response', () => js_util.jsify(response) as JSAny);
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
      (listener.toDart as DartDomEventListener)(mockEvent!.event);
    }
  }

  DomXMLHttpRequest getMock() => _mock as DomXMLHttpRequest;
}

class MockEvent {
  MockEvent(this.type, this.event);

  final String type;
  final DomEvent event;
}
