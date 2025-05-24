// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:material/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

typedef TraversalTestFunction = Future<void> Function(TraversalTester tester);
const Size tenByTen = Size(10.0, 10.0);

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  void testTraversal(String description, TraversalTestFunction testFunction) {
    testWidgets(description, (WidgetTester tester) async {
      final TraversalTester traversalTester = TraversalTester(tester);
      await testFunction(traversalTester);
      traversalTester.dispose();
    });
  }

  // ┌───┐ ┌───┐
  // │ A │>│ B │
  // └───┘ └───┘
  testTraversal('Semantics traverses horizontally left-to-right', (TraversalTester tester) async {
    await tester.test(
      textDirection: TextDirection.ltr,
      children: <String, Rect>{
        'A': Offset.zero & tenByTen,
        'B': const Offset(20.0, 0.0) & tenByTen,
      },
      expectedTraversal: 'A B',
    );
  });

  // ┌───┐ ┌───┐
  // │ A │<│ B │
  // └───┘ └───┘
  testTraversal('Semantics traverses horizontally right-to-left', (TraversalTester tester) async {
    await tester.test(
      textDirection: TextDirection.rtl,
      children: <String, Rect>{
        'A': Offset.zero & tenByTen,
        'B': const Offset(20.0, 0.0) & tenByTen,
      },
      expectedTraversal: 'B A',
    );
  });

  // ┌───┐
  // │ A │
  // └───┘
  //   V
  // ┌───┐
  // │ B │
  // └───┘
  testTraversal('Semantics traverses vertically top-to-bottom', (TraversalTester tester) async {
    for (final TextDirection textDirection in TextDirection.values) {
      await tester.test(
        textDirection: textDirection,
        children: <String, Rect>{
          'A': Offset.zero & tenByTen,
          'B': const Offset(0.0, 20.0) & tenByTen,
        },
        expectedTraversal: 'A B',
      );
    }
  });

  // ┌───┐ ┌───┐
  // │ A │>│ B │
  // └───┘ └───┘
  //   ┌─────┘
  //   V
  // ┌───┐ ┌───┐
  // │ C │>│ D │
  // └───┘ └───┘
  testTraversal('Semantics traverses a grid left-to-right', (TraversalTester tester) async {
    await tester.test(
      textDirection: TextDirection.ltr,
      children: <String, Rect>{
        'A': Offset.zero & tenByTen,
        'B': const Offset(20.0, 0.0) & tenByTen,
        'C': const Offset(0.0, 20.0) & tenByTen,
        'D': const Offset(20.0, 20.0) & tenByTen,
      },
      expectedTraversal: 'A B C D',
    );
  });

  // ┌───┐ ┌───┐
  // │ A │<│ B │
  // └───┘ └───┘
  //   └─────┐
  //         V
  // ┌───┐ ┌───┐
  // │ C │<│ D │
  // └───┘ └───┘
  testTraversal('Semantics traverses a grid right-to-left', (TraversalTester tester) async {
    await tester.test(
      textDirection: TextDirection.rtl,
      children: <String, Rect>{
        'A': Offset.zero & tenByTen,
        'B': const Offset(20.0, 0.0) & tenByTen,
        'C': const Offset(0.0, 20.0) & tenByTen,
        'D': const Offset(20.0, 20.0) & tenByTen,
      },
      expectedTraversal: 'B A D C',
    );
  });

  // ┌───┐           ┌───┐
  // │ A │           │ C │
  // └───┘<->┌───┐<->└───┘
  //         │ B │
  //         └───┘
  testTraversal('Semantics traverses vertically overlapping nodes horizontally', (
    TraversalTester tester,
  ) async {
    final Map<String, Rect> children = <String, Rect>{
      'A': Offset.zero & tenByTen,
      'B': const Offset(20.0, 5.0) & tenByTen,
      'C': const Offset(40.0, 0.0) & tenByTen,
    };

    await tester.test(
      textDirection: TextDirection.ltr,
      children: children,
      expectedTraversal: 'A B C',
    );

    await tester.test(
      textDirection: TextDirection.rtl,
      children: children,
      expectedTraversal: 'C B A',
    );
  });

  // LTR:
  // ┌───┐ ┌───┐ ┌───┐ ┌───┐
  // │ A │>│ B │>│ C │>│ D │
  // └───┘ └───┘ └───┘ └───┘
  //   ┌─────────────────┘
  //   V
  // ┌───┐ ┌─────────┐ ┌───┐
  // │ E │>│         │>│ G │
  // └───┘ │    F    │ └───┘
  //   ┌───|─────────|───┘
  // ┌───┐ │         │ ┌───┐
  // │ H │─|─────────|>│ I │
  // └───┘ └─────────┘ └───┘
  //   ┌─────────────────┘
  //   V
  // ┌───┐ ┌───┐ ┌───┐ ┌───┐
  // │ J │>│ K │>│ L │>│ M │
  // └───┘ └───┘ └───┘ └───┘
  //
  // RTL:
  // ┌───┐ ┌───┐ ┌───┐ ┌───┐
  // │ A │<│ B │<│ C │<│ D │
  // └───┘ └───┘ └───┘ └───┘
  //   └─────────────────┐
  //                     V
  // ┌───┐ ┌─────────┐ ┌───┐
  // │ E │<│         │<│ G │
  // └───┘ │    F    │ └───┘
  //    └──|─────────|────┐
  // ┌───┐ │         │ ┌───┐
  // │ H │<|─────────|─│ I │
  // └───┘ └─────────┘ └───┘
  //   └─────────────────┐
  //                     V
  // ┌───┐ ┌───┐ ┌───┐ ┌───┐
  // │ J │<│ K │<│ L │<│ M │
  // └───┘ └───┘ └───┘ └───┘
  testTraversal('Semantics traverses vertical groups, then horizontal groups, then knots', (
    TraversalTester tester,
  ) async {
    final Map<String, Rect> children = <String, Rect>{
      'A': Offset.zero & tenByTen,
      'B': const Offset(20.0, 0.0) & tenByTen,
      'C': const Offset(40.0, 0.0) & tenByTen,
      'D': const Offset(60.0, 0.0) & tenByTen,
      'E': const Offset(0.0, 20.0) & tenByTen,
      'F': const Offset(20.0, 20.0) & (tenByTen * 2.0),
      'G': const Offset(60.0, 20.0) & tenByTen,
      'H': const Offset(0.0, 40.0) & tenByTen,
      'I': const Offset(60.0, 40.0) & tenByTen,
      'J': const Offset(0.0, 60.0) & tenByTen,
      'K': const Offset(20.0, 60.0) & tenByTen,
      'L': const Offset(40.0, 60.0) & tenByTen,
      'M': const Offset(60.0, 60.0) & tenByTen,
    };

    await tester.test(
      textDirection: TextDirection.ltr,
      children: children,
      expectedTraversal: 'A B C D E F G H I J K L M',
    );

    await tester.test(
      textDirection: TextDirection.rtl,
      children: children,
      expectedTraversal: 'D C B A G F E I H M L K J',
    );
  });

  // The following test tests traversal of the simplest "knot", which is two
  // nodes overlapping both vertically and horizontally. For example:
  //
  // ┌─────────┐
  // │         │
  // │   A     │
  // │     ┌───┼─────┐
  // │     │   │     │
  // └─────┼───┘     │
  //       │     B   │
  //       │         │
  //       └─────────┘
  //
  // The outcome depends on the relative positions of the centers of `Rect`s of
  // their respective boxes, specifically the direction (i.e. angle) of the
  // vector pointing from A to B. We test different angles, one for each octant:
  //
  //  -3π/4 -π/2  -π/4
  //      ╲   │   ╱
  //       ╲ 1│2 ╱
  //        ╲ │ ╱
  //     i=0 ╲│╱ 3
  //  π ──────┼────── 0
  //       7 ╱│╲ 4
  //        ╱ │ ╲
  //       ╱ 6│5 ╲
  //      ╱   │   ╲
  //   3π/4  π/2   π/4
  //
  // For LTR, angles falling into octants 3, 4, 5, and 6, produce A -> B, all
  // others produce B -> A.
  //
  // For RTL, angles falling into octants 5, 6, 7, and 0, produce A -> B, all
  // others produce B -> A.
  testTraversal('Semantics sorts knots', (TraversalTester tester) async {
    const double start = -math.pi + math.pi / 8.0;

    for (int i = 0; i < 8; i += 1) {
      final double angle = start + i.toDouble() * math.pi / 4.0;
      // These values should be truncated so that double precision rounding
      // issues won't impact the heights/widths and throw off the traversal
      // ordering.
      final double dx = (math.cos(angle) * 15.0) / 10.0;
      final double dy = (math.sin(angle) * 15.0) / 10.0;

      final Map<String, Rect> children = <String, Rect>{
        'A': const Offset(10.0, 10.0) & tenByTen,
        'B': Offset(10.0 + dx, 10.0 + dy) & tenByTen,
      };

      try {
        await tester.test(
          textDirection: TextDirection.ltr,
          children: children,
          expectedTraversal: 3 <= i && i <= 6 ? 'A B' : 'B A',
        );

        await tester.test(
          textDirection: TextDirection.rtl,
          children: children,
          expectedTraversal: 1 <= i && i <= 4 ? 'B A' : 'A B',
        );
      } catch (error) {
        fail(
          'Test failed with i == $i, angle == ${angle / math.pi}π\n'
          '$error',
        );
      }
    }
  });
}

class TraversalTester {
  TraversalTester(this.tester) : semantics = SemanticsTester(tester);

  final WidgetTester tester;
  final SemanticsTester semantics;

  Future<void> test({
    required TextDirection textDirection,
    required Map<String, Rect> children,
    required String expectedTraversal,
  }) async {
    assert(children is LinkedHashMap);
    await tester.pumpWidget(
      Directionality(
        textDirection: textDirection,
        child: Semantics(
          textDirection: textDirection,
          child: CustomMultiChildLayout(
            delegate: TestLayoutDelegate(children),
            children:
                children.keys.map<Widget>((String label) {
                  return LayoutId(
                    id: label,
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      label: label,
                      child: SizedBox(
                        width: children[label]!.width,
                        height: children[label]!.height,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              textDirection: textDirection,
              children:
                  expectedTraversal.split(' ').map<TestSemantics>((String label) {
                    return TestSemantics(label: label);
                  }).toList(),
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );
  }

  void dispose() {
    semantics.dispose();
  }
}

class TestLayoutDelegate extends MultiChildLayoutDelegate {
  TestLayoutDelegate(this.children);

  final Map<String, Rect> children;

  @override
  void performLayout(Size size) {
    children.forEach((String label, Rect rect) {
      layoutChild(label, BoxConstraints.loose(size));
      positionChild(label, rect.topLeft);
    });
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) => oldDelegate == this;
}
