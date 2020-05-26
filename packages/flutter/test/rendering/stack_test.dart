// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import '../flutter_test_alternative.dart';

import 'rendering_tester.dart';

void main() {
  test('Stack can layout with top, right, bottom, left 0.0', () {
    final RenderBox size = RenderConstrainedBox(
      additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0))
    );

    final RenderBox red = RenderDecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFFF0000),
      ),
      child: size,
    );

    final RenderBox green = RenderDecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFFF0000),
      ),
    );

    final RenderBox stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[red, green],
    );
    final StackParentData greenParentData = green.parentData as StackParentData;
    greenParentData
      ..top = 0.0
      ..right = 0.0
      ..bottom = 0.0
      ..left = 0.0;

    layout(stack, constraints: const BoxConstraints());

    expect(stack.size.width, equals(100.0));
    expect(stack.size.height, equals(100.0));

    expect(red.size.width, equals(100.0));
    expect(red.size.height, equals(100.0));

    expect(green.size.width, equals(100.0));
    expect(green.size.height, equals(100.0));
  });

  test('Stack paint child in order according to child zIndex', () {
    int index = 0, redPaintIndex, greenPaintIndex;
    final RenderBox size = RenderConstrainedBox(
      additionalConstraints: BoxConstraints.tight(const Size(100.0, 300.0))
    );

    final RenderBox red = RenderCustomPaint(
            painter: TestCallbackPainter(
              onPaint: () { redPaintIndex = index ++; },
            ),
            child: RenderDecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFFF0000),
              ),
              child: size,
            ),
          );

    final RenderBox green = RenderCustomPaint(
          painter: TestCallbackPainter(
            onPaint: () { greenPaintIndex = index ++; },
          ),
          child: RenderDecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF00FF00),
            ),
          ),
        );

    final RenderBox stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[red, green],
    );

    final StackParentData redParentData = red.parentData as StackParentData;
    redParentData
      ..top = 0.0
      ..right = 0.0
      ..left = 0.0
      ..height = 200
      ..zIndex = 2;

    final StackParentData greenParentData = green.parentData as StackParentData;
    greenParentData
      ..top = 100.0
      ..right = 0.0
      ..left = 0.0
      ..height = 200.0
      ..zIndex = 1;

    layout(stack, phase: EnginePhase.paint);

    expect(redPaintIndex, greaterThan(greenPaintIndex));
  });

  test('Stack can layout with no children', () {
    final RenderBox stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[],
    );

    layout(stack, constraints: BoxConstraints.tight(const Size(100.0, 100.0)));

    expect(stack.size.width, equals(100.0));
    expect(stack.size.height, equals(100.0));
  });

  group('RenderIndexedStack', () {
    test('visitChildrenForSemantics only visits displayed child', () {
      final RenderBox child1 = RenderConstrainedBox(
          additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0))
      );
      final RenderBox child2 = RenderConstrainedBox(
          additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0))
      );
      final RenderBox child3 = RenderConstrainedBox(
          additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0))
      );
      final RenderBox stack = RenderIndexedStack(
          index: 1,
          textDirection: TextDirection.ltr,
          children: <RenderBox>[child1, child2, child3],
      );

      final List<RenderObject> visitedChildren = <RenderObject>[];
      final RenderObjectVisitor visitor = (RenderObject child) {
        visitedChildren.add(child);
      };

      stack.visitChildrenForSemantics(visitor);

      expect(visitedChildren, hasLength(1));
      expect(visitedChildren.first, child2);
    });

  });

  // More tests in ../widgets/stack_test.dart
}
