// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_android/src/android_webview.dart'
    as android_webview;
import 'package:webview_flutter_android/webview_android_cookie_manager.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'webview_android_cookie_manager_test.mocks.dart';

@GenerateMocks(<Type>[android_webview.CookieManager])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    android_webview.CookieManager.instance = MockCookieManager();
  });

  test('clearCookies should call android_webview.clearCookies', () {
    when(android_webview.CookieManager.instance.clearCookies())
        .thenAnswer((_) => Future<bool>.value(true));
    WebViewAndroidCookieManager().clearCookies();
    verify(android_webview.CookieManager.instance.clearCookies());
  });

  test('setCookie should throw ArgumentError for cookie with invalid path', () {
    expect(
      () => WebViewAndroidCookieManager().setCookie(const WebViewCookie(
        name: 'foo',
        value: 'bar',
        domain: 'flutter.dev',
        path: 'invalid;path',
      )),
      throwsA(const TypeMatcher<ArgumentError>()),
    );
  });

  test(
      'setCookie should call android_webview.csetCookie with properly formatted cookie value',
      () {
    WebViewAndroidCookieManager().setCookie(const WebViewCookie(
      name: 'foo&',
      value: 'bar@',
      domain: 'flutter.dev',
    ));
    verify(android_webview.CookieManager.instance
        .setCookie('flutter.dev', 'foo%26=bar%40; path=/'));
  });
}
