// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_android/src/android_webview.dart'
    as android_webview;
import 'package:webview_flutter_android/src/android_webview_api_impls.dart';
import 'package:webview_flutter_android/src/instance_manager.dart';
import 'package:webview_flutter_android/webview_android_widget.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'android_webview_test.mocks.dart' show MockTestWebViewHostApi;
import 'test_android_webview.pigeon.dart';
import 'webview_android_widget_test.mocks.dart';

@GenerateMocks(<Type>[
  android_webview.FlutterAssetManager,
  android_webview.WebSettings,
  android_webview.WebStorage,
  android_webview.WebView,
  android_webview.WebResourceRequest,
  WebViewAndroidDownloadListener,
  WebViewAndroidJavaScriptChannel,
  WebViewAndroidWebChromeClient,
  WebViewAndroidWebViewClient,
  JavascriptChannelRegistry,
  WebViewPlatformCallbacksHandler,
  WebViewProxy,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebViewAndroidWidget', () {
    late MockFlutterAssetManager mockFlutterAssetManager;
    late MockWebView mockWebView;
    late MockWebSettings mockWebSettings;
    late MockWebStorage mockWebStorage;
    late MockWebViewProxy mockWebViewProxy;

    late MockWebViewPlatformCallbacksHandler mockCallbacksHandler;
    late WebViewAndroidWebViewClient webViewClient;
    late WebViewAndroidDownloadListener downloadListener;
    late WebViewAndroidWebChromeClient webChromeClient;

    late MockJavascriptChannelRegistry mockJavascriptChannelRegistry;

    late WebViewAndroidPlatformController testController;

    setUp(() {
      mockFlutterAssetManager = MockFlutterAssetManager();
      mockWebView = MockWebView();
      mockWebSettings = MockWebSettings();
      mockWebStorage = MockWebStorage();
      when(mockWebView.settings).thenReturn(mockWebSettings);

      mockWebViewProxy = MockWebViewProxy();
      when(mockWebViewProxy.createWebView(
        useHybridComposition: anyNamed('useHybridComposition'),
      )).thenReturn(mockWebView);

      mockCallbacksHandler = MockWebViewPlatformCallbacksHandler();
      mockJavascriptChannelRegistry = MockJavascriptChannelRegistry();
    });

    // Builds a AndroidWebViewWidget with default parameters.
    Future<void> buildWidget(
      WidgetTester tester, {
      CreationParams? creationParams,
      bool hasNavigationDelegate = false,
      bool hasProgressTracking = false,
      bool useHybridComposition = false,
    }) async {
      await tester.pumpWidget(WebViewAndroidWidget(
        useHybridComposition: useHybridComposition,
        creationParams: creationParams ??
            CreationParams(
                webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: hasNavigationDelegate,
              hasProgressTracking: hasProgressTracking,
            )),
        callbacksHandler: mockCallbacksHandler,
        javascriptChannelRegistry: mockJavascriptChannelRegistry,
        webViewProxy: mockWebViewProxy,
        flutterAssetManager: mockFlutterAssetManager,
        webStorage: mockWebStorage,
        onBuildWidget: (WebViewAndroidPlatformController controller) {
          testController = controller;
          return Container();
        },
      ));

      webViewClient = testController.webViewClient;
      downloadListener = testController.downloadListener;
      webChromeClient = testController.webChromeClient;
    }

    testWidgets('WebViewAndroidWidget', (WidgetTester tester) async {
      await buildWidget(tester);

      verify(mockWebSettings.setDomStorageEnabled(true));
      verify(mockWebSettings.setJavaScriptCanOpenWindowsAutomatically(true));
      verify(mockWebSettings.setSupportMultipleWindows(true));
      verify(mockWebSettings.setLoadWithOverviewMode(true));
      verify(mockWebSettings.setUseWideViewPort(true));
      verify(mockWebSettings.setDisplayZoomControls(false));
      verify(mockWebSettings.setBuiltInZoomControls(true));

      verifyInOrder(<Future<void>>[
        mockWebView.setWebViewClient(webViewClient),
        mockWebView.setDownloadListener(downloadListener),
        mockWebView.setWebChromeClient(webChromeClient),
      ]);
    });

    testWidgets(
      'Create Widget with Hybrid Composition',
      (WidgetTester tester) async {
        await buildWidget(tester, useHybridComposition: true);
        verify(mockWebViewProxy.createWebView(useHybridComposition: true));
      },
    );

    group('CreationParams', () {
      testWidgets('initialUrl', (WidgetTester tester) async {
        await buildWidget(
          tester,
          creationParams: CreationParams(
            initialUrl: 'https://www.google.com',
            webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: false,
            ),
          ),
        );
        verify(mockWebView.loadUrl(
          'https://www.google.com',
          <String, String>{},
        ));
      });

      testWidgets('userAgent', (WidgetTester tester) async {
        await buildWidget(
          tester,
          creationParams: CreationParams(
            userAgent: 'MyUserAgent',
            webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: false,
            ),
          ),
        );

        verify(mockWebSettings.setUserAgentString('MyUserAgent'));
      });

      testWidgets('autoMediaPlaybackPolicy true', (WidgetTester tester) async {
        await buildWidget(
          tester,
          creationParams: CreationParams(
            webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: false,
            ),
          ),
        );

        verify(mockWebSettings.setMediaPlaybackRequiresUserGesture(any));
      });

      testWidgets('autoMediaPlaybackPolicy false', (WidgetTester tester) async {
        await buildWidget(
          tester,
          creationParams: CreationParams(
            autoMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
            webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: false,
            ),
          ),
        );

        verify(mockWebSettings.setMediaPlaybackRequiresUserGesture(false));
      });

      testWidgets('javascriptChannelNames', (WidgetTester tester) async {
        await buildWidget(
          tester,
          creationParams: CreationParams(
            javascriptChannelNames: <String>{'a', 'b'},
            webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: false,
            ),
          ),
        );

        final List<dynamic> javaScriptChannels =
            verify(mockWebView.addJavaScriptChannel(captureAny)).captured;
        expect(javaScriptChannels[0].channelName, 'a');
        expect(javaScriptChannels[1].channelName, 'b');
      });

      group('WebSettings', () {
        testWidgets('javascriptMode', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                javascriptMode: JavascriptMode.unrestricted,
                hasNavigationDelegate: false,
              ),
            ),
          );

          verify(mockWebSettings.setJavaScriptEnabled(true));
        });

        testWidgets('hasNavigationDelegate', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                hasNavigationDelegate: true,
              ),
            ),
          );

          expect(testController.webViewClient.handlesNavigation, isTrue);
          expect(testController.webViewClient.shouldOverrideUrlLoading, isTrue);
        });

        testWidgets('debuggingEnabled true', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                debuggingEnabled: true,
                hasNavigationDelegate: false,
              ),
            ),
          );

          verify(mockWebViewProxy.setWebContentsDebuggingEnabled(true));
        });

        testWidgets('debuggingEnabled false', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                debuggingEnabled: false,
                hasNavigationDelegate: false,
              ),
            ),
          );

          verify(mockWebViewProxy.setWebContentsDebuggingEnabled(false));
        });

        testWidgets('userAgent', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.of('myUserAgent'),
                hasNavigationDelegate: false,
              ),
            ),
          );

          verify(mockWebSettings.setUserAgentString('myUserAgent'));
        });

        testWidgets('zoomEnabled', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                zoomEnabled: false,
                hasNavigationDelegate: false,
              ),
            ),
          );

          verify(mockWebSettings.setSupportZoom(false));
        });
      });
    });

    group('WebViewPlatformController', () {
      testWidgets('loadFile without "file://" prefix',
          (WidgetTester tester) async {
        await buildWidget(tester);

        const String filePath = '/path/to/file.html';
        await testController.loadFile(filePath);

        verify(mockWebView.loadUrl(
          'file://$filePath',
          <String, String>{},
        ));
      });

      testWidgets('loadFile with "file://" prefix',
          (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.loadFile('file:///path/to/file.html');

        verify(mockWebView.loadUrl(
          'file:///path/to/file.html',
          <String, String>{},
        ));
      });

      testWidgets('loadFile should setAllowFileAccess to true',
          (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.loadFile('file:///path/to/file.html');

        verify(mockWebSettings.setAllowFileAccess(true));
      });

      testWidgets('loadFlutterAsset', (WidgetTester tester) async {
        await buildWidget(tester);
        const String assetKey = 'test_assets/index.html';

        when(mockFlutterAssetManager.getAssetFilePathByName(assetKey))
            .thenAnswer(
                (_) => Future<String>.value('flutter_assets/$assetKey'));
        when(mockFlutterAssetManager.list('flutter_assets/test_assets'))
            .thenAnswer(
                (_) => Future<List<String>>.value(<String>['index.html']));

        await testController.loadFlutterAsset(assetKey);

        verify(mockWebView.loadUrl(
          'file:///android_asset/flutter_assets/$assetKey',
          <String, String>{},
        ));
      });

      testWidgets('loadFlutterAsset with file in root',
          (WidgetTester tester) async {
        await buildWidget(tester);
        const String assetKey = 'index.html';

        when(mockFlutterAssetManager.getAssetFilePathByName(assetKey))
            .thenAnswer(
                (_) => Future<String>.value('flutter_assets/$assetKey'));
        when(mockFlutterAssetManager.list('flutter_assets')).thenAnswer(
            (_) => Future<List<String>>.value(<String>['index.html']));

        await testController.loadFlutterAsset(assetKey);

        verify(mockWebView.loadUrl(
          'file:///android_asset/flutter_assets/$assetKey',
          <String, String>{},
        ));
      });

      testWidgets(
          'loadFlutterAsset throws ArgumentError when asset does not exists',
          (WidgetTester tester) async {
        await buildWidget(tester);
        const String assetKey = 'test_assets/index.html';

        when(mockFlutterAssetManager.getAssetFilePathByName(assetKey))
            .thenAnswer(
                (_) => Future<String>.value('flutter_assets/$assetKey'));
        when(mockFlutterAssetManager.list('flutter_assets/test_assets'))
            .thenAnswer((_) => Future<List<String>>.value(<String>['']));

        expect(
          () => testController.loadFlutterAsset(assetKey),
          throwsA(
            isA<ArgumentError>()
                .having((ArgumentError error) => error.name, 'name', 'key')
                .having((ArgumentError error) => error.message, 'message',
                    'Asset for key "$assetKey" not found.'),
          ),
        );
      });

      testWidgets('loadHtmlString without base URL',
          (WidgetTester tester) async {
        await buildWidget(tester);

        const String htmlString = '<html><body>Test data.</body></html>';
        await testController.loadHtmlString(htmlString);

        verify(mockWebView.loadDataWithBaseUrl(
          data: htmlString,
          mimeType: 'text/html',
        ));
      });

      testWidgets('loadHtmlString with base URL', (WidgetTester tester) async {
        await buildWidget(tester);

        const String htmlString = '<html><body>Test data.</body></html>';
        await testController.loadHtmlString(
          htmlString,
          baseUrl: 'https://flutter.dev',
        );

        verify(mockWebView.loadDataWithBaseUrl(
          baseUrl: 'https://flutter.dev',
          data: htmlString,
          mimeType: 'text/html',
        ));
      });

      testWidgets('loadUrl', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.loadUrl(
          'https://www.google.com',
          <String, String>{'a': 'header'},
        );

        verify(mockWebView.loadUrl(
          'https://www.google.com',
          <String, String>{'a': 'header'},
        ));
      });

      group('loadRequest', () {
        testWidgets('Throws ArgumentError for empty scheme',
            (WidgetTester tester) async {
          await buildWidget(tester);

          expect(
              () async => await testController.loadRequest(
                    WebViewRequest(
                      uri: Uri.parse('www.google.com'),
                      method: WebViewRequestMethod.get,
                    ),
                  ),
              throwsA(const TypeMatcher<ArgumentError>()));
        });

        testWidgets('GET without headers', (WidgetTester tester) async {
          await buildWidget(tester);

          await testController.loadRequest(WebViewRequest(
            uri: Uri.parse('https://www.google.com'),
            method: WebViewRequestMethod.get,
          ));

          verify(mockWebView.loadUrl(
            'https://www.google.com',
            <String, String>{},
          ));
        });

        testWidgets('GET with headers', (WidgetTester tester) async {
          await buildWidget(tester);

          await testController.loadRequest(WebViewRequest(
            uri: Uri.parse('https://www.google.com'),
            method: WebViewRequestMethod.get,
            headers: <String, String>{'a': 'header'},
          ));

          verify(mockWebView.loadUrl(
            'https://www.google.com',
            <String, String>{'a': 'header'},
          ));
        });

        testWidgets('POST without body', (WidgetTester tester) async {
          await buildWidget(tester);

          await testController.loadRequest(WebViewRequest(
            uri: Uri.parse('https://www.google.com'),
            method: WebViewRequestMethod.post,
          ));

          verify(mockWebView.postUrl(
            'https://www.google.com',
            Uint8List(0),
          ));
        });

        testWidgets('POST with body', (WidgetTester tester) async {
          await buildWidget(tester);

          final Uint8List body = Uint8List.fromList('Test Body'.codeUnits);

          await testController.loadRequest(WebViewRequest(
              uri: Uri.parse('https://www.google.com'),
              method: WebViewRequestMethod.post,
              body: body));

          verify(mockWebView.postUrl(
            'https://www.google.com',
            body,
          ));
        });
      });

      testWidgets('no update to userAgentString when there is no change',
          (WidgetTester tester) async {
        await buildWidget(tester);

        reset(mockWebSettings);

        await testController.updateSettings(WebSettings(
          userAgent: const WebSetting<String>.absent(),
        ));

        verifyNever(mockWebSettings.setUserAgentString(any));
      });

      testWidgets('update null userAgentString with empty string',
          (WidgetTester tester) async {
        await buildWidget(tester);

        reset(mockWebSettings);

        await testController.updateSettings(WebSettings(
          userAgent: const WebSetting<String?>.of(null),
        ));

        verify(mockWebSettings.setUserAgentString(''));
      });

      testWidgets('currentUrl', (WidgetTester tester) async {
        await buildWidget(tester);

        when(mockWebView.getUrl())
            .thenAnswer((_) => Future<String>.value('https://www.google.com'));
        expect(
            testController.currentUrl(), completion('https://www.google.com'));
      });

      testWidgets('canGoBack', (WidgetTester tester) async {
        await buildWidget(tester);

        when(mockWebView.canGoBack()).thenAnswer(
          (_) => Future<bool>.value(false),
        );
        expect(testController.canGoBack(), completion(false));
      });

      testWidgets('canGoForward', (WidgetTester tester) async {
        await buildWidget(tester);

        when(mockWebView.canGoForward()).thenAnswer(
          (_) => Future<bool>.value(true),
        );
        expect(testController.canGoForward(), completion(true));
      });

      testWidgets('goBack', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.goBack();
        verify(mockWebView.goBack());
      });

      testWidgets('goForward', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.goForward();
        verify(mockWebView.goForward());
      });

      testWidgets('reload', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.reload();
        verify(mockWebView.reload());
      });

      testWidgets('clearCache', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.clearCache();
        verify(mockWebView.clearCache(true));
        verify(mockWebStorage.deleteAllData());
      });

      testWidgets('evaluateJavascript', (WidgetTester tester) async {
        await buildWidget(tester);

        when(mockWebView.evaluateJavascript('runJavaScript')).thenAnswer(
          (_) => Future<String>.value('returnString'),
        );
        expect(
          testController.evaluateJavascript('runJavaScript'),
          completion('returnString'),
        );
      });

      testWidgets('runJavascriptReturningResult', (WidgetTester tester) async {
        await buildWidget(tester);

        when(mockWebView.evaluateJavascript('runJavaScript')).thenAnswer(
          (_) => Future<String>.value('returnString'),
        );
        expect(
          testController.runJavascriptReturningResult('runJavaScript'),
          completion('returnString'),
        );
      });

      testWidgets('runJavascript', (WidgetTester tester) async {
        await buildWidget(tester);

        when(mockWebView.evaluateJavascript('runJavaScript')).thenAnswer(
          (_) => Future<String>.value('returnString'),
        );
        expect(
          testController.runJavascript('runJavaScript'),
          completes,
        );
      });

      testWidgets('addJavascriptChannels', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.addJavascriptChannels(<String>{'c', 'd'});
        final List<dynamic> javaScriptChannels =
            verify(mockWebView.addJavaScriptChannel(captureAny)).captured;
        expect(javaScriptChannels[0].channelName, 'c');
        expect(javaScriptChannels[1].channelName, 'd');
      });

      testWidgets('removeJavascriptChannels', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.addJavascriptChannels(<String>{'c', 'd'});
        await testController.removeJavascriptChannels(<String>{'c', 'd'});
        final List<dynamic> javaScriptChannels =
            verify(mockWebView.removeJavaScriptChannel(captureAny)).captured;
        expect(javaScriptChannels[0].channelName, 'c');
        expect(javaScriptChannels[1].channelName, 'd');
      });

      testWidgets('getTitle', (WidgetTester tester) async {
        await buildWidget(tester);

        when(mockWebView.getTitle())
            .thenAnswer((_) => Future<String>.value('Web Title'));
        expect(testController.getTitle(), completion('Web Title'));
      });

      testWidgets('scrollTo', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.scrollTo(1, 2);
        verify(mockWebView.scrollTo(1, 2));
      });

      testWidgets('scrollBy', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.scrollBy(3, 4);
        verify(mockWebView.scrollBy(3, 4));
      });

      testWidgets('getScrollX', (WidgetTester tester) async {
        await buildWidget(tester);

        when(mockWebView.getScrollX()).thenAnswer((_) => Future<int>.value(23));
        expect(testController.getScrollX(), completion(23));
      });

      testWidgets('getScrollY', (WidgetTester tester) async {
        await buildWidget(tester);

        when(mockWebView.getScrollY()).thenAnswer((_) => Future<int>.value(25));
        expect(testController.getScrollY(), completion(25));
      });
    });

    group('WebViewPlatformCallbacksHandler', () {
      testWidgets('onPageStarted', (WidgetTester tester) async {
        await buildWidget(tester);
        webViewClient.onPageStarted(mockWebView, 'https://google.com');
        verify(mockCallbacksHandler.onPageStarted('https://google.com'));
      });

      testWidgets('onPageFinished', (WidgetTester tester) async {
        await buildWidget(tester);
        webViewClient.onPageFinished(mockWebView, 'https://google.com');
        verify(mockCallbacksHandler.onPageFinished('https://google.com'));
      });

      testWidgets('onWebResourceError from onReceivedError',
          (WidgetTester tester) async {
        await buildWidget(tester);
        webViewClient.onReceivedError(
          mockWebView,
          android_webview.WebViewClient.errorAuthentication,
          'description',
          'https://google.com',
        );

        final WebResourceError error =
            verify(mockCallbacksHandler.onWebResourceError(captureAny))
                .captured
                .single as WebResourceError;
        expect(error.description, 'description');
        expect(error.errorCode, -4);
        expect(error.failingUrl, 'https://google.com');
        expect(error.domain, isNull);
        expect(error.errorType, WebResourceErrorType.authentication);
      });

      testWidgets('onWebResourceError from onReceivedRequestError',
          (WidgetTester tester) async {
        await buildWidget(tester);
        webViewClient.onReceivedRequestError(
          mockWebView,
          android_webview.WebResourceRequest(
            url: 'https://google.com',
            isForMainFrame: true,
            isRedirect: false,
            hasGesture: false,
            method: 'POST',
            requestHeaders: <String, String>{},
          ),
          android_webview.WebResourceError(
            errorCode: android_webview.WebViewClient.errorUnsafeResource,
            description: 'description',
          ),
        );

        final WebResourceError error =
            verify(mockCallbacksHandler.onWebResourceError(captureAny))
                .captured
                .single as WebResourceError;
        expect(error.description, 'description');
        expect(error.errorCode, -16);
        expect(error.failingUrl, 'https://google.com');
        expect(error.domain, isNull);
        expect(error.errorType, WebResourceErrorType.unsafeResource);
      });

      testWidgets('onNavigationRequest from urlLoading',
          (WidgetTester tester) async {
        await buildWidget(tester, hasNavigationDelegate: true);
        when(mockCallbacksHandler.onNavigationRequest(
          isForMainFrame: argThat(isTrue, named: 'isForMainFrame'),
          url: 'https://google.com',
        )).thenReturn(true);

        webViewClient.urlLoading(mockWebView, 'https://google.com');
        verify(mockCallbacksHandler.onNavigationRequest(
          url: 'https://google.com',
          isForMainFrame: true,
        ));
        verify(mockWebView.loadUrl('https://google.com', <String, String>{}));
      });

      testWidgets('onNavigationRequest from requestLoading',
          (WidgetTester tester) async {
        await buildWidget(tester, hasNavigationDelegate: true);
        when(mockCallbacksHandler.onNavigationRequest(
          isForMainFrame: argThat(isTrue, named: 'isForMainFrame'),
          url: 'https://google.com',
        )).thenReturn(true);

        webViewClient.requestLoading(
          mockWebView,
          android_webview.WebResourceRequest(
            url: 'https://google.com',
            isForMainFrame: true,
            isRedirect: false,
            hasGesture: false,
            method: 'POST',
            requestHeaders: <String, String>{},
          ),
        );
        verify(mockCallbacksHandler.onNavigationRequest(
          url: 'https://google.com',
          isForMainFrame: true,
        ));
        verify(mockWebView.loadUrl('https://google.com', <String, String>{}));
      });

      group('JavascriptChannelRegistry', () {
        testWidgets('onJavascriptChannelMessage', (WidgetTester tester) async {
          await buildWidget(tester);

          await testController.addJavascriptChannels(<String>{'hello'});

          final WebViewAndroidJavaScriptChannel javaScriptChannel =
              verify(mockWebView.addJavaScriptChannel(captureAny))
                  .captured
                  .single as WebViewAndroidJavaScriptChannel;
          javaScriptChannel.postMessage('goodbye');
          verify(mockJavascriptChannelRegistry.onJavascriptChannelMessage(
            'hello',
            'goodbye',
          ));
        });
      });
    });
  });

  group('WebViewProxy', () {
    late MockTestWebViewHostApi mockPlatformHostApi;
    late InstanceManager instanceManager;

    setUp(() {
      // WebViewProxy calls static methods that can't be mocked, so the mocks
      // have to be set up at the next layer down, by mocking the implementation
      // of WebView itstelf.
      mockPlatformHostApi = MockTestWebViewHostApi();
      TestWebViewHostApi.setup(mockPlatformHostApi);
      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
      android_webview.WebView.api =
          WebViewHostApiImpl(instanceManager: instanceManager);
    });

    test('setWebContentsDebuggingEnabled true', () {
      const WebViewProxy webViewProxy = WebViewProxy();
      webViewProxy.setWebContentsDebuggingEnabled(true);
      verify(mockPlatformHostApi.setWebContentsDebuggingEnabled(true));
    });

    test('setWebContentsDebuggingEnabled false', () {
      const WebViewProxy webViewProxy = WebViewProxy();
      webViewProxy.setWebContentsDebuggingEnabled(false);
      verify(mockPlatformHostApi.setWebContentsDebuggingEnabled(false));
    });
  });

  group('WebViewAndroidWebViewClient', () {
    test(
        'urlLoading should call loadUrl when onNavigationRequestCallback returns true',
        () {
      final Completer<void> completer = Completer<void>();
      final WebViewAndroidWebViewClient webViewClient =
          WebViewAndroidWebViewClient.handlesNavigation(
              onPageStartedCallback: (_) {},
              onPageFinishedCallback: (_) {},
              onWebResourceErrorCallback: (_) {},
              onNavigationRequestCallback: ({
                required bool isForMainFrame,
                required String url,
              }) =>
                  true,
              loadUrl: (String url, Map<String, String>? headers) async {
                completer.complete();
              });

      webViewClient.urlLoading(MockWebView(), 'https://flutter.dev');
      expect(completer.isCompleted, isTrue);
    });

    test(
        'urlLoading should call loadUrl when onNavigationRequestCallback returns a Future true',
        () async {
      final Completer<void> completer = Completer<void>();
      final WebViewAndroidWebViewClient webViewClient =
          WebViewAndroidWebViewClient.handlesNavigation(
              onPageStartedCallback: (_) {},
              onPageFinishedCallback: (_) {},
              onWebResourceErrorCallback: (_) {},
              onNavigationRequestCallback: ({
                required bool isForMainFrame,
                required String url,
              }) =>
                  Future<bool>.value(true),
              loadUrl: (String url, Map<String, String>? headers) async {
                completer.complete();
              });

      webViewClient.urlLoading(MockWebView(), 'https://flutter.dev');
      expect(completer.future, completes);
    });

    test(
        'urlLoading should not call laodUrl when onNavigationRequestCallback returns false',
        () async {
      final WebViewAndroidWebViewClient webViewClient =
          WebViewAndroidWebViewClient.handlesNavigation(
              onPageStartedCallback: (_) {},
              onPageFinishedCallback: (_) {},
              onWebResourceErrorCallback: (_) {},
              onNavigationRequestCallback: ({
                required bool isForMainFrame,
                required String url,
              }) =>
                  false,
              loadUrl: (String url, Map<String, String>? headers) async {
                fail(
                    'loadUrl should not be called if onNavigationRequestCallback returns false.');
              });

      webViewClient.urlLoading(MockWebView(), 'https://flutter.dev');
    });

    test(
        'urlLoading should not call loadUrl when onNavigationRequestCallback returns a Future false',
        () {
      final WebViewAndroidWebViewClient webViewClient =
          WebViewAndroidWebViewClient.handlesNavigation(
              onPageStartedCallback: (_) {},
              onPageFinishedCallback: (_) {},
              onWebResourceErrorCallback: (_) {},
              onNavigationRequestCallback: ({
                required bool isForMainFrame,
                required String url,
              }) =>
                  Future<bool>.value(false),
              loadUrl: (String url, Map<String, String>? headers) async {
                fail(
                    'loadUrl should not be called if onNavigationRequestCallback returns false.');
              });

      webViewClient.urlLoading(MockWebView(), 'https://flutter.dev');
    });

    test(
        'requestLoading should call loadUrl when onNavigationRequestCallback returns true',
        () {
      final Completer<void> completer = Completer<void>();
      final MockWebResourceRequest mockRequest = MockWebResourceRequest();
      when(mockRequest.isForMainFrame).thenReturn(true);
      when(mockRequest.url).thenReturn('https://flutter.dev');
      final WebViewAndroidWebViewClient webViewClient =
          WebViewAndroidWebViewClient.handlesNavigation(
              onPageStartedCallback: (_) {},
              onPageFinishedCallback: (_) {},
              onWebResourceErrorCallback: (_) {},
              onNavigationRequestCallback: ({
                required bool isForMainFrame,
                required String url,
              }) =>
                  true,
              loadUrl: (String url, Map<String, String>? headers) async {
                expect(url, 'https://flutter.dev');
                completer.complete();
              });

      webViewClient.requestLoading(MockWebView(), mockRequest);
      expect(completer.isCompleted, isTrue);
    });

    test(
        'requestLoading should call loadUrl when onNavigationRequestCallback returns a Future true',
        () async {
      final Completer<void> completer = Completer<void>();
      final MockWebResourceRequest mockRequest = MockWebResourceRequest();
      when(mockRequest.isForMainFrame).thenReturn(true);
      when(mockRequest.url).thenReturn('https://flutter.dev');
      final WebViewAndroidWebViewClient webViewClient =
          WebViewAndroidWebViewClient.handlesNavigation(
              onPageStartedCallback: (_) {},
              onPageFinishedCallback: (_) {},
              onWebResourceErrorCallback: (_) {},
              onNavigationRequestCallback: ({
                required bool isForMainFrame,
                required String url,
              }) =>
                  Future<bool>.value(true),
              loadUrl: (String url, Map<String, String>? headers) async {
                expect(url, 'https://flutter.dev');
                completer.complete();
              });

      webViewClient.requestLoading(MockWebView(), mockRequest);
      expect(completer.future, completes);
    });

    test(
        'requestLoading should not call loadUrl when onNavigationRequestCallback returns false',
        () {
      final MockWebResourceRequest mockRequest = MockWebResourceRequest();
      when(mockRequest.isForMainFrame).thenReturn(true);
      when(mockRequest.url).thenReturn('https://flutter.dev');
      final WebViewAndroidWebViewClient webViewClient =
          WebViewAndroidWebViewClient.handlesNavigation(
              onPageStartedCallback: (_) {},
              onPageFinishedCallback: (_) {},
              onWebResourceErrorCallback: (_) {},
              onNavigationRequestCallback: ({
                required bool isForMainFrame,
                required String url,
              }) =>
                  false,
              loadUrl: (String url, Map<String, String>? headers) {
                fail(
                    'loadUrl should not be called if onNavigationRequestCallback returns false.');
              });

      webViewClient.requestLoading(MockWebView(), mockRequest);
    });

    test(
        'requestLoading should not call loadUrl when onNavigationRequestCallback returns a Future false',
        () {
      final MockWebResourceRequest mockRequest = MockWebResourceRequest();
      when(mockRequest.isForMainFrame).thenReturn(true);
      when(mockRequest.url).thenReturn('https://flutter.dev');
      final WebViewAndroidWebViewClient webViewClient =
          WebViewAndroidWebViewClient.handlesNavigation(
              onPageStartedCallback: (_) {},
              onPageFinishedCallback: (_) {},
              onWebResourceErrorCallback: (_) {},
              onNavigationRequestCallback: ({
                required bool isForMainFrame,
                required String url,
              }) =>
                  Future<bool>.value(false),
              loadUrl: (String url, Map<String, String>? headers) {
                fail(
                    'loadUrl should not be called if onNavigationRequestCallback returns false.');
              });

      webViewClient.requestLoading(MockWebView(), mockRequest);
    });
  });
}
