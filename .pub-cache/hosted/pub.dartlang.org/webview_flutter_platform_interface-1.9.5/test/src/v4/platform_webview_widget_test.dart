// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:webview_flutter_platform_interface/v4/src/platform_webview_controller.dart';
import 'package:webview_flutter_platform_interface/v4/src/platform_webview_widget.dart';
import 'package:webview_flutter_platform_interface/v4/src/webview_platform.dart';

import 'webview_platform_test.mocks.dart';

void main() {
  setUp(() {
    WebViewPlatform.instance = MockWebViewPlatformWithMixin();
  });

  test('Cannot be implemented with `implements`', () {
    final MockWebViewControllerDelegate controller =
        MockWebViewControllerDelegate();
    final PlatformWebViewWidgetCreationParams params =
        PlatformWebViewWidgetCreationParams(controller: controller);
    when(WebViewPlatform.instance!.createPlatformWebViewWidget(params))
        .thenReturn(ImplementsWebViewWidgetDelegate());

    expect(() {
      PlatformWebViewWidget(params);
      // In versions of `package:plugin_platform_interface` prior to fixing
      // https://github.com/flutter/flutter/issues/109339, an attempt to
      // implement a platform interface using `implements` would sometimes throw
      // a `NoSuchMethodError` and other times throw an `AssertionError`.  After
      // the issue is fixed, an `AssertionError` will always be thrown.  For the
      // purpose of this test, we don't really care what exception is thrown, so
      // just allow any exception.
    }, throwsA(anything));
  });

  test('Can be extended', () {
    final MockWebViewControllerDelegate controller =
        MockWebViewControllerDelegate();
    final PlatformWebViewWidgetCreationParams params =
        PlatformWebViewWidgetCreationParams(controller: controller);
    when(WebViewPlatform.instance!.createPlatformWebViewWidget(params))
        .thenReturn(ExtendsWebViewWidgetDelegate(params));

    expect(PlatformWebViewWidget(params), isNotNull);
  });

  test('Can be mocked with `implements`', () {
    final MockWebViewControllerDelegate controller =
        MockWebViewControllerDelegate();
    final PlatformWebViewWidgetCreationParams params =
        PlatformWebViewWidgetCreationParams(controller: controller);
    when(WebViewPlatform.instance!.createPlatformWebViewWidget(params))
        .thenReturn(MockWebViewWidgetDelegate());

    expect(PlatformWebViewWidget(params), isNotNull);
  });
}

class MockWebViewPlatformWithMixin extends MockWebViewPlatform
    with
        // ignore: prefer_mixin
        MockPlatformInterfaceMixin {}

class ImplementsWebViewWidgetDelegate implements PlatformWebViewWidget {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWebViewWidgetDelegate extends Mock
    with
        // ignore: prefer_mixin
        MockPlatformInterfaceMixin
    implements
        PlatformWebViewWidget {}

class ExtendsWebViewWidgetDelegate extends PlatformWebViewWidget {
  ExtendsWebViewWidgetDelegate(PlatformWebViewWidgetCreationParams params)
      : super.implementation(params);

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError(
        'build is not implemented for ExtendedWebViewWidgetDelegate.');
  }
}

class MockWebViewControllerDelegate extends Mock
    with
        // ignore: prefer_mixin
        MockPlatformInterfaceMixin
    implements
        PlatformWebViewController {}
