// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_android/src/android_webview.dart';
import 'package:webview_flutter_android/src/android_webview.pigeon.dart';
import 'package:webview_flutter_android/src/android_webview_api_impls.dart';
import 'package:webview_flutter_android/src/instance_manager.dart';

import 'android_webview_test.mocks.dart';
import 'test_android_webview.pigeon.dart';

@GenerateMocks(<Type>[
  CookieManagerHostApi,
  DownloadListener,
  JavaScriptChannel,
  TestDownloadListenerHostApi,
  TestJavaObjectHostApi,
  TestJavaScriptChannelHostApi,
  TestWebChromeClientHostApi,
  TestWebSettingsHostApi,
  TestWebStorageHostApi,
  TestWebViewClientHostApi,
  TestWebViewHostApi,
  TestAssetManagerHostApi,
  WebChromeClient,
  WebView,
  WebViewClient,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android WebView', () {
    group('JavaObject', () {
      late MockTestJavaObjectHostApi mockPlatformHostApi;

      setUp(() {
        mockPlatformHostApi = MockTestJavaObjectHostApi();
        TestJavaObjectHostApi.setup(mockPlatformHostApi);
      });

      tearDown(() {
        TestJavaObjectHostApi.setup(null);
      });

      test('JavaObject.dispose', () async {
        int? callbackIdentifier;
        final InstanceManager instanceManager = InstanceManager(
          onWeakReferenceRemoved: (int identifier) {
            callbackIdentifier = identifier;
          },
        );

        final JavaObject object = JavaObject.detached(
          instanceManager: instanceManager,
        );
        instanceManager.addHostCreatedInstance(object, 0);

        JavaObject.dispose(object);

        expect(callbackIdentifier, 0);
      });

      test('JavaObjectFlutterApi.dispose', () {
        final InstanceManager instanceManager = InstanceManager(
          onWeakReferenceRemoved: (_) {},
        );

        final JavaObject object = JavaObject.detached(
          instanceManager: instanceManager,
        );
        instanceManager.addHostCreatedInstance(object, 0);
        instanceManager.removeWeakReference(object);

        expect(instanceManager.containsIdentifier(0), isTrue);

        final JavaObjectFlutterApiImpl flutterApi = JavaObjectFlutterApiImpl(
          instanceManager: instanceManager,
        );
        flutterApi.dispose(0);

        expect(instanceManager.containsIdentifier(0), isFalse);
      });
    });

    group('WebView', () {
      late MockTestWebViewHostApi mockPlatformHostApi;

      late InstanceManager instanceManager;

      late WebView webView;
      late int webViewInstanceId;

      setUp(() {
        mockPlatformHostApi = MockTestWebViewHostApi();
        TestWebViewHostApi.setup(mockPlatformHostApi);

        instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
        WebView.api = WebViewHostApiImpl(instanceManager: instanceManager);

        webView = WebView();
        webViewInstanceId = instanceManager.getIdentifier(webView)!;
      });

      test('create', () {
        verify(mockPlatformHostApi.create(webViewInstanceId, false));
      });

      test('setWebContentsDebuggingEnabled true', () {
        WebView.setWebContentsDebuggingEnabled(true);
        verify(mockPlatformHostApi.setWebContentsDebuggingEnabled(true));
      });

      test('setWebContentsDebuggingEnabled false', () {
        WebView.setWebContentsDebuggingEnabled(false);
        verify(mockPlatformHostApi.setWebContentsDebuggingEnabled(false));
      });

      test('loadData', () {
        webView.loadData(
          data: 'hello',
          mimeType: 'text/plain',
          encoding: 'base64',
        );
        verify(mockPlatformHostApi.loadData(
          webViewInstanceId,
          'hello',
          'text/plain',
          'base64',
        ));
      });

      test('loadData with null values', () {
        webView.loadData(data: 'hello');
        verify(mockPlatformHostApi.loadData(
          webViewInstanceId,
          'hello',
          null,
          null,
        ));
      });

      test('loadDataWithBaseUrl', () {
        webView.loadDataWithBaseUrl(
          baseUrl: 'https://base.url',
          data: 'hello',
          mimeType: 'text/plain',
          encoding: 'base64',
          historyUrl: 'https://history.url',
        );

        verify(mockPlatformHostApi.loadDataWithBaseUrl(
          webViewInstanceId,
          'https://base.url',
          'hello',
          'text/plain',
          'base64',
          'https://history.url',
        ));
      });

      test('loadDataWithBaseUrl with null values', () {
        webView.loadDataWithBaseUrl(data: 'hello');
        verify(mockPlatformHostApi.loadDataWithBaseUrl(
          webViewInstanceId,
          null,
          'hello',
          null,
          null,
          null,
        ));
      });

      test('loadUrl', () {
        webView.loadUrl('hello', <String, String>{'a': 'header'});
        verify(mockPlatformHostApi.loadUrl(
          webViewInstanceId,
          'hello',
          <String, String>{'a': 'header'},
        ));
      });

      test('canGoBack', () {
        when(mockPlatformHostApi.canGoBack(webViewInstanceId))
            .thenReturn(false);
        expect(webView.canGoBack(), completion(false));
      });

      test('canGoForward', () {
        when(mockPlatformHostApi.canGoForward(webViewInstanceId))
            .thenReturn(true);
        expect(webView.canGoForward(), completion(true));
      });

      test('goBack', () {
        webView.goBack();
        verify(mockPlatformHostApi.goBack(webViewInstanceId));
      });

      test('goForward', () {
        webView.goForward();
        verify(mockPlatformHostApi.goForward(webViewInstanceId));
      });

      test('reload', () {
        webView.reload();
        verify(mockPlatformHostApi.reload(webViewInstanceId));
      });

      test('clearCache', () {
        webView.clearCache(false);
        verify(mockPlatformHostApi.clearCache(webViewInstanceId, false));
      });

      test('evaluateJavascript', () {
        when(
          mockPlatformHostApi.evaluateJavascript(
              webViewInstanceId, 'runJavaScript'),
        ).thenAnswer((_) => Future<String>.value('returnValue'));
        expect(
          webView.evaluateJavascript('runJavaScript'),
          completion('returnValue'),
        );
      });

      test('getTitle', () {
        when(mockPlatformHostApi.getTitle(webViewInstanceId))
            .thenReturn('aTitle');
        expect(webView.getTitle(), completion('aTitle'));
      });

      test('scrollTo', () {
        webView.scrollTo(12, 13);
        verify(mockPlatformHostApi.scrollTo(webViewInstanceId, 12, 13));
      });

      test('scrollBy', () {
        webView.scrollBy(12, 14);
        verify(mockPlatformHostApi.scrollBy(webViewInstanceId, 12, 14));
      });

      test('getScrollX', () {
        when(mockPlatformHostApi.getScrollX(webViewInstanceId)).thenReturn(67);
        expect(webView.getScrollX(), completion(67));
      });

      test('getScrollY', () {
        when(mockPlatformHostApi.getScrollY(webViewInstanceId)).thenReturn(56);
        expect(webView.getScrollY(), completion(56));
      });

      test('getScrollPosition', () async {
        when(mockPlatformHostApi.getScrollPosition(webViewInstanceId))
            .thenReturn(WebViewPoint(x: 2, y: 16));
        await expectLater(
          webView.getScrollPosition(),
          completion(const Offset(2.0, 16.0)),
        );
      });

      test('setWebViewClient', () {
        TestWebViewClientHostApi.setup(MockTestWebViewClientHostApi());
        WebViewClient.api = WebViewClientHostApiImpl(
          instanceManager: instanceManager,
        );

        final WebViewClient mockWebViewClient = MockWebViewClient();
        when(mockWebViewClient.copy()).thenReturn(MockWebViewClient());
        when(mockWebViewClient.shouldOverrideUrlLoading).thenReturn(false);
        webView.setWebViewClient(mockWebViewClient);

        final int webViewClientInstanceId =
            instanceManager.getIdentifier(mockWebViewClient)!;
        verify(mockPlatformHostApi.setWebViewClient(
          webViewInstanceId,
          webViewClientInstanceId,
        ));
      });

      test('addJavaScriptChannel', () {
        TestJavaScriptChannelHostApi.setup(MockTestJavaScriptChannelHostApi());
        JavaScriptChannel.api = JavaScriptChannelHostApiImpl(
          instanceManager: instanceManager,
        );

        final JavaScriptChannel mockJavaScriptChannel = MockJavaScriptChannel();
        when(mockJavaScriptChannel.copy()).thenReturn(MockJavaScriptChannel());
        when(mockJavaScriptChannel.channelName).thenReturn('aChannel');

        webView.addJavaScriptChannel(mockJavaScriptChannel);

        final int javaScriptChannelInstanceId =
            instanceManager.getIdentifier(mockJavaScriptChannel)!;
        verify(mockPlatformHostApi.addJavaScriptChannel(
          webViewInstanceId,
          javaScriptChannelInstanceId,
        ));
      });

      test('removeJavaScriptChannel', () {
        TestJavaScriptChannelHostApi.setup(MockTestJavaScriptChannelHostApi());
        JavaScriptChannel.api = JavaScriptChannelHostApiImpl(
          instanceManager: instanceManager,
        );

        final JavaScriptChannel mockJavaScriptChannel = MockJavaScriptChannel();
        when(mockJavaScriptChannel.copy()).thenReturn(MockJavaScriptChannel());
        when(mockJavaScriptChannel.channelName).thenReturn('aChannel');

        expect(
          webView.removeJavaScriptChannel(mockJavaScriptChannel),
          completes,
        );

        webView.addJavaScriptChannel(mockJavaScriptChannel);
        webView.removeJavaScriptChannel(mockJavaScriptChannel);

        final int javaScriptChannelInstanceId =
            instanceManager.getIdentifier(mockJavaScriptChannel)!;
        verify(mockPlatformHostApi.removeJavaScriptChannel(
          webViewInstanceId,
          javaScriptChannelInstanceId,
        ));
      });

      test('setDownloadListener', () {
        TestDownloadListenerHostApi.setup(MockTestDownloadListenerHostApi());
        DownloadListener.api = DownloadListenerHostApiImpl(
          instanceManager: instanceManager,
        );

        final DownloadListener mockDownloadListener = MockDownloadListener();
        when(mockDownloadListener.copy()).thenReturn(MockDownloadListener());
        webView.setDownloadListener(mockDownloadListener);

        final int downloadListenerInstanceId =
            instanceManager.getIdentifier(mockDownloadListener)!;
        verify(mockPlatformHostApi.setDownloadListener(
          webViewInstanceId,
          downloadListenerInstanceId,
        ));
      });

      test('setWebChromeClient', () {
        // Setting a WebChromeClient requires setting a WebViewClient first.
        TestWebViewClientHostApi.setup(MockTestWebViewClientHostApi());
        WebViewClient.api = WebViewClientHostApiImpl(
          instanceManager: instanceManager,
        );
        final WebViewClient mockWebViewClient = MockWebViewClient();
        when(mockWebViewClient.copy()).thenReturn(MockWebViewClient());
        when(mockWebViewClient.shouldOverrideUrlLoading).thenReturn(false);
        webView.setWebViewClient(mockWebViewClient);

        TestWebChromeClientHostApi.setup(MockTestWebChromeClientHostApi());
        WebChromeClient.api = WebChromeClientHostApiImpl(
          instanceManager: instanceManager,
        );

        final WebChromeClient mockWebChromeClient = MockWebChromeClient();
        when(mockWebChromeClient.copy()).thenReturn(MockWebChromeClient());
        webView.setWebChromeClient(mockWebChromeClient);

        final int webChromeClientInstanceId =
            instanceManager.getIdentifier(mockWebChromeClient)!;
        verify(mockPlatformHostApi.setWebChromeClient(
          webViewInstanceId,
          webChromeClientInstanceId,
        ));
      });

      test('release', () {
        final MockTestWebSettingsHostApi mockWebSettingsPlatformHostApi =
            MockTestWebSettingsHostApi();
        TestWebSettingsHostApi.setup(mockWebSettingsPlatformHostApi);

        WebSettings.api =
            WebSettingsHostApiImpl(instanceManager: instanceManager);
        final int webSettingsInstanceId =
            instanceManager.getIdentifier(webView.settings)!;

        webView.release();
        verify(mockWebSettingsPlatformHostApi.dispose(webSettingsInstanceId));
        verify(mockPlatformHostApi.dispose(webViewInstanceId));
      });

      test('copy', () {
        expect(webView.copy(), isA<WebView>());
      });
    });

    group('WebSettings', () {
      late MockTestWebSettingsHostApi mockPlatformHostApi;

      late InstanceManager instanceManager;

      late WebSettings webSettings;
      late int webSettingsInstanceId;

      setUp(() {
        instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});

        TestWebViewHostApi.setup(MockTestWebViewHostApi());
        WebView.api = WebViewHostApiImpl(instanceManager: instanceManager);

        mockPlatformHostApi = MockTestWebSettingsHostApi();
        TestWebSettingsHostApi.setup(mockPlatformHostApi);

        WebSettings.api = WebSettingsHostApiImpl(
          instanceManager: instanceManager,
        );

        webSettings = WebSettings(WebView());
        webSettingsInstanceId = instanceManager.getIdentifier(webSettings)!;
      });

      test('create', () {
        verify(mockPlatformHostApi.create(webSettingsInstanceId, any));
      });

      test('setDomStorageEnabled', () {
        webSettings.setDomStorageEnabled(false);
        verify(mockPlatformHostApi.setDomStorageEnabled(
          webSettingsInstanceId,
          false,
        ));
      });

      test('setJavaScriptCanOpenWindowsAutomatically', () {
        webSettings.setJavaScriptCanOpenWindowsAutomatically(true);
        verify(mockPlatformHostApi.setJavaScriptCanOpenWindowsAutomatically(
          webSettingsInstanceId,
          true,
        ));
      });

      test('setSupportMultipleWindows', () {
        webSettings.setSupportMultipleWindows(false);
        verify(mockPlatformHostApi.setSupportMultipleWindows(
          webSettingsInstanceId,
          false,
        ));
      });

      test('setJavaScriptEnabled', () {
        webSettings.setJavaScriptEnabled(true);
        verify(mockPlatformHostApi.setJavaScriptEnabled(
          webSettingsInstanceId,
          true,
        ));
      });

      test('setUserAgentString', () {
        webSettings.setUserAgentString('hola');
        verify(mockPlatformHostApi.setUserAgentString(
          webSettingsInstanceId,
          'hola',
        ));
      });

      test('setMediaPlaybackRequiresUserGesture', () {
        webSettings.setMediaPlaybackRequiresUserGesture(false);
        verify(mockPlatformHostApi.setMediaPlaybackRequiresUserGesture(
          webSettingsInstanceId,
          false,
        ));
      });

      test('setSupportZoom', () {
        webSettings.setSupportZoom(true);
        verify(mockPlatformHostApi.setSupportZoom(
          webSettingsInstanceId,
          true,
        ));
      });

      test('setLoadWithOverviewMode', () {
        webSettings.setLoadWithOverviewMode(false);
        verify(mockPlatformHostApi.setLoadWithOverviewMode(
          webSettingsInstanceId,
          false,
        ));
      });

      test('setUseWideViewPort', () {
        webSettings.setUseWideViewPort(true);
        verify(mockPlatformHostApi.setUseWideViewPort(
          webSettingsInstanceId,
          true,
        ));
      });

      test('setDisplayZoomControls', () {
        webSettings.setDisplayZoomControls(false);
        verify(mockPlatformHostApi.setDisplayZoomControls(
          webSettingsInstanceId,
          false,
        ));
      });

      test('setBuiltInZoomControls', () {
        webSettings.setBuiltInZoomControls(true);
        verify(mockPlatformHostApi.setBuiltInZoomControls(
          webSettingsInstanceId,
          true,
        ));
      });

      test('setAllowFileAccess', () {
        webSettings.setAllowFileAccess(true);
        verify(mockPlatformHostApi.setAllowFileAccess(
          webSettingsInstanceId,
          true,
        ));
      });

      test('copy', () {
        expect(webSettings.copy(), isA<WebSettings>());
      });
    });

    group('JavaScriptChannel', () {
      late JavaScriptChannelFlutterApiImpl flutterApi;

      late InstanceManager instanceManager;

      late MockJavaScriptChannel mockJavaScriptChannel;
      late int mockJavaScriptChannelInstanceId;

      setUp(() {
        instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
        flutterApi = JavaScriptChannelFlutterApiImpl(
          instanceManager: instanceManager,
        );

        mockJavaScriptChannel = MockJavaScriptChannel();
        when(mockJavaScriptChannel.copy()).thenReturn(MockJavaScriptChannel());

        mockJavaScriptChannelInstanceId =
            instanceManager.addDartCreatedInstance(mockJavaScriptChannel);
      });

      test('postMessage', () {
        flutterApi.postMessage(
          mockJavaScriptChannelInstanceId,
          'Hello, World!',
        );
        verify(mockJavaScriptChannel.postMessage('Hello, World!'));
      });

      test('copy', () {
        expect(
          JavaScriptChannel.detached('channel').copy(),
          isA<JavaScriptChannel>(),
        );
      });
    });

    group('WebViewClient', () {
      late WebViewClientFlutterApiImpl flutterApi;

      late InstanceManager instanceManager;

      late MockWebViewClient mockWebViewClient;
      late int mockWebViewClientInstanceId;

      late MockWebView mockWebView;
      late int mockWebViewInstanceId;

      setUp(() {
        instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
        flutterApi = WebViewClientFlutterApiImpl(
          instanceManager: instanceManager,
        );

        mockWebViewClient = MockWebViewClient();
        when(mockWebViewClient.copy()).thenReturn(MockWebViewClient());
        mockWebViewClientInstanceId =
            instanceManager.addDartCreatedInstance(mockWebViewClient);

        mockWebView = MockWebView();
        when(mockWebView.copy()).thenReturn(MockWebView());
        mockWebViewInstanceId =
            instanceManager.addDartCreatedInstance(mockWebView);
      });

      test('onPageStarted', () {
        flutterApi.onPageStarted(
          mockWebViewClientInstanceId,
          mockWebViewInstanceId,
          'https://www.google.com',
        );
        verify(mockWebViewClient.onPageStarted(
          mockWebView,
          'https://www.google.com',
        ));
      });

      test('onPageFinished', () {
        flutterApi.onPageFinished(
          mockWebViewClientInstanceId,
          mockWebViewInstanceId,
          'https://www.google.com',
        );
        verify(mockWebViewClient.onPageFinished(
          mockWebView,
          'https://www.google.com',
        ));
      });

      test('onReceivedRequestError', () {
        flutterApi.onReceivedRequestError(
          mockWebViewClientInstanceId,
          mockWebViewInstanceId,
          WebResourceRequestData(
            url: 'https://www.google.com',
            isForMainFrame: true,
            hasGesture: true,
            method: 'POST',
            isRedirect: false,
            requestHeaders: <String?, String?>{},
          ),
          WebResourceErrorData(errorCode: 34, description: 'error description'),
        );

        verify(mockWebViewClient.onReceivedRequestError(
          mockWebView,
          argThat(isNotNull),
          argThat(isNotNull),
        ));
      });

      test('onReceivedError', () {
        flutterApi.onReceivedError(
          mockWebViewClientInstanceId,
          mockWebViewInstanceId,
          14,
          'desc',
          'https://www.google.com',
        );

        verify(mockWebViewClient.onReceivedError(
          mockWebView,
          14,
          'desc',
          'https://www.google.com',
        ));
      });

      test('requestLoading', () {
        flutterApi.requestLoading(
          mockWebViewClientInstanceId,
          mockWebViewInstanceId,
          WebResourceRequestData(
            url: 'https://www.google.com',
            isForMainFrame: true,
            hasGesture: true,
            method: 'POST',
            isRedirect: true,
            requestHeaders: <String?, String?>{},
          ),
        );

        verify(mockWebViewClient.requestLoading(
          mockWebView,
          argThat(isNotNull),
        ));
      });

      test('urlLoading', () {
        flutterApi.urlLoading(mockWebViewClientInstanceId,
            mockWebViewInstanceId, 'https://www.google.com');

        verify(mockWebViewClient.urlLoading(
          mockWebView,
          'https://www.google.com',
        ));
      });

      test('copy', () {
        expect(WebViewClient.detached().copy(), isA<WebViewClient>());
      });
    });

    group('DownloadListener', () {
      late DownloadListenerFlutterApiImpl flutterApi;

      late InstanceManager instanceManager;

      late MockDownloadListener mockDownloadListener;
      late int mockDownloadListenerInstanceId;

      setUp(() {
        instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
        flutterApi = DownloadListenerFlutterApiImpl(
          instanceManager: instanceManager,
        );

        mockDownloadListener = MockDownloadListener();
        when(mockDownloadListener.copy()).thenReturn(MockDownloadListener());
        mockDownloadListenerInstanceId =
            instanceManager.addDartCreatedInstance(mockDownloadListener);
      });

      test('onPageStarted', () {
        flutterApi.onDownloadStart(
          mockDownloadListenerInstanceId,
          'url',
          'userAgent',
          'contentDescription',
          'mimetype',
          45,
        );
        verify(mockDownloadListener.onDownloadStart(
          'url',
          'userAgent',
          'contentDescription',
          'mimetype',
          45,
        ));
      });

      test('copy', () {
        expect(DownloadListener.detached().copy(), isA<DownloadListener>());
      });
    });

    group('WebChromeClient', () {
      late WebChromeClientFlutterApiImpl flutterApi;

      late InstanceManager instanceManager;

      late MockWebChromeClient mockWebChromeClient;
      late int mockWebChromeClientInstanceId;

      late MockWebView mockWebView;
      late int mockWebViewInstanceId;

      setUp(() {
        instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
        flutterApi = WebChromeClientFlutterApiImpl(
          instanceManager: instanceManager,
        );

        mockWebChromeClient = MockWebChromeClient();
        when(mockWebChromeClient.copy()).thenReturn(MockWebChromeClient());

        mockWebChromeClientInstanceId =
            instanceManager.addDartCreatedInstance(mockWebChromeClient);

        mockWebView = MockWebView();
        when(mockWebView.copy()).thenReturn(MockWebView());
        mockWebViewInstanceId =
            instanceManager.addDartCreatedInstance(mockWebView);
      });

      test('onPageStarted', () {
        flutterApi.onProgressChanged(
          mockWebChromeClientInstanceId,
          mockWebViewInstanceId,
          76,
        );
        verify(mockWebChromeClient.onProgressChanged(mockWebView, 76));
      });

      test('copy', () {
        expect(WebChromeClient.detached().copy(), isA<WebChromeClient>());
      });
    });
  });

  group('CookieManager', () {
    test('setCookie calls setCookie on CookieManagerHostApi', () {
      CookieManager.api = MockCookieManagerHostApi();
      CookieManager.instance.setCookie('foo', 'bar');
      verify(CookieManager.api.setCookie('foo', 'bar'));
    });

    test('clearCookies calls clearCookies on CookieManagerHostApi', () {
      CookieManager.api = MockCookieManagerHostApi();
      when(CookieManager.api.clearCookies())
          .thenAnswer((_) => Future<bool>.value(true));
      CookieManager.instance.clearCookies();
      verify(CookieManager.api.clearCookies());
    });
  });

  group('WebStorage', () {
    late MockTestWebStorageHostApi mockPlatformHostApi;

    late WebStorage webStorage;
    late int webStorageInstanceId;

    setUp(() {
      mockPlatformHostApi = MockTestWebStorageHostApi();
      TestWebStorageHostApi.setup(mockPlatformHostApi);

      webStorage = WebStorage();
      webStorageInstanceId =
          WebStorage.api.instanceManager.getIdentifier(webStorage)!;
    });

    test('create', () {
      verify(mockPlatformHostApi.create(webStorageInstanceId));
    });

    test('deleteAllData', () {
      webStorage.deleteAllData();
      verify(mockPlatformHostApi.deleteAllData(webStorageInstanceId));
    });

    test('copy', () {
      expect(WebStorage.detached().copy(), isA<WebStorage>());
    });
  });
}
