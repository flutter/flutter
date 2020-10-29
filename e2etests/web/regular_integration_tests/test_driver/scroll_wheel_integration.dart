// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:regular_integration_tests/scroll_wheel_main.dart' as app;

import 'package:integration_test/integration_test.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized() as IntegrationTestWidgetsFlutterBinding;

  testWidgets('Test mousewheel scroll by line',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    final Finder finder = find.byKey(const Key('scroll-button'));
    expect(finder, findsOneWidget);
    await tester.tap(find.byKey(const Key('scroll-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scroll-button')));
    await tester.pumpAndSettle();

    // TODO: enable screenshot when
    //  https://github.com/flutter/flutter/issues/68502 is resolved.
    await binding.takeScreenshot('wheel_scroll_by_line');
  });
}
