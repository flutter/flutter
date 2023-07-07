// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_wkwebview/src/common/instance_manager.dart';
import 'package:webview_flutter_wkwebview/src/foundation/foundation.dart';
import 'package:webview_flutter_wkwebview/src/v4/src/webkit_proxy.dart';
import 'package:webview_flutter_wkwebview/src/v4/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_wkwebview/src/web_kit/web_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebKitWebViewWidget', () {
    testWidgets('build', (WidgetTester tester) async {
      final InstanceManager instanceManager = InstanceManager(
        onWeakReferenceRemoved: (_) {},
      );

      final WebKitWebViewController controller = WebKitWebViewController(
        WebKitWebViewControllerCreationParams(
          webKitProxy: WebKitProxy(
            createWebView: (
              WKWebViewConfiguration configuration, {
              void Function(
                String keyPath,
                NSObject object,
                Map<NSKeyValueChangeKey, Object?> change,
              )?
                  observeValue,
            }) {
              final WKWebView webView = WKWebView.detached(
                instanceManager: instanceManager,
              );
              instanceManager.addDartCreatedInstance(webView);
              return webView;
            },
            createWebViewConfiguration: WKWebViewConfiguration.detached,
          ),
        ),
      );

      final WebKitWebViewWidget widget = WebKitWebViewWidget(
        WebKitWebViewWidgetCreationParams(
          controller: controller,
          instanceManager: instanceManager,
        ),
      );

      await tester.pumpWidget(
        Builder(builder: (BuildContext context) => widget.build(context)),
      );

      expect(find.byType(UiKitView), findsOneWidget);
    });
  });
}
