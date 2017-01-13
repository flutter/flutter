// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('RenderFittedBox paint', () {
    bool painted;
    RenderFittedBox makeFittedBox() {
      return new RenderFittedBox(
        child: new RenderCustomPaint(
          painter: new TestCallbackPainter(
            onPaint: () { painted = true; }
          ),
        ),
      );
    }

    painted = false;
    layout(makeFittedBox(), phase: EnginePhase.paint);
    expect(painted, equals(true));

    // The RenderFittedBox should not paint if it is empty.
    painted = false;
    layout(makeFittedBox(), constraints: new BoxConstraints.tight(Size.zero), phase: EnginePhase.paint);
    expect(painted, equals(false));
  });
}
