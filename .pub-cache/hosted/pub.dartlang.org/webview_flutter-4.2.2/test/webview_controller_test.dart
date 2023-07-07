// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'webview_controller_test.mocks.dart';

@GenerateMocks(<Type>[PlatformWebViewController, PlatformNavigationDelegate])
void main() {
  test('loadFile', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.loadFile('file/path');
    verify(mockPlatformWebViewController.loadFile('file/path'));
  });

  test('loadFlutterAsset', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.loadFlutterAsset('file/path');
    verify(mockPlatformWebViewController.loadFlutterAsset('file/path'));
  });

  test('loadHtmlString', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.loadHtmlString('html', baseUrl: 'baseUrl');
    verify(mockPlatformWebViewController.loadHtmlString(
      'html',
      baseUrl: 'baseUrl',
    ));
  });

  test('loadRequest', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.loadRequest(
      Uri(scheme: 'https', host: 'dart.dev'),
      method: LoadRequestMethod.post,
      headers: <String, String>{'a': 'header'},
      body: Uint8List(0),
    );

    final LoadRequestParams params =
        verify(mockPlatformWebViewController.loadRequest(captureAny))
            .captured[0] as LoadRequestParams;
    expect(params.uri, Uri(scheme: 'https', host: 'dart.dev'));
    expect(params.method, LoadRequestMethod.post);
    expect(params.headers, <String, String>{'a': 'header'});
    expect(params.body, Uint8List(0));
  });

  test('currentUrl', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();
    when(mockPlatformWebViewController.currentUrl()).thenAnswer(
      (_) => Future<String>.value('https://dart.dev'),
    );

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await expectLater(
      webViewController.currentUrl(),
      completion('https://dart.dev'),
    );
  });

  test('canGoBack', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();
    when(mockPlatformWebViewController.canGoBack()).thenAnswer(
      (_) => Future<bool>.value(false),
    );

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await expectLater(webViewController.canGoBack(), completion(false));
  });

  test('canGoForward', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();
    when(mockPlatformWebViewController.canGoForward()).thenAnswer(
      (_) => Future<bool>.value(true),
    );

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await expectLater(webViewController.canGoForward(), completion(true));
  });

  test('goBack', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.goBack();
    verify(mockPlatformWebViewController.goBack());
  });

  test('goForward', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.goForward();
    verify(mockPlatformWebViewController.goForward());
  });

  test('reload', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.reload();
    verify(mockPlatformWebViewController.reload());
  });

  test('clearCache', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.clearCache();
    verify(mockPlatformWebViewController.clearCache());
  });

  test('clearLocalStorage', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.clearLocalStorage();
    verify(mockPlatformWebViewController.clearLocalStorage());
  });

  test('runJavaScript', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.runJavaScript('1 + 1');
    verify(mockPlatformWebViewController.runJavaScript('1 + 1'));
  });

  test('runJavaScriptReturningResult', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();
    when(mockPlatformWebViewController.runJavaScriptReturningResult('1 + 1'))
        .thenAnswer((_) => Future<String>.value('2'));

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await expectLater(
      webViewController.runJavaScriptReturningResult('1 + 1'),
      completion('2'),
    );
  });

  test('addJavaScriptChannel', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    void onMessageReceived(JavaScriptMessage message) {}
    await webViewController.addJavaScriptChannel(
      'name',
      onMessageReceived: onMessageReceived,
    );

    final JavaScriptChannelParams params =
        verify(mockPlatformWebViewController.addJavaScriptChannel(captureAny))
            .captured[0] as JavaScriptChannelParams;
    expect(params.name, 'name');
    expect(params.onMessageReceived, onMessageReceived);
  });

  test('removeJavaScriptChannel', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.removeJavaScriptChannel('channel');
    verify(mockPlatformWebViewController.removeJavaScriptChannel('channel'));
  });

  test('getTitle', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();
    when(mockPlatformWebViewController.getTitle())
        .thenAnswer((_) => Future<String>.value('myTitle'));

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await expectLater(webViewController.getTitle(), completion('myTitle'));
  });

  test('scrollTo', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.scrollTo(2, 3);
    verify(mockPlatformWebViewController.scrollTo(2, 3));
  });

  test('scrollBy', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.scrollBy(2, 3);
    verify(mockPlatformWebViewController.scrollBy(2, 3));
  });

  test('getScrollPosition', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();
    when(mockPlatformWebViewController.getScrollPosition()).thenAnswer(
      (_) => Future<Offset>.value(const Offset(2, 3)),
    );

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await expectLater(
      webViewController.getScrollPosition(),
      completion(const Offset(2.0, 3.0)),
    );
  });

  test('enableZoom', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.enableZoom(false);
    verify(mockPlatformWebViewController.enableZoom(false));
  });

  test('setBackgroundColor', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.setBackgroundColor(Colors.green);
    verify(mockPlatformWebViewController.setBackgroundColor(Colors.green));
  });

  test('setJavaScriptMode', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.setJavaScriptMode(JavaScriptMode.disabled);
    verify(
      mockPlatformWebViewController.setJavaScriptMode(JavaScriptMode.disabled),
    );
  });

  test('setUserAgent', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();

    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    await webViewController.setUserAgent('userAgent');
    verify(mockPlatformWebViewController.setUserAgent('userAgent'));
  });

  test('setNavigationDelegate', () async {
    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();
    final WebViewController webViewController = WebViewController.fromPlatform(
      mockPlatformWebViewController,
    );

    final MockPlatformNavigationDelegate mockPlatformNavigationDelegate =
        MockPlatformNavigationDelegate();
    final NavigationDelegate navigationDelegate =
        NavigationDelegate.fromPlatform(mockPlatformNavigationDelegate);

    await webViewController.setNavigationDelegate(navigationDelegate);
    verify(mockPlatformWebViewController.setPlatformNavigationDelegate(
      mockPlatformNavigationDelegate,
    ));
  });

  test('onPermissionRequest', () async {
    bool permissionRequestCallbackCalled = false;

    final MockPlatformWebViewController mockPlatformWebViewController =
        MockPlatformWebViewController();
    WebViewController.fromPlatform(
      mockPlatformWebViewController,
      onPermissionRequest: (WebViewPermissionRequest request) {
        permissionRequestCallbackCalled = true;
      },
    );

    final void Function(PlatformWebViewPermissionRequest request)
        requestCallback = verify(mockPlatformWebViewController
                .setOnPlatformPermissionRequest(captureAny))
            .captured
            .single as void Function(PlatformWebViewPermissionRequest request);

    requestCallback(const TestPlatformWebViewPermissionRequest());
    expect(permissionRequestCallbackCalled, isTrue);
  });
}

class TestPlatformWebViewPermissionRequest
    extends PlatformWebViewPermissionRequest {
  const TestPlatformWebViewPermissionRequest()
      : super(types: const <WebViewPermissionResourceType>{});

  @override
  Future<void> grant() async {}

  @override
  Future<void> deny() async {}
}
