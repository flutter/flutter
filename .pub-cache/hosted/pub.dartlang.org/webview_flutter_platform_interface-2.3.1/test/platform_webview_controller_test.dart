// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'platform_navigation_delegate_test.dart';
import 'webview_platform_test.mocks.dart';

@GenerateMocks(<Type>[PlatformNavigationDelegate])
void main() {
  setUp(() {
    WebViewPlatform.instance = MockWebViewPlatformWithMixin();
  });

  test('Cannot be implemented with `implements`', () {
    when((WebViewPlatform.instance! as MockWebViewPlatform)
            .createPlatformWebViewController(any))
        .thenReturn(ImplementsPlatformWebViewController());

    expect(() {
      PlatformWebViewController(
          const PlatformWebViewControllerCreationParams());
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
    const PlatformWebViewControllerCreationParams params =
        PlatformWebViewControllerCreationParams();
    when((WebViewPlatform.instance! as MockWebViewPlatform)
            .createPlatformWebViewController(any))
        .thenReturn(ExtendsPlatformWebViewController(params));

    expect(PlatformWebViewController(params), isNotNull);
  });

  test('Can be mocked with `implements`', () {
    when((WebViewPlatform.instance! as MockWebViewPlatform)
            .createPlatformWebViewController(any))
        .thenReturn(MockWebViewControllerDelegate());

    expect(
        PlatformWebViewController(
            const PlatformWebViewControllerCreationParams()),
        isNotNull);
  });

  test('Default implementation of loadFile should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.loadFile(''),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of loadFlutterAsset should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.loadFlutterAsset(''),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of loadHtmlString should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.loadHtmlString(''),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of loadRequest should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.loadRequest(MockLoadRequestParamsDelegate()),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of currentUrl should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.currentUrl(),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of canGoBack should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.canGoBack(),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of canGoForward should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.canGoForward(),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of goBack should throw unimplemented error', () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.goBack(),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of goForward should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.goForward(),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of reload should throw unimplemented error', () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.reload(),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of clearCache should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.clearCache(),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of clearLocalStorage should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.clearLocalStorage(),
      throwsUnimplementedError,
    );
  });

  test(
    'Default implementation of the setNavigationCallback should throw unimplemented error',
    () {
      final PlatformWebViewController controller =
          ExtendsPlatformWebViewController(
              const PlatformWebViewControllerCreationParams());

      expect(
        () =>
            controller.setPlatformNavigationDelegate(MockNavigationDelegate()),
        throwsUnimplementedError,
      );
    },
  );

  test(
      'Default implementation of runJavaScript should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.runJavaScript('javaScript'),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of runJavaScriptReturningResult should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.runJavaScriptReturningResult('javaScript'),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of addJavaScriptChannel should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'test',
          onMessageReceived: (_) {},
        ),
      ),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of removeJavaScriptChannel should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.removeJavaScriptChannel('test'),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of getTitle should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.getTitle(),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of scrollTo should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.scrollTo(0, 0),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of scrollBy should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.scrollBy(0, 0),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of getScrollPosition should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.getScrollPosition(),
      throwsUnimplementedError,
    );
  });

  test('Default implementation of enableZoom should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.enableZoom(true),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of setBackgroundColor should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.setBackgroundColor(Colors.blue),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of setJavaScriptMode should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.setJavaScriptMode(JavaScriptMode.disabled),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of setUserAgent should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.setUserAgent(null),
      throwsUnimplementedError,
    );
  });

  test(
      'Default implementation of setOnPermissionRequest should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.setOnPlatformPermissionRequest((_) {}),
      throwsUnimplementedError,
    );
  });
}

class MockWebViewPlatformWithMixin extends MockWebViewPlatform
    with
        // ignore: prefer_mixin
        MockPlatformInterfaceMixin {}

class ImplementsPlatformWebViewController implements PlatformWebViewController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWebViewControllerDelegate extends Mock
    with
        // ignore: prefer_mixin
        MockPlatformInterfaceMixin
    implements
        PlatformWebViewController {}

class ExtendsPlatformWebViewController extends PlatformWebViewController {
  ExtendsPlatformWebViewController(super.params) : super.implementation();
}

// ignore: must_be_immutable
class MockLoadRequestParamsDelegate extends Mock
    with
        //ignore: prefer_mixin
        MockPlatformInterfaceMixin
    implements
        LoadRequestParams {}
