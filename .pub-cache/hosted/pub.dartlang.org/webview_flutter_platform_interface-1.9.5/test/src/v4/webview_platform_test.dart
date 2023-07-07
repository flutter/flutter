// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:webview_flutter_platform_interface/v4/src/platform_webview_controller.dart';
import 'package:webview_flutter_platform_interface/v4/src/webview_platform.dart';

import 'webview_platform_test.mocks.dart';

@GenerateMocks(<Type>[WebViewPlatform])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Default instance WebViewPlatform instance should be null', () {
    expect(WebViewPlatform.instance, isNull);
  });

  test('Cannot be implemented with `implements`', () {
    expect(() {
      WebViewPlatform.instance = ImplementsWebViewPlatform();
      // In versions of `package:plugin_platform_interface` prior to fixing
      // https://github.com/flutter/flutter/issues/109339, an attempt to
      // implement a platform interface using `implements` would sometimes throw
      // a `NoSuchMethodError` and other times throw an `AssertionError`.  After
      // the issue is fixed, an `AssertionError` will always be thrown.  For the
      // purpose of this test, we don't really care what exception is thrown, so
      // just allow any exception.
    }, throwsA(anything));
  });

  test('Can be extended', () {
    WebViewPlatform.instance = ExtendsWebViewPlatform();
  });

  test('Can be mocked with `implements`', () {
    final MockWebViewPlatform mock = MockWebViewPlatformWithMixin();
    WebViewPlatform.instance = mock;
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of createCookieManagerDelegate should throw unimplemented error',
      () {
    final WebViewPlatform webViewPlatform = ExtendsWebViewPlatform();

    expect(
      () => webViewPlatform.createPlatformCookieManager(
          const PlatformWebViewCookieManagerCreationParams()),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of createNavigationCallbackHandlerDelegate should throw unimplemented error',
      () {
    final WebViewPlatform webViewPlatform = ExtendsWebViewPlatform();

    expect(
      () => webViewPlatform.createPlatformNavigationDelegate(
          const PlatformNavigationDelegateCreationParams()),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of createWebViewControllerDelegate should throw unimplemented error',
      () {
    final WebViewPlatform webViewPlatform = ExtendsWebViewPlatform();

    expect(
      () => webViewPlatform.createPlatformWebViewController(
          const PlatformWebViewControllerCreationParams()),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of createWebViewWidgetDelegate should throw unimplemented error',
      () {
    final WebViewPlatform webViewPlatform = ExtendsWebViewPlatform();
    final MockWebViewControllerDelegate controller =
        MockWebViewControllerDelegate();

    expect(
      () => webViewPlatform.createPlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller)),
      throwsUnimplementedError,
    );
  });
}

class ImplementsWebViewPlatform implements WebViewPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWebViewPlatformWithMixin extends MockWebViewPlatform
    with
        // ignore: prefer_mixin
        MockPlatformInterfaceMixin {}

class ExtendsWebViewPlatform extends WebViewPlatform {}

class MockWebViewControllerDelegate extends Mock
    with
        // ignore: prefer_mixin
        MockPlatformInterfaceMixin
    implements
        PlatformWebViewController {}
