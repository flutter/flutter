// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import '../flutter_test_alternative.dart';

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
          )
        )
      )
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

  test('Repaint boundary can get a new parent after a hot reload without crashing', () {
    // Regression test for https://github.com/flutter/flutter/issues/24029.

    final RenderBox repaintBoundary = RenderRepaintBoundary();
    layout(repaintBoundary, phase: EnginePhase.flushSemantics);

    // Simulate hot reload.
    renderer.renderView.reassemble();

    // Give the repaint boundary a new parent.
    renderer.renderView.dropChild(repaintBoundary);
    final RenderBox padding = RenderPadding(
      padding: const EdgeInsets.all(50),
    );
    renderer.renderView.adoptChild(padding);
    padding.adoptChild(repaintBoundary);
    pumpFrame(phase: EnginePhase.flushSemantics);
  });
}
