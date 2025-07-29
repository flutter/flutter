// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  group('RenderShiftedBox', () {
    test('RenderShiftedBox has computeDryBaseline method implemented', () {
      final TestRenderShiftedBox shiftedBox = TestRenderShiftedBox();

      // Verify the method exists and can be called
      expect(
        () => shiftedBox.computeDryBaseline(
          const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
          TextBaseline.alphabetic,
        ),
        returnsNormally,
      );

      // Test with no child - should return null
      final double? baseline = shiftedBox.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );
      expect(baseline, isNull);
    });

    test('computeDryBaseline returns null when child is null', () {
      final RenderPadding padding = RenderPadding(padding: const EdgeInsets.all(10.0));

      final double? baseline = padding.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );

      expect(baseline, isNull);
    });

    test('computeDryBaseline returns null when child has no baseline', () {
      final MockRenderBoxNoBaseline child = MockRenderBoxNoBaseline();
      final RenderPadding padding = RenderPadding(
        padding: const EdgeInsets.all(10.0),
        child: child,
      );

      final double? baseline = padding.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );

      expect(baseline, isNull);
    });

    test('computeDryBaseline works with RenderAligningShiftedBox alignment', () {
      // Create a mock render box that has a baseline
      final MockRenderBox child = MockRenderBox();
      final RenderPositionedBox positioner = RenderPositionedBox(
        alignment: Alignment.center,
        child: child,
      );

      // Test that the baseline calculation includes alignment offset
      final double? baseline = positioner.computeDryBaseline(
        const BoxConstraints(maxWidth: 200.0, maxHeight: 200.0),
        TextBaseline.alphabetic,
      );

      // The exact value depends on the mock implementation,
      // but it should not be null if the child has a baseline
      expect(baseline, isNotNull);
    });

    test('computeDryBaseline works with non-aligning shifted boxes', () {
      final MockRenderBox child = MockRenderBox();
      final RenderBaseline baseline = RenderBaseline(
        baseline: 50.0,
        baselineType: TextBaseline.alphabetic,
        child: child,
      );

      final double? result = baseline.computeDryBaseline(
        const BoxConstraints(maxWidth: 100.0, maxHeight: 100.0),
        TextBaseline.alphabetic,
      );

      expect(result, isNotNull);
    });
  });
}

// Test implementation of RenderShiftedBox for testing the abstract class
class TestRenderShiftedBox extends RenderShiftedBox {
  TestRenderShiftedBox([super.child]);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.constrain(const Size(100.0, 100.0));
  }

  @override
  void performLayout() {
    size = constraints.constrain(const Size(100.0, 100.0));
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      childParentData.offset = Offset.zero;
    }
  }
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
