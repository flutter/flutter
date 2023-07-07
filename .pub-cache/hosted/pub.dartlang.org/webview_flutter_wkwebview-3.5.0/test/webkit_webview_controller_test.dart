// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/src/common/instance_manager.dart';
import 'package:webview_flutter_wkwebview/src/foundation/foundation.dart';
import 'package:webview_flutter_wkwebview/src/ui_kit/ui_kit.dart';
import 'package:webview_flutter_wkwebview/src/web_kit/web_kit.dart';
import 'package:webview_flutter_wkwebview/src/webkit_proxy.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'webkit_webview_controller_test.mocks.dart';

@GenerateMocks(<Type>[
  NSUrl,
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
      WKUIDelegate? uiDelegate,
      MockWKUserContentController? mockUserContentController,
      MockWKWebsiteDataStore? mockWebsiteDataStore,
      MockWKWebView Function(
        WKWebViewConfiguration configuration, {
        void Function(
          String keyPath,
          NSObject object,
          Map<NSKeyValueChangeKey, Object?> change,
        )? observeValue,
      })? createMockWebView,
      MockWKWebViewConfiguration? mockWebViewConfiguration,
      InstanceManager? instanceManager,
    }) {
      final MockWKWebViewConfiguration nonNullMockWebViewConfiguration =
          mockWebViewConfiguration ?? MockWKWebViewConfiguration();
      late final MockWKWebView nonNullMockWebView;

      final PlatformWebViewControllerCreationParams controllerCreationParams =
          WebKitWebViewControllerCreationParams(
        webKitProxy: WebKitProxy(
          createWebViewConfiguration: ({InstanceManager? instanceManager}) {
            return nonNullMockWebViewConfiguration;
          },
          createWebView: (
            _, {
            void Function(
              String keyPath,
              NSObject object,
              Map<NSKeyValueChangeKey, Object?> change,
            )? observeValue,
            InstanceManager? instanceManager,
          }) {
            nonNullMockWebView = createMockWebView == null
                ? MockWKWebView()
                : createMockWebView(
                    nonNullMockWebViewConfiguration,
                    observeValue: observeValue,
                  );
            return nonNullMockWebView;
          },
          createUIDelegate: ({
            void Function(
              WKWebView webView,
              WKWebViewConfiguration configuration,
              WKNavigationAction navigationAction,
            )? onCreateWebView,
            Future<WKPermissionDecision> Function(
              WKUIDelegate instance,
              WKWebView webView,
              WKSecurityOrigin origin,
              WKFrameInfo frame,
              WKMediaCaptureType type,
            )? requestMediaCapturePermission,
            InstanceManager? instanceManager,
          }) {
            return uiDelegate ??
                CapturingUIDelegate(
                  onCreateWebView: onCreateWebView,
                  requestMediaCapturePermission: requestMediaCapturePermission,
                );
          },
        ),
        instanceManager: instanceManager,
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

    group('WebKitWebViewControllerCreationParams', () {
      test('allowsInlineMediaPlayback', () {
        final MockWKWebViewConfiguration mockConfiguration =
            MockWKWebViewConfiguration();

        WebKitWebViewControllerCreationParams(
          webKitProxy: WebKitProxy(
            createWebViewConfiguration: ({InstanceManager? instanceManager}) {
              return mockConfiguration;
            },
          ),
          allowsInlineMediaPlayback: true,
        );

        verify(
          mockConfiguration.setAllowsInlineMediaPlayback(true),
        );
      });

      test('limitsNavigationsToAppBoundDomains', () {
        final MockWKWebViewConfiguration mockConfiguration =
            MockWKWebViewConfiguration();

        WebKitWebViewControllerCreationParams(
          webKitProxy: WebKitProxy(
            createWebViewConfiguration: ({InstanceManager? instanceManager}) {
              return mockConfiguration;
            },
          ),
          limitsNavigationsToAppBoundDomains: true,
        );

        verify(
          mockConfiguration.setLimitsNavigationsToAppBoundDomains(true),
        );
      });

      test('mediaTypesRequiringUserAction', () {
        final MockWKWebViewConfiguration mockConfiguration =
            MockWKWebViewConfiguration();

        WebKitWebViewControllerCreationParams(
          webKitProxy: WebKitProxy(
            createWebViewConfiguration: ({InstanceManager? instanceManager}) {
              return mockConfiguration;
            },
          ),
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{
            PlaybackMediaTypes.video,
          },
        );

        verify(
          mockConfiguration.setMediaTypesRequiringUserActionForPlayback(
            <WKAudiovisualMediaType>{
              WKAudiovisualMediaType.video,
            },
          ),
        );
      });

      test('mediaTypesRequiringUserAction defaults to include audio and video',
          () {
        final MockWKWebViewConfiguration mockConfiguration =
            MockWKWebViewConfiguration();

        WebKitWebViewControllerCreationParams(
          webKitProxy: WebKitProxy(
            createWebViewConfiguration: ({InstanceManager? instanceManager}) {
              return mockConfiguration;
            },
          ),
        );

        verify(
          mockConfiguration.setMediaTypesRequiringUserActionForPlayback(
            <WKAudiovisualMediaType>{
              WKAudiovisualMediaType.audio,
              WKAudiovisualMediaType.video,
            },
          ),
        );
      });

      test('mediaTypesRequiringUserAction sets value to none if set is empty',
          () {
        final MockWKWebViewConfiguration mockConfiguration =
            MockWKWebViewConfiguration();

        WebKitWebViewControllerCreationParams(
          webKitProxy: WebKitProxy(
            createWebViewConfiguration: ({InstanceManager? instanceManager}) {
              return mockConfiguration;
            },
          ),
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );

        verify(
          mockConfiguration.setMediaTypesRequiringUserActionForPlayback(
            <WKAudiovisualMediaType>{WKAudiovisualMediaType.none},
          ),
        );
      });
    });

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
          () async => controller.loadRequest(
            LoadRequestParams(uri: Uri.parse('www.google.com')),
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
          LoadRequestParams(uri: Uri.parse('https://www.google.com')),
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

    test('setAllowsBackForwardNavigationGestures', () async {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      await controller.setAllowsBackForwardNavigationGestures(true);
      verify(mockWebView.setAllowsBackForwardNavigationGestures(true));
    });

    test('runJavaScriptReturningResult', () {
      final MockWKWebView mockWebView = MockWKWebView();

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
      );

      final Object result = Object();
      when(mockWebView.evaluateJavaScript('runJavaScript')).thenAnswer(
        (_) => Future<Object>.value(result),
      );
      expect(
        controller.runJavaScriptReturningResult('runJavaScript'),
        completion(result),
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
        completion(const Offset(8.0, 16.0)),
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

      // UIScrollView.setBackgroundColor must be called last.
      verifyInOrder(<Object>[
        mockWebView.setOpaque(false),
        mockWebView.setBackgroundColor(Colors.transparent),
        mockScrollView.setBackgroundColor(Colors.red),
      ]);
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
          ) didReceiveScriptMessage,
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
          ) didReceiveScriptMessage,
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
          ) didReceiveScriptMessage,
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
            createUIDelegate: CapturingUIDelegate.new,
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
          )? observeValue,
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
            createUIDelegate: WKUIDelegate.detached,
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

    test('Requests to open a new window loads request in same window', () {
      // Reset last created delegate.
      CapturingUIDelegate.lastCreatedDelegate = CapturingUIDelegate();

      // Create a new WebKitWebViewController that sets
      // CapturingUIDelegate.lastCreatedDelegate.
      createControllerWithMocks();

      final MockWKWebView mockWebView = MockWKWebView();
      const NSUrlRequest request = NSUrlRequest(url: 'https://www.google.com');

      CapturingUIDelegate.lastCreatedDelegate.onCreateWebView!(
        mockWebView,
        WKWebViewConfiguration.detached(),
        const WKNavigationAction(
          request: request,
          targetFrame: WKFrameInfo(isMainFrame: false),
          navigationType: WKNavigationType.linkActivated,
        ),
      );

      verify(mockWebView.loadRequest(request));
    });

    test(
        'setPlatformNavigationDelegate onProgress can be changed by the WebKitNavigationDelegate',
        () async {
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
          )? observeValue,
        }) {
          webViewObserveValue = observeValue!;
          return mockWebView;
        },
      );

      final WebKitNavigationDelegate navigationDelegate =
          WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(
          webKitProxy: WebKitProxy(
            createNavigationDelegate: CapturingNavigationDelegate.new,
            createUIDelegate: WKUIDelegate.detached,
          ),
        ),
      );

      // First value of onProgress does nothing.
      await navigationDelegate.setOnProgress((_) {});
      await controller.setPlatformNavigationDelegate(navigationDelegate);

      // Second value of onProgress sets `callbackProgress`.
      late final int callbackProgress;
      await navigationDelegate.setOnProgress(
        (int progress) => callbackProgress = progress,
      );

      webViewObserveValue(
        'estimatedProgress',
        mockWebView,
        <NSKeyValueChangeKey, Object?>{NSKeyValueChangeKey.newValue: 0.0},
      );

      expect(callbackProgress, 0);
    });

    test('setPlatformNavigationDelegate onUrlChange', () async {
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
          )? observeValue,
        }) {
          webViewObserveValue = observeValue!;
          return mockWebView;
        },
      );

      verify(
        mockWebView.addObserver(
          mockWebView,
          keyPath: 'URL',
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
            createUIDelegate: WKUIDelegate.detached,
          ),
        ),
      );

      final Completer<UrlChange> urlChangeCompleter = Completer<UrlChange>();
      navigationDelegate.setOnUrlChange(
        (UrlChange change) => urlChangeCompleter.complete(change),
      );

      await controller.setPlatformNavigationDelegate(navigationDelegate);

      final MockNSUrl mockNSUrl = MockNSUrl();
      when(mockNSUrl.getAbsoluteString()).thenAnswer((_) {
        return Future<String>.value('https://www.google.com');
      });
      webViewObserveValue(
        'URL',
        mockWebView,
        <NSKeyValueChangeKey, Object?>{NSKeyValueChangeKey.newValue: mockNSUrl},
      );

      final UrlChange urlChange = await urlChangeCompleter.future;
      expect(urlChange.url, 'https://www.google.com');
    });

    test('setPlatformNavigationDelegate onUrlChange to null NSUrl', () async {
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
          )? observeValue,
        }) {
          webViewObserveValue = observeValue!;
          return mockWebView;
        },
      );

      final WebKitNavigationDelegate navigationDelegate =
          WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(
          webKitProxy: WebKitProxy(
            createNavigationDelegate: CapturingNavigationDelegate.new,
            createUIDelegate: WKUIDelegate.detached,
          ),
        ),
      );

      final Completer<UrlChange> urlChangeCompleter = Completer<UrlChange>();
      navigationDelegate.setOnUrlChange(
        (UrlChange change) => urlChangeCompleter.complete(change),
      );

      await controller.setPlatformNavigationDelegate(navigationDelegate);

      webViewObserveValue(
        'URL',
        mockWebView,
        <NSKeyValueChangeKey, Object?>{NSKeyValueChangeKey.newValue: null},
      );

      final UrlChange urlChange = await urlChangeCompleter.future;
      expect(urlChange.url, isNull);
    });

    test('webViewIdentifier', () {
      final InstanceManager instanceManager = InstanceManager(
        onWeakReferenceRemoved: (_) {},
      );
      final MockWKWebView mockWebView = MockWKWebView();
      when(mockWebView.copy()).thenReturn(MockWKWebView());
      instanceManager.addHostCreatedInstance(mockWebView, 0);

      final WebKitWebViewController controller = createControllerWithMocks(
        createMockWebView: (_, {dynamic observeValue}) => mockWebView,
        instanceManager: instanceManager,
      );

      expect(
        controller.webViewIdentifier,
        instanceManager.getIdentifier(mockWebView),
      );
    });

    test('setOnPermissionRequest', () async {
      final WebKitWebViewController controller = createControllerWithMocks();

      late final PlatformWebViewPermissionRequest permissionRequest;
      await controller.setOnPlatformPermissionRequest(
        (PlatformWebViewPermissionRequest request) async {
          permissionRequest = request;
          request.grant();
        },
      );

      final Future<WKPermissionDecision> Function(
        WKUIDelegate instance,
        WKWebView webView,
        WKSecurityOrigin origin,
        WKFrameInfo frame,
        WKMediaCaptureType type,
      ) onPermissionRequestCallback = CapturingUIDelegate
          .lastCreatedDelegate.requestMediaCapturePermission!;

      final WKPermissionDecision decision = await onPermissionRequestCallback(
        CapturingUIDelegate.lastCreatedDelegate,
        WKWebView.detached(),
        const WKSecurityOrigin(host: '', port: 0, protocol: ''),
        const WKFrameInfo(isMainFrame: false),
        WKMediaCaptureType.microphone,
      );

      expect(permissionRequest.types, <WebViewPermissionResourceType>[
        WebViewPermissionResourceType.microphone,
      ]);
      expect(decision, WKPermissionDecision.grant);
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
          ) didReceiveScriptMessage,
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
