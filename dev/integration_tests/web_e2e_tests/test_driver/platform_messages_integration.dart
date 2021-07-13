// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
// platformViewRegistry is exposed in the web version
import 'dart:ui' as ui show platformViewRegistry; // ignore: undefined_shown_name

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_e2e_tests/platform_messages_main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('platform message for Clipboard.setData reply with future',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // TODO(nurhan): https://github.com/flutter/flutter/issues/51885
    SystemChannels.textInput.setMockMethodCallHandler(null);
    // Focus on a TextFormField.
    final Finder finder = find.byKey(const Key('input'));
    expect(finder, findsOneWidget);
    await tester.tap(find.byKey(const Key('input')));
    // Focus in input, otherwise clipboard will fail with
    // 'document is not focused' platform exception.
    html.document.querySelector('input')?.focus();
    await Clipboard.setData(const ClipboardData(text: 'sample text'));
  }, skip: true); // https://github.com/flutter/flutter/issues/54296

  testWidgets('Should create and dispose view embedder',
      (WidgetTester tester) async {
    int viewInstanceCount = 0;

    platformViewsRegistry.getNextPlatformViewId();
    // ignore: undefined_prefixed_name, avoid_dynamic_calls
    ui.platformViewRegistry.registerViewFactory('MyView', (int viewId) {
      ++viewInstanceCount;
      return html.DivElement();
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
