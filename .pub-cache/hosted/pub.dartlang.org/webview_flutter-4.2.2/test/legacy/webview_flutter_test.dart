// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/src/foundation/basic_types.dart';
import 'package:flutter/src/gestures/recognizer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter/src/webview_flutter_legacy.dart';
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

import 'webview_flutter_test.mocks.dart';

typedef VoidCallback = void Function();

@GenerateMocks(<Type>[WebViewPlatform, WebViewPlatformController])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWebViewPlatform mockWebViewPlatform;
  late MockWebViewPlatformController mockWebViewPlatformController;
  late MockWebViewCookieManagerPlatform mockWebViewCookieManagerPlatform;

  setUp(() {
    mockWebViewPlatformController = MockWebViewPlatformController();
    mockWebViewPlatform = MockWebViewPlatform();
    mockWebViewCookieManagerPlatform = MockWebViewCookieManagerPlatform();
    when(mockWebViewPlatform.build(
      context: anyNamed('context'),
      creationParams: anyNamed('creationParams'),
      webViewPlatformCallbacksHandler:
          anyNamed('webViewPlatformCallbacksHandler'),
      javascriptChannelRegistry: anyNamed('javascriptChannelRegistry'),
      onWebViewPlatformCreated: anyNamed('onWebViewPlatformCreated'),
      gestureRecognizers: anyNamed('gestureRecognizers'),
    )).thenAnswer((Invocation invocation) {
      final WebViewPlatformCreatedCallback onWebViewPlatformCreated =
          invocation.namedArguments[const Symbol('onWebViewPlatformCreated')]
              as WebViewPlatformCreatedCallback;
      return TestPlatformWebView(
        mockWebViewPlatformController: mockWebViewPlatformController,
        onWebViewPlatformCreated: onWebViewPlatformCreated,
      );
    });

    WebView.platform = mockWebViewPlatform;
    WebViewCookieManagerPlatform.instance = mockWebViewCookieManagerPlatform;
  });

  tearDown(() {
    mockWebViewCookieManagerPlatform.reset();
  });

  testWidgets('Create WebView', (WidgetTester tester) async {
    await tester.pumpWidget(const WebView());
  });

  testWidgets('Initial url', (WidgetTester tester) async {
    await tester.pumpWidget(const WebView(initialUrl: 'https://youtube.com'));

    final CreationParams params = captureBuildArgs(
      mockWebViewPlatform,
      creationParams: true,
    ).single as CreationParams;

    expect(params.initialUrl, 'https://youtube.com');
  });

  testWidgets('Javascript mode', (WidgetTester tester) async {
    await tester.pumpWidget(const WebView(
      javascriptMode: JavascriptMode.unrestricted,
    ));

    final CreationParams unrestrictedparams = captureBuildArgs(
      mockWebViewPlatform,
      creationParams: true,
    ).single as CreationParams;

    expect(
      unrestrictedparams.webSettings!.javascriptMode,
      JavascriptMode.unrestricted,
    );

    await tester.pumpWidget(const WebView());

    final CreationParams disabledparams = captureBuildArgs(
      mockWebViewPlatform,
      creationParams: true,
    ).single as CreationParams;

    expect(disabledparams.webSettings!.javascriptMode, JavascriptMode.disabled);
  });

  testWidgets('Load file', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    await controller!.loadFile('/test/path/index.html');

    verify(mockWebViewPlatformController.loadFile(
      '/test/path/index.html',
    ));
  });

  testWidgets('Load file with empty path', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    expect(() => controller!.loadFile(''), throwsAssertionError);
  });

  testWidgets('Load Flutter asset', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    await controller!.loadFlutterAsset('assets/index.html');

    verify(mockWebViewPlatformController.loadFlutterAsset(
      'assets/index.html',
    ));
  });

  testWidgets('Load Flutter asset with empty key', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    expect(() => controller!.loadFlutterAsset(''), throwsAssertionError);
  });

  testWidgets('Load HTML string without base URL', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    await controller!.loadHtmlString('<p>This is a test paragraph.</p>');

    verify(mockWebViewPlatformController.loadHtmlString(
      '<p>This is a test paragraph.</p>',
    ));
  });

  testWidgets('Load HTML string with base URL', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    await controller!.loadHtmlString(
      '<p>This is a test paragraph.</p>',
      baseUrl: 'https://flutter.dev',
    );

    verify(mockWebViewPlatformController.loadHtmlString(
      '<p>This is a test paragraph.</p>',
      baseUrl: 'https://flutter.dev',
    ));
  });

  testWidgets('Load HTML string with empty string',
      (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    expect(() => controller!.loadHtmlString(''), throwsAssertionError);
  });

  testWidgets('Load url', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    await controller!.loadUrl('https://flutter.io');

    verify(mockWebViewPlatformController.loadUrl(
      'https://flutter.io',
      argThat(isNull),
    ));
  });

  testWidgets('Invalid urls', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    final CreationParams params = captureBuildArgs(
      mockWebViewPlatform,
      creationParams: true,
    ).single as CreationParams;

    expect(params.initialUrl, isNull);

    expect(() => controller!.loadUrl(''), throwsA(anything));
    expect(() => controller!.loadUrl('flutter.io'), throwsA(anything));
  });

  testWidgets('Headers in loadUrl', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    final Map<String, String> headers = <String, String>{
      'CACHE-CONTROL': 'ABC'
    };
    await controller!.loadUrl('https://flutter.io', headers: headers);

    verify(mockWebViewPlatformController.loadUrl(
      'https://flutter.io',
      <String, String>{'CACHE-CONTROL': 'ABC'},
    ));
  });

  testWidgets('loadRequest', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );
    expect(controller, isNotNull);

    final WebViewRequest req = WebViewRequest(
      uri: Uri.parse('https://flutter.dev'),
      method: WebViewRequestMethod.post,
      headers: <String, String>{'foo': 'bar'},
      body: Uint8List.fromList('Test Body'.codeUnits),
    );

    await controller!.loadRequest(req);

    verify(mockWebViewPlatformController.loadRequest(req));
  });

  testWidgets('Clear Cache', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);

    await controller!.clearCache();

    verify(mockWebViewPlatformController.clearCache());
  });

  testWidgets('Can go back', (WidgetTester tester) async {
    when(mockWebViewPlatformController.canGoBack())
        .thenAnswer((_) => Future<bool>.value(true));

    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://flutter.io',
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);
    expect(controller!.canGoBack(), completion(true));
  });

  testWidgets("Can't go forward", (WidgetTester tester) async {
    when(mockWebViewPlatformController.canGoForward())
        .thenAnswer((_) => Future<bool>.value(false));

    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);
    expect(controller!.canGoForward(), completion(false));
  });

  testWidgets('Go back', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://youtube.com',
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    await controller!.goBack();
    verify(mockWebViewPlatformController.goBack());
  });

  testWidgets('Go forward', (WidgetTester tester) async {
    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://youtube.com',
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);
    await controller!.goForward();
    verify(mockWebViewPlatformController.goForward());
  });

  testWidgets('Current URL', (WidgetTester tester) async {
    when(mockWebViewPlatformController.currentUrl())
        .thenAnswer((_) => Future<String>.value('https://youtube.com'));

    WebViewController? controller;
    await tester.pumpWidget(
      WebView(
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(controller, isNotNull);
    expect(await controller!.currentUrl(), 'https://youtube.com');
  });

  testWidgets('Reload url', (WidgetTester tester) async {
    late WebViewController controller;
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://flutter.io',
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    await controller.reload();
    verify(mockWebViewPlatformController.reload());
  });

  testWidgets('evaluate Javascript', (WidgetTester tester) async {
    when(mockWebViewPlatformController.evaluateJavascript('fake js string'))
        .thenAnswer((_) => Future<String>.value('fake js string'));

    late WebViewController controller;
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://flutter.io',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );

    expect(
        // ignore: deprecated_member_use_from_same_package
        await controller.evaluateJavascript('fake js string'),
        'fake js string',
        reason: 'should get the argument');
  });

  testWidgets('evaluate Javascript with JavascriptMode disabled',
      (WidgetTester tester) async {
    late WebViewController controller;
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://flutter.io',
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );
    expect(
      // ignore: deprecated_member_use_from_same_package
      () => controller.evaluateJavascript('fake js string'),
      throwsA(anything),
    );
  });

  testWidgets('runJavaScript', (WidgetTester tester) async {
    late WebViewController controller;
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://flutter.io',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );
    await controller.runJavascript('fake js string');
    verify(mockWebViewPlatformController.runJavascript('fake js string'));
  });

  testWidgets('runJavaScript with JavascriptMode disabled',
      (WidgetTester tester) async {
    late WebViewController controller;
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://flutter.io',
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );
    expect(
      () => controller.runJavascript('fake js string'),
      throwsA(anything),
    );
  });

  testWidgets('runJavaScriptReturningResult', (WidgetTester tester) async {
    when(mockWebViewPlatformController
            .runJavascriptReturningResult('fake js string'))
        .thenAnswer((_) => Future<String>.value('fake js string'));

    late WebViewController controller;
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://flutter.io',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );
    expect(await controller.runJavascriptReturningResult('fake js string'),
        'fake js string',
        reason: 'should get the argument');
  });

  testWidgets('runJavaScriptReturningResult with JavascriptMode disabled',
      (WidgetTester tester) async {
    late WebViewController controller;
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://flutter.io',
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        },
      ),
    );
    expect(
      () => controller.runJavascriptReturningResult('fake js string'),
      throwsA(anything),
    );
  });

  testWidgets('Cookies can be cleared once', (WidgetTester tester) async {
    await tester.pumpWidget(
      const WebView(
        initialUrl: 'https://flutter.io',
      ),
    );
    final CookieManager cookieManager = CookieManager();
    final bool hasCookies = await cookieManager.clearCookies();
    expect(hasCookies, true);
  });

  testWidgets('Cookies can be set', (WidgetTester tester) async {
    const WebViewCookie cookie =
        WebViewCookie(name: 'foo', value: 'bar', domain: 'flutter.dev');

    await tester.pumpWidget(
      const WebView(
        initialUrl: 'https://flutter.io',
      ),
    );
    final CookieManager cookieManager = CookieManager();
    await cookieManager.setCookie(cookie);
    expect(mockWebViewCookieManagerPlatform.setCookieCalls,
        <WebViewCookie>[cookie]);
  });

  testWidgets('Initial JavaScript channels', (WidgetTester tester) async {
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://youtube.com',
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
              name: 'Tts', onMessageReceived: (JavascriptMessage msg) {}),
          JavascriptChannel(
              name: 'Alarm', onMessageReceived: (JavascriptMessage msg) {}),
        },
      ),
    );

    final CreationParams params = captureBuildArgs(
      mockWebViewPlatform,
      creationParams: true,
    ).single as CreationParams;

    expect(params.javascriptChannelNames,
        unorderedEquals(<String>['Tts', 'Alarm']));
  });

  test('Only valid JavaScript channel names are allowed', () {
    void noOp(JavascriptMessage msg) {}
    JavascriptChannel(name: 'Tts1', onMessageReceived: noOp);
    JavascriptChannel(name: '_Alarm', onMessageReceived: noOp);
    JavascriptChannel(name: 'foo_bar_', onMessageReceived: noOp);

    VoidCallback createChannel(String name) {
      return () {
        JavascriptChannel(name: name, onMessageReceived: noOp);
      };
    }

    expect(createChannel('1Alarm'), throwsAssertionError);
    expect(createChannel('foo.bar'), throwsAssertionError);
    expect(createChannel(''), throwsAssertionError);
  });

  testWidgets('Unique JavaScript channel names are required',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://youtube.com',
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
              name: 'Alarm', onMessageReceived: (JavascriptMessage msg) {}),
          JavascriptChannel(
              name: 'Alarm', onMessageReceived: (JavascriptMessage msg) {}),
        },
      ),
    );
    expect(tester.takeException(), isNot(null));
  });

  testWidgets('JavaScript channels update', (WidgetTester tester) async {
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://youtube.com',
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
              name: 'Tts', onMessageReceived: (JavascriptMessage msg) {}),
          JavascriptChannel(
              name: 'Alarm', onMessageReceived: (JavascriptMessage msg) {}),
        },
      ),
    );

    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://youtube.com',
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
              name: 'Tts', onMessageReceived: (JavascriptMessage msg) {}),
          JavascriptChannel(
              name: 'Alarm2', onMessageReceived: (JavascriptMessage msg) {}),
          JavascriptChannel(
              name: 'Alarm3', onMessageReceived: (JavascriptMessage msg) {}),
        },
      ),
    );

    final JavascriptChannelRegistry channelRegistry = captureBuildArgs(
      mockWebViewPlatform,
      javascriptChannelRegistry: true,
    ).first as JavascriptChannelRegistry;

    expect(
      channelRegistry.channels.keys,
      unorderedEquals(<String>['Tts', 'Alarm2', 'Alarm3']),
    );
  });

  testWidgets('Remove all JavaScript channels and then add',
      (WidgetTester tester) async {
    // This covers a specific bug we had where after updating javascriptChannels to null,
    // updating it again with a subset of the previously registered channels fails as the
    // widget's cache of current channel wasn't properly updated when updating javascriptChannels to
    // null.
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://youtube.com',
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
              name: 'Tts', onMessageReceived: (JavascriptMessage msg) {}),
        },
      ),
    );

    await tester.pumpWidget(
      const WebView(
        initialUrl: 'https://youtube.com',
      ),
    );

    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://youtube.com',
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
              name: 'Tts', onMessageReceived: (JavascriptMessage msg) {}),
        },
      ),
    );

    final JavascriptChannelRegistry channelRegistry = captureBuildArgs(
      mockWebViewPlatform,
      javascriptChannelRegistry: true,
    ).last as JavascriptChannelRegistry;

    expect(channelRegistry.channels.keys, unorderedEquals(<String>['Tts']));
  });

  testWidgets('JavaScript channel messages', (WidgetTester tester) async {
    final List<String> ttsMessagesReceived = <String>[];
    final List<String> alarmMessagesReceived = <String>[];
    await tester.pumpWidget(
      WebView(
        initialUrl: 'https://youtube.com',
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
              name: 'Tts',
              onMessageReceived: (JavascriptMessage msg) {
                ttsMessagesReceived.add(msg.message);
              }),
          JavascriptChannel(
              name: 'Alarm',
              onMessageReceived: (JavascriptMessage msg) {
                alarmMessagesReceived.add(msg.message);
              }),
        },
      ),
    );

    final JavascriptChannelRegistry channelRegistry = captureBuildArgs(
      mockWebViewPlatform,
      javascriptChannelRegistry: true,
    ).single as JavascriptChannelRegistry;

    expect(ttsMessagesReceived, isEmpty);
    expect(alarmMessagesReceived, isEmpty);

    channelRegistry.onJavascriptChannelMessage('Tts', 'Hello');
    channelRegistry.onJavascriptChannelMessage('Tts', 'World');

    expect(ttsMessagesReceived, <String>['Hello', 'World']);
  });

  group('$PageStartedCallback', () {
    testWidgets('onPageStarted is not null', (WidgetTester tester) async {
      String? returnedUrl;

      await tester.pumpWidget(WebView(
        initialUrl: 'https://youtube.com',
        onPageStarted: (String url) {
          returnedUrl = url;
        },
      ));

      final WebViewPlatformCallbacksHandler handler = captureBuildArgs(
        mockWebViewPlatform,
        webViewPlatformCallbacksHandler: true,
      ).single as WebViewPlatformCallbacksHandler;

      handler.onPageStarted('https://youtube.com');

      expect(returnedUrl, 'https://youtube.com');
    });

    testWidgets('onPageStarted is null', (WidgetTester tester) async {
      await tester.pumpWidget(const WebView(
        initialUrl: 'https://youtube.com',
      ));

      final WebViewPlatformCallbacksHandler handler = captureBuildArgs(
        mockWebViewPlatform,
        webViewPlatformCallbacksHandler: true,
      ).single as WebViewPlatformCallbacksHandler;

      // The platform side will always invoke a call for onPageStarted. This is
      // to test that it does not crash on a null callback.
      handler.onPageStarted('https://youtube.com');
    });

    testWidgets('onPageStarted changed', (WidgetTester tester) async {
      String? returnedUrl;

      await tester.pumpWidget(WebView(
        initialUrl: 'https://youtube.com',
        onPageStarted: (String url) {},
      ));

      await tester.pumpWidget(WebView(
        initialUrl: 'https://youtube.com',
        onPageStarted: (String url) {
          returnedUrl = url;
        },
      ));

      final WebViewPlatformCallbacksHandler handler = captureBuildArgs(
        mockWebViewPlatform,
        webViewPlatformCallbacksHandler: true,
      ).last as WebViewPlatformCallbacksHandler;
      handler.onPageStarted('https://youtube.com');

      expect(returnedUrl, 'https://youtube.com');
    });
  });

  group('$PageFinishedCallback', () {
    testWidgets('onPageFinished is not null', (WidgetTester tester) async {
      String? returnedUrl;

      await tester.pumpWidget(WebView(
        initialUrl: 'https://youtube.com',
        onPageFinished: (String url) {
          returnedUrl = url;
        },
      ));

      final WebViewPlatformCallbacksHandler handler = captureBuildArgs(
        mockWebViewPlatform,
        webViewPlatformCallbacksHandler: true,
      ).single as WebViewPlatformCallbacksHandler;
      handler.onPageFinished('https://youtube.com');

      expect(returnedUrl, 'https://youtube.com');
    });

    testWidgets('onPageFinished is null', (WidgetTester tester) async {
      await tester.pumpWidget(const WebView(
        initialUrl: 'https://youtube.com',
      ));

      final WebViewPlatformCallbacksHandler handler = captureBuildArgs(
        mockWebViewPlatform,
        webViewPlatformCallbacksHandler: true,
      ).single as WebViewPlatformCallbacksHandler;
      // The platform side will always invoke a call for onPageFinished. This is
      // to test that it does not crash on a null callback.
      handler.onPageFinished('https://youtube.com');
    });

    testWidgets('onPageFinished changed', (WidgetTester tester) async {
      String? returnedUrl;

      await tester.pumpWidget(WebView(
        initialUrl: 'https://youtube.com',
        onPageFinished: (String url) {},
      ));

      await tester.pumpWidget(WebView(
        initialUrl: 'https://youtube.com',
        onPageFinished: (String url) {
          returnedUrl = url;
        },
      ));

      final WebViewPlatformCallbacksHandler handler = captureBuildArgs(
        mockWebViewPlatform,
        webViewPlatformCallbacksHandler: true,
      ).last as WebViewPlatformCallbacksHandler;
      handler.onPageFinished('https://youtube.com');

      expect(returnedUrl, 'https://youtube.com');
    });
  });

  group('$PageLoadingCallback', () {
    testWidgets('onLoadingProgress is not null', (WidgetTester tester) async {
      int? loadingProgress;

      await tester.pumpWidget(WebView(
        initialUrl: 'https://youtube.com',
        onProgress: (int progress) {
          loadingProgress = progress;
        },
      ));

      final WebViewPlatformCallbacksHandler handler = captureBuildArgs(
        mockWebViewPlatform,
        webViewPlatformCallbacksHandler: true,
      ).single as WebViewPlatformCallbacksHandler;
      handler.onProgress(50);

      expect(loadingProgress, 50);
    });

    testWidgets('onLoadingProgress is null', (WidgetTester tester) async {
      await tester.pumpWidget(const WebView(
        initialUrl: 'https://youtube.com',
      ));

      final WebViewPlatformCallbacksHandler handler = captureBuildArgs(
        mockWebViewPlatform,
        webViewPlatformCallbacksHandler: true,
      ).single as WebViewPlatformCallbacksHandler;

      // This is to test that it does not crash on a null callback.
      handler.onProgress(50);
    });

    testWidgets('onLoadingProgress changed', (WidgetTester tester) async {
      int? loadingProgress;

      await tester.pumpWidget(WebView(
        initialUrl: 'https://youtube.com',
        onProgress: (int progress) {},
      ));

      await tester.pumpWidget(WebView(
        initialUrl: 'https://youtube.com',
        onProgress: (int progress) {
          loadingProgress = progress;
        },
      ));

      final WebViewPlatformCallbacksHandler handler = captureBuildArgs(
        mockWebViewPlatform,
        webViewPlatformCallbacksHandler: true,
      ).last as WebViewPlatformCallbacksHandler;
      handler.onProgress(50);

      expect(loadingProgress, 50);
    });
  });

  group('navigationDelegate', () {
    testWidgets('hasNavigationDelegate', (WidgetTester tester) async {
      await tester.pumpWidget(const WebView(
        initialUrl: 'https://youtube.com',
      ));

      final CreationParams params = captureBuildArgs(
        mockWebViewPlatform,
        creationParams: true,
      ).single as CreationParams;

      expect(params.webSettings!.hasNavigationDelegate, false);

      await tester.pumpWidget(WebView(
        initialUrl: 'https://youtube.com',
        navigationDelegate: (NavigationRequest r) =>
            NavigationDecision.navigate,
      ));

      final WebSettings updateSettings =
          verify(mockWebViewPlatformController.updateSettings(captureAny))
              .captured
              .single as WebSettings;

      expect(updateSettings.hasNavigationDelegate, true);
    });

    testWidgets('Block navigation', (WidgetTester tester) async {
      final List<NavigationRequest> navigationRequests = <NavigationRequest>[];

      await tester.pumpWidget(WebView(
          initialUrl: 'https://youtube.com',
          navigationDelegate: (NavigationRequest request) {
            navigationRequests.add(request);
            // Only allow navigating to https://flutter.dev
            return request.url == 'https://flutter.dev'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          }));

      final List<dynamic> args = captureBuildArgs(
        mockWebViewPlatform,
        creationParams: true,
        webViewPlatformCallbacksHandler: true,
      );

      final CreationParams params = args[0] as CreationParams;
      expect(params.webSettings!.hasNavigationDelegate, true);

      final WebViewPlatformCallbacksHandler handler =
          args[1] as WebViewPlatformCallbacksHandler;

      // The navigation delegate only allows navigation to https://flutter.dev
      // so we should still be in https://youtube.com.
      expect(
        handler.onNavigationRequest(
          url: 'https://www.google.com',
          isForMainFrame: true,
        ),
        completion(false),
      );

      expect(navigationRequests.length, 1);
      expect(navigationRequests[0].url, 'https://www.google.com');
      expect(navigationRequests[0].isForMainFrame, true);

      expect(
        handler.onNavigationRequest(
          url: 'https://flutter.dev',
          isForMainFrame: true,
        ),
        completion(true),
      );
    });
  });

  group('debuggingEnabled', () {
    testWidgets('enable debugging', (WidgetTester tester) async {
      await tester.pumpWidget(const WebView(
        debuggingEnabled: true,
      ));

      final CreationParams params = captureBuildArgs(
        mockWebViewPlatform,
        creationParams: true,
      ).single as CreationParams;

      expect(params.webSettings!.debuggingEnabled, true);
    });

    testWidgets('defaults to false', (WidgetTester tester) async {
      await tester.pumpWidget(const WebView());

      final CreationParams params = captureBuildArgs(
        mockWebViewPlatform,
        creationParams: true,
      ).single as CreationParams;

      expect(params.webSettings!.debuggingEnabled, false);
    });

    testWidgets('can be changed', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(WebView(key: key));

      await tester.pumpWidget(WebView(
        key: key,
        debuggingEnabled: true,
      ));

      final WebSettings enabledSettings =
          verify(mockWebViewPlatformController.updateSettings(captureAny))
              .captured
              .last as WebSettings;
      expect(enabledSettings.debuggingEnabled, true);

      await tester.pumpWidget(WebView(
        key: key,
      ));

      final WebSettings disabledSettings =
          verify(mockWebViewPlatformController.updateSettings(captureAny))
              .captured
              .last as WebSettings;
      expect(disabledSettings.debuggingEnabled, false);
    });
  });

  group('zoomEnabled', () {
    testWidgets('Enable zoom', (WidgetTester tester) async {
      await tester.pumpWidget(const WebView());

      final CreationParams params = captureBuildArgs(
        mockWebViewPlatform,
        creationParams: true,
      ).single as CreationParams;

      expect(params.webSettings!.zoomEnabled, isTrue);
    });

    testWidgets('defaults to true', (WidgetTester tester) async {
      await tester.pumpWidget(const WebView());

      final CreationParams params = captureBuildArgs(
        mockWebViewPlatform,
        creationParams: true,
      ).single as CreationParams;

      expect(params.webSettings!.zoomEnabled, isTrue);
    });

    testWidgets('can be changed', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(WebView(key: key));

      await tester.pumpWidget(WebView(
        key: key,
      ));

      final WebSettings enabledSettings =
          verify(mockWebViewPlatformController.updateSettings(captureAny))
              .captured
              .last as WebSettings;
      // Zoom defaults to true, so no changes are made to settings.
      expect(enabledSettings.zoomEnabled, isNull);

      await tester.pumpWidget(WebView(
        key: key,
        zoomEnabled: false,
      ));

      final WebSettings disabledSettings =
          verify(mockWebViewPlatformController.updateSettings(captureAny))
              .captured
              .last as WebSettings;
      expect(disabledSettings.zoomEnabled, isFalse);
    });
  });

  group('Background color', () {
    testWidgets('Defaults to null', (WidgetTester tester) async {
      await tester.pumpWidget(const WebView());

      final CreationParams params = captureBuildArgs(
        mockWebViewPlatform,
        creationParams: true,
      ).single as CreationParams;

      expect(params.backgroundColor, null);
    });

    testWidgets('Can be transparent', (WidgetTester tester) async {
      const Color transparentColor = Color(0x00000000);

      await tester.pumpWidget(const WebView(
        backgroundColor: transparentColor,
      ));

      final CreationParams params = captureBuildArgs(
        mockWebViewPlatform,
        creationParams: true,
      ).single as CreationParams;

      expect(params.backgroundColor, transparentColor);
    });
  });

  group('Custom platform implementation', () {
    setUp(() {
      WebView.platform = MyWebViewPlatform();
    });
    tearDownAll(() {
      WebView.platform = null;
    });

    testWidgets('creation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const WebView(
          initialUrl: 'https://youtube.com',
          gestureNavigationEnabled: true,
        ),
      );

      final MyWebViewPlatform builder = WebView.platform as MyWebViewPlatform;
      final MyWebViewPlatformController platform = builder.lastPlatformBuilt!;

      expect(
          platform.creationParams,
          MatchesCreationParams(CreationParams(
            initialUrl: 'https://youtube.com',
            webSettings: WebSettings(
              javascriptMode: JavascriptMode.disabled,
              hasNavigationDelegate: false,
              debuggingEnabled: false,
              userAgent: const WebSetting<String?>.of(null),
              gestureNavigationEnabled: true,
              zoomEnabled: true,
            ),
          )));
    });

    testWidgets('loadUrl', (WidgetTester tester) async {
      late WebViewController controller;
      await tester.pumpWidget(
        WebView(
          initialUrl: 'https://youtube.com',
          onWebViewCreated: (WebViewController webViewController) {
            controller = webViewController;
          },
        ),
      );

      final MyWebViewPlatform builder = WebView.platform as MyWebViewPlatform;
      final MyWebViewPlatformController platform = builder.lastPlatformBuilt!;

      final Map<String, String> headers = <String, String>{
        'header': 'value',
      };

      await controller.loadUrl('https://google.com', headers: headers);

      expect(platform.lastUrlLoaded, 'https://google.com');
      expect(platform.lastRequestHeaders, headers);
    });
  });

  testWidgets('Set UserAgent', (WidgetTester tester) async {
    await tester.pumpWidget(const WebView(
      initialUrl: 'https://youtube.com',
      javascriptMode: JavascriptMode.unrestricted,
    ));

    final CreationParams params = captureBuildArgs(
      mockWebViewPlatform,
      creationParams: true,
    ).single as CreationParams;

    expect(params.webSettings!.userAgent.value, isNull);

    await tester.pumpWidget(const WebView(
      initialUrl: 'https://youtube.com',
      javascriptMode: JavascriptMode.unrestricted,
      userAgent: 'UA',
    ));

    final WebSettings settings =
        verify(mockWebViewPlatformController.updateSettings(captureAny))
            .captured
            .last as WebSettings;
    expect(settings.userAgent.value, 'UA');
  });
}

List<dynamic> captureBuildArgs(
  MockWebViewPlatform mockWebViewPlatform, {
  bool context = false,
  bool creationParams = false,
  bool webViewPlatformCallbacksHandler = false,
  bool javascriptChannelRegistry = false,
  bool onWebViewPlatformCreated = false,
  bool gestureRecognizers = false,
}) {
  return verify(mockWebViewPlatform.build(
    context: context ? captureAnyNamed('context') : anyNamed('context'),
    creationParams: creationParams
        ? captureAnyNamed('creationParams')
        : anyNamed('creationParams'),
    webViewPlatformCallbacksHandler: webViewPlatformCallbacksHandler
        ? captureAnyNamed('webViewPlatformCallbacksHandler')
        : anyNamed('webViewPlatformCallbacksHandler'),
    javascriptChannelRegistry: javascriptChannelRegistry
        ? captureAnyNamed('javascriptChannelRegistry')
        : anyNamed('javascriptChannelRegistry'),
    onWebViewPlatformCreated: onWebViewPlatformCreated
        ? captureAnyNamed('onWebViewPlatformCreated')
        : anyNamed('onWebViewPlatformCreated'),
    gestureRecognizers: gestureRecognizers
        ? captureAnyNamed('gestureRecognizers')
        : anyNamed('gestureRecognizers'),
  )).captured;
}

// This Widget ensures that onWebViewPlatformCreated is only called once when
// making multiple calls to `WidgetTester.pumpWidget` with different parameters
// for the WebView.
class TestPlatformWebView extends StatefulWidget {
  const TestPlatformWebView({
    super.key,
    required this.mockWebViewPlatformController,
    this.onWebViewPlatformCreated,
  });

  final MockWebViewPlatformController mockWebViewPlatformController;
  final WebViewPlatformCreatedCallback? onWebViewPlatformCreated;

  @override
  State<StatefulWidget> createState() => TestPlatformWebViewState();
}

class TestPlatformWebViewState extends State<TestPlatformWebView> {
  @override
  void initState() {
    super.initState();
    final WebViewPlatformCreatedCallback? onWebViewPlatformCreated =
        widget.onWebViewPlatformCreated;
    if (onWebViewPlatformCreated != null) {
      onWebViewPlatformCreated(widget.mockWebViewPlatformController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MyWebViewPlatform implements WebViewPlatform {
  MyWebViewPlatformController? lastPlatformBuilt;

  @override
  Widget build({
    BuildContext? context,
    CreationParams? creationParams,
    required WebViewPlatformCallbacksHandler webViewPlatformCallbacksHandler,
    required JavascriptChannelRegistry javascriptChannelRegistry,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  }) {
    assert(onWebViewPlatformCreated != null);
    lastPlatformBuilt = MyWebViewPlatformController(
        creationParams, gestureRecognizers, webViewPlatformCallbacksHandler);
    onWebViewPlatformCreated!(lastPlatformBuilt);
    return Container();
  }

  @override
  Future<bool> clearCookies() {
    return Future<bool>.sync(() => true);
  }
}

class MyWebViewPlatformController extends WebViewPlatformController {
  MyWebViewPlatformController(this.creationParams, this.gestureRecognizers,
      WebViewPlatformCallbacksHandler platformHandler)
      : super(platformHandler);

  CreationParams? creationParams;
  Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  String? lastUrlLoaded;
  Map<String, String>? lastRequestHeaders;

  @override
  Future<void> loadUrl(String url, Map<String, String>? headers) async {
    equals(1, 1);
    lastUrlLoaded = url;
    lastRequestHeaders = headers;
  }
}

class MatchesWebSettings extends Matcher {
  MatchesWebSettings(this._webSettings);

  final WebSettings? _webSettings;

  @override
  Description describe(Description description) =>
      description.add('$_webSettings');

  @override
  bool matches(
      covariant WebSettings webSettings, Map<dynamic, dynamic> matchState) {
    return _webSettings!.javascriptMode == webSettings.javascriptMode &&
        _webSettings!.hasNavigationDelegate ==
            webSettings.hasNavigationDelegate &&
        _webSettings!.debuggingEnabled == webSettings.debuggingEnabled &&
        _webSettings!.gestureNavigationEnabled ==
            webSettings.gestureNavigationEnabled &&
        _webSettings!.userAgent == webSettings.userAgent &&
        _webSettings!.zoomEnabled == webSettings.zoomEnabled;
  }
}

class MatchesCreationParams extends Matcher {
  MatchesCreationParams(this._creationParams);

  final CreationParams _creationParams;

  @override
  Description describe(Description description) =>
      description.add('$_creationParams');

  @override
  bool matches(covariant CreationParams creationParams,
      Map<dynamic, dynamic> matchState) {
    return _creationParams.initialUrl == creationParams.initialUrl &&
        MatchesWebSettings(_creationParams.webSettings)
            .matches(creationParams.webSettings!, matchState) &&
        orderedEquals(_creationParams.javascriptChannelNames)
            .matches(creationParams.javascriptChannelNames, matchState);
  }
}

class MockWebViewCookieManagerPlatform extends WebViewCookieManagerPlatform {
  List<WebViewCookie> setCookieCalls = <WebViewCookie>[];

  @override
  Future<bool> clearCookies() async => true;

  @override
  Future<void> setCookie(WebViewCookie cookie) async {
    setCookieCalls.add(cookie);
  }

  void reset() {
    setCookieCalls = <WebViewCookie>[];
  }
}
