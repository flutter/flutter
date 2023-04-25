// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// For now, we're hiding dart:js_interop's `@JS` to avoid a conflict with
// package:js' `@JS`. In the future, we should be able to remove package:js
// altogether and just import dart:js_interop.
import 'dart:js_interop' hide JS;

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
    // TODO(srujzs): This is needed for when we reify JS types. Right now, JSAny
    // is a typedef for Object?, but when we reify, it'll be its own type.
    // ignore: unnecessary_cast
    final JSAny mock = _mock as JSAny;
    createGetter(mock, 'headers', () => js_util.jsify(headers) as JSAny);
    createGetter(mock,
        'responseHeaders', () => js_util.jsify(responseHeaders) as JSAny);
    createGetter(mock, 'status', () => status.toJS);
    createGetter(mock, 'response', () => js_util.jsify(response) as JSAny);
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
        (listener as JSFunction).toDart as DartDomEventListener;
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
