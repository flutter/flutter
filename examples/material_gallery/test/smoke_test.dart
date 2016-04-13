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
      tester.tap(tester.findText('Demos'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // wait til it's really opened

      tester.tap(tester.findText('Weather'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // wait til it's really opened

      // Go back
      Element backButton = tester.findElement((Element element) {
        Widget widget = element.widget;
        if (widget is Tooltip)
          return widget.message == 'Back';
        return false;
      });
      expect(backButton, isNotNull);
      tester.tap(backButton);
      tester.pump(); // start going back
      tester.pump(const Duration(seconds: 1)); // wait til it's finished

      // Open menu
      Element navigationMenu = tester.findElement((Element element) {
        Widget widget = element.widget;
        if (widget is Tooltip)
          return widget.message == 'Open navigation menu';
        return false;
      });
      expect(navigationMenu, isNotNull);
      tester.tap(navigationMenu);
      tester.pump(); // start opening menu
      tester.pump(const Duration(seconds: 1)); // wait til it's really opened

      // switch theme
      tester.tap(tester.findText('Dark'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // wait til it's changed

      // switch theme
      tester.tap(tester.findText('Light'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // wait til it's changed
    });
  });
}
