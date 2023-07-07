// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebWebViewWidget', () {
    testWidgets('build returns a HtmlElementView', (WidgetTester tester) async {
      final WebWebViewController controller =
          WebWebViewController(WebWebViewControllerCreationParams());

      final WebWebViewWidget widget = WebWebViewWidget(
        PlatformWebViewWidgetCreationParams(
          key: const Key('keyValue'),
          controller: controller,
        ),
      );

      await tester.pumpWidget(
        Builder(builder: (BuildContext context) => widget.build(context)),
      );

      expect(find.byType(HtmlElementView), findsOneWidget);
      expect(find.byKey(const Key('keyValue')), findsOneWidget);
    });
  });
}
