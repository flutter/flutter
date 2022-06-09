// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

class RenderLayoutTestBox extends RenderProxyBox {
  RenderLayoutTestBox(this.onLayout, {
    this.onPerformLayout,
  });

  final VoidCallback onLayout;
  final VoidCallback? onPerformLayout;

  @override
  void layout(Constraints constraints, { bool parentUsesSize = false }) {
    // Doing this in tests is ok, but if you're writing your own
    // render object, you want to override performLayout(), not
    // layout(). Overriding layout() would remove many critical
    // performance optimizations of the rendering system, as well as
    // many bypassing many checked-mode integrity checks.
    super.layout(constraints, parentUsesSize: parentUsesSize);
    onLayout();
  }

  @override
  bool get sizedByParent => true;

  @override
  void performLayout() {
    child?.layout(constraints, parentUsesSize: true);
    onPerformLayout?.call();
  }
}

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('moving children', () {
    RenderBox child1, child2;
    bool movedChild1 = false;
    bool movedChild2 = false;
    final RenderFlex block = RenderFlex(textDirection: TextDirection.ltr);
    block.add(child1 = RenderLayoutTestBox(() { movedChild1 = true; }));
    block.add(child2 = RenderLayoutTestBox(() { movedChild2 = true; }));

    expect(movedChild1, isFalse);
    expect(movedChild2, isFalse);
    layout(block);
    expect(movedChild1, isTrue);
    expect(movedChild2, isTrue);

    movedChild1 = false;
    movedChild2 = false;

    expect(movedChild1, isFalse);
    expect(movedChild2, isFalse);
    pumpFrame();
    expect(movedChild1, isFalse);
    expect(movedChild2, isFalse);

    block.move(child1, after: child2);
    expect(movedChild1, isFalse);
    expect(movedChild2, isFalse);
    pumpFrame();
    expect(movedChild1, isTrue);
    expect(movedChild2, isTrue);

    movedChild1 = false;
    movedChild2 = false;

    expect(movedChild1, isFalse);
    expect(movedChild2, isFalse);
    pumpFrame();
    expect(movedChild1, isFalse);
    expect(movedChild2, isFalse);
  });

  group('Throws when invalid mutations are attempted: ', () {
    FlutterError catchLayoutError(RenderBox box) {
      Object? error;
      layout(box, onErrors: () {
        error = TestRenderingFlutterBinding.instance.takeFlutterErrorDetails()!.exception;
      });
      expect(error, isFlutterError);
      return error! as FlutterError;
    }

    test('on disposed render objects', () {
      final RenderBox box = RenderLayoutTestBox(() {});
      box.dispose();

      Object? error;
      try {
        box.markNeedsLayout();
      } catch (e) {
        error = e;
      }

      expect(error, isFlutterError);
      expect(
        (error! as FlutterError).message,
        contains('A disposed RenderObject was mutated.'),
      );
    });

    test('marking itself dirty in performLayout', () {
      late RenderBox child1;
      final RenderFlex block = RenderFlex(textDirection: TextDirection.ltr);
      block.add(child1 = RenderLayoutTestBox(() {}, onPerformLayout: () { child1.markNeedsLayout(); }));

      expect(
        catchLayoutError(block).message,
        allOf(
          contains('A RenderLayoutTestBox was mutated in its own performLayout implementation.\n'),
          contains('A RenderObject must not re-dirty itself while still being laid out.\n'),
        )
      );
    });

    test('marking a sibling dirty in performLayout', () {
      late RenderBox child1;
      final RenderFlex block = RenderFlex(textDirection: TextDirection.ltr);
      block.add(child1 = RenderLayoutTestBox(() {}));
      block.add(RenderLayoutTestBox(() {}, onPerformLayout: () { child1.markNeedsLayout(); }));

      expect(
        catchLayoutError(block).message,
        allOf(
          contains('A RenderLayoutTestBox was mutated in RenderLayoutTestBox.performLayout.\n'),
          contains('A RenderObject must not mutate another RenderObject from a different render subtree in its performLayout method.\n'),
          contains('The RenderObject that was mutating the said RenderLayoutTestBox was:\n'),
          contains('Their common ancestor was:'),
        ),
      );
    });

    test('marking a descendant dirty in performLayout', () {
      late RenderBox child1;
      final RenderFlex block = RenderFlex(textDirection: TextDirection.ltr);
      block.add(child1 = RenderLayoutTestBox(() {}));
      block.add(RenderLayoutTestBox(child1.markNeedsLayout));

      expect(
        catchLayoutError(block).message,
        allOf(
          contains('A RenderLayoutTestBox was mutated in RenderFlex.performLayout.\n'),
          contains('A RenderObject must not mutate its descendants in its performLayout method.\n'),
          contains('The ancestor RenderObject that was mutating the said RenderLayoutTestBox was:\n'),
          isNot(contains('Their common ancestor was:')),
        ),
      );
    });

    test('marking an out-of-band mutation in performLayout', () {
      late RenderProxyBox child1, child11, child2;
      final RenderFlex block = RenderFlex(textDirection: TextDirection.ltr);
      block.add(child1 = RenderLayoutTestBox(() {}));
      block.add(child2 = RenderLayoutTestBox(() {}));
      child1.child = child11 = RenderLayoutTestBox(() {});
      layout(block);

      expect(block.debugNeedsLayout, false);
      expect(child1.debugNeedsLayout, false);
      expect(child2.debugNeedsLayout, false);

      // Add a new child to a relayout boundary.
      child2.child = RenderLayoutTestBox(() {}, onPerformLayout: child11.markNeedsLayout);

      FlutterError? error;
      pumpFrame(onErrors: () {
        error = TestRenderingFlutterBinding.instance.takeFlutterErrorDetails()!.exception as FlutterError;
      });

      expect(
        error?.message,
        allOf(
          contains('A RenderLayoutTestBox was mutated in RenderLayoutTestBox.performLayout.'),
          contains('The RenderObject was marked as needing layout when none of its ancestors is actively performing layout.'),
          isNot(contains('Their common ancestor was:')),
        ),
      );
    });
  });
}
