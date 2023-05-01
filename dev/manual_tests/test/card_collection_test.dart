// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manual_tests/card_collection.dart' as card_collection;

import 'mock_image_http.dart';

void main() {
  testWidgets('Card Collection smoke test', (WidgetTester tester) async {
    HttpOverrides.runZoned<Future<void>>(() async {
      card_collection.main(); // builds the app and schedules a frame but doesn't trigger one
      await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
      await tester.pump(); // triggers a frame

      final Finder navigationMenu = find.byWidgetPredicate((Widget widget) {
        if (widget is Tooltip) {
          return widget.message == 'Open navigation menu';
        }
        return false;
      });

      expect(navigationMenu, findsOneWidget);

      await tester.tap(navigationMenu);
      await tester.pump(); // start opening menu
      await tester.pump(const Duration(seconds: 1)); // wait til it's really opened

      // smoke test for various checkboxes
      await tester.tap(find.text('Make card labels editable'));
      await tester.pump();
      await tester.tap(find.text('Let the sun shine'));
      await tester.pump();
      await tester.tap(find.text('Make card labels editable'));
      await tester.pump();
      await tester.tap(find.text('Vary font sizes'));
      await tester.pump();
    }, createHttpClient: createMockImageHttpClient);
  });
}
