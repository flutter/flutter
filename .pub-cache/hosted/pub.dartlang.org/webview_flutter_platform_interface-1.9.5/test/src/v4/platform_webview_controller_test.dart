// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:webview_flutter_platform_interface/v4/src/platform_navigation_delegate.dart';
import 'package:webview_flutter_platform_interface/v4/src/platform_webview_controller.dart';
import 'package:webview_flutter_platform_interface/v4/src/webview_platform.dart';

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

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of loadFile should throw unimplemented error',
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
      // ignore: lines_longer_than_80_chars
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
      // ignore: lines_longer_than_80_chars
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

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of loadRequest should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.loadRequest(MockLoadRequestParamsDelegate()),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of currentUrl should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.currentUrl(),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of canGoBack should throw unimplemented error',
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
      // ignore: lines_longer_than_80_chars
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

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of goBack should throw unimplemented error', () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.goBack(),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of goForward should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.goForward(),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of reload should throw unimplemented error', () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.reload(),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of clearCache should throw unimplemented error',
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
      // ignore: lines_longer_than_80_chars
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
      // ignore: lines_longer_than_80_chars
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
      // ignore: lines_longer_than_80_chars
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
      // ignore: lines_longer_than_80_chars
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
      // ignore: lines_longer_than_80_chars
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

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of getTitle should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.getTitle(),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of scrollTo should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.scrollTo(0, 0),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of scrollBy should throw unimplemented error',
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
      // ignore: lines_longer_than_80_chars
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

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of enableDebugging should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.enableDebugging(true),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of enableGestureNavigation should throw unimplemented error',
      () {
    final PlatformWebViewController controller =
        ExtendsPlatformWebViewController(
            const PlatformWebViewControllerCreationParams());

    expect(
      () => controller.enableGestureNavigation(true),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of enableZoom should throw unimplemented error',
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
      // ignore: lines_longer_than_80_chars
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
      // ignore: lines_longer_than_80_chars
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
      // ignore: lines_longer_than_80_chars
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
  ExtendsPlatformWebViewController(
      PlatformWebViewControllerCreationParams params)
      : super.implementation(params);
}

// ignore: must_be_immutable
class MockLoadRequestParamsDelegate extends Mock
    with
        //ignore: prefer_mixin
        MockPlatformInterfaceMixin
    implements
        LoadRequestParams {}
