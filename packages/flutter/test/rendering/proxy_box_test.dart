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
    final RenderSemanticsGestureHandler renderObj = new RenderSemanticsGestureHandler(
      onTap: () {},
      onHorizontalDragUpdate: (DragUpdateDetails details) {},
    );

    SemanticsConfiguration config = new SemanticsConfiguration();
    renderObj.describeSemanticsConfiguration(config);
    expect(config.getActionHandler(SemanticsAction.tap), isNotNull);
    expect(config.getActionHandler(SemanticsAction.scrollLeft), isNotNull);
    expect(config.getActionHandler(SemanticsAction.scrollRight), isNotNull);

    config = new SemanticsConfiguration();
    renderObj.validActions = <SemanticsAction>[SemanticsAction.tap, SemanticsAction.scrollLeft].toSet();

    renderObj.describeSemanticsConfiguration(config);
    expect(config.getActionHandler(SemanticsAction.tap), isNotNull);
    expect(config.getActionHandler(SemanticsAction.scrollLeft), isNotNull);
    expect(config.getActionHandler(SemanticsAction.scrollRight), isNull);
  });

  group('RenderPhysicalShape', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    test('shape change triggers repaint', () {
      final RenderPhysicalShape root = new RenderPhysicalShape(
        color: const Color(0xffff00ff),
        clipper: const ShapeBorderClipper(shape: const CircleBorder()),
      );
      layout(root, phase: EnginePhase.composite);
      expect(root.debugNeedsPaint, isFalse);

      // Same shape, no repaint.
      root.clipper = const ShapeBorderClipper(shape: const CircleBorder());
      expect(root.debugNeedsPaint, isFalse);

      // Different shape triggers repaint.
      root.clipper = const ShapeBorderClipper(shape: const StadiumBorder());
      expect(root.debugNeedsPaint, isTrue);
    });

    test('compositing on non-Fuchsia', () {
      final RenderPhysicalShape root = new RenderPhysicalShape(
        color: const Color(0xffff00ff),
        clipper: const ShapeBorderClipper(shape: const CircleBorder()),
      );
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
  });
}
