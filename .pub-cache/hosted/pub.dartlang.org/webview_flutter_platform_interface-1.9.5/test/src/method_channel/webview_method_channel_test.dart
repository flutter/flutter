// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#106316)
// ignore: unnecessary_import
import 'dart:typed_data';

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#106316)
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tests on `plugin.flutter.io/webview_<channel_id>` channel', () {
    const int channelId = 1;
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/webview_$channelId');
    final WebViewPlatformCallbacksHandler callbacksHandler =
        MockWebViewPlatformCallbacksHandler();
    final JavascriptChannelRegistry javascriptChannelRegistry =
        MockJavascriptChannelRegistry();

    final List<MethodCall> log = <MethodCall>[];
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);

      switch (methodCall.method) {
        case 'currentUrl':
          return 'https://test.url';
        case 'canGoBack':
        case 'canGoForward':
          return true;
        case 'loadFile':
          if (methodCall.arguments == 'invalid file') {
            throw PlatformException(
                code: 'loadFile_failed', message: 'Failed loading file.');
          } else if (methodCall.arguments == 'some error') {
            throw PlatformException(
              code: 'some_error',
              message: 'Some error occurred.',
            );
          }
          return null;
        case 'loadFlutterAsset':
          if (methodCall.arguments == 'invalid key') {
            throw PlatformException(
              code: 'loadFlutterAsset_invalidKey',
              message: 'Failed loading asset.',
            );
          } else if (methodCall.arguments == 'some error') {
            throw PlatformException(
              code: 'some_error',
              message: 'Some error occurred.',
            );
          }
          return null;
        case 'runJavascriptReturningResult':
        case 'evaluateJavascript':
          return methodCall.arguments as String;
        case 'getScrollX':
          return 10;
        case 'getScrollY':
          return 20;
      }

      // Return null explicitly instead of relying on the implicit null
      // returned by the method channel if no return statement is specified.
      return null;
    });

    final MethodChannelWebViewPlatform webViewPlatform =
        MethodChannelWebViewPlatform(
      channelId,
      callbacksHandler,
      javascriptChannelRegistry,
    );

    tearDown(() {
      log.clear();
    });

    test('loadFile', () async {
      await webViewPlatform.loadFile(
        '/folder/asset.html',
      );

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'loadFile',
            arguments: '/folder/asset.html',
          ),
        ],
      );
    });

    test('loadFile with invalid file', () async {
      expect(
        () => webViewPlatform.loadFile('invalid file'),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError error) => error.message,
            'message',
            'Failed loading file.',
          ),
        ),
      );
    });

    test('loadFile with some error.', () async {
      expect(
        () => webViewPlatform.loadFile('some error'),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException error) => error.message,
            'message',
            'Some error occurred.',
          ),
        ),
      );
    });

    test('loadFlutterAsset', () async {
      await webViewPlatform.loadFlutterAsset(
        'folder/asset.html',
      );

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'loadFlutterAsset',
            arguments: 'folder/asset.html',
          ),
        ],
      );
    });

    test('loadFlutterAsset with empty key', () async {
      expect(() => webViewPlatform.loadFlutterAsset(''), throwsAssertionError);
    });

    test('loadFlutterAsset with invalid key', () async {
      expect(
        () => webViewPlatform.loadFlutterAsset('invalid key'),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError error) => error.message,
            'message',
            'Failed loading asset.',
          ),
        ),
      );
    });

    test('loadFlutterAsset with some error.', () async {
      expect(
        () => webViewPlatform.loadFlutterAsset('some error'),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException error) => error.message,
            'message',
            'Some error occurred.',
          ),
        ),
      );
    });

    test('loadHtmlString without base URL', () async {
      await webViewPlatform.loadHtmlString(
        'Test HTML string',
      );

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'loadHtmlString',
            arguments: <String, String?>{
              'html': 'Test HTML string',
              'baseUrl': null,
            },
          ),
        ],
      );
    });

    test('loadHtmlString without base URL', () async {
      await webViewPlatform.loadHtmlString(
        'Test HTML string',
        baseUrl: 'https://flutter.dev',
      );

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'loadHtmlString',
            arguments: <String, String?>{
              'html': 'Test HTML string',
              'baseUrl': 'https://flutter.dev',
            },
          ),
        ],
      );
    });

    test('loadUrl with headers', () async {
      await webViewPlatform.loadUrl(
        'https://test.url',
        const <String, String>{
          'Content-Type': 'text/plain',
          'Accept': 'text/html',
        },
      );

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'loadUrl',
            arguments: <String, dynamic>{
              'url': 'https://test.url',
              'headers': <String, String>{
                'Content-Type': 'text/plain',
                'Accept': 'text/html',
              },
            },
          ),
        ],
      );
    });

    test('loadUrl without headers', () async {
      await webViewPlatform.loadUrl(
        'https://test.url',
        null,
      );

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'loadUrl',
            arguments: <String, dynamic>{
              'url': 'https://test.url',
              'headers': null,
            },
          ),
        ],
      );
    });

    test('loadRequest', () async {
      await webViewPlatform.loadRequest(WebViewRequest(
        uri: Uri.parse('https://test.url'),
        method: WebViewRequestMethod.get,
      ));

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'loadRequest',
            arguments: <String, dynamic>{
              'request': <String, dynamic>{
                'uri': 'https://test.url',
                'method': 'get',
                'headers': <String, String>{},
                'body': null,
              }
            },
          ),
        ],
      );
    });

    test('loadRequest with optional parameters', () async {
      await webViewPlatform.loadRequest(WebViewRequest(
        uri: Uri.parse('https://test.url'),
        method: WebViewRequestMethod.get,
        headers: <String, String>{'foo': 'bar'},
        body: Uint8List.fromList('hello world'.codeUnits),
      ));

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'loadRequest',
            arguments: <String, dynamic>{
              'request': <String, dynamic>{
                'uri': 'https://test.url',
                'method': 'get',
                'headers': <String, String>{'foo': 'bar'},
                'body': 'hello world'.codeUnits,
              }
            },
          ),
        ],
      );
    });

    test('currentUrl', () async {
      final String? currentUrl = await webViewPlatform.currentUrl();

      expect(currentUrl, 'https://test.url');
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'currentUrl',
            arguments: null,
          ),
        ],
      );
    });

    test('canGoBack', () async {
      final bool canGoBack = await webViewPlatform.canGoBack();

      expect(canGoBack, true);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'canGoBack',
            arguments: null,
          ),
        ],
      );
    });

    test('canGoForward', () async {
      final bool canGoForward = await webViewPlatform.canGoForward();

      expect(canGoForward, true);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'canGoForward',
            arguments: null,
          ),
        ],
      );
    });

    test('goBack', () async {
      await webViewPlatform.goBack();

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'goBack',
            arguments: null,
          ),
        ],
      );
    });

    test('goForward', () async {
      await webViewPlatform.goForward();

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'goForward',
            arguments: null,
          ),
        ],
      );
    });

    test('reload', () async {
      await webViewPlatform.reload();

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'reload',
            arguments: null,
          ),
        ],
      );
    });

    test('clearCache', () async {
      await webViewPlatform.clearCache();

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'clearCache',
            arguments: null,
          ),
        ],
      );
    });

    test('updateSettings', () async {
      final WebSettings settings =
          WebSettings(userAgent: const WebSetting<String?>.of('Dart Test'));
      await webViewPlatform.updateSettings(settings);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'updateSettings',
            arguments: <String, dynamic>{
              'userAgent': 'Dart Test',
            },
          ),
        ],
      );
    });

    test('updateSettings all parameters', () async {
      final WebSettings settings = WebSettings(
        userAgent: const WebSetting<String?>.of('Dart Test'),
        javascriptMode: JavascriptMode.disabled,
        hasNavigationDelegate: true,
        hasProgressTracking: true,
        debuggingEnabled: true,
        gestureNavigationEnabled: true,
        allowsInlineMediaPlayback: true,
        zoomEnabled: false,
      );
      await webViewPlatform.updateSettings(settings);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'updateSettings',
            arguments: <String, dynamic>{
              'userAgent': 'Dart Test',
              'jsMode': 0,
              'hasNavigationDelegate': true,
              'hasProgressTracking': true,
              'debuggingEnabled': true,
              'gestureNavigationEnabled': true,
              'allowsInlineMediaPlayback': true,
              'zoomEnabled': false,
            },
          ),
        ],
      );
    });

    test('updateSettings without settings', () async {
      final WebSettings settings =
          WebSettings(userAgent: const WebSetting<String?>.absent());
      await webViewPlatform.updateSettings(settings);

      expect(
        log.isEmpty,
        true,
      );
    });

    test('evaluateJavascript', () async {
      final String evaluateJavascript =
          await webViewPlatform.evaluateJavascript(
        'This simulates some JavaScript code.',
      );

      expect('This simulates some JavaScript code.', evaluateJavascript);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'evaluateJavascript',
            arguments: 'This simulates some JavaScript code.',
          ),
        ],
      );
    });

    test('runJavascript', () async {
      await webViewPlatform.runJavascript(
        'This simulates some JavaScript code.',
      );

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'runJavascript',
            arguments: 'This simulates some JavaScript code.',
          ),
        ],
      );
    });

    test('runJavascriptReturningResult', () async {
      final String evaluateJavascript =
          await webViewPlatform.runJavascriptReturningResult(
        'This simulates some JavaScript code.',
      );

      expect('This simulates some JavaScript code.', evaluateJavascript);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'runJavascriptReturningResult',
            arguments: 'This simulates some JavaScript code.',
          ),
        ],
      );
    });

    test('addJavascriptChannels', () async {
      final Set<String> channels = <String>{'channel one', 'channel two'};
      await webViewPlatform.addJavascriptChannels(channels);

      expect(log, <Matcher>[
        isMethodCall(
          'addJavascriptChannels',
          arguments: <String>[
            'channel one',
            'channel two',
          ],
        ),
      ]);
    });

    test('addJavascriptChannels without channels', () async {
      final Set<String> channels = <String>{};
      await webViewPlatform.addJavascriptChannels(channels);

      expect(log, <Matcher>[
        isMethodCall(
          'addJavascriptChannels',
          arguments: <String>[],
        ),
      ]);
    });

    test('removeJavascriptChannels', () async {
      final Set<String> channels = <String>{'channel one', 'channel two'};
      await webViewPlatform.removeJavascriptChannels(channels);

      expect(log, <Matcher>[
        isMethodCall(
          'removeJavascriptChannels',
          arguments: <String>[
            'channel one',
            'channel two',
          ],
        ),
      ]);
    });

    test('removeJavascriptChannels without channels', () async {
      final Set<String> channels = <String>{};
      await webViewPlatform.removeJavascriptChannels(channels);

      expect(log, <Matcher>[
        isMethodCall(
          'removeJavascriptChannels',
          arguments: <String>[],
        ),
      ]);
    });

    test('getTitle', () async {
      final String? title = await webViewPlatform.getTitle();

      expect(title, null);
      expect(
        log,
        <Matcher>[
          isMethodCall('getTitle', arguments: null),
        ],
      );
    });

    test('scrollTo', () async {
      await webViewPlatform.scrollTo(10, 20);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'scrollTo',
            arguments: <String, int>{
              'x': 10,
              'y': 20,
            },
          ),
        ],
      );
    });

    test('scrollBy', () async {
      await webViewPlatform.scrollBy(10, 20);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'scrollBy',
            arguments: <String, int>{
              'x': 10,
              'y': 20,
            },
          ),
        ],
      );
    });

    test('getScrollX', () async {
      final int x = await webViewPlatform.getScrollX();

      expect(x, 10);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'getScrollX',
            arguments: null,
          ),
        ],
      );
    });

    test('getScrollY', () async {
      final int y = await webViewPlatform.getScrollY();

      expect(y, 20);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'getScrollY',
            arguments: null,
          ),
        ],
      );
    });

    test('backgroundColor is null by default', () {
      final CreationParams creationParams = CreationParams(
        webSettings: WebSettings(
          userAgent: const WebSetting<String?>.of('Dart Test'),
        ),
      );
      final Map<String, dynamic> creationParamsMap =
          MethodChannelWebViewPlatform.creationParamsToMap(creationParams);

      expect(creationParamsMap['backgroundColor'], null);
    });

    test('backgroundColor is converted to an int', () {
      const Color whiteColor = Color(0xFFFFFFFF);
      final CreationParams creationParams = CreationParams(
        backgroundColor: whiteColor,
        webSettings: WebSettings(
          userAgent: const WebSetting<String?>.of('Dart Test'),
        ),
      );
      final Map<String, dynamic> creationParamsMap =
          MethodChannelWebViewPlatform.creationParamsToMap(creationParams);

      expect(creationParamsMap['backgroundColor'], whiteColor.value);
    });
  });

  group('Tests on `plugins.flutter.io/cookie_manager` channel', () {
    const MethodChannel cookieChannel =
        MethodChannel('plugins.flutter.io/cookie_manager');

    final List<MethodCall> log = <MethodCall>[];
    cookieChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);

      if (methodCall.method == 'clearCookies') {
        return true;
      }

      // Return null explicitly instead of relying on the implicit null
      // returned by the method channel if no return statement is specified.
      return null;
    });

    tearDown(() {
      log.clear();
    });

    test('clearCookies', () async {
      final bool clearCookies =
          await MethodChannelWebViewPlatform.clearCookies();

      expect(clearCookies, true);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'clearCookies',
            arguments: null,
          ),
        ],
      );
    });

    test('setCookie', () async {
      await MethodChannelWebViewPlatform.setCookie(const WebViewCookie(
          name: 'foo', value: 'bar', domain: 'flutter.dev'));

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'setCookie',
            arguments: <String, String>{
              'name': 'foo',
              'value': 'bar',
              'domain': 'flutter.dev',
              'path': '/',
            },
          ),
        ],
      );
    });
  });
}

class MockWebViewPlatformCallbacksHandler extends Mock
    implements WebViewPlatformCallbacksHandler {}

class MockJavascriptChannelRegistry extends Mock
    implements JavascriptChannelRegistry {}
