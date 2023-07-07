// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#104231)
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_platform_interface/v4/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/src/foundation/foundation.dart';
import 'package:webview_flutter_wkwebview/src/ui_kit/ui_kit.dart';
import 'package:webview_flutter_wkwebview/src/v4/src/webkit_proxy.dart';
import 'package:webview_flutter_wkwebview/src/v4/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_wkwebview/src/web_kit/web_kit.dart';

import 'webkit_webview_controller_test.mocks.dart';

@GenerateMocks(<Type>[
  UIScrollView,
  WKPreferences,
  WKUserContentController,
  WKWebsiteDataStore,
  WKWebView,
  WKWebViewConfiguration,
])
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('WebKitWebViewController', () {
    WebKitWebViewController createControllerWithMocks({
      MockUIScrollView? mockScrollView,
      MockWKPreferences? mockPreferences,
      MockWKUserContentController? mockUserContentController,
      MockWKWebsiteDataStore? mockWebsiteDataStore,
      MockWKWebView Function(
        WKWebViewConfiguration configuration, {
        void Function(
          String keyPath,
          NSObject object,
          Map<NSKeyValueChangeKey, Object?> change,
        )?
            observeValue,
      })?
          createMockWebView,
      MockWKWebViewConfiguration? mockWebViewConfiguration,
    }) {
      final MockWKWebViewConfiguration nonNullMockWebViewConfiguration =
          mockWebViewConfiguration ?? MockWKWebViewConfiguration();
      late final MockWKWebView nonNullMockWebView;

      final PlatformWebViewControllerCreationParams controllerCreationParams =
          WebKitWebViewControllerCreationParams(
        webKitProxy: WebKitProxy(
          createWebViewConfiguration: () => nonNullMockWebViewConfiguration,
          createWebView: (
            _, {
            void Function(
              String keyPath,
              NSObject object,
              Map<NSKeyValueChangeKey, Object?> change,
            )?
                observeValue,
          }) {
            nonNullMockWebView = createMockWebView == null
                ? MockWKWebView()
                : createMockWebView(
                    nonNullMockWebViewConfiguration,
                    observeValue: observeValue,
                  );
            return nonNullMockWebView;
          },
        ),
      );

      final WebKitWebViewController controller = WebKitWebViewController(
        controllerCreationParams,
      );

      when(nonNullMockWebView.scrollView)
          .thenReturn(mockScrollView ?? MockUIScrollView());
      when(nonNullMockWebView.configuration)
          .thenReturn(nonNullMockWebViewConfiguration);

      when(nonNullMockWebViewConfiguration.preferences)
          .thenReturn(mockPreferences ?? MockWKPreferences());
      when(nonNullMockWebViewConfiguration.userContentController).thenReturn(
          mockUserContentController ?? MockWKUserContentController());
      when(nonNullMockWebViewConfiguration.websiteDataStore)
          .thenReturn(mockWebsiteDataStore ?? MockWKWebsiteDataStore());

      return controller;
    }

    test('loadFile', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      await controller.loadFile('/path/to/file.html');
      verify(mockWebView.loadFileUrl(
        '/path/to/file.html',
        readAccessUrl: '/path/to',
      ));
    });

    test('loadFlutterAsset', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      await controller.loadFlutterAsset('test_assets/index.html');
      verify(mockWebView.loadFlutterAsset('test_assets/index.html'));
    });

    test('loadHtmlString', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      const String htmlString = '<html><body>Test data.</body></html>';
      await controller.loadHtmlString(htmlString, baseUrl: 'baseUrl');

      verify(mockWebView.loadHtmlString(
        '<html><body>Test data.</body></html>',
        baseUrl: 'baseUrl',
      ));
    });

    group('loadRequest', () {
      test('Throws ArgumentError for empty scheme', () async {
        final MockWKWebView mockWebView = MockWKWebView();

        final WebKitWebViewController controller = createControllerWithMocks(
          createMockWebView: (_, {dynamic observeValue}) => mockWebView,
        );

        expect(
          () async => await controller.loadRequest(
            LoadRequestParams(
              uri: Uri.parse('www.google.com'),
              method: LoadRequestMethod.get,
              headers: const <String, String>{},
            ),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('GET without headers', () async {
        final MockWKWebView mockWebView = MockWKWebView();

        final WebKitWebViewController controller = createControllerWithMocks(
          createMockWebView: (_, {dynamic observeValue}) => mockWebView,
        );

        await controller.loadRequest(
          LoadRequestParams(
            uri: Uri.parse('https://www.google.com'),
            method: LoadRequestMethod.get,
            headers: const <String, String>{},
          ),
        );

        final NSUrlRequest request = verify(mockWebView.loadRequest(captureAny))
            .captured
            .single as NSUrlRequest;
        expect(request.url, 'https://www.google.com');
        expect(request.allHttpHeaderFields, <String, String>{});
        expect(request.httpMethod, 'get');
      });

      test('GET with headers', () async {
        final MockWKWebView mockWebView = MockWKWebView();

        final WebKitWebViewController controller = createControllerWithMocks(
          createMockWebView: (_, {dynamic observeValue}) => mockWebView,
        );

        await controller.loadRequest(
          LoadRequestParams(
            uri: Uri.parse('https://www.google.com'),
            method: LoadRequestMethod.get,
            headers: const <String, String>{'a': 'header'},
          ),
        );

        final NSUrlRequest request = verify(mockWebView.loadRequest(captureAny))
            .captured
            .single as NSUrlRequest;
        expect(request.url, 'https://www.google.com');
        expect(request.allHttpHeaderFields, <String, String>{'a': 'header'});
        expect(request.httpMethod, 'get');
      });

      test('POST without body', () async {
        final MockWKWebView mockWebView = MockWKWebView();

        final WebKitWebViewController controller = createControllerWithMocks(
          createMockWebView: (_, {dynamic observeValue}) => mockWebView,
        );

        await controller.loadRequest(LoadRequestParams(
          uri: Uri.parse('https://www.google.com'),
          method: LoadRequestMethod.post,
          headers: const <String, String>{},
        ));

        final NSUrlRequest request = verify(mockWebView.loadRequest(captureAny))
            .captured
            .single as NSUrlRequest;
        expect(request.url, 'https://www.google.com');
        expect(request.httpMethod, 'post');
      });

      test('POST with body', () async {
        final MockWKWebView mockWebView = MockWKWebView();

        final WebKitWebViewController controller = createControllerWithMocks(
          createMockWebView: (_, {dynamic observeValue}) => mockWebView,
        );

        await controller.loadRequest(LoadRequestParams(
          uri: Uri.parse('https://www.google.com'),
          method: LoadRequestMethod.post,
          body: Uint8List.fromList('Test Body'.codeUnits),
          headers: const <String, String>{},
        ));

        final NSUrlRequest request = verify(mockWebView.loadRequest(captureAny))
            .captured
            .single as NSUrlRequest;
        expect(request.url, 'https://www.google.com');
        expect(request.httpMethod, 'post');
        expect(
          request.httpBody,
          Uint8List.fromList('Test Body'.codeUnits),
        );
      });
    });

    test('canGoBack', () {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      when(mockWebView.canGoBack()).thenAnswer(
        (_) => Future<bool>.value(false),
      );
      expect(controller.canGoBack(), completion(false));
    });

    test('canGoForward', () {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      when(mockWebView.canGoForward()).thenAnswer(
        (_) => Future<bool>.value(true),
      );
      expect(controller.canGoForward(), completion(true));
    });

    test('goBack', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      await controller.goBack();
      verify(mockWebView.goBack());
    });

    test('goForward', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      await controller.goForward();
      verify(mockWebView.goForward());
    });

    test('reload', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      await controller.reload();
      verify(mockWebView.reload());
    });

    test('enableGestureNavigation', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      await controller.enableGestureNavigation(true);
      verify(mockWebView.setAllowsBackForwardNavigationGestures(true));
    });

    test('runJavaScriptReturningResult', () {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      when(mockWebView.evaluateJavaScript('runJavaScript')).thenAnswer(
        (_) => Future<String>.value('returnString'),
      );
      expect(
        controller.runJavaScriptReturningResult('runJavaScript'),
        completion('returnString'),
      );
    });

    test('runJavaScriptReturningResult throws error on null return value', () {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      when(mockWebView.evaluateJavaScript('runJavaScript')).thenAnswer(
        (_) => Future<String?>.value(),
      );
      expect(
        () => controller.runJavaScriptReturningResult('runJavaScript'),
        throwsArgumentError,
      );
    });

    test('runJavaScript', () {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      when(mockWebView.evaluateJavaScript('runJavaScript')).thenAnswer(
        (_) => Future<String>.value('returnString'),
      );
      expect(
        controller.runJavaScript('runJavaScript'),
        completes,
      );
    });

    test('runJavaScript ignores exception with unsupported javaScript type',
        () {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      when(mockWebView.evaluateJavaScript('runJavaScript'))
          .thenThrow(PlatformException(
        code: '',
        details: const NSError(
          code: WKErrorCode.javaScriptResultTypeIsUnsupported,
          domain: '',
          localizedDescription: '',
        ),
      ));
      expect(
        controller.runJavaScript('runJavaScript'),
        completes,
      );
    });

    test('getTitle', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      when(mockWebView.getTitle())
          .thenAnswer((_) => Future<String>.value('Web Title'));
      expect(controller.getTitle(), completion('Web Title'));
    });

    test('currentUrl', () {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      when(mockWebView.getUrl())
          .thenAnswer((_) => Future<String>.value('myUrl.com'));
      expect(controller.currentUrl(), completion('myUrl.com'));
    });

    test('scrollTo', () async {
      final MockUIScrollView mockScrollView = MockUIScrollView();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockScrollView: mockScrollView,
      );

      await controller.scrollTo(2, 4);
      verify(mockScrollView.setContentOffset(const Point<double>(2.0, 4.0)));
    });

    test('scrollBy', () async {
      final MockUIScrollView mockScrollView = MockUIScrollView();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockScrollView: mockScrollView,
      );

      await controller.scrollBy(2, 4);
      verify(mockScrollView.scrollBy(const Point<double>(2.0, 4.0)));
    });

    test('getScrollPosition', () {
      final MockUIScrollView mockScrollView = MockUIScrollView();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockScrollView: mockScrollView,
      );

      when(mockScrollView.getContentOffset()).thenAnswer(
        (_) => Future<Point<double>>.value(const Point<double>(8.0, 16.0)),
      );
      expect(
        controller.getScrollPosition(),
        completion(const Point<double>(8.0, 16.0)),
      );
    });

    test('disable zoom', () async {
      final MockWKUserContentController mockUserContentController =
          MockWKUserContentController();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockUserContentController: mockUserContentController,
      );

      await controller.enableZoom(false);

      final WKUserScript zoomScript =
          verify(mockUserContentController.addUserScript(captureAny))
              .captured
              .first as WKUserScript;
      expect(zoomScript.isMainFrameOnly, isTrue);
      expect(zoomScript.injectionTime, WKUserScriptInjectionTime.atDocumentEnd);
      expect(
        zoomScript.source,
        "var meta = document.createElement('meta');\n"
        "meta.name = 'viewport';\n"
        "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, "
        "user-scalable=no';\n"
        "var head = document.getElementsByTagName('head')[0];head.appendChild(meta);",
      );
    });

    test('setBackgroundColor', () async {
      final MockWKWebView mockWebView = MockWKWebView();
      final MockUIScrollView mockScrollView = MockUIScrollView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
        mockScrollView: mockScrollView,
      );

      controller.setBackgroundColor(Colors.red);

      verify(mockWebView.setOpaque(false));
      verify(mockWebView.setBackgroundColor(Colors.transparent));
      verify(mockScrollView.setBackgroundColor(Colors.red));
    });

    test('userAgent', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      await controller.setUserAgent('MyUserAgent');
      verify(mockWebView.setCustomUserAgent('MyUserAgent'));
    });

    test('enable JavaScript', () async {
      final MockWKPreferences mockPreferences = MockWKPreferences();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockPreferences: mockPreferences,
      );

      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      verify(mockPreferences.setJavaScriptEnabled(true));
    });

    test('disable JavaScript', () async {
      final MockWKPreferences mockPreferences = MockWKPreferences();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockPreferences: mockPreferences,
      );

      await controller.setJavaScriptMode(JavaScriptMode.disabled);

      verify(mockPreferences.setJavaScriptEnabled(false));
    });

    test('clearCache', () {
      final MockWKWebsiteDataStore mockWebsiteDataStore =
          MockWKWebsiteDataStore();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockWebsiteDataStore: mockWebsiteDataStore,
      );
      when(
        mockWebsiteDataStore.removeDataOfTypes(
          <WKWebsiteDataType>{
            WKWebsiteDataType.memoryCache,
            WKWebsiteDataType.diskCache,
            WKWebsiteDataType.offlineWebApplicationCache,
          },
          DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ).thenAnswer((_) => Future<bool>.value(false));

      expect(controller.clearCache(), completes);
    });

    test('clearLocalStorage', () {
      final MockWKWebsiteDataStore mockWebsiteDataStore =
          MockWKWebsiteDataStore();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockWebsiteDataStore: mockWebsiteDataStore,
      );
      when(
        mockWebsiteDataStore.removeDataOfTypes(
          <WKWebsiteDataType>{WKWebsiteDataType.localStorage},
          DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ).thenAnswer((_) => Future<bool>.value(false));

      expect(controller.clearLocalStorage(), completes);
    });

    test('addJavaScriptChannel', () async {
      final WebKitProxy webKitProxy = WebKitProxy(
        createScriptMessageHandler: ({
          required void Function(
            WKUserContentController userContentController,
            WKScriptMessage message,
          )
              didReceiveScriptMessage,
        }) {
          return WKScriptMessageHandler.detached(
            didReceiveScriptMessage: didReceiveScriptMessage,
          );
        },
      );

      final WebKitJavaScriptChannelParams javaScriptChannelParams =
          WebKitJavaScriptChannelParams(
        name: 'name',
        onMessageReceived: (JavaScriptMessage message) {},
        webKitProxy: webKitProxy,
      );

      final MockWKUserContentController mockUserContentController =
          MockWKUserContentController();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockUserContentController: mockUserContentController,
      );

      await controller.addJavaScriptChannel(javaScriptChannelParams);
      verify(mockUserContentController.addScriptMessageHandler(
        argThat(isA<WKScriptMessageHandler>()),
        'name',
      ));

      final WKUserScript userScript =
          verify(mockUserContentController.addUserScript(captureAny))
              .captured
              .single as WKUserScript;
      expect(userScript.source, 'window.name = webkit.messageHandlers.name;');
      expect(
        userScript.injectionTime,
        WKUserScriptInjectionTime.atDocumentStart,
      );
    });

    test('removeJavaScriptChannel', () async {
      final WebKitProxy webKitProxy = WebKitProxy(
        createScriptMessageHandler: ({
          required void Function(
            WKUserContentController userContentController,
            WKScriptMessage message,
          )
              didReceiveScriptMessage,
        }) {
          return WKScriptMessageHandler.detached(
            didReceiveScriptMessage: didReceiveScriptMessage,
          );
        },
      );

      final WebKitJavaScriptChannelParams javaScriptChannelParams =
          WebKitJavaScriptChannelParams(
        name: 'name',
        onMessageReceived: (JavaScriptMessage message) {},
        webKitProxy: webKitProxy,
      );

      final MockWKUserContentController mockUserContentController =
          MockWKUserContentController();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockUserContentController: mockUserContentController,
      );

      await controller.addJavaScriptChannel(javaScriptChannelParams);
      reset(mockUserContentController);

      await controller.removeJavaScriptChannel('name');

      verify(mockUserContentController.removeAllUserScripts());
      verify(mockUserContentController.removeScriptMessageHandler('name'));

      verifyNoMoreInteractions(mockUserContentController);
    });

    test('removeJavaScriptChannel with zoom disabled', () async {
      final WebKitProxy webKitProxy = WebKitProxy(
        createScriptMessageHandler: ({
          required void Function(
            WKUserContentController userContentController,
            WKScriptMessage message,
          )
              didReceiveScriptMessage,
        }) {
          return WKScriptMessageHandler.detached(
            didReceiveScriptMessage: didReceiveScriptMessage,
          );
        },
      );

      final WebKitJavaScriptChannelParams javaScriptChannelParams =
          WebKitJavaScriptChannelParams(
        name: 'name',
        onMessageReceived: (JavaScriptMessage message) {},
        webKitProxy: webKitProxy,
      );

      final MockWKUserContentController mockUserContentController =
          MockWKUserContentController();

      final WebKitWebViewController controller = createControllerWithMocks(
        mockUserContentController: mockUserContentController,
      );

      await controller.enableZoom(false);
      await controller.addJavaScriptChannel(javaScriptChannelParams);
      clearInteractions(mockUserContentController);
      await controller.removeJavaScriptChannel('name');

      final WKUserScript zoomScript =
          verify(mockUserContentController.addUserScript(captureAny))
              .captured
              .first as WKUserScript;
      expect(zoomScript.isMainFrameOnly, isTrue);
      expect(zoomScript.injectionTime, WKUserScriptInjectionTime.atDocumentEnd);
      expect(
        zoomScript.source,
        "var meta = document.createElement('meta');\n"
        "meta.name = 'viewport';\n"
        "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, "
        "user-scalable=no';\n"
        "var head = document.getElementsByTagName('head')[0];head.appendChild(meta);",
      );
    });

    test('setPlatformNavigationDelegate', () {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      final WebKitNavigationDelegate navigationDelegate =
          WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(
          webKitProxy: WebKitProxy(
            createNavigationDelegate: CapturingNavigationDelegate.new,
          ),
        ),
      );

      controller.setPlatformNavigationDelegate(navigationDelegate);

      verify(
        mockWebView.setNavigationDelegate(
          CapturingNavigationDelegate.lastCreatedDelegate,
        ),
      );
    });

    test('setPlatformNavigationDelegate onProgress', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      late final void Function(
        String keyPath,
        NSObject object,
        Map<NSKeyValueChangeKey, Object?> change,
      ) webViewObserveValue;

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (
          _, {
          void Function(
            String keyPath,
            NSObject object,
            Map<NSKeyValueChangeKey, Object?> change,
          )?
              observeValue,
        }) {
          webViewObserveValue = observeValue!;
          return mockWebView;
        },
      );

      verify(
        mockWebView.addObserver(
          mockWebView,
          keyPath: 'estimatedProgress',
          options: <NSKeyValueObservingOptions>{
            NSKeyValueObservingOptions.newValue,
          },
        ),
      );

      final WebKitNavigationDelegate navigationDelegate =
          WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(
          webKitProxy: WebKitProxy(
            createNavigationDelegate: CapturingNavigationDelegate.new,
          ),
        ),
      );

      late final int callbackProgress;
      navigationDelegate.setOnProgress(
        (int progress) => callbackProgress = progress,
      );

      await controller.setPlatformNavigationDelegate(navigationDelegate);

      webViewObserveValue(
        'estimatedProgress',
        mockWebView,
        <NSKeyValueChangeKey, Object?>{NSKeyValueChangeKey.newValue: 0.0},
      );

      expect(callbackProgress, 0);
    });
  });

  group('WebKitJavaScriptChannelParams', () {
    test('onMessageReceived', () async {
      late final WKScriptMessageHandler messageHandler;

      final WebKitProxy webKitProxy = WebKitProxy(
        createScriptMessageHandler: ({
          required void Function(
            WKUserContentController userContentController,
            WKScriptMessage message,
          )
              didReceiveScriptMessage,
        }) {
          messageHandler = WKScriptMessageHandler.detached(
            didReceiveScriptMessage: didReceiveScriptMessage,
          );
          return messageHandler;
        },
      );

      late final String callbackMessage;
      WebKitJavaScriptChannelParams(
        name: 'name',
        onMessageReceived: (JavaScriptMessage message) {
          callbackMessage = message.message;
        },
        webKitProxy: webKitProxy,
      );

      messageHandler.didReceiveScriptMessage(
        MockWKUserContentController(),
        const WKScriptMessage(name: 'name', body: 'myMessage'),
      );

      expect(callbackMessage, 'myMessage');
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
