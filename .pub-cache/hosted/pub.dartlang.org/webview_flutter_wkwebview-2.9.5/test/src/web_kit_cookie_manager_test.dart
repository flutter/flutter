// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/src/foundation/foundation.dart';
import 'package:webview_flutter_wkwebview/src/web_kit/web_kit.dart';
import 'package:webview_flutter_wkwebview/src/wkwebview_cookie_manager.dart';

import 'web_kit_cookie_manager_test.mocks.dart';

@GenerateMocks(<Type>[
  WKHttpCookieStore,
  WKWebsiteDataStore,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebKitWebViewWidget', () {
    late MockWKWebsiteDataStore mockWebsiteDataStore;
    late MockWKHttpCookieStore mockWKHttpCookieStore;

    late WKWebViewCookieManager cookieManager;

    setUp(() {
      mockWebsiteDataStore = MockWKWebsiteDataStore();
      mockWKHttpCookieStore = MockWKHttpCookieStore();
      when(mockWebsiteDataStore.httpCookieStore)
          .thenReturn(mockWKHttpCookieStore);

      cookieManager =
          WKWebViewCookieManager(websiteDataStore: mockWebsiteDataStore);
    });

    test('clearCookies', () async {
      when(mockWebsiteDataStore.removeDataOfTypes(
              <WKWebsiteDataType>{WKWebsiteDataType.cookies}, any))
          .thenAnswer((_) => Future<bool>.value(true));
      expect(cookieManager.clearCookies(), completion(true));

      when(mockWebsiteDataStore.removeDataOfTypes(
              <WKWebsiteDataType>{WKWebsiteDataType.cookies}, any))
          .thenAnswer((_) => Future<bool>.value(false));
      expect(cookieManager.clearCookies(), completion(false));
    });

    test('setCookie', () async {
      await cookieManager.setCookie(
        const WebViewCookie(name: 'a', value: 'b', domain: 'c', path: 'd'),
      );

      final NSHttpCookie cookie =
          verify(mockWKHttpCookieStore.setCookie(captureAny)).captured.single
              as NSHttpCookie;
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
      expect(
        () => cookieManager.setCookie(
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
