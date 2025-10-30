// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  group('RenderAligningShiftedBox', () {
    test('RenderAligningShiftedBox has computeDryBaseline method implemented', () {
      final RenderPositionedBox positionedBox = RenderPositionedBox();

      // Verify the method exists and can be called
      expect(
        () => positionedBox.computeDryBaseline(
          const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
          TextBaseline.alphabetic,
        ),
        returnsNormally,
      );

      // Test with no child - should return null
      final double? baseline = positionedBox.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );
      expect(baseline, isNull);
    });

    test('computeDryBaseline returns null when child is null', () {
      final RenderPositionedBox positioner = RenderPositionedBox(alignment: Alignment.topLeft);

      final double? baseline = positioner.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );

      expect(baseline, isNull);
    });

    test('computeDryBaseline returns null when child has no baseline', () {
      final MockRenderBoxNoBaseline child = MockRenderBoxNoBaseline();
      final RenderPositionedBox positioner = RenderPositionedBox(child: child);

      final double? baseline = positioner.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );

      expect(baseline, isNull);
    });

    test('computeDryBaseline works with center alignment', () {
      final MockRenderBox child = MockRenderBox();
      final RenderPositionedBox positioner = RenderPositionedBox(child: child);

      final double? baseline = positioner.computeDryBaseline(
        const BoxConstraints(maxWidth: 200.0, maxHeight: 200.0),
        TextBaseline.alphabetic,
      );

      // Should return child's baseline (40.0) plus the vertical offset from centering
      expect(baseline, isNotNull);
      expect(baseline! > 40.0, isTrue); // Should be greater than child's baseline due to centering
    });

    test('computeDryBaseline works with top-left alignment', () {
      final MockRenderBox child = MockRenderBox();
      final RenderPositionedBox positioner = RenderPositionedBox(
        alignment: Alignment.topLeft,
        child: child,
      );

      final double? baseline = positioner.computeDryBaseline(
        const BoxConstraints(maxWidth: 200.0, maxHeight: 200.0),
        TextBaseline.alphabetic,
      );

      // Should return exactly child's baseline (40.0) since no vertical offset with topLeft
      expect(baseline, equals(40.0));
    });

    test('computeDryBaseline works with bottom-right alignment', () {
      final MockRenderBox child = MockRenderBox();
      final RenderPositionedBox positioner = RenderPositionedBox(
        alignment: Alignment.bottomRight,
        child: child,
      );

      final double? baseline = positioner.computeDryBaseline(
        const BoxConstraints(maxWidth: 200.0, maxHeight: 200.0),
        TextBaseline.alphabetic,
      );

      // Should return child's baseline plus significant vertical offset from bottom alignment
      expect(baseline, isNotNull);
      expect(baseline! > 100.0, isTrue); // Should be much greater due to bottom alignment
    });

    test('computeDryBaseline with different TextBaseline types', () {
      final MockRenderBox child = MockRenderBox();
      final RenderPositionedBox positioner = RenderPositionedBox(
        alignment: Alignment.topLeft,
        child: child,
      );

      // Test alphabetic baseline
      final double? alphabeticBaseline = positioner.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );

      // Test ideographic baseline
      final double? ideographicBaseline = positioner.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.ideographic,
      );

      expect(alphabeticBaseline, isNotNull);
      expect(ideographicBaseline, isNotNull);
      // Both should return the same value since our mock returns 40.0 for both
      expect(alphabeticBaseline, equals(ideographicBaseline));
    });

    test('computeDryBaseline works with width and height factors', () {
      final MockRenderBox child = MockRenderBox();
      final RenderPositionedBox positioner = RenderPositionedBox(
        alignment: Alignment.topLeft,
        widthFactor: 2.0,
        heightFactor: 1.5,
        child: child,
      );

      final double? baseline = positioner.computeDryBaseline(
        const BoxConstraints(maxWidth: 200.0, maxHeight: 200.0),
        TextBaseline.alphabetic,
      );

      // Should return child's baseline since topLeft alignment
      expect(baseline, equals(40.0));
    });

    test('computeDryBaseline works with infinite constraints', () {
      final MockRenderBox child = MockRenderBox();
      final RenderPositionedBox positioner = RenderPositionedBox(
        alignment: Alignment.topLeft,
        child: child,
      );

      final double? baseline = positioner.computeDryBaseline(
        const BoxConstraints(),
        TextBaseline.alphabetic,
      );

      expect(baseline, equals(40.0));
    });
  });

  group('Other RenderShiftedBox classes', () {
    test('RenderConstrainedOverflowBox computeDryBaseline', () {
      final MockRenderBox child = MockRenderBox();
      final RenderConstrainedOverflowBox constrainedBox = RenderConstrainedOverflowBox(
        alignment: Alignment.topLeft,
        child: child,
      );

      final double? baseline = constrainedBox.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );

      expect(baseline, isNotNull);
    });

    test('RenderSizedOverflowBox computeDryBaseline', () {
      final MockRenderBox child = MockRenderBox();
      final RenderSizedOverflowBox sizedBox = RenderSizedOverflowBox(
        requestedSize: const Size(100.0, 100.0),
        alignment: Alignment.topLeft,
        child: child,
      );

      final double? baseline = sizedBox.computeDryBaseline(
        const BoxConstraints(maxWidth: 200.0, maxHeight: 200.0),
        TextBaseline.alphabetic,
      );

      expect(baseline, isNotNull);
    });

    test('RenderFractionallySizedOverflowBox computeDryBaseline', () {
      final MockRenderBox child = MockRenderBox();
      final RenderFractionallySizedOverflowBox fractionalBox = RenderFractionallySizedOverflowBox(
        alignment: Alignment.topLeft,
        widthFactor: 0.5,
        heightFactor: 0.5,
        child: child,
      );

      final double? baseline = fractionalBox.computeDryBaseline(
        const BoxConstraints(maxWidth: 200.0, maxHeight: 200.0),
        TextBaseline.alphabetic,
      );

      expect(baseline, isNotNull);
    });

    test('RenderPadding computeDryBaseline', () {
      final MockRenderBox child = MockRenderBox();
      final RenderPadding padding = RenderPadding(
        padding: const EdgeInsets.all(10.0),
        child: child,
      );

      final double? baseline = padding.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );

      expect(baseline, isNotNull);
    });

    test('RenderBaseline computeDryBaseline', () {
      final MockRenderBox child = MockRenderBox();
      final RenderBaseline baselineBox = RenderBaseline(
        baseline: 30.0,
        baselineType: TextBaseline.alphabetic,
        child: child,
      );

      final double? baseline = baselineBox.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );

      expect(baseline, isNotNull);
    });

    test('computeDryBaseline handles edge cases consistently', () {
      // Test with very small constraints
      final MockRenderBox child = MockRenderBox();
      final RenderPositionedBox positioner = RenderPositionedBox(child: child);

      final double? smallBaseline = positioner.computeDryBaseline(
        const BoxConstraints(maxWidth: 1.0, maxHeight: 1.0),
        TextBaseline.alphabetic,
      );

      expect(smallBaseline, isNotNull);

      // Test with zero constraints
      final double? zeroBaseline = positioner.computeDryBaseline(
        const BoxConstraints.tightFor(width: 0.0, height: 0.0),
        TextBaseline.alphabetic,
      );

      expect(zeroBaseline, isNotNull);
    });
  });
}

// Mock render box for testing
class MockRenderBox extends RenderBox {
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.constrain(const Size(50.0, 50.0));
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    return 40.0; // Mock baseline at 40 pixels from top
  }

  @override
  void performLayout() {
    size = constraints.constrain(const Size(50.0, 50.0));
  }
}

// Mock render box that has no baseline for testing
class MockRenderBoxNoBaseline extends RenderBox {
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.constrain(const Size(50.0, 50.0));
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    return null; // No baseline
  }

  @override
  void performLayout() {
    size = constraints.constrain(const Size(50.0, 50.0));
  }
}
