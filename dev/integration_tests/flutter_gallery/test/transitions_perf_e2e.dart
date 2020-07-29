// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e2e/e2e.dart';

import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;
import 'package:flutter_gallery/gallery/demos.dart';
import 'package:flutter_gallery/demo_lists.dart';
import 'package:flutter_gallery/gallery/home.dart';

import 'util.dart' show watchPerformance;

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
Future<void> runDemos(List<String> demos, WidgetTester tester) async {
  final Finder demoList = find.byType(Scrollable);
  String currentDemoCategory;

  for (final String demo in demos) {
    if (kSkippedDemos.contains(demo))
      continue;

    final String demoName = demo.substring(0, demo.indexOf('@'));
    final String demoCategory = demo.substring(demo.indexOf('@') + 1);
    print('> $demo');
    await tester.binding.delayed(const Duration(milliseconds: 250));

    if (currentDemoCategory == null) {
      await tester.tap(find.text(demoCategory));
      await tester.pumpAndSettle();
    } else if (currentDemoCategory != demoCategory) {
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(demoCategory));
      await tester.pumpAndSettle();
      // Scroll back to the top
      await tester.drag(demoList, const Offset(0.0, 10000.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }
    currentDemoCategory = demoCategory;

    final Finder demoItem = find.text(demoName);
    await tester.scrollUntilVisible(demoItem, demoList, 48.0);
    await tester.pumpAndSettle();

    for (int i = 0; i < 2; i += 1) {
      await tester.tap(demoItem); // Launch the demo

      if (kUnsynchronizedDemos.contains(demo)) {
        // These tests have animation, pumpAndSettle cannot be used.
        // This time is questionable. 300ms is the tested reasonable result.
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        await tester.pageBack();
      } else {
        await tester.pumpAndSettle();
        await tester.pageBack();
      }
      await tester.pumpAndSettle();
    }

    print('< Success');
  }

  // Return to the home screen
  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();
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
        final Map<String, List<int>> transitionTimes = <String, List<int>>{};
        galleryTransitionCallback = (String routeName) {
          TimingsCallback transitionWatcher;
          transitionWatcher = (Iterable<FrameTiming> timings) {
            transitionTimes[routeName] ??= <int>[];
            transitionTimes[routeName].add(timings.first.buildDuration.inMicroseconds);
            binding.removeTimingsCallback(transitionWatcher);
          };
          binding.addTimingsCallback(transitionWatcher);
        };
        runApp(const GalleryApp(testMode: true));
        await tester.pumpAndSettle();
        // Collect timeline data for just a limited set of demos to avoid OOMs.
        await watchPerformance(binding, () async {
          await runDemos(kProfiledDemos, tester);
        });

        print(transitionTimes);
        reportTransitionsHistogram(transitionTimes, binding);
        galleryTransitionCallback = null;

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

/// Validates and reports transition times.
///
/// This is a duplicate implementation of part of [saveDurationsHistogram] in
/// [test_driver/transitions_perf_test.dart].
void reportTransitionsHistogram(
  final Map<String, List<int>> durations,
  E2EWidgetsFlutterBinding binding,
) {
  if(durations.keys.isEmpty) {
    throw ArgumentError('no "Start Transition" timeline events found');
  }
  final Map<String, int> unexpectedValueCounts = <String, int>{};
  durations.forEach((String routeName, List<int> values) {
    if (values.length != 2) {
      unexpectedValueCounts[routeName] = values.length;
    }
  });

  if (unexpectedValueCounts.isNotEmpty) {
    throw ArgumentError('Some routes recorded wrong number of values '
    '(expected 2 values/route):\n'
    '\t${unexpectedValueCounts.keys.toList()}');
  }
  binding.reportData['transition_durations'] = durations;
}
