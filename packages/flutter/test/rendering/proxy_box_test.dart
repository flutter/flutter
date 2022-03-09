// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui show Gradient, Image, ImageFilter;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('RenderFittedBox handles applying paint transform and hit-testing with empty size', () {
    final RenderFittedBox fittedBox = RenderFittedBox(
      child: RenderCustomPaint(
        painter: TestCallbackPainter(onPaint: () {}),
      ),
    );

    layout(fittedBox, phase: EnginePhase.flushSemantics);
    final Matrix4 transform = Matrix4.identity();
    fittedBox.applyPaintTransform(fittedBox.child!, transform);
    expect(transform, Matrix4.zero());

    final BoxHitTestResult hitTestResult = BoxHitTestResult();
    expect(fittedBox.hitTestChildren(hitTestResult, position: Offset.zero), isFalse);
  });

  test('RenderFittedBox does not paint with empty sizes', () {
    bool painted;
    RenderFittedBox makeFittedBox(Size size) {
      return RenderFittedBox(
        child: RenderCustomPaint(
          preferredSize: size,
          painter: TestCallbackPainter(onPaint: () {
            painted = true;
          }),
        ),
      );
    }

    // The RenderFittedBox paints if both its size and its child's size are nonempty.
    painted = false;
    layout(makeFittedBox(const Size(1, 1)), phase: EnginePhase.paint);
    expect(painted, equals(true));

    // The RenderFittedBox should not paint if its child is empty-sized.
    painted = false;
    layout(makeFittedBox(Size.zero), phase: EnginePhase.paint);
    expect(painted, equals(false));

    // The RenderFittedBox should not paint if it is empty.
    painted = false;
    layout(makeFittedBox(const Size(1, 1)), constraints: BoxConstraints.tight(Size.zero), phase: EnginePhase.paint);
    expect(painted, equals(false));
  });

  test('RenderPhysicalModel compositing on Fuchsia', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

    final RenderPhysicalModel root = RenderPhysicalModel(color: const Color(0xffff00ff));
    layout(root, phase: EnginePhase.composite);
    expect(root.needsCompositing, isTrue);

    // On Fuchsia, the system compositor is responsible for drawing shadows
    // for physical model layers with non-zero elevation.
    root.elevation = 1.0;
    pumpFrame(phase: EnginePhase.composite);
    expect(root.needsCompositing, isTrue);

    root.elevation = 0.0;
    pumpFrame(phase: EnginePhase.composite);
    expect(root.needsCompositing, isTrue);

    debugDefaultTargetPlatformOverride = null;
  });

  test('RenderPhysicalModel compositing on non-Fuchsia', () {
    for (final TargetPlatform platform in TargetPlatform.values) {
      if (platform == TargetPlatform.fuchsia) {
        continue;
      }
      debugDefaultTargetPlatformOverride = platform;

      final RenderPhysicalModel root = RenderPhysicalModel(color: const Color(0xffff00ff));
      layout(root, phase: EnginePhase.composite);
      expect(root.needsCompositing, isTrue);

      // Flutter now composites physical shapes on all platforms.
      root.elevation = 1.0;
      pumpFrame(phase: EnginePhase.composite);
      expect(root.needsCompositing, isTrue);

      root.elevation = 0.0;
      pumpFrame(phase: EnginePhase.composite);
      expect(root.needsCompositing, isTrue);
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('RenderSemanticsGestureHandler adds/removes correct semantic actions', () {
    final RenderSemanticsGestureHandler renderObj = RenderSemanticsGestureHandler(
      onTap: () { },
      onHorizontalDragUpdate: (DragUpdateDetails details) { },
    );

    SemanticsConfiguration config = SemanticsConfiguration();
    renderObj.describeSemanticsConfiguration(config);
    expect(config.getActionHandler(SemanticsAction.tap), isNotNull);
    expect(config.getActionHandler(SemanticsAction.scrollLeft), isNotNull);
    expect(config.getActionHandler(SemanticsAction.scrollRight), isNotNull);

    config = SemanticsConfiguration();
    renderObj.validActions = <SemanticsAction>{SemanticsAction.tap, SemanticsAction.scrollLeft};

    renderObj.describeSemanticsConfiguration(config);
    expect(config.getActionHandler(SemanticsAction.tap), isNotNull);
    expect(config.getActionHandler(SemanticsAction.scrollLeft), isNotNull);
    expect(config.getActionHandler(SemanticsAction.scrollRight), isNull);
  });

  group('RenderPhysicalShape', () {
    test('shape change triggers repaint', () {
      for (final TargetPlatform platform in TargetPlatform.values) {
        if (platform == TargetPlatform.fuchsia) {
          continue;
        }
        debugDefaultTargetPlatformOverride = platform;

        final RenderPhysicalShape root = RenderPhysicalShape(
          color: const Color(0xffff00ff),
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
        );
        layout(root, phase: EnginePhase.composite);
        expect(root.debugNeedsPaint, isFalse);

        // Same shape, no repaint.
        root.clipper = const ShapeBorderClipper(shape: CircleBorder());
        expect(root.debugNeedsPaint, isFalse);

        // Different shape triggers repaint.
        root.clipper = const ShapeBorderClipper(shape: StadiumBorder());
        expect(root.debugNeedsPaint, isTrue);
      }
      debugDefaultTargetPlatformOverride = null;
    });

    test('compositing on non-Fuchsia', () {
      for (final TargetPlatform platform in TargetPlatform.values) {
        if (platform == TargetPlatform.fuchsia) {
          continue;
        }
        debugDefaultTargetPlatformOverride = platform;
        final RenderPhysicalShape root = RenderPhysicalShape(
          color: const Color(0xffff00ff),
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
        );
        layout(root, phase: EnginePhase.composite);
        expect(root.needsCompositing, isTrue);

        // On non-Fuchsia platforms, we composite physical shape layers
        root.elevation = 1.0;
        pumpFrame(phase: EnginePhase.composite);
        expect(root.needsCompositing, isTrue);

        root.elevation = 0.0;
        pumpFrame(phase: EnginePhase.composite);
        expect(root.needsCompositing, isTrue);
      }
      debugDefaultTargetPlatformOverride = null;
    });
  });

  test('RenderRepaintBoundary can capture images of itself', () async {
    RenderRepaintBoundary boundary = RenderRepaintBoundary();
    layout(boundary, constraints: BoxConstraints.tight(const Size(100.0, 200.0)));
    pumpFrame(phase: EnginePhase.composite);
    ui.Image image = await boundary.toImage();
    expect(image.width, equals(100));
    expect(image.height, equals(200));

    // Now with pixel ratio set to something other than 1.0.
    boundary = RenderRepaintBoundary();
    layout(boundary, constraints: BoxConstraints.tight(const Size(100.0, 200.0)));
    pumpFrame(phase: EnginePhase.composite);
    image = await boundary.toImage(pixelRatio: 2.0);
    expect(image.width, equals(200));
    expect(image.height, equals(400));

    // Try building one with two child layers and make sure it renders them both.
    boundary = RenderRepaintBoundary();
    final RenderStack stack = RenderStack()..alignment = Alignment.topLeft;
    final RenderDecoratedBox blackBox = RenderDecoratedBox(
      decoration: const BoxDecoration(color: Color(0xff000000)),
      child: RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size.square(20.0)),
      ),
    );
    stack.add(
      RenderOpacity()
        ..opacity = 0.5
        ..child = blackBox,
    );
    final RenderDecoratedBox whiteBox = RenderDecoratedBox(
      decoration: const BoxDecoration(color: Color(0xffffffff)),
      child: RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size.square(10.0)),
      ),
    );
    final RenderPositionedBox positioned = RenderPositionedBox(
      widthFactor: 2.0,
      heightFactor: 2.0,
      alignment: Alignment.topRight,
      child: whiteBox,
    );
    stack.add(positioned);
    boundary.child = stack;
    layout(boundary, constraints: BoxConstraints.tight(const Size(20.0, 20.0)));
    pumpFrame(phase: EnginePhase.composite);
    image = await boundary.toImage();
    expect(image.width, equals(20));
    expect(image.height, equals(20));
    ByteData data = (await image.toByteData())!;

    int getPixel(int x, int y) => data.getUint32((x + y * image.width) * 4);

    expect(data.lengthInBytes, equals(20 * 20 * 4));
    expect(data.elementSizeInBytes, equals(1));
    expect(getPixel(0, 0), equals(0x00000080));
    expect(getPixel(image.width - 1, 0 ), equals(0xffffffff));

    final OffsetLayer layer = boundary.debugLayer! as OffsetLayer;

    image = await layer.toImage(Offset.zero & const Size(20.0, 20.0));
    expect(image.width, equals(20));
    expect(image.height, equals(20));
    data = (await image.toByteData())!;
    expect(getPixel(0, 0), equals(0x00000080));
    expect(getPixel(image.width - 1, 0 ), equals(0xffffffff));

    // non-zero offsets.
    image = await layer.toImage(const Offset(-10.0, -10.0) & const Size(30.0, 30.0));
    expect(image.width, equals(30));
    expect(image.height, equals(30));
    data = (await image.toByteData())!;
    expect(getPixel(0, 0), equals(0x00000000));
    expect(getPixel(10, 10), equals(0x00000080));
    expect(getPixel(image.width - 1, 0), equals(0x00000000));
    expect(getPixel(image.width - 1, 10), equals(0xffffffff));

    // offset combined with a custom pixel ratio.
    image = await layer.toImage(const Offset(-10.0, -10.0) & const Size(30.0, 30.0), pixelRatio: 2.0);
    expect(image.width, equals(60));
    expect(image.height, equals(60));
    data = (await image.toByteData())!;
    expect(getPixel(0, 0), equals(0x00000000));
    expect(getPixel(20, 20), equals(0x00000080));
    expect(getPixel(image.width - 1, 0), equals(0x00000000));
    expect(getPixel(image.width - 1, 20), equals(0xffffffff));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/49857

  test('RenderOpacity does not composite if it is transparent', () {
    final RenderOpacity renderOpacity = RenderOpacity(
      opacity: 0.0,
      child: RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    );

    layout(renderOpacity, phase: EnginePhase.composite);
    expect(renderOpacity.needsCompositing, false);
  });

  test('RenderOpacity does composite if it is opaque', () {
    final RenderOpacity renderOpacity = RenderOpacity(
      child: RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    );

    layout(renderOpacity, phase: EnginePhase.composite);
    expect(renderOpacity.needsCompositing, true);
  });

  test('RenderOpacity reuses its layer', () {
    _testLayerReuse<OpacityLayer>(RenderOpacity(
      opacity: 0.5,  // must not be 0 or 1.0. Otherwise, it won't create a layer
      child: RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    ));
  });

  test('RenderAnimatedOpacity does not composite if it is transparent', () async {
    final Animation<double> opacityAnimation = AnimationController(
      vsync: FakeTickerProvider(),
    )..value = 0.0;

    final RenderAnimatedOpacity renderAnimatedOpacity = RenderAnimatedOpacity(
      opacity: opacityAnimation,
      child: RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    );

    layout(renderAnimatedOpacity, phase: EnginePhase.composite);
    expect(renderAnimatedOpacity.needsCompositing, false);
  });

  test('RenderAnimatedOpacity does composite if it is opaque', () {
    final Animation<double> opacityAnimation = AnimationController(
      vsync: FakeTickerProvider(),
    )..value = 1.0;

    final RenderAnimatedOpacity renderAnimatedOpacity = RenderAnimatedOpacity(
      opacity: opacityAnimation,
      child: RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    );

    layout(renderAnimatedOpacity, phase: EnginePhase.composite);
    expect(renderAnimatedOpacity.needsCompositing, true);
  });

  test('RenderAnimatedOpacity reuses its layer', () {
    final Animation<double> opacityAnimation = AnimationController(
      vsync: FakeTickerProvider(),
    )..value = 0.5;  // must not be 0 or 1.0. Otherwise, it won't create a layer

    _testLayerReuse<OpacityLayer>(RenderAnimatedOpacity(
      opacity: opacityAnimation,
      child: RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    ));
  });

  test('RenderShaderMask reuses its layer', () {
    _testLayerReuse<ShaderMaskLayer>(RenderShaderMask(
      shaderCallback: (Rect rect) {
        return ui.Gradient.radial(
          rect.center,
          rect.shortestSide / 2.0,
          const <Color>[Color.fromRGBO(0, 0, 0, 1.0), Color.fromRGBO(255, 255, 255, 1.0)],
        );
      },
      child: RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    ));
  });

  test('RenderBackdropFilter reuses its layer', () {
    _testLayerReuse<BackdropFilterLayer>(RenderBackdropFilter(
      filter: ui.ImageFilter.blur(),
      child: RenderSizedBox(const Size(1.0, 1.0)), // size doesn't matter
    ));
  });

  test('RenderClipRect reuses its layer', () {
    _testLayerReuse<ClipRectLayer>(RenderClipRect(
      clipper: _TestRectClipper(),
      // Inject opacity under the clip to force compositing.
      child: RenderOpacity(
        opacity: 0.5,
        child: RenderSizedBox(const Size(1.0, 1.0)),
      ), // size doesn't matter
    ));
  });

  test('RenderClipRRect reuses its layer', () {
    _testLayerReuse<ClipRRectLayer>(RenderClipRRect(
      clipper: _TestRRectClipper(),
      // Inject opacity under the clip to force compositing.
      child: RenderOpacity(
        opacity: 0.5,
        child: RenderSizedBox(const Size(1.0, 1.0)),
      ), // size doesn't matter
    ));
  });

  test('RenderClipOval reuses its layer', () {
    _testLayerReuse<ClipPathLayer>(RenderClipOval(
      clipper: _TestRectClipper(),
      // Inject opacity under the clip to force compositing.
      child: RenderOpacity(
        opacity: 0.5,
        child: RenderSizedBox(const Size(1.0, 1.0)),
      ), // size doesn't matter
    ));
  });

  test('RenderClipPath reuses its layer', () {
    _testLayerReuse<ClipPathLayer>(RenderClipPath(
      clipper: _TestPathClipper(),
      // Inject opacity under the clip to force compositing.
      child: RenderOpacity(
        opacity: 0.5,
        child: RenderSizedBox(const Size(1.0, 1.0)),
      ), // size doesn't matter
    ));
  });

  test('RenderPhysicalModel reuses its layer', () {
    _testLayerReuse<PhysicalModelLayer>(RenderPhysicalModel(
      color: const Color.fromRGBO(0, 0, 0, 1.0),
      // Inject opacity under the clip to force compositing.
      child: RenderOpacity(
        opacity: 0.5,
        child: RenderSizedBox(const Size(1.0, 1.0)),
      ), // size doesn't matter
    ));
  });

  test('RenderPhysicalShape reuses its layer', () {
    _testLayerReuse<PhysicalModelLayer>(RenderPhysicalShape(
      clipper: _TestPathClipper(),
      color: const Color.fromRGBO(0, 0, 0, 1.0),
      // Inject opacity under the clip to force compositing.
      child: RenderOpacity(
        opacity: 0.5,
        child: RenderSizedBox(const Size(1.0, 1.0)),
      ), // size doesn't matter
    ));
  });

  test('RenderTransform reuses its layer', () {
    _testLayerReuse<TransformLayer>(RenderTransform(
      // Use a 3D transform to force compositing.
      transform: Matrix4.rotationX(0.1),
      // Inject opacity under the clip to force compositing.
      child: RenderOpacity(
        opacity: 0.5,
        child: RenderSizedBox(const Size(1.0, 1.0)),
      ), // size doesn't matter
    ));
  });

  void _testFittedBoxWithClipRectLayer() {
    _testLayerReuse<ClipRectLayer>(RenderFittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      // Inject opacity under the clip to force compositing.
      child: RenderOpacity(
        opacity: 0.5,
        child: RenderSizedBox(const Size(100.0, 200.0)),
      ), // size doesn't matter
    ));
  }

  void _testFittedBoxWithTransformLayer() {
    _testLayerReuse<TransformLayer>(RenderFittedBox(
      fit: BoxFit.fill,
      // Inject opacity under the clip to force compositing.
      child: RenderOpacity(
        opacity: 0.5,
        child: RenderSizedBox(const Size(1, 1)),
      ), // size doesn't matter
    ));
  }

  test('RenderFittedBox reuses ClipRectLayer', () {
    _testFittedBoxWithClipRectLayer();
  });

  test('RenderFittedBox reuses TransformLayer', () {
    _testFittedBoxWithTransformLayer();
  });

  test('RenderFittedBox switches between ClipRectLayer and TransformLayer, and reuses them', () {
    _testFittedBoxWithClipRectLayer();

    // clip -> transform
    _testFittedBoxWithTransformLayer();
    // transform -> clip
    _testFittedBoxWithClipRectLayer();
  });

  test('RenderFittedBox respects clipBehavior', () {
    const BoxConstraints viewport = BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    final TestClipPaintingContext context = TestClipPaintingContext();

    // By default, clipBehavior should be Clip.none
    final RenderFittedBox defaultBox = RenderFittedBox(child: box200x200, fit: BoxFit.none);
    layout(defaultBox, constraints: viewport, phase: EnginePhase.composite, onErrors: expectOverflowedErrors);
    defaultBox.paint(context, Offset.zero);
    expect(context.clipBehavior, equals(Clip.none));

    for (final Clip clip in Clip.values) {
      final RenderFittedBox box = RenderFittedBox(child: box200x200, fit: BoxFit.none, clipBehavior: clip);
      layout(box, constraints: viewport, phase: EnginePhase.composite, onErrors: expectOverflowedErrors);
      box.paint(context, Offset.zero);
      expect(context.clipBehavior, equals(clip));
    }
  });

  test('RenderMouseRegion can change properties when detached', () {
    final RenderMouseRegion object = RenderMouseRegion();
    object
      ..opaque = false
      ..onEnter = (_) {}
      ..onExit = (_) {}
      ..onHover = (_) {};
    // Passes if no error is thrown
  });

  test('RenderFractionalTranslation updates its semantics after its translation value is set', () {
    final _TestSemanticsUpdateRenderFractionalTranslation box = _TestSemanticsUpdateRenderFractionalTranslation(
      translation: const Offset(0.5, 0.5),
    );
    layout(box, constraints: BoxConstraints.tight(const Size(200.0, 200.0)));
    expect(box.markNeedsSemanticsUpdateCallCount, 1);
    box.translation = const Offset(0.4, 0.4);
    expect(box.markNeedsSemanticsUpdateCallCount, 2);
    box.translation = const Offset(0.3, 0.3);
    expect(box.markNeedsSemanticsUpdateCallCount, 3);
  });

  test('RenderFollowerLayer hit test without a leader layer and the showWhenUnlinked is true', () {
    final RenderFollowerLayer follower = RenderFollowerLayer(
      link: LayerLink(),
      child: RenderSizedBox(const Size(1.0, 1.0)),
    );
    layout(follower, constraints: BoxConstraints.tight(const Size(200.0, 200.0)));
    final BoxHitTestResult hitTestResult = BoxHitTestResult();
    expect(follower.hitTest(hitTestResult, position: Offset.zero), isTrue);
  });

  test('RenderFollowerLayer hit test without a leader layer and the showWhenUnlinked is false', () {
    final RenderFollowerLayer follower = RenderFollowerLayer(
      link: LayerLink(),
      showWhenUnlinked: false,
      child: RenderSizedBox(const Size(1.0, 1.0)),
    );
    layout(follower, constraints: BoxConstraints.tight(const Size(200.0, 200.0)));
    final BoxHitTestResult hitTestResult = BoxHitTestResult();
    expect(follower.hitTest(hitTestResult, position: Offset.zero), isFalse);
  });

  test('RenderFollowerLayer hit test with a leader layer and the showWhenUnlinked is true', () {
    // Creates a layer link with a leader.
    final LayerLink link = LayerLink();
    final LeaderLayer leader = LeaderLayer(link: link);
    leader.attach(Object());

    final RenderFollowerLayer follower = RenderFollowerLayer(
      link: link,
      child: RenderSizedBox(const Size(1.0, 1.0)),
    );
    layout(follower, constraints: BoxConstraints.tight(const Size(200.0, 200.0)));
    final BoxHitTestResult hitTestResult = BoxHitTestResult();
    expect(follower.hitTest(hitTestResult, position: Offset.zero), isTrue);
  });

  test('RenderFollowerLayer hit test with a leader layer and the showWhenUnlinked is false', () {
    // Creates a layer link with a leader.
    final LayerLink link = LayerLink();
    final LeaderLayer leader = LeaderLayer(link: link);
    leader.attach(Object());

    final RenderFollowerLayer follower = RenderFollowerLayer(
      link: link,
      showWhenUnlinked: false,
      child: RenderSizedBox(const Size(1.0, 1.0)),
    );
    layout(follower, constraints: BoxConstraints.tight(const Size(200.0, 200.0)));
    final BoxHitTestResult hitTestResult = BoxHitTestResult();
    // The follower is still hit testable because there is a leader layer.
    expect(follower.hitTest(hitTestResult, position: Offset.zero), isTrue);
  });
}

class _TestRectClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.zero;
  }

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldReclip(_TestRectClipper oldClipper) => true;
}

class _TestRRectClipper extends CustomClipper<RRect> {
  @override
  RRect getClip(Size size) {
    return RRect.zero;
  }

  @override
  Rect getApproximateClipRect(Size size) => getClip(size).outerRect;

  @override
  bool shouldReclip(_TestRRectClipper oldClipper) => true;
}

// Forces two frames and checks that:
// - a layer is created on the first frame
// - the layer is reused on the second frame
void _testLayerReuse<L extends Layer>(RenderBox renderObject) {
  expect(L, isNot(Layer));
  expect(renderObject.debugLayer, null);
  layout(renderObject, phase: EnginePhase.paint, constraints: BoxConstraints.tight(const Size(10, 10)));
  final Layer layer = renderObject.debugLayer!;
  expect(layer, isA<L>());
  expect(layer, isNotNull);

  // Mark for repaint otherwise pumpFrame is a noop.
  renderObject.markNeedsPaint();
  expect(renderObject.debugNeedsPaint, true);
  pumpFrame(phase: EnginePhase.paint);
  expect(renderObject.debugNeedsPaint, false);
  expect(renderObject.debugLayer, same(layer));
}

class _TestPathClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(const Rect.fromLTWH(50.0, 50.0, 100.0, 100.0));
  }
  @override
  bool shouldReclip(_TestPathClipper oldClipper) => false;
}

class _TestSemanticsUpdateRenderFractionalTranslation extends RenderFractionalTranslation {
  _TestSemanticsUpdateRenderFractionalTranslation({
    required Offset translation,
    RenderBox? child,
  }) : super(translation: translation, child: child);

  int markNeedsSemanticsUpdateCallCount = 0;

  @override
  void markNeedsSemanticsUpdate() {
    markNeedsSemanticsUpdateCallCount++;
    super.markNeedsSemanticsUpdate();
  }
}
