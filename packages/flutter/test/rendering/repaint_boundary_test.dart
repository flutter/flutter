// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('nested repaint boundaries - smoke test', () {
    RenderOpacity a, b, c;
    a = new RenderOpacity(
      opacity: 1.0,
      child: new RenderRepaintBoundary(
        child: b = new RenderOpacity(
          opacity: 1.0,
          child: new RenderRepaintBoundary(
            child: c = new RenderOpacity(
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
}
