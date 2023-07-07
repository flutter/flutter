// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_android/src/legacy/webview_surface_android.dart';
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SurfaceAndroidWebView', () {
    late List<MethodCall> log;

    setUpAll(() {
      _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
          .defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform_views,
        (MethodCall call) async {
          log.add(call);
          if (call.method == 'resize') {
            final Map<String, Object?> arguments =
                (call.arguments as Map<Object?, Object?>)
                    .cast<String, Object?>();
            return <String, Object?>{
              'width': arguments['width'],
              'height': arguments['height'],
            };
          }
          return null;
        },
      );
    });

    tearDownAll(() {
      _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
          .defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, null);
    });

    setUp(() {
      log = <MethodCall>[];
    });

    testWidgets(
        'uses hybrid composition when background color is not 100% opaque',
        (WidgetTester tester) async {
      await tester.pumpWidget(Builder(builder: (BuildContext context) {
        return SurfaceAndroidWebView().build(
          context: context,
          creationParams: CreationParams(
              backgroundColor: Colors.transparent,
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                hasNavigationDelegate: false,
              )),
          javascriptChannelRegistry: JavascriptChannelRegistry(null),
          webViewPlatformCallbacksHandler:
              TestWebViewPlatformCallbacksHandler(),
        );
      }));
      await tester.pumpAndSettle();

      final MethodCall createMethodCall = log[0];
      expect(createMethodCall.method, 'create');
      expect(createMethodCall.arguments, containsPair('hybrid', true));
    });

    testWidgets('default text direction is ltr', (WidgetTester tester) async {
      await tester.pumpWidget(Builder(builder: (BuildContext context) {
        return SurfaceAndroidWebView().build(
          context: context,
          creationParams: CreationParams(
              webSettings: WebSettings(
            userAgent: const WebSetting<String?>.absent(),
            hasNavigationDelegate: false,
          )),
          javascriptChannelRegistry: JavascriptChannelRegistry(null),
          webViewPlatformCallbacksHandler:
              TestWebViewPlatformCallbacksHandler(),
        );
      }));
      await tester.pumpAndSettle();

      final MethodCall createMethodCall = log[0];
      expect(createMethodCall.method, 'create');
      expect(
        createMethodCall.arguments,
        containsPair(
          'direction',
          AndroidViewController.kAndroidLayoutDirectionLtr,
        ),
      );
    });
  });
}

class TestWebViewPlatformCallbacksHandler
    implements WebViewPlatformCallbacksHandler {
  @override
  FutureOr<bool> onNavigationRequest({
    required String url,
    required bool isForMainFrame,
  }) {
    throw UnimplementedError();
  }

  @override
  void onPageFinished(String url) {}

  @override
  void onPageStarted(String url) {}

  @override
  void onProgress(int progress) {}

  @override
  void onWebResourceError(WebResourceError error) {}
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
T? _ambiguate<T>(T? value) => value;
