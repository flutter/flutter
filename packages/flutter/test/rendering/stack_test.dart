// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('Stack can layout with top, right, bottom, left 0.0', () {
    final RenderBox size = RenderConstrainedBox(
      additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
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
    final StackParentData greenParentData = green.parentData! as StackParentData;
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

  test('Stack can layout with no children', () {
    final RenderBox stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[],
    );

    layout(stack, constraints: BoxConstraints.tight(const Size(100.0, 100.0)));

    expect(stack.size.width, equals(100.0));
    expect(stack.size.height, equals(100.0));
  });

  test('Stack respects clipBehavior', () {
    const BoxConstraints viewport = BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    final TestClipPaintingContext context = TestClipPaintingContext();

    // By default, clipBehavior should be Clip.none
    final RenderStack defaultStack = RenderStack(textDirection: TextDirection.ltr, children: <RenderBox>[box200x200]);
    layout(defaultStack, constraints: viewport, phase: EnginePhase.composite, onErrors: expectOverflowedErrors);
    defaultStack.paint(context, Offset.zero);
    expect(context.clipBehavior, equals(Clip.none));

    for (final Clip clip in Clip.values) {
      final RenderBox child = box200x200;
      final RenderStack stack = RenderStack(
          textDirection: TextDirection.ltr,
          children: <RenderBox>[child],
          clipBehavior: clip,
      );
      { // Make sure that the child is positioned so the stack will consider it as overflowed.
        final StackParentData parentData = child.parentData! as StackParentData;
        parentData.left = parentData.right = 0;
      }
      layout(stack, constraints: viewport, phase: EnginePhase.composite, onErrors: expectOverflowedErrors);
      context.paintChild(stack, Offset.zero);
      expect(context.clipBehavior, equals(clip));
    }
  });

  group('RenderIndexedStack', () {
    test('visitChildrenForSemantics only visits displayed child', () {
      final RenderBox child1 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );
      final RenderBox child2 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );
      final RenderBox child3 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );
      final RenderBox stack = RenderIndexedStack(
        index: 1,
        textDirection: TextDirection.ltr,
        children: <RenderBox>[child1, child2, child3],
      );

      final List<RenderObject> visitedChildren = <RenderObject>[];
      void visitor(RenderObject child) {
        visitedChildren.add(child);
      }

      stack.visitChildrenForSemantics(visitor);

      expect(visitedChildren, hasLength(1));
      expect(visitedChildren.first, child2);
    });

  });

  // More tests in ../widgets/stack_test.dart
}
