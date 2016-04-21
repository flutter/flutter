// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

import '../card_collection.dart' as card_collection;

void main() {
  test("Card Collection smoke test", () {
    testWidgets((WidgetTester tester) {
      card_collection.main(); // builds the app and schedules a frame but doesn't trigger one
      tester.pump(); // see https://github.com/flutter/flutter/issues/1865
      tester.pump(); // triggers a frame

      Finder navigationMenu = find.byWidgetPredicate((Widget widget) {
        if (widget is Tooltip)
          return widget.message == 'Open navigation menu';
        return false;
      });

      expect(tester, hasWidget(navigationMenu));

      tester.tap(navigationMenu);
      tester.pump(); // start opening menu
      tester.pump(const Duration(seconds: 1)); // wait til it's really opened

      // smoke test for various checkboxes
      tester.tap(find.text('Make card labels editable'));
      tester.pump();
      tester.tap(find.text('Let the sun shine'));
      tester.pump();
      tester.tap(find.text('Make card labels editable'));
      tester.pump();
      tester.tap(find.text('Vary font sizes'));
      tester.pump();
    });
  });
}
