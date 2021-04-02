// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('nested repaint boundaries - smoke test', () {
    RenderOpacity a, b, c;
    a = RenderOpacity(
      opacity: 1.0,
      child: RenderRepaintBoundary(
        child: b = RenderOpacity(
          opacity: 1.0,
          child: RenderRepaintBoundary(
            child: c = RenderOpacity(
              opacity: 1.0
            )
          ),
        ),
      ),
    );
    layout(a, phase: EnginePhase.flushSemantics);
    c.opacity = 0.9;
    pumpFrame(phase: EnginePhase.flushSemantics);
    a.opacity = 0.8;
    c.opacity = 0.8;
    pumpFrame(phase: EnginePhase.flushSemantics);
    a.opacity = 0.7;
    b.opacity = 0.7;
    c.opacity = 0.7;
    pumpFrame(phase: EnginePhase.flushSemantics);
  });

  test('Repaint boundary can get new parent after markNeedsCompositingBitsUpdate', () {
    // Regression test for https://github.com/flutter/flutter/issues/24029.

    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    layout(repaintBoundary, phase: EnginePhase.flushSemantics);

    repaintBoundary.markNeedsCompositingBitsUpdate();

    renderer.renderView.child = null;
    final RenderPadding padding = RenderPadding(
      padding: const EdgeInsets.all(50),
    );
    renderer.renderView.child = padding;
    padding.child = repaintBoundary;
    pumpFrame(phase: EnginePhase.flushSemantics);
  });

  test('Framework creates an OffsetLayer for a repaint boundary', () {
    final _TestRepaintBoundary repaintBoundary = _TestRepaintBoundary();
    final RenderOpacity opacity = RenderOpacity(
      opacity: 1.0,
      child: repaintBoundary,
    );
    layout(opacity, phase: EnginePhase.flushSemantics);
    expect(repaintBoundary.debugLayer, isA<OffsetLayer>());
  });

  test('Framework does not create an OffsetLayer for a non-repaint boundary', () {
    final _TestNonCompositedBox nonCompositedBox = _TestNonCompositedBox();
    final RenderOpacity opacity = RenderOpacity(
      opacity: 1.0,
      child: nonCompositedBox,
    );
    layout(opacity, phase: EnginePhase.flushSemantics);
    expect(nonCompositedBox.debugLayer, null);
  });

  test('Framework allows a non-repaint boundary to create own layer', () {
    final _TestCompositedBox compositedBox = _TestCompositedBox();
    final RenderOpacity opacity = RenderOpacity(
      opacity: 1.0,
      child: compositedBox,
    );
    layout(opacity, phase: EnginePhase.flushSemantics);
    expect(compositedBox.debugLayer, isA<OpacityLayer>());
  });

  test('Framework ensures repaint boundary layer is not overwritten', () {
    final _TestRepaintBoundaryThatOverwritesItsLayer faultyRenderObject = _TestRepaintBoundaryThatOverwritesItsLayer();
    final RenderOpacity opacity = RenderOpacity(
      opacity: 1.0,
      child: faultyRenderObject,
    );

    late FlutterErrorDetails error;
    layout(opacity, phase: EnginePhase.flushSemantics, onErrors: () {
      error = renderer.takeFlutterErrorDetails()!;
    });
    expect('${error.exception}', contains('Attempted to set a layer to a repaint boundary render object.'));
  });
}

// A plain render object that's a repaint boundary.
class _TestRepaintBoundary extends RenderBox {
  @override
  bool get isRepaintBoundary => true;

  @override
  void performLayout() {
    size = constraints.smallest;
  }
}

// A render object that's a repaint boundary and (incorrectly) creates its own layer.
class _TestRepaintBoundaryThatOverwritesItsLayer extends RenderBox {
  @override
  bool get isRepaintBoundary => true;

  @override
  void performLayout() {
    size = constraints.smallest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    layer = OpacityLayer(alpha: 50);
  }
}

// A render object that's neither a repaint boundary nor creates its own layer.
class _TestNonCompositedBox extends RenderBox {
  @override
  bool get isRepaintBoundary => false;

  @override
  void performLayout() {
    size = constraints.smallest;
  }
}

// A render object that's not a repaint boundary but creates its own layer.
class _TestCompositedBox extends RenderBox {
  @override
  bool get isRepaintBoundary => false;

  @override
  void performLayout() {
    size = constraints.smallest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    layer = OpacityLayer(alpha: 50);
  }
}
