// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui show Image;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/scheduler/ticker.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('RenderFittedBox paint', () {
    bool painted;
    RenderFittedBox makeFittedBox() {
      return new RenderFittedBox(
        child: new RenderCustomPaint(
          painter: new TestCallbackPainter(onPaint: () {
            painted = true;
          }),
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

  test('RenderRepaintBoundary can capture images of itself', () async {
    RenderRepaintBoundary boundary = new RenderRepaintBoundary();
    layout(boundary, constraints: new BoxConstraints.tight(const Size(100.0, 200.0)));
    pumpFrame(phase: EnginePhase.composite);
    ui.Image image = await boundary.toImage();
    expect(image.width, equals(100));
    expect(image.height, equals(200));

    // Now with pixel ratio set to something other than 1.0.
    boundary = new RenderRepaintBoundary();
    layout(boundary, constraints: new BoxConstraints.tight(const Size(100.0, 200.0)));
    pumpFrame(phase: EnginePhase.composite);
    image = await boundary.toImage(pixelRatio: 2.0);
    expect(image.width, equals(200));
    expect(image.height, equals(400));

    // Try building one with two child layers and make sure it renders them both.
    boundary = new RenderRepaintBoundary();
    final RenderStack stack = new RenderStack()..alignment = Alignment.topLeft;
    final RenderDecoratedBox blackBox = new RenderDecoratedBox(
        decoration: const BoxDecoration(color: const Color(0xff000000)),
        child: new RenderConstrainedBox(
          additionalConstraints: new BoxConstraints.tight(const Size.square(20.0)),
        ));
    stack.add(new RenderOpacity()
      ..opacity = 0.5
      ..child = blackBox);
    final RenderDecoratedBox whiteBox = new RenderDecoratedBox(
        decoration: const BoxDecoration(color: const Color(0xffffffff)),
        child: new RenderConstrainedBox(
          additionalConstraints: new BoxConstraints.tight(const Size.square(10.0)),
        ));
    final RenderPositionedBox positioned = new RenderPositionedBox(
      widthFactor: 2.0,
      heightFactor: 2.0,
      alignment: Alignment.topRight,
      child: whiteBox,
    );
    stack.add(positioned);
    boundary.child = stack;
    layout(boundary, constraints: new BoxConstraints.tight(const Size(20.0, 20.0)));
    pumpFrame(phase: EnginePhase.composite);
    image = await boundary.toImage();
    expect(image.width, equals(20));
    expect(image.height, equals(20));
    final ByteData data = await image.toByteData();
    expect(data.lengthInBytes, equals(20 * 20 * 4));
    expect(data.elementSizeInBytes, equals(1));
    const int stride = 20 * 4;
    expect(data.getUint32(0), equals(0x00000080));
    expect(data.getUint32(stride - 4), equals(0xffffffff));
  });

  test('RenderOpacity does not composite if it is transparent', () {
    final RenderOpacity renderOpacity = new RenderOpacity(
      opacity: 0.0,
      child: new RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    );

    layout(renderOpacity, phase: EnginePhase.composite);
    expect(renderOpacity.needsCompositing, false);
  });

  test('RenderOpacity does not composite if it is opaque', () {
    final RenderOpacity renderOpacity = new RenderOpacity(
      opacity: 1.0,
      child: new RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    );

    layout(renderOpacity, phase: EnginePhase.composite);
    expect(renderOpacity.needsCompositing, false);
  });

  test('RenderAnimatedOpacity does not composite if it is transparent', () async {
    final Animation<double> opacityAnimation = new AnimationController(
      vsync: new _FakeTickerProvider(),
    )..value = 0.0;

    final RenderAnimatedOpacity renderAnimatedOpacity = new RenderAnimatedOpacity(
      opacity: opacityAnimation,
      child: new RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    );

    layout(renderAnimatedOpacity, phase: EnginePhase.composite);
    expect(renderAnimatedOpacity.needsCompositing, false);
  });

  test('RenderAnimatedOpacity does not composite if it is opaque', () {
    final Animation<double> opacityAnimation = new AnimationController(
      vsync: new _FakeTickerProvider(),
    )..value = 1.0;

    final RenderAnimatedOpacity renderAnimatedOpacity = new RenderAnimatedOpacity(
      opacity: opacityAnimation,
      child: new RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    );

    layout(renderAnimatedOpacity, phase: EnginePhase.composite);
    expect(renderAnimatedOpacity.needsCompositing, false);
  });
}

class _FakeTickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return new _FakeTicker();
  }
}

class _FakeTicker implements Ticker {
  @override
  bool muted;

  @override
  void absorbTicker(Ticker originalTicker) {}

  @override
  String get debugLabel => null;

  @override
  bool get isActive => null;

  @override
  bool get isTicking => null;

  @override
  bool get scheduled => null;

  @override
  bool get shouldScheduleTick => null;

  @override
  void dispose() {}

  @override
  void scheduleTick({bool rescheduling = false}) {}

  @override
  TickerFuture start() {
    return null;
  }

  @override
  void stop({bool canceled = false}) {}

  @override
  void unscheduleTick() {}
}