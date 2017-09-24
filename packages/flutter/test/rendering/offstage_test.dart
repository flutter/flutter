// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('offstage', () {
    RenderBox child;
    bool painted = false;
    // incoming constraints are tight 800x600
    final RenderBox root = new RenderPositionedBox(
      child: new RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(width: 800.0),
        child: new RenderOffstage(
          child: new RenderCustomPaint(
            painter: new TestCallbackPainter(
              onPaint: () { painted = true; },
            ),
            child: child = new RenderConstrainedBox(
              additionalConstraints: const BoxConstraints.tightFor(height: 10.0, width: 10.0),
            ),
          ),
        ),
      ),
    );
    expect(child.hasSize, isFalse);
    expect(painted, isFalse);
    layout(root, phase: EnginePhase.paint);
    expect(child.hasSize, isTrue);
    expect(painted, isFalse);
    expect(child.size, equals(const Size(800.0, 10.0)));
  });
}
