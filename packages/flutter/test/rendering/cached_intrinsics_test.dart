// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

class RenderTestBox extends RenderBox {
  late Size boxSize;
  int calls = 0;
  double value = 0.0;
  double next() {
    value += 1.0;
    return value;
  }

  @override
  double computeMinIntrinsicWidth(double height) => next();
  @override
  double computeMaxIntrinsicWidth(double height) => next();
  @override
  double computeMinIntrinsicHeight(double width) => next();
  @override
  double computeMaxIntrinsicHeight(double width) => next();

  @override
  void performLayout() {
    size = constraints.biggest;
    boxSize = size;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    if (!RenderObject.debugCheckingIntrinsics) {
      calls += 1;
    }
    return boxSize.height / 2.0;
  }
}

class RenderDryBaselineTestBox extends RenderTestBox {
  double? baselineOverride;

  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    if (!RenderObject.debugCheckingIntrinsics) {
      calls += 1;
    }
    return baselineOverride ?? constraints.biggest.height / 2.0;
  }
}

class RenderBadDryBaselineTestBox extends RenderTestBox {
  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    return size.height / 2.0;
  }
}

class RenderCountingDryLayoutTestBox extends RenderBox {
  int dryLayoutCalls = 0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    dryLayoutCalls += 1;
    return constraints.smallest;
  }

  @override
  void performLayout() {
    size = constraints.smallest;
  }
}

class RenderCountingDryBaselineTestBox extends RenderBox {
  int dryBaselineCalls = 0;

  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    dryBaselineCalls += 1;
    return constraints.biggest.height;
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }
}

class RenderCannotComputeDryBaselineTestBox extends RenderTestBox {
  bool shouldAssert = true;
  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    if (shouldAssert) {
      assert(debugCannotComputeDryLayout(reason: 'no dry baseline for you'));
    }
    return null;
  }
}

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('Intrinsics cache', () {
    final RenderBox test = RenderTestBox();

    expect(test.getMinIntrinsicWidth(0.0), equals(1.0));
    expect(test.getMinIntrinsicWidth(100.0), equals(2.0));
    expect(test.getMinIntrinsicWidth(200.0), equals(3.0));
    expect(test.getMinIntrinsicWidth(0.0), equals(1.0));
    expect(test.getMinIntrinsicWidth(100.0), equals(2.0));
    expect(test.getMinIntrinsicWidth(200.0), equals(3.0));

    expect(test.getMaxIntrinsicWidth(0.0), equals(4.0));
    expect(test.getMaxIntrinsicWidth(100.0), equals(5.0));
    expect(test.getMaxIntrinsicWidth(200.0), equals(6.0));
    expect(test.getMaxIntrinsicWidth(0.0), equals(4.0));
    expect(test.getMaxIntrinsicWidth(100.0), equals(5.0));
    expect(test.getMaxIntrinsicWidth(200.0), equals(6.0));

    expect(test.getMinIntrinsicHeight(0.0), equals(7.0));
    expect(test.getMinIntrinsicHeight(100.0), equals(8.0));
    expect(test.getMinIntrinsicHeight(200.0), equals(9.0));
    expect(test.getMinIntrinsicHeight(0.0), equals(7.0));
    expect(test.getMinIntrinsicHeight(100.0), equals(8.0));
    expect(test.getMinIntrinsicHeight(200.0), equals(9.0));

    expect(test.getMaxIntrinsicHeight(0.0), equals(10.0));
    expect(test.getMaxIntrinsicHeight(100.0), equals(11.0));
    expect(test.getMaxIntrinsicHeight(200.0), equals(12.0));
    expect(test.getMaxIntrinsicHeight(0.0), equals(10.0));
    expect(test.getMaxIntrinsicHeight(100.0), equals(11.0));
    expect(test.getMaxIntrinsicHeight(200.0), equals(12.0));

    // now read them all again backwards
    expect(test.getMaxIntrinsicHeight(200.0), equals(12.0));
    expect(test.getMaxIntrinsicHeight(100.0), equals(11.0));
    expect(test.getMaxIntrinsicHeight(0.0), equals(10.0));
    expect(test.getMinIntrinsicHeight(200.0), equals(9.0));
    expect(test.getMinIntrinsicHeight(100.0), equals(8.0));
    expect(test.getMinIntrinsicHeight(0.0), equals(7.0));
    expect(test.getMaxIntrinsicWidth(200.0), equals(6.0));
    expect(test.getMaxIntrinsicWidth(100.0), equals(5.0));
    expect(test.getMaxIntrinsicWidth(0.0), equals(4.0));
    expect(test.getMinIntrinsicWidth(200.0), equals(3.0));
    expect(test.getMinIntrinsicWidth(100.0), equals(2.0));
    expect(test.getMinIntrinsicWidth(0.0), equals(1.0));
  });

  group('Bounded layout caches', () {
    // Regression tests for https://github.com/flutter/flutter/issues/193075:
    // RenderBox's dry-layout/intrinsics memoization caches must not grow
    // without bound, since nothing clears them just because a parent asks
    // for the same computation with a series of different inputs (e.g. an
    // InputDecorator computing a dry layout every time its incoming
    // constraints change, such as while its ancestor is being resized).

    // These tests deliberately avoid hard-coding the cache's exact bound:
    // they only assert that (a) a realistic, moderate number of distinct
    // queries within one pass all stay cached (so the bound doesn't
    // regress to being too tight and defeat legitimate reuse), and (b) a
    // sustained stream of never-before-seen inputs - as happens when an
    // ancestor keeps resizing across many layout passes - eventually
    // evicts the earliest entries rather than growing forever.
    const int comfortableDistinctQueries = 50;
    const int guaranteedEvictionQueries = 5000;

    test('Cached intrinsics are evicted once enough distinct inputs accumulate', () {
      final RenderTestBox test = RenderTestBox();

      final List<double> comfortableResults = <double>[
        for (int i = 0; i < comfortableDistinctQueries; i += 1) test.getMinIntrinsicWidth(i.toDouble()),
      ];
      // All of them are still cached: querying them again does not advance
      // the underlying counter, i.e. computeMinIntrinsicWidth is not re-run.
      for (int i = 0; i < comfortableDistinctQueries; i += 1) {
        expect(test.getMinIntrinsicWidth(i.toDouble()), comfortableResults[i]);
      }

      for (int i = comfortableDistinctQueries; i < guaranteedEvictionQueries; i += 1) {
        test.getMinIntrinsicWidth(i.toDouble());
      }
      final double valueBeforeRequery = test.value;
      // The very first input queried must have been evicted by now, so this
      // recomputes (and advances the counter) rather than returning the
      // stale cached result from an unbounded cache.
      test.getMinIntrinsicWidth(0.0);
      expect(test.value, greaterThan(valueBeforeRequery));
    });

    test('Cached dry layout sizes are evicted once enough distinct inputs accumulate', () {
      final test = RenderCountingDryLayoutTestBox();
      BoxConstraints constraintsFor(int i) =>
          BoxConstraints(minWidth: i.toDouble(), maxWidth: i.toDouble(), minHeight: i.toDouble(), maxHeight: i.toDouble());

      for (int i = 0; i < comfortableDistinctQueries; i += 1) {
        test.getDryLayout(constraintsFor(i));
      }
      expect(test.dryLayoutCalls, comfortableDistinctQueries);

      // Still all cached: repeat queries don't recompute.
      for (int i = 0; i < comfortableDistinctQueries; i += 1) {
        test.getDryLayout(constraintsFor(i));
      }
      expect(test.dryLayoutCalls, comfortableDistinctQueries);

      for (int i = comfortableDistinctQueries; i < guaranteedEvictionQueries; i += 1) {
        test.getDryLayout(constraintsFor(i));
      }
      final int callsBeforeRequery = test.dryLayoutCalls;
      // The first constraints queried must have been evicted by now, so
      // this recomputes. Before the fix, this cache was never bounded, so
      // it would still have been served from the (ever-growing) cache.
      test.getDryLayout(constraintsFor(0));
      expect(test.dryLayoutCalls, greaterThan(callsBeforeRequery));
    });

    test('Cached dry baselines are evicted once enough distinct inputs accumulate', () {
      final test = RenderCountingDryBaselineTestBox();
      const TextBaseline baseline = TextBaseline.alphabetic;
      BoxConstraints constraintsFor(int i) => BoxConstraints(minHeight: i.toDouble(), maxHeight: i.toDouble());

      for (int i = 0; i < comfortableDistinctQueries; i += 1) {
        test.getDryBaseline(constraintsFor(i), baseline);
      }
      // getDryBaseline always additionally invokes computeDryBaseline once
      // in an assert (to catch debugCannotComputeDryLayout misuse), on top
      // of the memoized call, so a miss bumps the counter by 2.
      expect(test.dryBaselineCalls, comfortableDistinctQueries * 2);

      for (int i = 0; i < comfortableDistinctQueries; i += 1) {
        test.getDryBaseline(constraintsFor(i), baseline);
      }
      // Still all cached: a repeat query only pays for the debug-mode
      // consistency check (+1), not a real recomputation (+2).
      expect(test.dryBaselineCalls, comfortableDistinctQueries * 3);

      for (int i = comfortableDistinctQueries; i < guaranteedEvictionQueries; i += 1) {
        test.getDryBaseline(constraintsFor(i), baseline);
      }
      final int callsBeforeRequery = test.dryBaselineCalls;
      // The first constraints queried must have been evicted by now, so
      // this recomputes: a +2 jump, not the +1 an unbounded cache's mere
      // debug-consistency-check hit would produce.
      test.getDryBaseline(constraintsFor(0), baseline);
      expect(test.dryBaselineCalls, callsBeforeRequery + 2);
    });
  });

  // Regression test for https://github.com/flutter/flutter/issues/101179
  test('Cached baselines should be cleared if its parent re-layout', () {
    var viewHeight = 200.0;
    final test = RenderTestBox();
    final RenderBox baseline = RenderBaseline(
      baseline: 0.0,
      baselineType: TextBaseline.alphabetic,
      child: test,
    );
    final root = RenderConstrainedBox(
      additionalConstraints: BoxConstraints.tightFor(width: 200.0, height: viewHeight),
      child: baseline,
    );

    layout(RenderPositionedBox(child: root));

    var parentData = test.parentData as BoxParentData?;
    expect(parentData!.offset.dy, -(viewHeight / 2.0));
    expect(test.calls, 1);

    // Trigger the root render re-layout.
    viewHeight = 300.0;
    root.additionalConstraints = BoxConstraints.tightFor(width: 200.0, height: viewHeight);
    pumpFrame();

    parentData = test.parentData as BoxParentData?;
    expect(parentData!.offset.dy, -(viewHeight / 2.0));
    expect(test.calls, 2); // The layout constraints change will clear the cached data.

    final RenderObject parent = test.parent!;
    expect(parent.debugNeedsLayout, false);

    // Do not forget notify parent dirty after the cached data be cleared by `layout()`
    test.markNeedsLayout();
    expect(parent.debugNeedsLayout, true);

    pumpFrame();
    expect(parent.debugNeedsLayout, false);
    expect(test.calls, 3); // Self dirty will clear the cached data.

    parent.markNeedsLayout();
    pumpFrame();

    expect(test.calls, 3); // Use the cached data if the layout constraints do not change.
  });

  group('Dry baseline', () {
    test(
      'computeDryBaseline results are cached and shared with computeDistanceToActualBaseline',
      () {
        const viewHeight = 200.0;
        const constraints = BoxConstraints.tightFor(width: 200.0, height: viewHeight);
        final test = RenderDryBaselineTestBox();
        final RenderBox baseline = RenderBaseline(
          baseline: 0.0,
          baselineType: TextBaseline.alphabetic,
          child: test,
        );

        final root = RenderConstrainedBox(additionalConstraints: constraints, child: baseline);

        layout(RenderPositionedBox(child: root));
        expect(test.calls, 1);

        // The baseline widget loosens the input constraints when passing on to child.
        expect(
          test.getDryBaseline(constraints.loosen(), TextBaseline.alphabetic),
          test.boxSize.height / 2,
        );
        // There's cache for the constraints so this should be 1, but we always evaluate
        // computeDryBaseline in debug mode in case it asserts even if the baseline
        // cache hits.
        expect(test.calls, 2);

        const newConstraints = BoxConstraints.tightFor(width: 10.0, height: 10.0);
        expect(test.getDryBaseline(newConstraints.loosen(), TextBaseline.alphabetic), 5.0);
        // Should be 3 but there's an additional computeDryBaseline call in getDryBaseline,
        // in an assert.
        expect(test.calls, 4);

        root.additionalConstraints = newConstraints;
        pumpFrame();
        expect(test.calls, 4);
      },
    );

    test('Asserts when a RenderBox cannot compute dry baseline', () {
      final test = RenderCannotComputeDryBaselineTestBox();
      layout(RenderBaseline(baseline: 0.0, baselineType: TextBaseline.alphabetic, child: test));

      final BoxConstraints incomingConstraints = test.constraints;
      assert(incomingConstraints != const BoxConstraints());
      expect(
        () => test.getDryBaseline(const BoxConstraints(), TextBaseline.alphabetic),
        throwsA(
          isA<AssertionError>().having(
            (AssertionError e) => e.message,
            'message',
            contains('no dry baseline for you'),
          ),
        ),
      );

      // Still throws when there is cache.
      expect(
        () => test.getDryBaseline(incomingConstraints, TextBaseline.alphabetic),
        throwsA(
          isA<AssertionError>().having(
            (AssertionError e) => e.message,
            'message',
            contains('no dry baseline for you'),
          ),
        ),
      );
    });

    test(
      'Catches inconsistencies between computeDryBaseline and computeDistanceToActualBaseline',
      () {
        final test = RenderDryBaselineTestBox();
        layout(test, phase: EnginePhase.composite);

        FlutterErrorDetails? error;
        test.markNeedsLayout();
        test.baselineOverride = 123;
        pumpFrame(
          phase: EnginePhase.composite,
          onErrors: () {
            error = TestRenderingFlutterBinding.instance.takeFlutterErrorDetails();
          },
        );

        expect(
          error?.exceptionAsString(),
          contains('differs from the baseline location computed by computeDryBaseline'),
        );
      },
    );

    test('Accessing RenderBox.size in computeDryBaseline is not allowed', () {
      final test = RenderBadDryBaselineTestBox();
      FlutterErrorDetails? error;
      layout(
        test,
        phase: EnginePhase.composite,
        onErrors: () {
          error = TestRenderingFlutterBinding.instance.takeFlutterErrorDetails();
        },
      );

      expect(
        error?.exceptionAsString(),
        contains('RenderBox.size accessed in RenderBadDryBaselineTestBox.computeDryBaseline.'),
      );
    });

    test('debug baseline checks do not freak out when debugCannotComputeDryLayout is called', () {
      FlutterErrorDetails? error;
      void onErrors() {
        error = TestRenderingFlutterBinding.instance.takeFlutterErrorDetails();
      }

      final test = RenderCannotComputeDryBaselineTestBox();
      layout(test, phase: EnginePhase.composite, onErrors: onErrors);
      expect(error, isNull);

      test.shouldAssert = false;
      test.markNeedsLayout();
      pumpFrame(phase: EnginePhase.composite, onErrors: onErrors);
      expect(
        error?.exceptionAsString(),
        contains('differs from the baseline location computed by computeDryBaseline'),
      );
    });
  });
}
