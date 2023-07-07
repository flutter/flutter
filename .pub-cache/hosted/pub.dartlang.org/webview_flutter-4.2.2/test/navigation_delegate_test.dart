// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'navigation_delegate_test.mocks.dart';

@GenerateMocks(<Type>[WebViewPlatform, PlatformNavigationDelegate])
void main() {
  group('NavigationDelegate', () {
    test('onNavigationRequest', () async {
      WebViewPlatform.instance = TestWebViewPlatform();

      NavigationDecision onNavigationRequest(NavigationRequest request) {
        return NavigationDecision.navigate;
      }

      final NavigationDelegate delegate = NavigationDelegate(
        onNavigationRequest: onNavigationRequest,
      );

      verify(delegate.platform.setOnNavigationRequest(onNavigationRequest));
    });

    test('onPageStarted', () async {
      WebViewPlatform.instance = TestWebViewPlatform();

      void onPageStarted(String url) {}

      final NavigationDelegate delegate = NavigationDelegate(
        onPageStarted: onPageStarted,
      );

      verify(delegate.platform.setOnPageStarted(onPageStarted));
    });

    test('onPageFinished', () async {
      WebViewPlatform.instance = TestWebViewPlatform();

      void onPageFinished(String url) {}

      final NavigationDelegate delegate = NavigationDelegate(
        onPageFinished: onPageFinished,
      );

      verify(delegate.platform.setOnPageFinished(onPageFinished));
    });

    test('onProgress', () async {
      WebViewPlatform.instance = TestWebViewPlatform();

      void onProgress(int progress) {}

      final NavigationDelegate delegate = NavigationDelegate(
        onProgress: onProgress,
      );

      verify(delegate.platform.setOnProgress(onProgress));
    });

    test('onWebResourceError', () async {
      WebViewPlatform.instance = TestWebViewPlatform();

      void onWebResourceError(WebResourceError error) {}

      final NavigationDelegate delegate = NavigationDelegate(
        onWebResourceError: onWebResourceError,
      );

      verify(delegate.platform.setOnWebResourceError(onWebResourceError));
    });

    test('onUrlChange', () async {
      WebViewPlatform.instance = TestWebViewPlatform();

      void onUrlChange(UrlChange change) {}

      final NavigationDelegate delegate = NavigationDelegate(
        onUrlChange: onUrlChange,
      );

      verify(delegate.platform.setOnUrlChange(onUrlChange));
    });
  });
}

class TestWebViewPlatform extends WebViewPlatform {
  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return TestMockPlatformNavigationDelegate();
  }
}

class TestMockPlatformNavigationDelegate extends MockPlatformNavigationDelegate
    with MockPlatformInterfaceMixin {}
