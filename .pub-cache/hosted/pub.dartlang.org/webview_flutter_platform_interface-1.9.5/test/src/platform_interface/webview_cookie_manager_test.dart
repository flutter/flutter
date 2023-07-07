// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/src/platform_interface/platform_interface.dart';
import 'package:webview_flutter_platform_interface/src/types/webview_cookie.dart';

void main() {
  WebViewCookieManagerPlatform? cookieManager;

  setUp(() {
    cookieManager = TestWebViewCookieManagerPlatform();
  });

  test('clearCookies should throw UnimplementedError', () {
    expect(() => cookieManager!.clearCookies(), throwsUnimplementedError);
  });

  test('setCookie should throw UnimplementedError', () {
    const WebViewCookie cookie =
        WebViewCookie(domain: 'flutter.dev', name: 'foo', value: 'bar');
    expect(() => cookieManager!.setCookie(cookie), throwsUnimplementedError);
  });
}

class TestWebViewCookieManagerPlatform extends WebViewCookieManagerPlatform {}
