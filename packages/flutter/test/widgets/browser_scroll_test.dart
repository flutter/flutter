// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The test harness uses `BrowserScrollViewBinding.calls`, which only exists in
// the IO stub (`_browser_scroll_view_io.dart`). On web the binding delegates
// to the real engine via `FlutterView` method calls and has no recorded calls
// list. Skip the file on web.
@TestOn('!chrome')
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(ScrollController controller) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: BrowserScrollable(
        child: ListView.builder(
          controller: controller,
          itemCount: 20,
          itemBuilder: (context, index) => SizedBox(height: 200.0, child: Text('Item $index')),
        ),
      ),
    ),
  );
}

Widget _buildTestAppNoPrimaryNoController() {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: BrowserScrollable(
        child: ListView.builder(
          primary: false,
          itemCount: 20,
          itemBuilder: (context, index) => SizedBox(height: 200.0, child: Text('Item $index')),
        ),
      ),
    ),
  );
}

void _simulateOnScroll(double offset) {
  ScrollableState.browserScrollViewBinding?.onBrowserScroll?.call(offset);
}

List<Map<String, Object?>> _bindingCalls() {
  return ScrollableState.browserScrollViewBinding?.calls ?? <Map<String, Object?>>[];
}

List<Map<String, Object?>> _callsOf(String method) {
  return _bindingCalls().where((c) => c['method'] == method).toList();
}

void _clearCalls() {
  ScrollableState.browserScrollViewBinding?.calls.clear();
}

void main() {
  group('ScrollableState browser-scroll integration – placeholder height', () {
    late ScrollController controller;

    setUp(() {
      controller = ScrollController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('reports initial height via binding', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _simulateOnScroll(0);
      await tester.pump();

      if (controller.hasClients) {
        expect(controller.position.pixels, closeTo(0.0, 1.0));
      }
    });

    testWidgets('reports content height to engine', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _simulateOnScroll(0);
      await tester.pump();

      final List<Map<String, Object?>> heights = _callsOf('updateBrowserScrollContentHeight');
      expect(heights, isNotEmpty);

      final double viewport = tester.getSize(find.byType(ListView)).height;
      final lastHeight = heights.last['args']! as double;
      expect(lastHeight, closeTo(viewport * 2, 2.0));
    });

    testWidgets('content height grows as user scrolls down', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _simulateOnScroll(500);
      await tester.pump();

      _simulateOnScroll(1000);
      await tester.pump();

      final List<double> heights = _callsOf(
        'updateBrowserScrollContentHeight',
      ).map((c) => c['args']! as double).toList();
      if (heights.length >= 2) {
        expect(heights.last, greaterThanOrEqualTo(heights.first));
      }
    });

    testWidgets('duplicate heights within tolerance are not re-reported', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _simulateOnScroll(100);
      await tester.pump();

      final int countAfterFirst = _callsOf('updateBrowserScrollContentHeight').length;

      _simulateOnScroll(100);
      await tester.pump();

      expect(_callsOf('updateBrowserScrollContentHeight').length, countAfterFirst);
    });

    testWidgets('onScroll syncs Flutter position to browser scrollTop', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _simulateOnScroll(300);
      await tester.pump();

      if (controller.hasClients) {
        final ScrollPosition pos = controller.position;
        expect(pos.pixels, closeTo(300.0, 1.0));
      }
    });

    testWidgets('onScroll clamps to maxScrollExtent', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _simulateOnScroll(999999);
      await tester.pump();

      if (controller.hasClients) {
        final ScrollPosition pos = controller.position;
        expect(pos.pixels, lessThanOrEqualTo(pos.maxScrollExtent + 1.0));
      }
    });

    testWidgets('mounts and unmounts cleanly', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('dispose triggers disableBrowserScrolling and clears binding', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      expect(ScrollableState.browserScrollViewBinding, isNotNull);

      // Capture the binding before it is cleared on teardown, so we can inspect
      // its call log after the widget is disposed.
      // ignore: specify_nonobvious_local_variable_types
      final binding = ScrollableState.browserScrollViewBinding!;
      binding.calls.clear();

      // Replace the widget tree with something that has no BrowserScrollable.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // The static binding must be cleared on teardown.
      expect(ScrollableState.browserScrollViewBinding, isNull);

      // disableBrowserScrolling must have been recorded by the captured binding.
      expect(
        binding.calls.where((Map<String, Object?> c) => c['method'] == 'disableBrowserScrolling'),
        isNotEmpty,
      );
    });

    testWidgets('controller swap re-registers callback', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      final controller2 = ScrollController();
      addTearDown(controller2.dispose);

      await tester.pumpWidget(_buildTestApp(controller2));
      await tester.pump();

      _simulateOnScroll(100);
      await tester.pump();

      if (controller2.hasClients) {
        expect(controller2.position.pixels, closeTo(100.0, 1.0));
      }
    });

    testWidgets('disabling enableBrowserScrolling tears down callback', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _simulateOnScroll(200);
      await tester.pump();

      expect(controller.position.pixels, closeTo(200.0, 1.0));

      // Rebuild with enableBrowserScrolling: false.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(enableBrowserScrolling: false),
              child: ListView.builder(
                controller: controller,
                itemCount: 20,
                itemBuilder: (context, index) =>
                    SizedBox(height: 200.0, child: Text('Item $index')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // The callback should be null now, so simulateOnScroll should do nothing.
      final double pixelsBefore = controller.position.pixels;
      _simulateOnScroll(0);
      await tester.pump();
      expect(controller.position.pixels, pixelsBefore);
    });
  });

  group('ScrollableState browser-scroll – primary:false fallback controller', () {
    testWidgets('works with primary:false and no explicit controller', (tester) async {
      await tester.pumpWidget(_buildTestAppNoPrimaryNoController());
      await tester.pump();

      _simulateOnScroll(400);
      await tester.pump();

      final Finder listFinder = find.byType(ListView);
      final ScrollableState scrollable = tester.state(
        find.descendant(of: listFinder, matching: find.byType(Scrollable)),
      );
      expect(scrollable.position.pixels, closeTo(400.0, 1.0));
    });
  });

  group('BrowserScrollable – OverscrollNotification edge passthrough', () {
    late ScrollController controller;

    setUp(() {
      controller = ScrollController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('consumes OverscrollNotification when not at edge', (tester) async {
      final leaked = <OverscrollNotification>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: NotificationListener<OverscrollNotification>(
              onNotification: (OverscrollNotification n) {
                leaked.add(n);
                return false;
              },
              child: BrowserScrollable(
                child: ListView.builder(
                  controller: controller,
                  itemCount: 20,
                  itemBuilder: (context, index) =>
                      SizedBox(height: 200.0, child: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      _simulateOnScroll(500);
      await tester.pump();

      leaked.clear();
      _clearCalls();

      final ScrollPosition pos = controller.position;
      OverscrollNotification(
        overscroll: 50.0,
        metrics: pos.copyWith(),
        context: tester.element(find.byType(ListView)),
      ).dispatch(tester.element(find.byType(ListView)));
      await tester.pump();

      expect(leaked, isEmpty);
      expect(_callsOf('browserScrollBy'), isNotEmpty);
    });

    testWidgets('lets OverscrollNotification bubble at top edge', (tester) async {
      final leaked = <OverscrollNotification>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: NotificationListener<OverscrollNotification>(
              onNotification: (OverscrollNotification n) {
                leaked.add(n);
                return false;
              },
              child: BrowserScrollable(
                child: ListView.builder(
                  controller: controller,
                  itemCount: 20,
                  itemBuilder: (context, index) =>
                      SizedBox(height: 200.0, child: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      _simulateOnScroll(0);
      await tester.pump();

      leaked.clear();
      _clearCalls();

      final ScrollPosition pos = controller.position;
      OverscrollNotification(
        overscroll: -30.0,
        metrics: pos.copyWith(),
        context: tester.element(find.byType(ListView)),
      ).dispatch(tester.element(find.byType(ListView)));
      await tester.pump();

      expect(leaked, hasLength(1));
      expect(leaked.first.overscroll, -30.0);
      expect(_callsOf('browserScrollBy'), isEmpty);
    });

    testWidgets('lets OverscrollNotification bubble at bottom edge', (tester) async {
      final leaked = <OverscrollNotification>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: NotificationListener<OverscrollNotification>(
              onNotification: (OverscrollNotification n) {
                leaked.add(n);
                return false;
              },
              child: BrowserScrollable(
                child: ListView.builder(
                  controller: controller,
                  itemCount: 20,
                  itemBuilder: (context, index) =>
                      SizedBox(height: 200.0, child: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final double maxExtent = controller.position.maxScrollExtent;
      _simulateOnScroll(maxExtent);
      await tester.pump();

      leaked.clear();
      _clearCalls();

      final ScrollPosition pos = controller.position;
      OverscrollNotification(
        overscroll: 40.0,
        metrics: pos.copyWith(),
        context: tester.element(find.byType(ListView)),
      ).dispatch(tester.element(find.byType(ListView)));
      await tester.pump();

      expect(leaked, hasLength(1));
      expect(leaked.first.overscroll, 40.0);
      expect(_callsOf('browserScrollBy'), isEmpty);
    });

    testWidgets('forwards overscroll just inside the bottom edge', (tester) async {
      // Regression: the edge-guard uses `>=`, so a fractional gap below the
      // maxScrollExtent must NOT count as "at edge". An overscroll with
      // pixels = maxExtent - 0.01 and positive delta should forward to the
      // browser rather than bubble for RefreshIndicator-style handlers.
      // A tight 0.01 gap also catches refactors that fuzz the edge check
      // with an epsilon larger than 0.01.
      final leaked = <OverscrollNotification>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: NotificationListener<OverscrollNotification>(
              onNotification: (OverscrollNotification n) {
                leaked.add(n);
                return false;
              },
              child: BrowserScrollable(
                child: ListView.builder(
                  controller: controller,
                  itemCount: 20,
                  itemBuilder: (context, index) =>
                      SizedBox(height: 200.0, child: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final double maxExtent = controller.position.maxScrollExtent;
      _simulateOnScroll(maxExtent - 0.01);
      await tester.pump();

      leaked.clear();
      _clearCalls();

      final ScrollPosition pos = controller.position;
      OverscrollNotification(
        overscroll: 40.0,
        metrics: pos.copyWith(pixels: maxExtent - 0.01),
        context: tester.element(find.byType(ListView)),
      ).dispatch(tester.element(find.byType(ListView)));
      await tester.pump();

      // Not at the exact edge, so BrowserScrollable should forward.
      expect(leaked, isEmpty);
      expect(_callsOf('browserScrollBy'), isNotEmpty);
    });
  });

  group('ScrollableState browser-scroll – programmatic scrolling', () {
    late ScrollController controller;

    setUp(() {
      controller = ScrollController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('jumpTo delegates to browser and does not move pixels directly', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _clearCalls();

      controller.jumpTo(500);
      await tester.pump();

      // pixels stays at 0 until the browser fires onBrowserScroll back
      expect(controller.position.pixels, closeTo(0.0, 1.0));

      final List<Map<String, Object?>> scrollToCalls = _callsOf('browserScrollTo');
      expect(scrollToCalls, isNotEmpty);
      expect(scrollToCalls.last['args']! as double, closeTo(500.0, 1.0));

      // simulate the browser responding, which syncs pixels
      _simulateOnScroll(500);
      await tester.pump();
      expect(controller.position.pixels, closeTo(500.0, 1.0));
    });

    testWidgets('jumpTo delegates to browser and does not move pixels directly – via controller', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _clearCalls();

      // jumpTo on the outermost BrowserScrollPhysics scrollable must delegate
      // to the browser rather than moving pixels in Dart directly.
      controller.jumpTo(300);
      await tester.pump();

      // pixels does not change until the browser fires onBrowserScroll back.
      expect(controller.position.pixels, closeTo(0.0, 1.0));

      final List<Map<String, Object?>> scrollToCalls = _callsOf('browserScrollTo');
      expect(scrollToCalls, isNotEmpty);
      expect(scrollToCalls.last['args']! as double, closeTo(300.0, 1.0));

      // simulate the browser responding, which syncs pixels
      _simulateOnScroll(300);
      await tester.pump();
      expect(controller.position.pixels, closeTo(300.0, 1.0));
    });

    testWidgets('animateTo delegates to browser smooth scroll', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _clearCalls();

      controller.animateTo(400, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));

      // pixels stays at 0 until the browser fires onBrowserScroll back
      expect(controller.position.pixels, closeTo(0.0, 1.0));

      final List<Map<String, Object?>> smoothCalls = _callsOf('browserSmoothScrollTo');
      expect(smoothCalls, isNotEmpty);
      expect(smoothCalls.last['args']! as double, closeTo(400.0, 1.0));
    });

    testWidgets('animateTo Future resolves when browser reaches target', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _clearCalls();

      var completed = false;
      final Future<void> done = controller
          .animateTo(400, duration: const Duration(milliseconds: 200), curve: Curves.easeOut)
          .whenComplete(() => completed = true);

      await tester.pump();
      // Before the browser reports back, the Future must NOT be complete. It
      // is important that `await animateTo(...)` reflects scroll settle, not
      // the dispatch of the scroll command.
      expect(completed, isFalse);
      expect(controller.position.pixels, closeTo(0.0, 1.0));

      // Simulate the browser's smooth-scroll settling at the target.
      _simulateOnScroll(400);
      await tester.pump();
      await done;

      expect(completed, isTrue);
      expect(controller.position.pixels, closeTo(400.0, 1.0));
    });

    testWidgets('animateTo Future resolves when jumpTo supersedes it', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _clearCalls();

      var animateCompleted = false;
      final Future<void> done = controller
          .animateTo(1000, duration: const Duration(milliseconds: 300), curve: Curves.easeOut)
          .whenComplete(() => animateCompleted = true);

      await tester.pump();
      expect(animateCompleted, isFalse);

      // A jumpTo before the browser settles must supersede the pending
      // animation and complete its Future.
      controller.jumpTo(200);
      await tester.pump();
      await done;

      expect(animateCompleted, isTrue);
    });

    testWidgets('animateTo Future resolves when a later animateTo supersedes it', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      _clearCalls();

      var firstCompleted = false;
      final Future<void> firstDone = controller
          .animateTo(1000, duration: const Duration(milliseconds: 300), curve: Curves.easeOut)
          .whenComplete(() => firstCompleted = true);

      await tester.pump();
      expect(firstCompleted, isFalse);

      // A second animateTo replaces the first; the first Future must resolve
      // so awaiting code doesn't hang.
      controller.animateTo(600, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      await tester.pump();
      await firstDone;

      expect(firstCompleted, isTrue);
    });

    testWidgets('animateTo to current pixels resolves immediately', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      // Sync pixels to a known value.
      _simulateOnScroll(150);
      await tester.pump();
      expect(controller.position.pixels, closeTo(150.0, 1.0));

      _clearCalls();

      // Asking to animate to where we already are should return a resolved
      // future without dispatching a smooth scroll.
      await controller.animateTo(
        150,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );

      expect(_callsOf('browserSmoothScrollTo'), isEmpty);
    });

    testWidgets('animateTo grows the placeholder to cover the target', (tester) async {
      // A long ListView so maxScrollExtent far exceeds the initial placeholder
      // height (which is 2 viewports before any scrolling has happened).
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: BrowserScrollable(
              child: ListView.builder(
                controller: controller,
                itemCount: 100,
                itemBuilder: (context, index) =>
                    SizedBox(height: 200.0, child: Text('Item $index')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final double viewport = controller.position.viewportDimension;
      final double maxExtent = controller.position.maxScrollExtent;
      final double target = maxExtent * 0.9; // well past the initial placeholder

      _clearCalls();

      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      await tester.pump();

      // The framework must have bumped the reported content height to cover
      // the target before dispatching browserSmoothScrollTo, otherwise the
      // browser would clamp the smooth scroll short.
      final List<double> heights = _callsOf(
        'updateBrowserScrollContentHeight',
      ).map((c) => c['args']! as double).toList();
      expect(heights, isNotEmpty);
      expect(heights.last, greaterThanOrEqualTo(target + viewport - 1.0));

      final List<Map<String, Object?>> smoothCalls = _callsOf('browserSmoothScrollTo');
      expect(smoothCalls, isNotEmpty);
      expect(smoothCalls.last['args']! as double, closeTo(target, 1.0));
    });

    testWidgets('animateTo past maxScrollExtent clamps placeholder growth', (tester) async {
      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();

      final double viewport = controller.position.viewportDimension;
      final double maxExtent = controller.position.maxScrollExtent;

      _clearCalls();

      // Ask to go far past the real content end.
      controller.animateTo(
        maxExtent * 10,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      await tester.pump();

      final List<double> heights = _callsOf(
        'updateBrowserScrollContentHeight',
      ).map((c) => c['args']! as double).toList();
      if (heights.isNotEmpty) {
        // Placeholder never grows past maxScrollExtent + viewport; we must
        // not promise more scroll area than Flutter can paint.
        expect(heights.last, lessThanOrEqualTo(maxExtent + viewport + 1.0));
      }
    });

    testWidgets('jumpTo grows the placeholder to cover the target', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: BrowserScrollable(
              child: ListView.builder(
                controller: controller,
                itemCount: 100,
                itemBuilder: (context, index) =>
                    SizedBox(height: 200.0, child: Text('Item $index')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final double viewport = controller.position.viewportDimension;
      final double maxExtent = controller.position.maxScrollExtent;
      final double target = maxExtent * 0.9;

      _clearCalls();

      controller.jumpTo(target);
      await tester.pump();

      final List<double> heights = _callsOf(
        'updateBrowserScrollContentHeight',
      ).map((c) => c['args']! as double).toList();
      expect(heights, isNotEmpty);
      expect(heights.last, greaterThanOrEqualTo(target + viewport - 1.0));
    });

    testWidgets('ensureVisible triggers scroll', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: BrowserScrollable(
              child: ListView.builder(
                controller: controller,
                itemCount: 50,
                itemBuilder: (context, index) => SizedBox(
                  height: 200.0,
                  key: index == 40 ? const Key('target') : null,
                  child: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      _simulateOnScroll(2000);
      await tester.pump();

      _clearCalls();

      final Finder target = find.byKey(const Key('target'));
      if (target.evaluate().isNotEmpty) {
        await Scrollable.ensureVisible(target.evaluate().first);
        await tester.pump();

        expect(controller.position.pixels, greaterThan(0));
        expect(_callsOf('browserScrollTo'), isNotEmpty);
      }
    });

    testWidgets('focus traversal triggers scroll for offscreen widget', (tester) async {
      final List<FocusNode> focusNodes = List.generate(30, (_) => FocusNode());
      addTearDown(() {
        for (final node in focusNodes) {
          node.dispose();
        }
      });

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) => BrowserScrollable(
            child: ListView.builder(
              controller: controller,
              itemCount: 30,
              itemBuilder: (context, index) => Focus(
                focusNode: focusNodes[index],
                child: SizedBox(height: 200.0, child: Text('Button $index')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      focusNodes[0].requestFocus();
      await tester.pump();

      _clearCalls();

      for (var i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }

      // Focus traversal delegates programmatic scroll to the browser via jumpTo.
      // pixels stays at 0 until onBrowserScroll fires; the browser call is the
      // observable effect.
      expect(
        _callsOf('browserScrollTo'),
        isNotEmpty,
        reason: 'Focus traversal to offscreen widget should send browserScrollTo to engine',
      );
    });
  });

  group('ScrollableState browser-scroll – nested scrollable isolation', () {
    late ScrollController outerController;

    setUp(() {
      outerController = ScrollController();
    });

    tearDown(() {
      outerController.dispose();
    });

    testWidgets('only the outermost scrollable owns the binding', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: BrowserScrollable(
              child: ListView(
                controller: outerController,
                children: [
                  const SizedBox(height: 100),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: 50,
                      itemBuilder: (context, index) =>
                          SizedBox(height: 40, child: Text('Inner $index')),
                    ),
                  ),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      _clearCalls();

      outerController.jumpTo(200);
      await tester.pump();

      // jumpTo on the outermost scrollable delegates to the browser and does
      // not move pixels directly; pixels updates when onBrowserScroll fires.
      final List<Map<String, Object?>> scrollToCalls = _callsOf('browserScrollTo');
      expect(scrollToCalls, isNotEmpty);
      expect(scrollToCalls.last['args']! as double, closeTo(200.0, 1.0));

      _simulateOnScroll(200);
      await tester.pump();
      expect(outerController.position.pixels, closeTo(200.0, 1.0));
    });

    testWidgets('inner scrollable at boundary forwards delta to engine via browserScrollBy', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: BrowserScrollable(
              child: ListView(
                controller: outerController,
                children: [
                  const SizedBox(height: 100),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: 50,
                      itemBuilder: (context, index) =>
                          SizedBox(height: 40, child: Text('Inner $index')),
                    ),
                  ),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final Finder innerListFinder = find.byType(Scrollable).at(1);
      final ScrollableState innerScrollable = tester.state(innerListFinder);
      final ScrollPosition innerPos = innerScrollable.position;

      // Scroll the inner list to its bottom boundary.
      innerPos.jumpTo(innerPos.maxScrollExtent);
      await tester.pump();

      _clearCalls();

      // Drag the inner list past its bottom boundary.
      // applyUserOffset detects wasAtMax and calls browserScrollBy.
      await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -60));
      await tester.pump();

      final List<Map<String, Object?>> scrollByCalls = _callsOf('browserScrollBy');
      expect(
        scrollByCalls,
        isNotEmpty,
        reason: 'Inner scrollable at bottom boundary should forward delta to engine',
      );
    });

    testWidgets('scrollable without BrowserScrollable binding scrolls normally in Dart', (
      tester,
    ) async {
      // Build a plain scrollable with NO BrowserScrollable wrapper.
      // applyUserOffset should take the "no browser binding" path and move
      // pixels directly in Dart.
      final controller2 = ScrollController();
      addTearDown(controller2.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: ListView.builder(
              controller: controller2,
              itemCount: 20,
              itemBuilder: (context, index) => SizedBox(height: 200.0, child: Text('Item $index')),
            ),
          ),
        ),
      );
      await tester.pump();

      // No browser binding should be set.
      expect(ScrollableState.browserScrollViewBinding, isNull);

      // A drag should move pixels directly via normal Dart physics.
      await tester.drag(find.byType(Scrollable), const Offset(0, -300));
      await tester.pump();

      expect(controller2.position.pixels, greaterThan(0.0));
    });

    testWidgets('inner scrollable scrolls independently without BrowserScrollPhysics', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: BrowserScrollable(
              child: ListView(
                controller: outerController,
                children: [
                  const SizedBox(height: 100),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: 50,
                      itemBuilder: (context, index) =>
                          SizedBox(height: 40, child: Text('Inner $index')),
                    ),
                  ),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final Finder innerListFinder = find.byType(Scrollable).at(1);
      final ScrollableState innerScrollable = tester.state(innerListFinder);
      final ScrollPosition innerPos = innerScrollable.position;

      expect(innerPos.pixels, 0.0);

      innerPos.jumpTo(100);
      await tester.pump();

      expect(innerPos.pixels, closeTo(100.0, 1.0));
    });
  });

  group('ScrollableState browser-scroll – slot reclamation', () {
    testWidgets('second BrowserScrollable reclaims the slot when the first is disposed', (
      tester,
    ) async {
      // Two BrowserScrollables mounted simultaneously simulates the overlap
      // during a Navigator push: route A still mounted while route B mounts.
      // Only one owns the slot at a time; this test verifies the rejected
      // scrollable reclaims when the owner disposes.
      final firstController = ScrollController();
      addTearDown(firstController.dispose);
      final secondController = ScrollController();
      addTearDown(secondController.dispose);

      Widget buildStack({required bool includeFirst}) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Stack(
              children: <Widget>[
                if (includeFirst)
                  SizedBox(
                    height: 600,
                    child: BrowserScrollable(
                      child: ListView.builder(
                        controller: firstController,
                        itemCount: 20,
                        itemBuilder: (context, index) =>
                            SizedBox(height: 200.0, child: Text('A $index')),
                      ),
                    ),
                  ),
                SizedBox(
                  height: 600,
                  child: BrowserScrollable(
                    child: ListView.builder(
                      controller: secondController,
                      itemCount: 20,
                      itemBuilder: (context, index) =>
                          SizedBox(height: 200.0, child: Text('B $index')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      await tester.pumpWidget(buildStack(includeFirst: true));
      await tester.pump();

      // Before the first is disposed, the binding belongs to the first
      // scrollable. Drive it via its controller and see the browser path fire.
      _clearCalls();
      firstController.jumpTo(150);
      await tester.pump();
      expect(
        _callsOf('browserScrollTo'),
        isNotEmpty,
        reason: 'First scrollable owns the slot and should delegate to the browser',
      );

      // Second scrollable is rejected: driving it does NOT hit the browser
      // path because it never claimed the binding.
      _clearCalls();
      secondController.jumpTo(150);
      await tester.pump();
      expect(
        _callsOf('browserScrollTo'),
        isEmpty,
        reason: 'Second scrollable was rejected and must not drive the shared binding',
      );

      // Dispose the first scrollable. The second should reclaim.
      await tester.pumpWidget(buildStack(includeFirst: false));
      await tester.pump();

      _clearCalls();
      secondController.jumpTo(200);
      await tester.pump();
      expect(
        _callsOf('browserScrollTo'),
        isNotEmpty,
        reason:
            'After the first scrollable disposes, the second must reclaim '
            'the slot and delegate to the browser. Otherwise Navigator '
            'push leaves the top route stuck on Dart-driven physics.',
      );
    });
  });

  group('ScrollableState browser-scroll – wheel events', () {
    late ScrollController controller;

    setUp(() {
      controller = ScrollController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets(
      'wheel on outer BrowserScrollable does not move pixels and allows browser default',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(controller));
        await tester.pump();

        _clearCalls();

        final respondCalls = <bool>[];
        final Offset location = tester.getCenter(find.byType(ListView));
        final testPointer = TestPointer(1, PointerDeviceKind.mouse);
        testPointer.hover(location);

        final event = PointerScrollEvent(
          position: location,
          scrollDelta: const Offset(0.0, 100.0),
          onRespond: ({required bool allowPlatformDefault}) {
            respondCalls.add(allowPlatformDefault);
          },
        );

        await tester.sendEventToBinding(event);
        await tester.pump();

        // Pixels must not move: the framework declined to handle the wheel
        // because BrowserScrollPhysics is active; the browser owns this
        // wheel event.
        expect(controller.position.pixels, 0.0);

        // The resolver auto-responds true when no widget registers. This is
        // the signal the engine watches to decide whether to preventDefault.
        expect(
          respondCalls,
          equals(<bool>[true]),
          reason:
              'Outer BrowserScrollPhysics declined the wheel event. '
              'PointerSignalResolver should auto-respond allowPlatformDefault=true '
              'so the web engine skips preventDefault and lets the browser '
              'scroll <flutter-view> natively.',
        );

        // The framework did not push a programmatic scroll to the engine.
        expect(_callsOf('browserScrollTo'), isEmpty);
        expect(_callsOf('browserSmoothScrollTo'), isEmpty);
      },
    );

    testWidgets('wheel on nested inner Scrollable moves the inner, not the outer', (tester) async {
      final innerController = ScrollController();
      addTearDown(innerController.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: BrowserScrollable(
              child: ListView(
                controller: controller,
                children: <Widget>[
                  SizedBox(
                    height: 400.0,
                    child: ListView.builder(
                      key: const Key('inner'),
                      controller: innerController,
                      itemCount: 30,
                      itemBuilder: (context, index) =>
                          SizedBox(height: 50.0, child: Text('Inner $index')),
                    ),
                  ),
                  const SizedBox(height: 2000.0, child: Text('Outer tail')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      _clearCalls();

      final respondCalls = <bool>[];
      final Offset location = tester.getCenter(find.byKey(const Key('inner')));
      final testPointer = TestPointer(1, PointerDeviceKind.mouse);
      testPointer.hover(location);

      final event = PointerScrollEvent(
        position: location,
        scrollDelta: const Offset(0.0, 80.0),
        onRespond: ({required bool allowPlatformDefault}) {
          respondCalls.add(allowPlatformDefault);
        },
      );

      await tester.sendEventToBinding(event);
      await tester.pump();

      // Inner scrollable handled the wheel.
      expect(innerController.offset, closeTo(80.0, 1.0));
      expect(controller.position.pixels, 0.0);

      // Inner called respond(allowPlatformDefault=false) so the engine will
      // preventDefault and the browser won't also scroll <flutter-view>.
      expect(respondCalls, equals(<bool>[false]));
    });
  });
}
