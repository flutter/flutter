// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JsonEncoder, json;
import 'dart:io' show File, sleep, stdout;

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

// To run this test for all demos:
//    flutter drive --profile --trace-startup -t test_driver/transitions_perf.dart -d <device>
// To run this test for just Crane, with scrolling:
//    flutter drive --profile --trace-startup -t test_driver/transitions_perf.dart -d <device> --dart-define=onlyCrane=true
// To run this test for just Reply, with animations:
//    flutter drive --profile --trace-startup -t test_driver/transitions_perf.dart -d <device> --dart-define=onlyReply=true
// Enable semantics with the --with_semantics flag
// Note: The number of tests executed with timeline collection enabled
// significantly impacts heap size of the running app. When run with
// --trace-startup, as we do in this test, the VM stores trace events in an
// endless buffer instead of a ring buffer.

// Demos for which timeline data will be collected using
// FlutterDriver.traceAction().
//
// These names must match the output of GalleryDemo.describe in
// lib/data/demos.dart.
const List<String> _profiledDemos = <String>[
  'reply@study',
  'shrine@study',
  'rally@study',
  'crane@study',
  'fortnightly@study',
  'bottom-navigation@material',
  'button@material',
  'card@material',
  'chip@material',
  'dialog@material',
  'pickers@material',
  'cupertino-alerts@cupertino',
  'colors@other',
];

// Demos that will be backed out of within FlutterDriver.runUnsynchronized();
//
// These names must match the output of GalleryDemo.describe in
// lib/data/demos.dart.
const List<String> _unsynchronizedDemos = <String>[
  'progress-indicator@material',
  'cupertino-activity-indicator@cupertino',
  'colors@other',
];

// Demos that will be not be launched.
//
// These names must match the output of GalleryDemo.describe in
// lib/data/demos.dart.
const List<String> _skippedDemos = <String>[];

// All of the gallery demos, identified as "title@category".
//
// These names are reported by the test app, see _handleMessages()
// in transitions_perf.dart.
List<String> _allDemos = <String>[];

// SerializableFinders for scrolling actions.
final SerializableFinder homeList = find.byValueKey('HomeListView');
final SerializableFinder backButton = find.byValueKey('Back');
final SerializableFinder galleryHeader = find.text('Gallery');
final SerializableFinder categoriesHeader = find.text('Categories');
final SerializableFinder craneFlyList = find.byValueKey('CraneListView-0');

// SerializableFinders for reply study actions.
final SerializableFinder replyFab = find.byValueKey('ReplyFab');
final SerializableFinder replySearch = find.byValueKey('ReplySearch');
final SerializableFinder replyEmail = find.byValueKey('ReplyEmail-0');
final SerializableFinder replyLogo = find.byValueKey('ReplyLogo');
final SerializableFinder replySentMailbox = find.byValueKey('Reply-Sent');
final SerializableFinder replyExit = find.byValueKey('ReplyExit');

// Let overscroll animation settle on iOS after driver.scroll.
void handleOverscrollAnimation() {
  sleep(const Duration(seconds: 1));
}

/// Scroll to the top of the app, given the current demo. Works with both mobile
/// and desktop layouts.
Future<void> scrollToTop(SerializableFinder demoItem, FlutterDriver driver) async {
  stdout.writeln('scrolling to top');

  // Scroll to the Categories header.
  await driver.scroll(demoItem, 0, 5000, const Duration(milliseconds: 200));
  handleOverscrollAnimation();

  // Scroll to top.
  await driver.scroll(categoriesHeader, 0, 500, const Duration(milliseconds: 200));
  handleOverscrollAnimation();
}

/// Returns a [Future] that resolves to true if the widget specified by [finder]
/// is present, false otherwise.
Future<bool> isPresent(
  SerializableFinder finder,
  FlutterDriver driver, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    await driver.waitFor(finder, timeout: timeout);
    return true;
  } catch (exception) {
    return false;
  }
}

/// Scrolls each demo into view, launches it, then returns to the
/// home screen, twice.
///
/// Optionally specify a callback to perform further actions for each demo.
/// Optionally specify whether a scroll to top should be performed after the
/// demo has been opened twice (true by default).
Future<void> runDemos(
  List<String> demos,
  FlutterDriver driver, {
  Future<void> Function()? additionalActions,
  bool scrollToTopWhenDone = true,
}) async {
  String? currentDemoCategory;
  late SerializableFinder demoList;
  SerializableFinder? demoItem;

  for (final demo in demos) {
    if (_skippedDemos.contains(demo)) {
      continue;
    }

    stdout.writeln('> $demo');

    final String demoCategory = demo.substring(demo.indexOf('@') + 1);
    if (demoCategory != currentDemoCategory) {
      // We've switched categories.
      currentDemoCategory = demoCategory;
      demoList = find.byValueKey('${demoCategory}DemoList');

      // We may want to return to the previous category later.
      // Reset its scroll (matters for desktop layout).
      if (demoItem != null) {
        await scrollToTop(demoItem, driver);
      }

      // Scroll to the category list.
      if (demoCategory != 'study') {
        stdout.writeln('scrolling to $currentDemoCategory category');
        await driver.scrollUntilVisible(
          homeList,
          demoList,
          dyScroll: -1000,
          timeout: const Duration(seconds: 10),
        );
      }
    }

    // Scroll to demo and open it twice.
    demoItem = find.byValueKey(demo);

    stdout.writeln('scrolling to demo');

    // demoList below may be either the horizontally-scrolling Studies carousel
    // or vertically scrolling Material/Cupertino/Other demo lists.
    //
    // The Studies carousel has scroll physics that snap items to the starting
    // edge of the widget. TestDriver.scrollUntilVisible scrolls in increments
    // along the x and y axes; if the distance is too small, the list snaps
    // back to its previous position, if it's too large, it may scroll too far.
    // To resolve this, we scroll 75% of the list width/height dimensions on
    // each increment.
    final DriverOffset topLeft = await driver.getTopLeft(
      demoList,
      timeout: const Duration(seconds: 10),
    );
    final DriverOffset bottomRight = await driver.getBottomRight(
      demoList,
      timeout: const Duration(seconds: 10),
    );
    final double listWidth = bottomRight.dx - topLeft.dx;
    final double listHeight = bottomRight.dy - topLeft.dy;
    await driver.scrollUntilVisible(
      demoList,
      demoItem,
      dxScroll: -listWidth * 0.75,
      dyScroll: -listHeight * 0.75,
      alignment: 0.5,
      timeout: const Duration(seconds: 10),
    );

    // We launch each demo twice to be able to measure and compare first and
    // subsequent builds.
    for (var i = 0; i < 2; i += 1) {
      stdout.writeln('tapping demo');
      await driver.tap(demoItem); // Launch the demo

      sleep(const Duration(milliseconds: 500));

      if (additionalActions != null) {
        await additionalActions();
      }

      if (_unsynchronizedDemos.contains(demo)) {
        await driver.runUnsynchronized<void>(() async {
          await driver.tap(backButton);
        });
      } else {
        await driver.tap(backButton);
      }
    }
    stdout.writeln('< Success');
  }

  if (scrollToTopWhenDone) {
    await scrollToTop(demoItem!, driver);
  }
}

/// Summarizes how well the Impeller pipelines created up front (warmed) covered
/// the draws made so far, as reported by `_flutter.getPipelineUsage`.
///
/// Returns no metrics, rather than failing the benchmark, if pipeline usage is
/// unavailable, for example because the app is not rendering with Impeller.
Future<Map<String, Object?>> pipelineWarmupMetrics(FlutterDriver driver) async {
  try {
    final Map<String, Object?>? views = (await driver.serviceClient.callMethod(
      '_flutter.listViews',
    )).json;
    if (views case {'views': [{'id': final String viewId}, ...]}) {
      final Map<String, Object?>? usage = (await driver.serviceClient.callMethod(
        '_flutter.getPipelineUsage',
        args: <String, Object?>{'viewId': viewId},
      )).json;
      if (usage case {'pipelines': final List<Object?> pipelines}) {
        return _summarizePipelineUsage(pipelines);
      }
      throw FormatException(
        'Expected a "pipelines" list in the _flutter.getPipelineUsage response for view '
        '$viewId, but got keys ${usage?.keys.toList()}.',
      );
    }
    throw FormatException(
      'Expected at least one Flutter view in the _flutter.listViews response, but got $views.',
    );
  } catch (error) {
    stdout.writeln('Not reporting pipeline warmup metrics: $error');
    return const <String, Object?>{};
  }
}

/// The warmup metrics for the `pipelines` of a `_flutter.getPipelineUsage`
/// response. Also logs the pipelines that were created lazily, to help track
/// down regressions.
Map<String, Object?> _summarizePipelineUsage(List<Object?> pipelines) {
  var totalDraws = 0;
  var warmedDraws = 0;
  var warmedNeverDrawn = 0;
  final lazyPipelines = <String>[];
  for (final pipeline in pipelines) {
    if (pipeline case {
      'label': final String label,
      'constants': final List<Object?> constants,
      'count': final int count,
      'eagerly_created': final bool eagerlyCreated,
    }) {
      totalDraws += count;
      if (!eagerlyCreated) {
        final name = constants.isEmpty ? label : '$label $constants';
        lazyPipelines.add('$name: $count draws');
      } else if (count == 0) {
        warmedNeverDrawn += 1;
      } else {
        warmedDraws += count;
      }
    } else {
      throw FormatException(
        'Expected a label, constants, count and eagerly_created in each '
        '_flutter.getPipelineUsage entry, but got $pipeline.',
      );
    }
  }
  if (totalDraws == 0) {
    throw FormatException(
      '_flutter.getPipelineUsage reported ${pipelines.length} pipelines, but no draws.',
    );
  }

  final double warmedDrawPercent = double.parse(
    (warmedDraws * 100 / totalDraws).toStringAsFixed(2),
  );
  stdout.writeln(
    'Impeller pipeline warmup: ${warmedDrawPercent.toStringAsFixed(2)}% of $totalDraws draws '
    'used a warmed pipeline, $warmedNeverDrawn warmed pipelines were never drawn with, and '
    '${lazyPipelines.length} pipelines were created lazily:',
  );
  lazyPipelines.sort();
  for (final pipeline in lazyPipelines) {
    stdout.writeln('  $pipeline');
  }
  return <String, Object?>{
    'shader_warmed_draw_percent': warmedDrawPercent,
    'shader_lazy_variants': lazyPipelines.length,
    'shader_warmed_never_drawn_variants': warmedNeverDrawn,
  };
}

void main([List<String> args = const <String>[]]) {
  group('Flutter Gallery transitions', () {
    late FlutterDriver driver;

    late bool isTestingCraneOnly;
    late bool isTestingReplyOnly;

    setUpAll(() async {
      driver = await FlutterDriver.connect();

      // See _handleMessages() in transitions_perf.dart.
      _allDemos = List<String>.from(
        json.decode(await driver.requestData('demoDescriptions')) as List<dynamic>,
      );
      if (_allDemos.isEmpty) {
        throw 'no demo names found';
      }

      // See _handleMessages() in transitions_perf.dart.
      isTestingCraneOnly = await driver.requestData('isTestingCraneOnly') == 'true';

      // See _handleMessages() in transitions_perf.dart.
      isTestingReplyOnly = await driver.requestData('isTestingReplyOnly') == 'true';

      if (args.contains('--with_semantics')) {
        stdout.writeln('Enabling semantics...');
        await driver.setSemantics(true);
      }

      await isPresent(galleryHeader, driver);
    });

    tearDownAll(() async {
      await driver.close();

      stdout.writeln(
        'Timeline summaries for profiled demos have been output to the build/ directory.',
      );
    });

    test('only Crane', () async {
      if (!isTestingCraneOnly) {
        return;
      }

      // Collect timeline data for just the Crane study.
      final Timeline timeline = await driver.traceAction(() async {
        await runDemos(
          <String>['crane@study'],
          driver,
          additionalActions: () async =>
              driver.scroll(craneFlyList, 0, -1000, const Duration(seconds: 1)),
          scrollToTopWhenDone: false,
        );
      }, streams: const <TimelineStream>[TimelineStream.dart, TimelineStream.embedder]);

      final summary = TimelineSummary.summarize(timeline);
      await summary.writeTimelineToFile('transitions-crane', pretty: true);
    }, timeout: Timeout.none);

    test('only Reply', () async {
      if (!isTestingReplyOnly) {
        return;
      }

      // Collect timeline data for just the Crane study.
      final Timeline timeline = await driver.traceAction(() async {
        await runDemos(
          <String>['reply@study'],
          driver,
          additionalActions: () async {
            // Tap compose fab to trigger open container transform/fade through
            await driver.tap(replyFab);
            // Exit compose page
            await driver.tap(replyExit);
            // Tap search icon to trigger shared axis transition
            await driver.tap(replySearch);
            // Exit search page
            await driver.tap(replyExit);
            // Tap on email to trigger open container transform
            await driver.tap(replyEmail);
            // Exit email page
            await driver.tap(replyExit);
            // Tap Reply logo to open bottom drawer/navigation rail
            await driver.tap(replyLogo);
            // Tap Reply logo to close bottom drawer/navigation rail
            await driver.tap(replyLogo);
            // Tap Reply logo to open bottom drawer/navigation rail
            await driver.tap(replyLogo);
            // Tap sent mailbox destination to trigger fade through transition
            await driver.tap(replySentMailbox);
          },
          scrollToTopWhenDone: false,
        );
      }, streams: const <TimelineStream>[TimelineStream.dart, TimelineStream.embedder]);

      final summary = TimelineSummary.summarize(timeline);
      await summary.writeTimelineToFile('transitions-reply', pretty: true);
    }, timeout: Timeout.none);

    test('all demos', () async {
      if (isTestingCraneOnly || isTestingReplyOnly) {
        return;
      }

      // Collect timeline data for just a limited set of demos to avoid OOMs.
      final Timeline timeline = await driver.traceAction(
        () async {
          await runDemos(_profiledDemos, driver);
        },
        streams: const <TimelineStream>[TimelineStream.dart, TimelineStream.embedder],
        retainPriorEvents: true,
      );

      final summary = TimelineSummary.summarize(timeline);
      // The summary is written once every demo has run, so that it can include
      // the pipeline warmup metrics.
      await summary.writeTimelineToFile('transitions', pretty: true, includeSummary: false);

      // Execute the remaining tests.
      final unprofiledDemos = Set<String>.from(_allDemos)..removeAll(_profiledDemos);
      await runDemos(unprofiledDemos.toList(), driver);

      final summaryJson = <String, Object?>{
        ...summary.summaryJson,
        ...await pipelineWarmupMetrics(driver),
      };
      await File('$testOutputsDirectory/transitions.timeline_summary.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(summaryJson));
    }, timeout: Timeout.none);
  });
}
