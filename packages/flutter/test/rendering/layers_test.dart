// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('non-painted layers are detached', () {
    RenderObject boundary, inner;
    final RenderOpacity root = new RenderOpacity(
      child: boundary = new RenderRepaintBoundary(
        child: inner = new RenderDecoratedBox(
          decoration: const BoxDecoration(),
        ),
      ),
    );
    layout(root, phase: EnginePhase.paint);
    expect(inner.isRepaintBoundary, isFalse);
    expect(() => inner.layer, throwsAssertionError);
    expect(boundary.isRepaintBoundary, isTrue);
    expect(boundary.layer, isNotNull);
    expect(boundary.layer.attached, isTrue); // this time it painted...

    root.opacity = 0.0;
    pumpFrame(phase: EnginePhase.paint);
    expect(inner.isRepaintBoundary, isFalse);
    expect(() => inner.layer, throwsAssertionError);
    expect(boundary.isRepaintBoundary, isTrue);
    expect(boundary.layer, isNotNull);
    expect(boundary.layer.attached, isFalse); // this time it did not.

    root.opacity = 0.5;
    pumpFrame(phase: EnginePhase.paint);
    expect(inner.isRepaintBoundary, isFalse);
    expect(() => inner.layer, throwsAssertionError);
    expect(boundary.isRepaintBoundary, isTrue);
    expect(boundary.layer, isNotNull);
    expect(boundary.layer.attached, isTrue); // this time it did again!
  });
}
