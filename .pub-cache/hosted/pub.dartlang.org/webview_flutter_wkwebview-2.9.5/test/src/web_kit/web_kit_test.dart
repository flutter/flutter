// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_wkwebview/src/common/instance_manager.dart';
import 'package:webview_flutter_wkwebview/src/common/web_kit.pigeon.dart';
import 'package:webview_flutter_wkwebview/src/foundation/foundation.dart';
import 'package:webview_flutter_wkwebview/src/web_kit/web_kit.dart';
import 'package:webview_flutter_wkwebview/src/web_kit/web_kit_api_impls.dart';

import '../common/test_web_kit.pigeon.dart';
import 'web_kit_test.mocks.dart';

@GenerateMocks(<Type>[
  TestWKHttpCookieStoreHostApi,
  TestWKNavigationDelegateHostApi,
  TestWKPreferencesHostApi,
  TestWKScriptMessageHandlerHostApi,
  TestWKUIDelegateHostApi,
  TestWKUserContentControllerHostApi,
  TestWKWebViewConfigurationHostApi,
  TestWKWebViewHostApi,
  TestWKWebsiteDataStoreHostApi,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebKit', () {
    late InstanceManager instanceManager;
    late WebKitFlutterApis flutterApis;

    setUp(() {
      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
      flutterApis = WebKitFlutterApis(instanceManager: instanceManager);
      WebKitFlutterApis.instance = flutterApis;
    });

    group('WKWebsiteDataStore', () {
      late MockTestWKWebsiteDataStoreHostApi mockPlatformHostApi;

      late WKWebsiteDataStore websiteDataStore;

      late WKWebViewConfiguration webViewConfiguration;

      setUp(() {
        mockPlatformHostApi = MockTestWKWebsiteDataStoreHostApi();
        TestWKWebsiteDataStoreHostApi.setup(mockPlatformHostApi);

        TestWKWebViewConfigurationHostApi.setup(
          MockTestWKWebViewConfigurationHostApi(),
        );
        webViewConfiguration = WKWebViewConfiguration(
          instanceManager: instanceManager,
        );

        websiteDataStore = WKWebsiteDataStore.fromWebViewConfiguration(
          webViewConfiguration,
          instanceManager: instanceManager,
        );
      });

      tearDown(() {
        TestWKWebsiteDataStoreHostApi.setup(null);
        TestWKWebViewConfigurationHostApi.setup(null);
      });

      test('WKWebViewConfigurationFlutterApi.create', () {
        final WebKitFlutterApis flutterApis = WebKitFlutterApis(
          instanceManager: instanceManager,
        );

        flutterApis.webViewConfiguration.create(2);

        expect(instanceManager.containsIdentifier(2), isTrue);
        expect(
          instanceManager.getInstanceWithWeakReference(2),
          isA<WKWebViewConfiguration>(),
        );
      });

      test('createFromWebViewConfiguration', () {
        verify(mockPlatformHostApi.createFromWebViewConfiguration(
          instanceManager.getIdentifier(websiteDataStore),
          instanceManager.getIdentifier(webViewConfiguration),
        ));
      });

      test('createDefaultDataStore', () {
        final WKWebsiteDataStore defaultDataStore =
            WKWebsiteDataStore.defaultDataStore;
        verify(
          mockPlatformHostApi.createDefaultDataStore(
            NSObject.globalInstanceManager.getIdentifier(defaultDataStore),
          ),
        );
      });

      test('removeDataOfTypes', () {
        when(mockPlatformHostApi.removeDataOfTypes(
          any,
          any,
          any,
        )).thenAnswer((_) => Future<bool>.value(true));

        expect(
          websiteDataStore.removeDataOfTypes(
            <WKWebsiteDataType>{WKWebsiteDataType.cookies},
            DateTime.fromMillisecondsSinceEpoch(5000),
          ),
          completion(true),
        );

        final List<WKWebsiteDataTypeEnumData> typeData =
            verify(mockPlatformHostApi.removeDataOfTypes(
          instanceManager.getIdentifier(websiteDataStore),
          captureAny,
          5.0,
        )).captured.single.cast<WKWebsiteDataTypeEnumData>()
                as List<WKWebsiteDataTypeEnumData>;

        expect(typeData.single.value, WKWebsiteDataTypeEnum.cookies);
      });
    });

    group('WKHttpCookieStore', () {
      late MockTestWKHttpCookieStoreHostApi mockPlatformHostApi;

      late WKHttpCookieStore httpCookieStore;

      late WKWebsiteDataStore websiteDataStore;

      setUp(() {
        mockPlatformHostApi = MockTestWKHttpCookieStoreHostApi();
        TestWKHttpCookieStoreHostApi.setup(mockPlatformHostApi);

        TestWKWebViewConfigurationHostApi.setup(
          MockTestWKWebViewConfigurationHostApi(),
        );
        TestWKWebsiteDataStoreHostApi.setup(
          MockTestWKWebsiteDataStoreHostApi(),
        );

        websiteDataStore = WKWebsiteDataStore.fromWebViewConfiguration(
          WKWebViewConfiguration(instanceManager: instanceManager),
          instanceManager: instanceManager,
        );

        httpCookieStore = WKHttpCookieStore.fromWebsiteDataStore(
          websiteDataStore,
          instanceManager: instanceManager,
        );
      });

      tearDown(() {
        TestWKHttpCookieStoreHostApi.setup(null);
        TestWKWebsiteDataStoreHostApi.setup(null);
        TestWKWebViewConfigurationHostApi.setup(null);
      });

      test('createFromWebsiteDataStore', () {
        verify(mockPlatformHostApi.createFromWebsiteDataStore(
          instanceManager.getIdentifier(httpCookieStore),
          instanceManager.getIdentifier(websiteDataStore),
        ));
      });

      test('setCookie', () async {
        await httpCookieStore.setCookie(
            const NSHttpCookie.withProperties(<NSHttpCookiePropertyKey, Object>{
          NSHttpCookiePropertyKey.comment: 'aComment',
        }));

        final NSHttpCookieData cookie = verify(
          mockPlatformHostApi.setCookie(
            instanceManager.getIdentifier(httpCookieStore),
            captureAny,
          ),
        ).captured.single as NSHttpCookieData;

        expect(
          cookie.propertyKeys.single!.value,
          NSHttpCookiePropertyKeyEnum.comment,
        );
        expect(cookie.propertyValues.single, 'aComment');
      });
    });

    group('WKScriptMessageHandler', () {
      late MockTestWKScriptMessageHandlerHostApi mockPlatformHostApi;

      late WKScriptMessageHandler scriptMessageHandler;

      setUp(() async {
        mockPlatformHostApi = MockTestWKScriptMessageHandlerHostApi();
        TestWKScriptMessageHandlerHostApi.setup(mockPlatformHostApi);

        scriptMessageHandler = WKScriptMessageHandler(
          didReceiveScriptMessage: (_, __) {},
          instanceManager: instanceManager,
        );
      });

      tearDown(() {
        TestWKScriptMessageHandlerHostApi.setup(null);
      });

      test('create', () async {
        verify(mockPlatformHostApi.create(
          instanceManager.getIdentifier(scriptMessageHandler),
        ));
      });

      test('didReceiveScriptMessage', () async {
        final Completer<List<Object?>> argsCompleter =
            Completer<List<Object?>>();

        WebKitFlutterApis.instance = WebKitFlutterApis(
          instanceManager: instanceManager,
        );

        scriptMessageHandler = WKScriptMessageHandler(
          instanceManager: instanceManager,
          didReceiveScriptMessage: (
            WKUserContentController userContentController,
            WKScriptMessage message,
          ) {
            argsCompleter.complete(<Object?>[userContentController, message]);
          },
        );

        final WKUserContentController userContentController =
            WKUserContentController.detached(
          instanceManager: instanceManager,
        );
        instanceManager.addHostCreatedInstance(userContentController, 2);

        WebKitFlutterApis.instance.scriptMessageHandler.didReceiveScriptMessage(
          instanceManager.getIdentifier(scriptMessageHandler)!,
          2,
          WKScriptMessageData(name: 'name'),
        );

        expect(
          argsCompleter.future,
          completion(<Object?>[userContentController, isA<WKScriptMessage>()]),
        );
      });
    });

    group('WKPreferences', () {
      late MockTestWKPreferencesHostApi mockPlatformHostApi;

      late WKPreferences preferences;

      late WKWebViewConfiguration webViewConfiguration;

      setUp(() {
        mockPlatformHostApi = MockTestWKPreferencesHostApi();
        TestWKPreferencesHostApi.setup(mockPlatformHostApi);

        TestWKWebViewConfigurationHostApi.setup(
          MockTestWKWebViewConfigurationHostApi(),
        );
        webViewConfiguration = WKWebViewConfiguration(
          instanceManager: instanceManager,
        );

        preferences = WKPreferences.fromWebViewConfiguration(
          webViewConfiguration,
          instanceManager: instanceManager,
        );
      });

      tearDown(() {
        TestWKPreferencesHostApi.setup(null);
        TestWKWebViewConfigurationHostApi.setup(null);
      });

      test('createFromWebViewConfiguration', () async {
        verify(mockPlatformHostApi.createFromWebViewConfiguration(
          instanceManager.getIdentifier(preferences),
          instanceManager.getIdentifier(webViewConfiguration),
        ));
      });

      test('setJavaScriptEnabled', () async {
        await preferences.setJavaScriptEnabled(true);
        verify(mockPlatformHostApi.setJavaScriptEnabled(
          instanceManager.getIdentifier(preferences),
          true,
        ));
      });
    });

    group('WKUserContentController', () {
      late MockTestWKUserContentControllerHostApi mockPlatformHostApi;

      late WKUserContentController userContentController;

      late WKWebViewConfiguration webViewConfiguration;

      setUp(() {
        mockPlatformHostApi = MockTestWKUserContentControllerHostApi();
        TestWKUserContentControllerHostApi.setup(mockPlatformHostApi);

        TestWKWebViewConfigurationHostApi.setup(
          MockTestWKWebViewConfigurationHostApi(),
        );
        webViewConfiguration = WKWebViewConfiguration(
          instanceManager: instanceManager,
        );

        userContentController =
            WKUserContentController.fromWebViewConfiguration(
          webViewConfiguration,
          instanceManager: instanceManager,
        );
      });

      tearDown(() {
        TestWKUserContentControllerHostApi.setup(null);
        TestWKWebViewConfigurationHostApi.setup(null);
      });

      test('createFromWebViewConfiguration', () async {
        verify(mockPlatformHostApi.createFromWebViewConfiguration(
          instanceManager.getIdentifier(userContentController),
          instanceManager.getIdentifier(webViewConfiguration),
        ));
      });

      test('addScriptMessageHandler', () async {
        TestWKScriptMessageHandlerHostApi.setup(
          MockTestWKScriptMessageHandlerHostApi(),
        );
        final WKScriptMessageHandler handler = WKScriptMessageHandler(
          didReceiveScriptMessage: (_, __) {},
          instanceManager: instanceManager,
        );

        userContentController.addScriptMessageHandler(handler, 'handlerName');
        verify(mockPlatformHostApi.addScriptMessageHandler(
          instanceManager.getIdentifier(userContentController),
          instanceManager.getIdentifier(handler),
          'handlerName',
        ));
      });

      test('removeScriptMessageHandler', () async {
        userContentController.removeScriptMessageHandler('handlerName');
        verify(mockPlatformHostApi.removeScriptMessageHandler(
          instanceManager.getIdentifier(userContentController),
          'handlerName',
        ));
      });

      test('removeAllScriptMessageHandlers', () async {
        userContentController.removeAllScriptMessageHandlers();
        verify(mockPlatformHostApi.removeAllScriptMessageHandlers(
          instanceManager.getIdentifier(userContentController),
        ));
      });

      test('addUserScript', () {
        userContentController.addUserScript(const WKUserScript(
          'aScript',
          WKUserScriptInjectionTime.atDocumentEnd,
          isMainFrameOnly: false,
        ));
        verify(mockPlatformHostApi.addUserScript(
          instanceManager.getIdentifier(userContentController),
          argThat(isA<WKUserScriptData>()),
        ));
      });

      test('removeAllUserScripts', () {
        userContentController.removeAllUserScripts();
        verify(mockPlatformHostApi.removeAllUserScripts(
          instanceManager.getIdentifier(userContentController),
        ));
      });
    });

    group('WKWebViewConfiguration', () {
      late MockTestWKWebViewConfigurationHostApi mockPlatformHostApi;

      late WKWebViewConfiguration webViewConfiguration;

      setUp(() async {
        mockPlatformHostApi = MockTestWKWebViewConfigurationHostApi();
        TestWKWebViewConfigurationHostApi.setup(mockPlatformHostApi);

        webViewConfiguration = WKWebViewConfiguration(
          instanceManager: instanceManager,
        );
      });

      tearDown(() {
        TestWKWebViewConfigurationHostApi.setup(null);
      });

      test('create', () async {
        verify(
          mockPlatformHostApi.create(instanceManager.getIdentifier(
            webViewConfiguration,
          )),
        );
      });

      test('createFromWebView', () async {
        TestWKWebViewHostApi.setup(MockTestWKWebViewHostApi());
        final WKWebView webView = WKWebView(
          webViewConfiguration,
          instanceManager: instanceManager,
        );

        final WKWebViewConfiguration configurationFromWebView =
            WKWebViewConfiguration.fromWebView(
          webView,
          instanceManager: instanceManager,
        );
        verify(mockPlatformHostApi.createFromWebView(
          instanceManager.getIdentifier(configurationFromWebView),
          instanceManager.getIdentifier(webView),
        ));
      });

      test('allowsInlineMediaPlayback', () {
        webViewConfiguration.setAllowsInlineMediaPlayback(true);
        verify(mockPlatformHostApi.setAllowsInlineMediaPlayback(
          instanceManager.getIdentifier(webViewConfiguration),
          true,
        ));
      });

      test('mediaTypesRequiringUserActionForPlayback', () {
        webViewConfiguration.setMediaTypesRequiringUserActionForPlayback(
          <WKAudiovisualMediaType>{
            WKAudiovisualMediaType.audio,
            WKAudiovisualMediaType.video,
          },
        );

        final List<WKAudiovisualMediaTypeEnumData?> typeData = verify(
            mockPlatformHostApi.setMediaTypesRequiringUserActionForPlayback(
          instanceManager.getIdentifier(webViewConfiguration),
          captureAny,
        )).captured.single as List<WKAudiovisualMediaTypeEnumData?>;

        expect(typeData, hasLength(2));
        expect(typeData[0]!.value, WKAudiovisualMediaTypeEnum.audio);
        expect(typeData[1]!.value, WKAudiovisualMediaTypeEnum.video);
      });
    });

    group('WKNavigationDelegate', () {
      late MockTestWKNavigationDelegateHostApi mockPlatformHostApi;

      late WKWebView webView;

      late WKNavigationDelegate navigationDelegate;

      setUp(() async {
        mockPlatformHostApi = MockTestWKNavigationDelegateHostApi();
        TestWKNavigationDelegateHostApi.setup(mockPlatformHostApi);

        TestWKWebViewConfigurationHostApi.setup(
          MockTestWKWebViewConfigurationHostApi(),
        );
        TestWKWebViewHostApi.setup(MockTestWKWebViewHostApi());
        webView = WKWebView(
          WKWebViewConfiguration(instanceManager: instanceManager),
          instanceManager: instanceManager,
        );

        navigationDelegate = WKNavigationDelegate(
          instanceManager: instanceManager,
        );
      });

      tearDown(() {
        TestWKNavigationDelegateHostApi.setup(null);
        TestWKWebViewConfigurationHostApi.setup(null);
        TestWKWebViewHostApi.setup(null);
      });

      test('create', () async {
        navigationDelegate = WKNavigationDelegate(
          instanceManager: instanceManager,
        );

        verify(mockPlatformHostApi.create(
          instanceManager.getIdentifier(navigationDelegate),
        ));
      });

      test('didFinishNavigation', () async {
        final Completer<List<Object?>> argsCompleter =
            Completer<List<Object?>>();

        WebKitFlutterApis.instance = WebKitFlutterApis(
          instanceManager: instanceManager,
        );

        navigationDelegate = WKNavigationDelegate(
          instanceManager: instanceManager,
          didFinishNavigation: (WKWebView webView, String? url) {
            argsCompleter.complete(<Object?>[webView, url]);
          },
        );

        WebKitFlutterApis.instance.navigationDelegate.didFinishNavigation(
          instanceManager.getIdentifier(navigationDelegate)!,
          instanceManager.getIdentifier(webView)!,
          'url',
        );

        expect(argsCompleter.future, completion(<Object?>[webView, 'url']));
      });

      test('didStartProvisionalNavigation', () async {
        final Completer<List<Object?>> argsCompleter =
            Completer<List<Object?>>();

        WebKitFlutterApis.instance = WebKitFlutterApis(
          instanceManager: instanceManager,
        );

        navigationDelegate = WKNavigationDelegate(
          instanceManager: instanceManager,
          didStartProvisionalNavigation: (WKWebView webView, String? url) {
            argsCompleter.complete(<Object?>[webView, url]);
          },
        );

        WebKitFlutterApis.instance.navigationDelegate
            .didStartProvisionalNavigation(
          instanceManager.getIdentifier(navigationDelegate)!,
          instanceManager.getIdentifier(webView)!,
          'url',
        );

        expect(argsCompleter.future, completion(<Object?>[webView, 'url']));
      });

      test('decidePolicyForNavigationAction', () async {
        WebKitFlutterApis.instance = WebKitFlutterApis(
          instanceManager: instanceManager,
        );

        navigationDelegate = WKNavigationDelegate(
          instanceManager: instanceManager,
          decidePolicyForNavigationAction: (
            WKWebView webView,
            WKNavigationAction navigationAction,
          ) async {
            return WKNavigationActionPolicy.cancel;
          },
        );

        final WKNavigationActionPolicyEnumData policyData =
            await WebKitFlutterApis.instance.navigationDelegate
                .decidePolicyForNavigationAction(
          instanceManager.getIdentifier(navigationDelegate)!,
          instanceManager.getIdentifier(webView)!,
          WKNavigationActionData(
            request: NSUrlRequestData(
              url: 'url',
              allHttpHeaderFields: <String, String>{},
            ),
            targetFrame: WKFrameInfoData(isMainFrame: false),
          ),
        );

        expect(policyData.value, WKNavigationActionPolicyEnum.cancel);
      });

      test('didFailNavigation', () async {
        final Completer<List<Object?>> argsCompleter =
            Completer<List<Object?>>();

        WebKitFlutterApis.instance = WebKitFlutterApis(
          instanceManager: instanceManager,
        );

        navigationDelegate = WKNavigationDelegate(
          instanceManager: instanceManager,
          didFailNavigation: (WKWebView webView, NSError error) {
            argsCompleter.complete(<Object?>[webView, error]);
          },
        );

        WebKitFlutterApis.instance.navigationDelegate.didFailNavigation(
          instanceManager.getIdentifier(navigationDelegate)!,
          instanceManager.getIdentifier(webView)!,
          NSErrorData(
            code: 23,
            domain: 'Hello',
            localizedDescription: 'localiziedDescription',
          ),
        );

        expect(
          argsCompleter.future,
          completion(<Object?>[webView, isA<NSError>()]),
        );
      });

      test('didFailProvisionalNavigation', () async {
        final Completer<List<Object?>> argsCompleter =
            Completer<List<Object?>>();

        WebKitFlutterApis.instance = WebKitFlutterApis(
          instanceManager: instanceManager,
        );

        navigationDelegate = WKNavigationDelegate(
          instanceManager: instanceManager,
          didFailProvisionalNavigation: (WKWebView webView, NSError error) {
            argsCompleter.complete(<Object?>[webView, error]);
          },
        );

        WebKitFlutterApis.instance.navigationDelegate
            .didFailProvisionalNavigation(
          instanceManager.getIdentifier(navigationDelegate)!,
          instanceManager.getIdentifier(webView)!,
          NSErrorData(
            code: 23,
            domain: 'Hello',
            localizedDescription: 'localiziedDescription',
          ),
        );

        expect(
          argsCompleter.future,
          completion(<Object?>[webView, isA<NSError>()]),
        );
      });

      test('webViewWebContentProcessDidTerminate', () async {
        final Completer<List<Object?>> argsCompleter =
            Completer<List<Object?>>();

        WebKitFlutterApis.instance = WebKitFlutterApis(
          instanceManager: instanceManager,
        );

        navigationDelegate = WKNavigationDelegate(
          instanceManager: instanceManager,
          webViewWebContentProcessDidTerminate: (WKWebView webView) {
            argsCompleter.complete(<Object?>[webView]);
          },
        );

        WebKitFlutterApis.instance.navigationDelegate
            .webViewWebContentProcessDidTerminate(
          instanceManager.getIdentifier(navigationDelegate)!,
          instanceManager.getIdentifier(webView)!,
        );

        expect(argsCompleter.future, completion(<Object?>[webView]));
      });
    });

    group('WKWebView', () {
      late MockTestWKWebViewHostApi mockPlatformHostApi;

      late WKWebViewConfiguration webViewConfiguration;

      late WKWebView webView;
      late int webViewInstanceId;

      setUp(() {
        mockPlatformHostApi = MockTestWKWebViewHostApi();
        TestWKWebViewHostApi.setup(mockPlatformHostApi);

        TestWKWebViewConfigurationHostApi.setup(
            MockTestWKWebViewConfigurationHostApi());
        webViewConfiguration = WKWebViewConfiguration(
          instanceManager: instanceManager,
        );

        webView = WKWebView(
          webViewConfiguration,
          instanceManager: instanceManager,
        );
        webViewInstanceId = instanceManager.getIdentifier(webView)!;
      });

      tearDown(() {
        TestWKWebViewHostApi.setup(null);
        TestWKWebViewConfigurationHostApi.setup(null);
      });

      test('create', () async {
        verify(mockPlatformHostApi.create(
          instanceManager.getIdentifier(webView),
          instanceManager.getIdentifier(
            webViewConfiguration,
          ),
        ));
      });

      test('setUIDelegate', () async {
        TestWKUIDelegateHostApi.setup(MockTestWKUIDelegateHostApi());
        final WKUIDelegate uiDelegate = WKUIDelegate(
          instanceManager: instanceManager,
        );

        await webView.setUIDelegate(uiDelegate);
        verify(mockPlatformHostApi.setUIDelegate(
          webViewInstanceId,
          instanceManager.getIdentifier(uiDelegate),
        ));

        TestWKUIDelegateHostApi.setup(null);
      });

      test('setNavigationDelegate', () async {
        TestWKNavigationDelegateHostApi.setup(
          MockTestWKNavigationDelegateHostApi(),
        );
        final WKNavigationDelegate navigationDelegate = WKNavigationDelegate(
          instanceManager: instanceManager,
        );

        await webView.setNavigationDelegate(navigationDelegate);
        verify(mockPlatformHostApi.setNavigationDelegate(
          webViewInstanceId,
          instanceManager.getIdentifier(navigationDelegate),
        ));

        TestWKNavigationDelegateHostApi.setup(null);
      });

      test('getUrl', () {
        when(
          mockPlatformHostApi.getUrl(webViewInstanceId),
        ).thenReturn('www.flutter.dev');
        expect(webView.getUrl(), completion('www.flutter.dev'));
      });

      test('getEstimatedProgress', () {
        when(
          mockPlatformHostApi.getEstimatedProgress(webViewInstanceId),
        ).thenReturn(54.5);
        expect(webView.getEstimatedProgress(), completion(54.5));
      });

      test('loadRequest', () {
        webView.loadRequest(const NSUrlRequest(url: 'www.flutter.dev'));
        verify(mockPlatformHostApi.loadRequest(
          webViewInstanceId,
          argThat(isA<NSUrlRequestData>()),
        ));
      });

      test('loadHtmlString', () {
        webView.loadHtmlString('a', baseUrl: 'b');
        verify(mockPlatformHostApi.loadHtmlString(webViewInstanceId, 'a', 'b'));
      });

      test('loadFileUrl', () {
        webView.loadFileUrl('a', readAccessUrl: 'b');
        verify(mockPlatformHostApi.loadFileUrl(webViewInstanceId, 'a', 'b'));
      });

      test('loadFlutterAsset', () {
        webView.loadFlutterAsset('a');
        verify(mockPlatformHostApi.loadFlutterAsset(webViewInstanceId, 'a'));
      });

      test('canGoBack', () {
        when(mockPlatformHostApi.canGoBack(webViewInstanceId)).thenReturn(true);
        expect(webView.canGoBack(), completion(isTrue));
      });

      test('canGoForward', () {
        when(mockPlatformHostApi.canGoForward(webViewInstanceId))
            .thenReturn(false);
        expect(webView.canGoForward(), completion(isFalse));
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

      test('getTitle', () {
        when(mockPlatformHostApi.getTitle(webViewInstanceId))
            .thenReturn('MyTitle');
        expect(webView.getTitle(), completion('MyTitle'));
      });

      test('setAllowsBackForwardNavigationGestures', () {
        webView.setAllowsBackForwardNavigationGestures(false);
        verify(mockPlatformHostApi.setAllowsBackForwardNavigationGestures(
          webViewInstanceId,
          false,
        ));
      });

      test('customUserAgent', () {
        webView.setCustomUserAgent('hello');
        verify(mockPlatformHostApi.setCustomUserAgent(
          webViewInstanceId,
          'hello',
        ));
      });

      test('evaluateJavaScript', () {
        when(mockPlatformHostApi.evaluateJavaScript(webViewInstanceId, 'gogo'))
            .thenAnswer((_) => Future<String>.value('stopstop'));
        expect(webView.evaluateJavaScript('gogo'), completion('stopstop'));
      });

      test('evaluateJavaScript returns NSError', () {
        when(mockPlatformHostApi.evaluateJavaScript(webViewInstanceId, 'gogo'))
            .thenThrow(
          PlatformException(
            code: '',
            details: NSErrorData(
              code: 0,
              domain: 'domain',
              localizedDescription: 'desc',
            ),
          ),
        );
        expect(
          webView.evaluateJavaScript('gogo'),
          throwsA(
            isA<PlatformException>().having(
              (PlatformException exception) => exception.details,
              'details',
              isA<NSError>(),
            ),
          ),
        );
      });
    });

    group('WKUIDelegate', () {
      late MockTestWKUIDelegateHostApi mockPlatformHostApi;

      late WKUIDelegate uiDelegate;

      setUp(() async {
        mockPlatformHostApi = MockTestWKUIDelegateHostApi();
        TestWKUIDelegateHostApi.setup(mockPlatformHostApi);

        uiDelegate = WKUIDelegate(instanceManager: instanceManager);
      });

      tearDown(() {
        TestWKUIDelegateHostApi.setup(null);
      });

      test('create', () async {
        verify(mockPlatformHostApi.create(
          instanceManager.getIdentifier(uiDelegate),
        ));
      });

      test('onCreateWebView', () async {
        final Completer<List<Object?>> argsCompleter =
            Completer<List<Object?>>();

        WebKitFlutterApis.instance = WebKitFlutterApis(
          instanceManager: instanceManager,
        );

        uiDelegate = WKUIDelegate(
          instanceManager: instanceManager,
          onCreateWebView: (
            WKWebView webView,
            WKWebViewConfiguration configuration,
            WKNavigationAction navigationAction,
          ) {
            argsCompleter.complete(<Object?>[
              webView,
              configuration,
              navigationAction,
            ]);
          },
        );

        final WKWebView webView = WKWebView.detached(
          instanceManager: instanceManager,
        );
        instanceManager.addHostCreatedInstance(webView, 2);

        final WKWebViewConfiguration configuration =
            WKWebViewConfiguration.detached(
          instanceManager: instanceManager,
        );
        instanceManager.addHostCreatedInstance(configuration, 3);

        WebKitFlutterApis.instance.uiDelegate.onCreateWebView(
          instanceManager.getIdentifier(uiDelegate)!,
          2,
          3,
          WKNavigationActionData(
            request: NSUrlRequestData(
              url: 'url',
              allHttpHeaderFields: <String, String>{},
            ),
            targetFrame: WKFrameInfoData(isMainFrame: false),
          ),
        );

        expect(
          argsCompleter.future,
          completion(<Object?>[
            webView,
            configuration,
            isA<WKNavigationAction>(),
          ]),
        );
      });
    });
  });
}
