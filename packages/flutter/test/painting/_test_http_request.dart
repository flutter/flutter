// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:flutter/src/services/dom.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

/// Defines a new property on an Object.
@JS('Object.defineProperty')
external JSVoid objectDefineProperty(final JSAny o, final JSString symbol, final JSAny desc);

void createGetter(final JSAny mock, final String key, final JSAny? Function() get) {
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
    final JSFunction? open,
    final JSString responseType,
    final JSNumber timeout,
    final JSBoolean withCredentials,
    final JSFunction? send,
    final JSFunction? setRequestHeader,
    final JSFunction addEventListener,
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
  JSVoid open(final JSString method, final JSString url, final JSBoolean async) {}
  JSVoid send() {}
  JSVoid setRequestHeader(final JSString name, final JSString value) {
    headers[name.toDart] = value.toDart;
  }

  JSVoid addEventListener(final JSString type, final DomEventListener listener) {
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
