// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web/web.dart' as web;
import 'package:web_e2e_tests/platform_messages_main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('platform message for Clipboard.setData reply with future',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // TODO(nurhan): https://github.com/flutter/flutter/issues/51885
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, null);
    // Focus on a TextFormField.
    final Finder finder = find.byKey(const Key('input'));
    expect(finder, findsOneWidget);
    await tester.tap(find.byKey(const Key('input')));
    // Focus in input, otherwise clipboard will fail with
    // 'document is not focused' platform exception.
    (web.document.querySelector('input') as web.HTMLElement?)?.focus();
    await Clipboard.setData(const ClipboardData(text: 'sample text'));
  }, skip: true); // https://github.com/flutter/flutter/issues/54296

  testWidgets('Should create and dispose view embedder',
      (WidgetTester tester) async {
    int viewInstanceCount = 0;

    platformViewsRegistry.getNextPlatformViewId();
    ui_web.platformViewRegistry.registerViewFactory('MyView', (int viewId) {
      viewInstanceCount += 1;
      return web.HTMLDivElement();
    });

    app.main();
    await tester.pumpAndSettle();
    final Map<String, dynamic> createArgs = <String, dynamic>{
      'id': 567,
      'viewType': 'MyView',
    };
    await SystemChannels.platform_views.invokeMethod<void>('create', createArgs);
    await SystemChannels.platform_views.invokeMethod<void>('dispose', 567);
    expect(viewInstanceCount, 1);
  });
}
