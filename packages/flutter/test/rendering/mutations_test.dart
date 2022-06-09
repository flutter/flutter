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
  void performLayout() => onPerformLayout?.call();
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
    FlutterError catchError(VoidCallback callback) {
      Object? error;
      try {
        callback();
      } catch (e) {
        error = e;
      }

      expect(error, isFlutterError);
      return error! as FlutterError;
    }

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
        contains('has already been disposed.'),
      );
    });

    test('marking itself dirty in performLayout', () {
      late RenderBox child1;
      final RenderFlex block = RenderFlex(textDirection: TextDirection.ltr);
      block.add(child1 = RenderLayoutTestBox(() {}, onPerformLayout: () { child1.markNeedsLayout(); }));

      expect(
        catchLayoutError(block).message,
        contains(
          'A render object must not mark itself dirty while actively doing layout.\n'
          'If you wish to change the layout of a subtree during layout, consider using the LayoutBuilder widget.'
        ),
      );
    });

    test('marking a sibling dirty in performLayout', () {
      late RenderBox child1;
      final RenderFlex block = RenderFlex(textDirection: TextDirection.ltr);
      block.add(child1 = RenderLayoutTestBox(() {}));
      block.add(RenderLayoutTestBox(() {}, onPerformLayout: () { child1.markNeedsLayout(); }));

      expect(
        catchLayoutError(block).message,
        equalsIgnoringHashCodes(
          'Mutating RenderLayoutTestBox#00000 from RenderLayoutTestBox#00000 is not allowed:\n'
          'Consider using the LayoutBuilder widget to dynamically mutate a subtree during layout.'
        ),
      );
    });
  });
}
