// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/services/dom.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

void createGetter<T>(Object mock, String key, T Function() get) {
  objectDefineProperty(
      mock,
      key,
      js_util.jsify(
          <dynamic, dynamic>{
            'get': allowInterop(() => get())
          }
      ));
}

@JS()
@staticInterop
@anonymous
class DomXMLHttpRequestMock {
  external factory DomXMLHttpRequestMock({
    void Function(String method, String url, bool async)? open,
    String responseType = 'invalid',
    int timeout = 10,
    bool withCredentials = false,
    void Function()? send,
    void Function(String name, String value)? setRequestHeader,
    void Function(String type, DomEventListener listener) addEventListener,
  });
}

class TestHttpRequest {
  TestHttpRequest() {
    _mock = DomXMLHttpRequestMock(
        open: allowInterop(open),
        send: allowInterop(send),
        setRequestHeader: allowInterop(setRequestHeader),
        addEventListener: allowInterop(addEventListener),
    );
    createGetter(_mock, 'headers', () => headers);
    createGetter(_mock, 'responseHeaders', () => responseHeaders);
    createGetter(_mock, 'status', () => status);
    createGetter(_mock, 'response', () => response);
  }

  late DomXMLHttpRequestMock _mock;
  MockEvent? mockEvent;
  Map<String, String> headers = <String, String>{};
  int status = -1;
  dynamic response;

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

  DomXMLHttpRequest getMock() => _mock as DomXMLHttpRequest;
}

class MockEvent {
  MockEvent(this.type, this.event);

  final String type;
  final DomEvent event;
}
