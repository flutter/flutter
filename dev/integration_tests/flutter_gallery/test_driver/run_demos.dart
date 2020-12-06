// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gallery/demo_lists.dart';

const List<String> kSkippedDemos = <String>[];

/// Scrolls each demo menu item into view, launches it, then returns to the
/// home screen twice.
Future<void> runDemos(List<String> demos, WidgetController controller) async {
  final Finder demoList = find.byType(Scrollable);
  String currentDemoCategory;

  for (final String demo in demos) {
    if (kSkippedDemos.contains(demo))
      continue;

    final String demoName = demo.substring(0, demo.indexOf('@'));
    final String demoCategory = demo.substring(demo.indexOf('@') + 1);
    print('> $demo');
    await controller.pump(const Duration(milliseconds: 250));

    if (currentDemoCategory == null) {
      await controller.tap(find.text(demoCategory));
      await controller.pumpAndSettle();
    } else if (currentDemoCategory != demoCategory) {
      await controller.tap(find.byTooltip('Back'));
      await controller.pumpAndSettle();
      await controller.tap(find.text(demoCategory));
      await controller.pumpAndSettle();
      // Scroll back to the top
      await controller.drag(demoList, const Offset(0.0, 10000.0));
      await controller.pumpAndSettle(const Duration(milliseconds: 100));
    }
    currentDemoCategory = demoCategory;

    final Finder demoItem = find.text(demoName);
    await controller.scrollUntilVisible(demoItem, 48.0);
    await controller.pumpAndSettle();

    Future<void> pageBack() {
      Finder backButton = find.byTooltip('Back');
      if (backButton.evaluate().isEmpty) {
        backButton = find.byType(CupertinoNavigationBarBackButton);
      }
      return controller.tap(backButton);
    }

    for (int i = 0; i < 2; i += 1) {
      await controller.tap(demoItem); // Launch the demo

      if (kUnsynchronizedDemos.contains(demo)) {
        // These tests have animation, pumpAndSettle cannot be used.
        // This time is questionable. 400ms is the tested reasonable result.
        await controller.pump(const Duration(milliseconds: 400));
        await controller.pump();
        await pageBack();
      } else {
        await controller.pumpAndSettle();
        // page back
        await pageBack();
      }
      await controller.pumpAndSettle();
    }

    print('< Success');
  }

  // Return to the home screen
  await controller.tap(find.byTooltip('Back'));
  await controller.pumpAndSettle();
}
