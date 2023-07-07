// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_platform_interface/v4/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/src/foundation/foundation.dart';
import 'package:webview_flutter_wkwebview/src/v4/src/webkit_proxy.dart';
import 'package:webview_flutter_wkwebview/src/v4/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_wkwebview/src/web_kit/web_kit.dart';

import 'webkit_webview_cookie_manager_test.mocks.dart';

@GenerateMocks(<Type>[WKWebsiteDataStore, WKHttpCookieStore])
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('WebKitWebViewCookieManager', () {
    test('clearCookies', () {
      final MockWKWebsiteDataStore mockWKWebsiteDataStore =
          MockWKWebsiteDataStore();

      final WebKitWebViewCookieManager manager = WebKitWebViewCookieManager(
        WebKitWebViewCookieManagerCreationParams(
          webKitProxy: WebKitProxy(
            defaultWebsiteDataStore: () => mockWKWebsiteDataStore,
          ),
        ),
      );

      when(
        mockWKWebsiteDataStore.removeDataOfTypes(
          <WKWebsiteDataType>{WKWebsiteDataType.cookies},
          any,
        ),
      ).thenAnswer((_) => Future<bool>.value(true));
      expect(manager.clearCookies(), completion(true));

      when(
        mockWKWebsiteDataStore.removeDataOfTypes(
          <WKWebsiteDataType>{WKWebsiteDataType.cookies},
          any,
        ),
      ).thenAnswer((_) => Future<bool>.value(false));
      expect(manager.clearCookies(), completion(false));
    });

    test('setCookie', () async {
      final MockWKWebsiteDataStore mockWKWebsiteDataStore =
          MockWKWebsiteDataStore();

      final MockWKHttpCookieStore mockCookieStore = MockWKHttpCookieStore();
      when(mockWKWebsiteDataStore.httpCookieStore).thenReturn(mockCookieStore);

      final WebKitWebViewCookieManager manager = WebKitWebViewCookieManager(
        WebKitWebViewCookieManagerCreationParams(
          webKitProxy: WebKitProxy(
            defaultWebsiteDataStore: () => mockWKWebsiteDataStore,
          ),
        ),
      );

      await manager.setCookie(
        const WebViewCookie(name: 'a', value: 'b', domain: 'c', path: 'd'),
      );

      final NSHttpCookie cookie = verify(mockCookieStore.setCookie(captureAny))
          .captured
          .single as NSHttpCookie;
      expect(
        cookie.properties,
        <NSHttpCookiePropertyKey, Object>{
          NSHttpCookiePropertyKey.name: 'a',
          NSHttpCookiePropertyKey.value: 'b',
          NSHttpCookiePropertyKey.domain: 'c',
          NSHttpCookiePropertyKey.path: 'd',
        },
      );
    });

    test('setCookie throws argument error with invalid path', () async {
      final MockWKWebsiteDataStore mockWKWebsiteDataStore =
          MockWKWebsiteDataStore();

      final MockWKHttpCookieStore mockCookieStore = MockWKHttpCookieStore();
      when(mockWKWebsiteDataStore.httpCookieStore).thenReturn(mockCookieStore);

      final WebKitWebViewCookieManager manager = WebKitWebViewCookieManager(
        WebKitWebViewCookieManagerCreationParams(
          webKitProxy: WebKitProxy(
            defaultWebsiteDataStore: () => mockWKWebsiteDataStore,
          ),
        ),
      );

      expect(
        () => manager.setCookie(
          WebViewCookie(
            name: 'a',
            value: 'b',
            domain: 'c',
            path: String.fromCharCode(0x1F),
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
