// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e2e/e2e.dart';

import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;
import 'package:flutter_gallery/gallery/demos.dart';
import 'package:flutter_gallery/demo_lists.dart';

import 'e2e_utils.dart';

const List<String> kSkippedDemos = <String>[];

// All of the gallery demos, identified as "title@category".
//
// These names are reported by the test app, see _handleMessages()
// in transitions_perf.dart.
List<String> _allDemos = kAllGalleryDemos.map(
  (GalleryDemo demo) => '${demo.title}@${demo.category.name}',
).toList();

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
        // This time is questionable. 300ms is the tested reasonable result.
        await controller.pump(const Duration(milliseconds: 300));
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

void main([List<String> args = const <String>[]]) {
  final bool withSemantics = args.contains('--with_semantics');
  final E2EWidgetsFlutterBinding binding =
      E2EWidgetsFlutterBinding.ensureInitialized() as E2EWidgetsFlutterBinding;
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  group('flutter gallery transitions on e2e', () {
    testWidgets('find.bySemanticsLabel', (WidgetTester tester) async {
      runApp(const GalleryApp(testMode: true));
      await tester.pumpAndSettle();
      final int id = tester.getSemantics(find.bySemanticsLabel('Material')).id;
      expect(id, greaterThan(-1));
    }, skip: !withSemantics, semanticsEnabled: true);

    testWidgets(
      'all demos',
      (WidgetTester tester) async {
        runApp(const GalleryApp(testMode: true));
        await tester.pumpAndSettle();
        // Collect timeline data for just a limited set of demos to avoid OOMs.
        await watchPerformance(binding, () async {
          await runDemos(kProfiledDemos, tester);
        });

        // Execute the remaining tests.
        final Set<String> unprofiledDemos = Set<String>.from(_allDemos)
          ..removeAll(kProfiledDemos);
        await runDemos(unprofiledDemos.toList(), tester);
      },
      timeout: const Timeout(Duration(minutes: 5)),
      semanticsEnabled: withSemantics,
    );
  });
}
