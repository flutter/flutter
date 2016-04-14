// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

import '../lib/main.dart' as material_gallery;

void main() {
  test('Material Gallery app smoke test', () {
    testWidgets((WidgetTester tester) {
      material_gallery.main(); // builds the app and schedules a frame but doesn't trigger one
      tester.pump(); // see https://github.com/flutter/flutter/issues/1865
      tester.pump(); // triggers a frame

      // Try loading Weather demo
      tester.tap(find.text('Demos'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // wait til it's really opened

      tester.tap(find.text('Weather'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // wait til it's really opened

      // Go back
      Finder backButton = find.byElement((Element element) {
        Widget widget = element.widget;
        if (widget is Tooltip)
          return widget.message == 'Back';
        return false;
      });
      expect(tester, hasWidget(backButton));
      tester.tap(backButton);
      tester.pump(); // start going back
      tester.pump(const Duration(seconds: 1)); // wait til it's finished

      // Open menu
      Finder navigationMenu = find.byElement((Element element) {
        Widget widget = element.widget;
        if (widget is Tooltip)
          return widget.message == 'Open navigation menu';
        return false;
      });
      expect(tester, hasWidget(navigationMenu));
      tester.tap(navigationMenu);
      tester.pump(); // start opening menu
      tester.pump(const Duration(seconds: 1)); // wait til it's really opened

      // switch theme
      tester.tap(find.text('Dark'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // wait til it's changed

      // switch theme
      tester.tap(find.text('Light'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // wait til it's changed
    });
  });
}
