// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/src/foundation/foundation.dart';
import 'package:webview_flutter_wkwebview/src/web_kit/web_kit.dart';
import 'package:webview_flutter_wkwebview/src/webkit_proxy.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('WebKitNavigationDelegate', () {
    test('WebKitNavigationDelegate uses params field in constructor', () async {
      await runZonedGuarded(
        () async => WebKitNavigationDelegate(
          const PlatformNavigationDelegateCreationParams(),
        ),
        (Object error, __) {
          expect(error, isNot(isA<TypeError>()));
        },
      );
    });

    test('setOnPageFinished', () {
      final WebKitNavigationDelegate webKitDelegate = WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(
          webKitProxy: WebKitProxy(
            createNavigationDelegate: CapturingNavigationDelegate.new,
            createUIDelegate: CapturingUIDelegate.new,
          ),
        ),
      );

      late final String callbackUrl;
      webKitDelegate.setOnPageFinished((String url) => callbackUrl = url);

      CapturingNavigationDelegate.lastCreatedDelegate.didFinishNavigation!(
        WKWebView.detached(),
        'https://www.google.com',
      );

      expect(callbackUrl, 'https://www.google.com');
    });

    test('setOnPageStarted', () {
      final WebKitNavigationDelegate webKitDelegate = WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(
          webKitProxy: WebKitProxy(
            createNavigationDelegate: CapturingNavigationDelegate.new,
            createUIDelegate: CapturingUIDelegate.new,
          ),
        ),
      );

      late final String callbackUrl;
      webKitDelegate.setOnPageStarted((String url) => callbackUrl = url);

      CapturingNavigationDelegate
          .lastCreatedDelegate.didStartProvisionalNavigation!(
        WKWebView.detached(),
        'https://www.google.com',
      );

      expect(callbackUrl, 'https://www.google.com');
    });

    test('onWebResourceError from didFailNavigation', () {
      final WebKitNavigationDelegate webKitDelegate = WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(
          webKitProxy: WebKitProxy(
            createNavigationDelegate: CapturingNavigationDelegate.new,
            createUIDelegate: CapturingUIDelegate.new,
          ),
        ),
      );

      late final WebKitWebResourceError callbackError;
      void onWebResourceError(WebResourceError error) {
        callbackError = error as WebKitWebResourceError;
      }

      webKitDelegate.setOnWebResourceError(onWebResourceError);

      CapturingNavigationDelegate.lastCreatedDelegate.didFailNavigation!(
        WKWebView.detached(),
        const NSError(
          code: WKErrorCode.webViewInvalidated,
          domain: 'domain',
          localizedDescription: 'my desc',
        ),
      );

      expect(callbackError.description, 'my desc');
      expect(callbackError.errorCode, WKErrorCode.webViewInvalidated);
      expect(callbackError.domain, 'domain');
      expect(callbackError.errorType, WebResourceErrorType.webViewInvalidated);
      expect(callbackError.isForMainFrame, true);
    });

    test('onWebResourceError from didFailProvisionalNavigation', () {
      final WebKitNavigationDelegate webKitDelegate = WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(
          webKitProxy: WebKitProxy(
            createNavigationDelegate: CapturingNavigationDelegate.new,
            createUIDelegate: CapturingUIDelegate.new,
          ),
        ),
      );

      late final WebKitWebResourceError callbackError;
      void onWebResourceError(WebResourceError error) {
        callbackError = error as WebKitWebResourceError;
      }

      webKitDelegate.setOnWebResourceError(onWebResourceError);

      CapturingNavigationDelegate
          .lastCreatedDelegate.didFailProvisionalNavigation!(
        WKWebView.detached(),
        const NSError(
          code: WKErrorCode.webViewInvalidated,
          domain: 'domain',
          localizedDescription: 'my desc',
        ),
      );

      expect(callbackError.description, 'my desc');
      expect(callbackError.errorCode, WKErrorCode.webViewInvalidated);
      expect(callbackError.domain, 'domain');
      expect(callbackError.errorType, WebResourceErrorType.webViewInvalidated);
      expect(callbackError.isForMainFrame, true);
    });

    test('onWebResourceError from webViewWebContentProcessDidTerminate', () {
      final WebKitNavigationDelegate webKitDelegate = WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(
          webKitProxy: WebKitProxy(
            createNavigationDelegate: CapturingNavigationDelegate.new,
            createUIDelegate: CapturingUIDelegate.new,
          ),
        ),
      );

      late final WebKitWebResourceError callbackError;
      void onWebResourceError(WebResourceError error) {
        callbackError = error as WebKitWebResourceError;
      }

      webKitDelegate.setOnWebResourceError(onWebResourceError);

      CapturingNavigationDelegate
          .lastCreatedDelegate.webViewWebContentProcessDidTerminate!(
        WKWebView.detached(),
      );

      expect(callbackError.description, '');
      expect(callbackError.errorCode, WKErrorCode.webContentProcessTerminated);
      expect(callbackError.domain, 'WKErrorDomain');
      expect(
        callbackError.errorType,
        WebResourceErrorType.webContentProcessTerminated,
      );
      expect(callbackError.isForMainFrame, true);
    });

    test('onNavigationRequest from decidePolicyForNavigationAction', () {
      final WebKitNavigationDelegate webKitDelegate = WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(
          webKitProxy: WebKitProxy(
            createNavigationDelegate: CapturingNavigationDelegate.new,
            createUIDelegate: CapturingUIDelegate.new,
          ),
        ),
      );

      late final NavigationRequest callbackRequest;
      FutureOr<NavigationDecision> onNavigationRequest(
          NavigationRequest request) {
        callbackRequest = request;
        return NavigationDecision.navigate;
      }

      webKitDelegate.setOnNavigationRequest(onNavigationRequest);

      expect(
        CapturingNavigationDelegate
            .lastCreatedDelegate.decidePolicyForNavigationAction!(
          WKWebView.detached(),
          const WKNavigationAction(
            request: NSUrlRequest(url: 'https://www.google.com'),
            targetFrame: WKFrameInfo(isMainFrame: false),
            navigationType: WKNavigationType.linkActivated,
          ),
        ),
        completion(WKNavigationActionPolicy.allow),
      );

      expect(callbackRequest.url, 'https://www.google.com');
      expect(callbackRequest.isMainFrame, isFalse);
    });
  });
}

// Records the last created instance of itself.
class CapturingNavigationDelegate extends WKNavigationDelegate {
  CapturingNavigationDelegate({
    super.didFinishNavigation,
    super.didStartProvisionalNavigation,
    super.didFailNavigation,
    super.didFailProvisionalNavigation,
    super.decidePolicyForNavigationAction,
    super.webViewWebContentProcessDidTerminate,
  }) : super.detached() {
    lastCreatedDelegate = this;
  }
  static CapturingNavigationDelegate lastCreatedDelegate =
      CapturingNavigationDelegate();
}

// Records the last created instance of itself.
class CapturingUIDelegate extends WKUIDelegate {
  CapturingUIDelegate({
    super.onCreateWebView,
    super.requestMediaCapturePermission,
    super.instanceManager,
  }) : super.detached() {
    lastCreatedDelegate = this;
  }
  static CapturingUIDelegate lastCreatedDelegate = CapturingUIDelegate();
}
