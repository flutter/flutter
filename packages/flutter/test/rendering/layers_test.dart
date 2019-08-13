// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('non-painted layers are detached', () {
    RenderObject boundary, inner;
    final RenderOpacity root = RenderOpacity(
      child: boundary = RenderRepaintBoundary(
        child: inner = RenderDecoratedBox(
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

  test('layer subtree dirtiness is correctly computed', () {
    final ContainerLayer a = ContainerLayer();
    final ContainerLayer b = ContainerLayer();
    final ContainerLayer c = ContainerLayer();
    final ContainerLayer d = ContainerLayer();
    final ContainerLayer e = ContainerLayer();
    final ContainerLayer f = ContainerLayer();
    final ContainerLayer g = ContainerLayer();

    final PictureLayer h = PictureLayer(Rect.zero);
    final PictureLayer i = PictureLayer(Rect.zero);
    final PictureLayer j = PictureLayer(Rect.zero);

    // The tree is like the following where b and j are dirty:
    //        a____
    //       /     \
    //   (x)b___    c
    //     / \  \   |
    //    d   e  f  g
    //   / \        |
    //  h   i       j(x)
    a.append(b);
    a.append(c);
    b.append(d);
    b.append(e);
    b.append(f);
    d.append(h);
    d.append(i);
    c.append(g);
    g.append(j);

    a.debugMarkClean();
    b.markNeedsAddToScene();
    c.debugMarkClean();
    d.debugMarkClean();
    e.debugMarkClean();
    f.debugMarkClean();
    g.debugMarkClean();
    h.debugMarkClean();
    i.debugMarkClean();
    j.markNeedsAddToScene();

    a.updateSubtreeNeedsAddToScene();

    expect(a.debugSubtreeNeedsAddToScene, true);
    expect(b.debugSubtreeNeedsAddToScene, true);
    expect(c.debugSubtreeNeedsAddToScene, true);
    expect(g.debugSubtreeNeedsAddToScene, true);
    expect(j.debugSubtreeNeedsAddToScene, true);

    expect(d.debugSubtreeNeedsAddToScene, false);
    expect(e.debugSubtreeNeedsAddToScene, false);
    expect(f.debugSubtreeNeedsAddToScene, false);
    expect(h.debugSubtreeNeedsAddToScene, false);
    expect(i.debugSubtreeNeedsAddToScene, false);
  });

  test('leader and follower layers are always dirty', () {
    final LayerLink link = LayerLink();
    final LeaderLayer leaderLayer = LeaderLayer(link: link);
    final FollowerLayer followerLayer = FollowerLayer(link: link);
    leaderLayer.debugMarkClean();
    followerLayer.debugMarkClean();
    leaderLayer.updateSubtreeNeedsAddToScene();
    followerLayer.updateSubtreeNeedsAddToScene();
    expect(leaderLayer.debugSubtreeNeedsAddToScene, true);
    expect(followerLayer.debugSubtreeNeedsAddToScene, true);
  });

  test('depthFirstIterateChildren', () {
    final ContainerLayer a = ContainerLayer();
    final ContainerLayer b = ContainerLayer();
    final ContainerLayer c = ContainerLayer();
    final ContainerLayer d = ContainerLayer();
    final ContainerLayer e = ContainerLayer();
    final ContainerLayer f = ContainerLayer();
    final ContainerLayer g = ContainerLayer();

    final PictureLayer h = PictureLayer(Rect.zero);
    final PictureLayer i = PictureLayer(Rect.zero);
    final PictureLayer j = PictureLayer(Rect.zero);

    // The tree is like the following:
    //        a____
    //       /     \
    //      b___    c
    //     / \  \   |
    //    d   e  f  g
    //   / \        |
    //  h   i       j
    a.append(b);
    a.append(c);
    b.append(d);
    b.append(e);
    b.append(f);
    d.append(h);
    d.append(i);
    c.append(g);
    g.append(j);

    expect(
      a.depthFirstIterateChildren(),
      <Layer>[b, d, h, i, e, f, c, g, j],
    );

    d.remove();
    //        a____
    //       /     \
    //      b___    c
    //       \  \   |
    //        e  f  g
    //              |
    //              j
    expect(
      a.depthFirstIterateChildren(),
      <Layer>[b, e, f, c, g, j],
    );
  });

  void checkNeedsAddToScene(Layer layer, void mutateCallback()) {
    layer.debugMarkClean();
    layer.updateSubtreeNeedsAddToScene();
    expect(layer.debugSubtreeNeedsAddToScene, false);
    mutateCallback();
    layer.updateSubtreeNeedsAddToScene();
    expect(layer.debugSubtreeNeedsAddToScene, true);
  }

  test('mutating PictureLayer fields triggers needsAddToScene', () {
    final PictureLayer pictureLayer = PictureLayer(Rect.zero);
    checkNeedsAddToScene(pictureLayer, () {
      final PictureRecorder recorder = PictureRecorder();
      pictureLayer.picture = recorder.endRecording();
    });

    pictureLayer.isComplexHint = false;
    checkNeedsAddToScene(pictureLayer, () {
      pictureLayer.isComplexHint = true;
    });

    pictureLayer.willChangeHint = false;
    checkNeedsAddToScene(pictureLayer, () {
      pictureLayer.willChangeHint = true;
    });
  });

  const Rect unitRect = Rect.fromLTRB(0, 0, 1, 1);

  test('mutating PerformanceOverlayLayer fields triggers needsAddToScene', () {
    final PerformanceOverlayLayer layer = PerformanceOverlayLayer(
        overlayRect: Rect.zero, optionsMask: 0, rasterizerThreshold: 0,
        checkerboardRasterCacheImages: false, checkerboardOffscreenLayers: false);
    checkNeedsAddToScene(layer, () {
      layer.overlayRect = unitRect;
    });
  });

  test('mutating OffsetLayer fields triggers needsAddToScene', () {
    final OffsetLayer layer = OffsetLayer();
    checkNeedsAddToScene(layer, () {
      layer.offset = const Offset(1, 1);
    });
  });

  test('mutating ClipRectLayer fields triggers needsAddToScene', () {
    final ClipRectLayer layer = ClipRectLayer(clipRect: Rect.zero);
    checkNeedsAddToScene(layer, () {
      layer.clipRect = unitRect;
    });
    checkNeedsAddToScene(layer, () {
      layer.clipBehavior = Clip.antiAliasWithSaveLayer;
    });
  });

  test('mutating ClipRRectLayer fields triggers needsAddToScene', () {
    final ClipRRectLayer layer = ClipRRectLayer(clipRRect: RRect.zero);
    checkNeedsAddToScene(layer, () {
      layer.clipRRect = RRect.fromRectAndRadius(unitRect, const Radius.circular(0));
    });
    checkNeedsAddToScene(layer, () {
      layer.clipBehavior = Clip.antiAliasWithSaveLayer;
    });
  });

  test('mutating ClipPath fields triggers needsAddToScene', () {
    final ClipPathLayer layer = ClipPathLayer(clipPath: Path());
    checkNeedsAddToScene(layer, () {
      final Path newPath = Path();
      newPath.addRect(unitRect);
      layer.clipPath = newPath;
    });
    checkNeedsAddToScene(layer, () {
      layer.clipBehavior = Clip.antiAliasWithSaveLayer;
    });
  });

  test('mutating OpacityLayer fields triggers needsAddToScene', () {
    final OpacityLayer layer = OpacityLayer(alpha: 0);
    checkNeedsAddToScene(layer, () {
      layer.alpha = 1;
    });
    checkNeedsAddToScene(layer, () {
      layer.offset = const Offset(1, 1);
    });
  });

  test('mutating ColorFilterLayer fields triggers needsAddToScene', () {
    final ColorFilterLayer layer = ColorFilterLayer(
      colorFilter: const ColorFilter.mode(Color(0xFFFF0000), BlendMode.color),
    );
    checkNeedsAddToScene(layer, () {
      layer.colorFilter = const ColorFilter.mode(Color(0xFF00FF00), BlendMode.color);
    });
  });

  test('mutating ShaderMaskLayer fields triggers needsAddToScene', () {
    const Gradient gradient = RadialGradient(colors: <Color>[Color(0x00000000), Color(0x00000001)]);
    final Shader shader = gradient.createShader(Rect.zero);
    final ShaderMaskLayer layer = ShaderMaskLayer(shader: shader, maskRect: Rect.zero, blendMode: BlendMode.clear);
    checkNeedsAddToScene(layer, () {
      layer.maskRect = unitRect;
    });
    checkNeedsAddToScene(layer, () {
      layer.blendMode = BlendMode.color;
    });
    checkNeedsAddToScene(layer, () {
      layer.shader = gradient.createShader(unitRect);
    });
  });

  test('mutating BackdropFilterLayer fields triggers needsAddToScene', () {
    final BackdropFilterLayer layer = BackdropFilterLayer(filter: ImageFilter.blur());
    checkNeedsAddToScene(layer, () {
      layer.filter = ImageFilter.blur(sigmaX: 1.0);
    });
  });

  test('mutating PhysicalModelLayer fields triggers needsAddToScene', () {
    final PhysicalModelLayer layer = PhysicalModelLayer(
        clipPath: Path(), elevation: 0, color: const Color(0x00000000), shadowColor: const Color(0x00000000));
    checkNeedsAddToScene(layer, () {
      final Path newPath = Path();
      newPath.addRect(unitRect);
      layer.clipPath = newPath;
    });
    checkNeedsAddToScene(layer, () {
      layer.elevation = 1;
    });
    checkNeedsAddToScene(layer, () {
      layer.color = const Color(0x00000001);
    });
    checkNeedsAddToScene(layer, () {
      layer.shadowColor = const Color(0x00000001);
    });
  });

  group('PhysicalModelLayer checks elevations', () {
    /// Adds the layers to a container where A paints before B.
    ///
    /// Expects there to be `expectedErrorCount` errors.  Checking elevations is
    /// enabled by default.
    void _testConflicts(
      PhysicalModelLayer layerA,
      PhysicalModelLayer layerB, {
      @required int expectedErrorCount,
      bool enableCheck = true,
    }) {
      assert(expectedErrorCount != null);
      assert(enableCheck || expectedErrorCount == 0, 'Cannot disable check and expect non-zero error count.');
      final OffsetLayer container = OffsetLayer();
      container.append(layerA);
      container.append(layerB);
      debugCheckElevationsEnabled = enableCheck;
      debugDisableShadows = false;
      int errors = 0;
      if (enableCheck) {
        FlutterError.onError = (FlutterErrorDetails details) {
          errors++;
        };
      }
      container.buildScene(SceneBuilder());
      expect(errors, expectedErrorCount);
      debugCheckElevationsEnabled = false;
    }

    // Tests:
    //
    //  ─────────────                    (LayerA, paints first)
    //      │     ─────────────          (LayerB, paints second)
    //      │          │
    // ───────────────────────────
    test('Overlapping layers at wrong elevation', () {
      final PhysicalModelLayer layerA = PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(0, 0, 20, 20)),
        elevation: 3.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      );
      final PhysicalModelLayer layerB =PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(10, 10, 20, 20)),
        elevation: 2.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      );
      _testConflicts(layerA, layerB, expectedErrorCount: 1);
    });

    // Tests:
    //
    //  ─────────────                    (LayerA, paints first)
    //      │     ─────────────          (LayerB, paints second)
    //      │         │
    // ───────────────────────────
    //
    // Causes no error if check is disabled.
    test('Overlapping layers at wrong elevation, check disabled', () {
      final PhysicalModelLayer layerA = PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(0, 0, 20, 20)),
        elevation: 3.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      );
      final PhysicalModelLayer layerB =PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(10, 10, 20, 20)),
        elevation: 2.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      );
      _testConflicts(layerA, layerB, expectedErrorCount: 0, enableCheck: false);
    });

    // Tests:
    //
    //   ──────────                      (LayerA, paints first)
    //        │       ───────────        (LayerB, paints second)
    //        │            │
    // ────────────────────────────
    test('Non-overlapping layers at wrong elevation', () {
      final PhysicalModelLayer layerA = PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(0, 0, 20, 20)),
        elevation: 3.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      );
      final PhysicalModelLayer layerB =PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(20, 20, 20, 20)),
        elevation: 2.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      );
      _testConflicts(layerA, layerB, expectedErrorCount: 0);
    });

    // Tests:
    //
    //     ───────                       (Child of A, paints second)
    //        │
    //   ───────────                     (LayerA, paints first)
    //        │       ────────────       (LayerB, paints third)
    //        │             │
    // ────────────────────────────
    test('Non-overlapping layers at wrong elevation, child at lower elevation', () {
      final PhysicalModelLayer layerA = PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(0, 0, 20, 20)),
        elevation: 3.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      );

      layerA.append(PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(2, 2, 10, 10)),
        elevation: 1.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      ));

      final PhysicalModelLayer layerB =PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(20, 20, 20, 20)),
        elevation: 2.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      );
      _testConflicts(layerA, layerB, expectedErrorCount: 0);
    });

    // Tests:
    //
    //        ───────────                (Child of A, paints second, overflows)
    //           │    ────────────       (LayerB, paints third)
    //   ───────────       │             (LayerA, paints first)
    //         │           │
    //         │           │
    // ────────────────────────────
    //
    // Which fails because the overflowing child overlaps something that paints
    // after it at a lower elevation.
    test('Child overflows parent and overlaps another physical layer', () {
      final PhysicalModelLayer layerA = PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(0, 0, 20, 20)),
        elevation: 3.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      );

      layerA.append(PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(15, 15, 25, 25)),
        elevation: 2.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      ));

      final PhysicalModelLayer layerB =PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(20, 20, 20, 20)),
        elevation: 4.0,
        color: const Color(0x00000000),
        shadowColor: const Color(0x00000000),
      );

      _testConflicts(layerA, layerB, expectedErrorCount: 1);
    });
  }, skip: isBrowser);

  test('OffsetLayer.hitTest respects offset (positive)', () {
    // The target position would have fallen outside of child1 without the
    // offset of root.
    const Offset position = Offset(-5, 5);

    final ContainerLayer root = OffsetLayer(offset: const Offset(-10, 0));
    final Layer child1 = AnnotatedRegionLayer<int>(
      1, size: const Size(10, 10), opaque: true);
    root.append(child1);

    final List<int> result = <int>[];
    final bool absorbed = root.hitTest(result, regionOffset: position);
    expect(absorbed, isTrue);
    expect(result, <int>[1]);
  });

  test('OffsetLayer.hitTest respects offset (negative)', () {
    // The target position would have fallen inside of child1 without the
    // offset of root.
    const Offset position = Offset(5, 5);

    final ContainerLayer root = OffsetLayer(offset: const Offset(-10, 0));
    final Layer child1 = AnnotatedRegionLayer<int>(
      1, size: const Size(10, 10), opaque: true);
    root.append(child1);

    final List<int> result = <int>[];
    final bool absorbed = root.hitTest(result, regionOffset: position);
    expect(absorbed, isFalse);
    expect(result, <int>[]);
  });

  test('AnnotatedRegionLayer.hitTest should return its descendents\' value froms front to back', () {

    // Tests:
    //
    //     o            (child21)
    //     │
    //     o            (child2)
    //     |   o        (child11)
    //     |   |
    //     |   o        (child1)
    //      \ /
    //       o          (root)

    final ContainerLayer root = AnnotatedRegionLayer<int>(0);
    final ContainerLayer child1 = AnnotatedRegionLayer<int>(1);
    root.append(child1);
    final ContainerLayer child2 = AnnotatedRegionLayer<int>(2);
    root.append(child2);

    final ContainerLayer child11 = AnnotatedRegionLayer<int>(11);
    child1.append(child11);
    final ContainerLayer child21 = AnnotatedRegionLayer<int>(21);
    child2.append(child21);

    final List<int> result = <int>[];
    final bool absorbed = root.hitTest(result, regionOffset: Offset.zero);
    expect(absorbed, isFalse);
    expect(result, <int>[21, 2, 11, 1, 0]);
  });

  test('AnnotatedRegionLayer.hitTest should only add to the list when type matches', () {

    // Tests:
    //
    //     .            (child21, double)
    //     │
    //     o            (child2, int)
    //     |   o        (child11, int)
    //     |   |
    //     |   .        (child1, double)
    //      \ /
    //       .          (root, double)

    final ContainerLayer root = AnnotatedRegionLayer<double>(0);
    final ContainerLayer child1 = AnnotatedRegionLayer<double>(1);
    root.append(child1);
    final ContainerLayer child2 = AnnotatedRegionLayer<int>(2);
    root.append(child2);

    final ContainerLayer child11 = AnnotatedRegionLayer<int>(11);
    child1.append(child11);
    final ContainerLayer child21 = AnnotatedRegionLayer<double>(21);
    child2.append(child21);

    final List<int> result = <int>[];
    final bool absorbed = root.hitTest(result, regionOffset: Offset.zero);
    expect(absorbed, isFalse);
    expect(result, <int>[2, 11]);
  });

  test('AnnotatedRegionLayer.hitTest should respect size and offset, '
    'and always allow children to add to the result', () {

    // Tests:
    //           v
    //    ──────────              (child21, contains despite being child)
    //     │
    //    ────                    (child2, fails because of size)
    //     |    ────────          (child11, contains)
    //     |         |
    //     |    ────────          (child1, contains)
    //     │         │
    //    ──────────────          (root)

    const Offset position = Offset(50, 5);

    final ContainerLayer root = AnnotatedRegionLayer<int>(
      0, size: const Size(100, 10));
    final ContainerLayer child1 = AnnotatedRegionLayer<int>(
      1, size: const Size(60, 10), offset: const Offset(40, 0));
    root.append(child1);
    final ContainerLayer child2 = AnnotatedRegionLayer<int>(
      2, size: const Size(30, 10));
    root.append(child2);

    final ContainerLayer child11 = AnnotatedRegionLayer<int>(
      11, size: const Size(60, 10), offset: const Offset(40, 0));
    child1.append(child11);
    final ContainerLayer child21 = AnnotatedRegionLayer<int>(
      21, size: const Size(60, 10));
    child2.append(child21);

    final List<int> result = <int>[];
    final bool absorbed = root.hitTest(result, regionOffset: position);
    expect(absorbed, isFalse);
    expect(result, <int>[21, 11, 1, 0]);
  });

  test('AnnotatedRegionLayer.hitTest when opaque should stop at the first child '
    'that absorbs, then return true', () {

    // Tests:
    //
    //     o            (child3, translucent)
    //     | x          (child2, opaque)
    //     | | o        (child1)
    //      \|/
    //       x          (root, opaque)

    final ContainerLayer root = AnnotatedRegionLayer<int>(0, opaque: true);
    final ContainerLayer child1 = AnnotatedRegionLayer<int>(1);
    root.append(child1);
    final ContainerLayer child2 = AnnotatedRegionLayer<int>(2, opaque: true);
    root.append(child2);
    final ContainerLayer child3 = AnnotatedRegionLayer<int>(3);
    root.append(child3);

    final List<int> result = <int>[];
    final bool absorbed = root.hitTest(result, regionOffset: Offset.zero);
    expect(absorbed, isTrue);
    expect(result, <int>[3, 2, 0]);
  });

  test('AnnotatedRegionLayer.hitTest when translucent should stop at the first '
    'that absorbs, then return false', () {

    // Tests:
    //
    //     o            (child3, translucent)
    //     | x          (child2, opaque)
    //     | | o        (child1)
    //      \|/
    //       o          (root, translucent)

    final ContainerLayer root = AnnotatedRegionLayer<int>(0);
    final ContainerLayer child1 = AnnotatedRegionLayer<int>(1);
    root.append(child1);
    final ContainerLayer child2 = AnnotatedRegionLayer<int>(2, opaque: true);
    root.append(child2);
    final ContainerLayer child3 = AnnotatedRegionLayer<int>(3);
    root.append(child3);

    final List<int> result = <int>[];
    final bool absorbed = root.hitTest(result, regionOffset: Offset.zero);
    expect(absorbed, isFalse);
    expect(result, <int>[3, 2, 0]);
  });

  test('AnnotatedRegionLayer.hitTest should not change the return value if it '
    'does not contain the pointer', () {

    // Tests:
    //         v
    //    ──────────        (child1, translucent)
    //     │
    //    ────              (root, opaque)

    const Offset position = Offset(50, 5);

    final ContainerLayer root = AnnotatedRegionLayer<int>(
      0, size: const Size(20, 10), opaque: true);
    final ContainerLayer child1 = AnnotatedRegionLayer<int>(
      1, size: const Size(100, 10), opaque: false);
    root.append(child1);

    final List<int> result = <int>[];
    final bool absorbed = root.hitTest(result, regionOffset: position);
    expect(absorbed, isFalse);
    expect(result, <int>[1]);
  });
}
