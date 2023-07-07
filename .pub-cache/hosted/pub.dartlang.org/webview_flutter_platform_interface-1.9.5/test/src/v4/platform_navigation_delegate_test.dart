// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:webview_flutter_platform_interface/v4/src/platform_navigation_delegate.dart';
import 'package:webview_flutter_platform_interface/v4/src/webview_platform.dart';

import 'webview_platform_test.mocks.dart';

void main() {
  setUp(() {
    WebViewPlatform.instance = MockWebViewPlatformWithMixin();
  });

  test('Cannot be implemented with `implements`', () {
    const PlatformNavigationDelegateCreationParams params =
        PlatformNavigationDelegateCreationParams();
    when(WebViewPlatform.instance!.createPlatformNavigationDelegate(params))
        .thenReturn(ImplementsPlatformNavigationDelegate());

    expect(() {
      PlatformNavigationDelegate(params);
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
    const PlatformNavigationDelegateCreationParams params =
        PlatformNavigationDelegateCreationParams();
    when(WebViewPlatform.instance!.createPlatformNavigationDelegate(params))
        .thenReturn(ExtendsPlatformNavigationDelegate(params));

    expect(PlatformNavigationDelegate(params), isNotNull);
  });

  test('Can be mocked with `implements`', () {
    const PlatformNavigationDelegateCreationParams params =
        PlatformNavigationDelegateCreationParams();
    when(WebViewPlatform.instance!.createPlatformNavigationDelegate(params))
        .thenReturn(MockNavigationDelegate());

    expect(PlatformNavigationDelegate(params), isNotNull);
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of setOnNavigationRequest should throw unimplemented error',
      () {
    final PlatformNavigationDelegate callbackDelegate =
        ExtendsPlatformNavigationDelegate(
            const PlatformNavigationDelegateCreationParams());

    expect(
      () => callbackDelegate.setOnNavigationRequest(
          ({required bool isForMainFrame, required String url}) => true),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of setOnPageStarted should throw unimplemented error',
      () {
    final PlatformNavigationDelegate callbackDelegate =
        ExtendsPlatformNavigationDelegate(
            const PlatformNavigationDelegateCreationParams());

    expect(
      () => callbackDelegate.setOnPageStarted((String url) {}),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of setOnPageFinished should throw unimplemented error',
      () {
    final PlatformNavigationDelegate callbackDelegate =
        ExtendsPlatformNavigationDelegate(
            const PlatformNavigationDelegateCreationParams());

    expect(
      () => callbackDelegate.setOnPageFinished((String url) {}),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of setOnProgress should throw unimplemented error',
      () {
    final PlatformNavigationDelegate callbackDelegate =
        ExtendsPlatformNavigationDelegate(
            const PlatformNavigationDelegateCreationParams());

    expect(
      () => callbackDelegate.setOnProgress((int progress) {}),
      throwsUnimplementedError,
    );
  });

  test(
      // ignore: lines_longer_than_80_chars
      'Default implementation of setOnWebResourceError should throw unimplemented error',
      () {
    final PlatformNavigationDelegate callbackDelegate =
        ExtendsPlatformNavigationDelegate(
            const PlatformNavigationDelegateCreationParams());

    expect(
      () => callbackDelegate.setOnWebResourceError((WebResourceError error) {}),
      throwsUnimplementedError,
    );
  });
}

class MockWebViewPlatformWithMixin extends MockWebViewPlatform
    with
        // ignore: prefer_mixin
        MockPlatformInterfaceMixin {}

class ImplementsPlatformNavigationDelegate
    implements PlatformNavigationDelegate {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNavigationDelegate extends Mock
    with
        // ignore: prefer_mixin
        MockPlatformInterfaceMixin
    implements
        PlatformNavigationDelegate {}

class ExtendsPlatformNavigationDelegate extends PlatformNavigationDelegate {
  ExtendsPlatformNavigationDelegate(
      PlatformNavigationDelegateCreationParams params)
      : super.implementation(params);
}
