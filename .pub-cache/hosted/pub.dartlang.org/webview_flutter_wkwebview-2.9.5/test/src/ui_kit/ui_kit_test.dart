// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_wkwebview/src/common/instance_manager.dart';
import 'package:webview_flutter_wkwebview/src/ui_kit/ui_kit.dart';
import 'package:webview_flutter_wkwebview/src/web_kit/web_kit.dart';

import '../common/test_web_kit.pigeon.dart';
import 'ui_kit_test.mocks.dart';

@GenerateMocks(<Type>[
  TestWKWebViewConfigurationHostApi,
  TestWKWebViewHostApi,
  TestUIScrollViewHostApi,
  TestUIViewHostApi,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UIKit', () {
    late InstanceManager instanceManager;

    setUp(() {
      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
    });

    group('UIScrollView', () {
      late MockTestUIScrollViewHostApi mockPlatformHostApi;

      late UIScrollView scrollView;
      late int scrollViewInstanceId;

      setUp(() {
        mockPlatformHostApi = MockTestUIScrollViewHostApi();
        TestUIScrollViewHostApi.setup(mockPlatformHostApi);

        TestWKWebViewConfigurationHostApi.setup(
          MockTestWKWebViewConfigurationHostApi(),
        );
        TestWKWebViewHostApi.setup(MockTestWKWebViewHostApi());
        final WKWebView webView = WKWebView(
          WKWebViewConfiguration(instanceManager: instanceManager),
          instanceManager: instanceManager,
        );

        scrollView = UIScrollView.fromWebView(
          webView,
          instanceManager: instanceManager,
        );
        scrollViewInstanceId = instanceManager.getIdentifier(scrollView)!;
      });

      tearDown(() {
        TestUIScrollViewHostApi.setup(null);
        TestWKWebViewConfigurationHostApi.setup(null);
        TestWKWebViewHostApi.setup(null);
      });

      test('getContentOffset', () async {
        when(mockPlatformHostApi.getContentOffset(scrollViewInstanceId))
            .thenReturn(<double>[4.0, 10.0]);
        expect(
          scrollView.getContentOffset(),
          completion(const Point<double>(4.0, 10.0)),
        );
      });

      test('scrollBy', () async {
        await scrollView.scrollBy(const Point<double>(4.0, 10.0));
        verify(mockPlatformHostApi.scrollBy(scrollViewInstanceId, 4.0, 10.0));
      });

      test('setContentOffset', () async {
        await scrollView.setContentOffset(const Point<double>(4.0, 10.0));
        verify(mockPlatformHostApi.setContentOffset(
          scrollViewInstanceId,
          4.0,
          10.0,
        ));
      });
    });

    group('UIView', () {
      late MockTestUIViewHostApi mockPlatformHostApi;

      late UIView view;
      late int viewInstanceId;

      setUp(() {
        mockPlatformHostApi = MockTestUIViewHostApi();
        TestUIViewHostApi.setup(mockPlatformHostApi);

        view = UIView.detached(instanceManager: instanceManager);
        viewInstanceId = instanceManager.addDartCreatedInstance(view);
      });

      tearDown(() {
        TestUIViewHostApi.setup(null);
      });

      test('setBackgroundColor', () async {
        await view.setBackgroundColor(Colors.red);
        verify(mockPlatformHostApi.setBackgroundColor(
          viewInstanceId,
          Colors.red.value,
        ));
      });

      test('setOpaque', () async {
        await view.setOpaque(false);
        verify(mockPlatformHostApi.setOpaque(viewInstanceId, false));
      });
    });
  });
}
