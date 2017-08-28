// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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

  test('RenderPhysicalModel compositing on Fuchsia', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

    final RenderPhysicalModel root = new RenderPhysicalModel(color: const Color(0xffff00ff));
    layout(root, phase: EnginePhase.composite);
    expect(root.needsCompositing, isFalse);

    // On Fuchsia, the system compositor is responsible for drawing shadows
    // for physical model layers with non-zero elevation.
    root.elevation = 1.0;
    pumpFrame(phase: EnginePhase.composite);
    expect(root.needsCompositing, isTrue);

    root.elevation = 0.0;
    pumpFrame(phase: EnginePhase.composite);
    expect(root.needsCompositing, isFalse);

    debugDefaultTargetPlatformOverride = null;
  });

  test('RenderPhysicalModel compositing on non-Fuchsia', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final RenderPhysicalModel root = new RenderPhysicalModel(color: const Color(0xffff00ff));
    layout(root, phase: EnginePhase.composite);
    expect(root.needsCompositing, isFalse);

    // On non-Fuchsia platforms, Flutter draws its own shadows.
    root.elevation = 1.0;
    pumpFrame(phase: EnginePhase.composite);
    expect(root.needsCompositing, isFalse);

    root.elevation = 0.0;
    pumpFrame(phase: EnginePhase.composite);
    expect(root.needsCompositing, isFalse);

    debugDefaultTargetPlatformOverride = null;
  });

  test('RenderSemanticsGestureHandler adds/removes correct semantic actions', () {
    SemanticsNode node = new SemanticsNode();
    final RenderSemanticsGestureHandler renderObj = new RenderSemanticsGestureHandler(
      onTap: () {},
      onHorizontalDragUpdate: (DragUpdateDetails details) {},
    );

    renderObj.semanticsAnnotator(node);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.scrollLeft), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.scrollRight), isTrue);

    node = new SemanticsNode();
    renderObj.validActions = <SemanticsAction>[SemanticsAction.tap, SemanticsAction.scrollLeft].toSet();

    renderObj.semanticsAnnotator(node);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.scrollLeft), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.scrollRight), isFalse);
  });
}
