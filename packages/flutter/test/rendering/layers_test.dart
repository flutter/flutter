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

  test('mutating ShaderMaskLayer fields triggers needsAddToScene', () {
    const Gradient gradient = RadialGradient(colors: <Color>[Color(0), Color(1)]);
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
        clipPath: Path(), elevation: 0, color: const Color(0), shadowColor: const Color(0));
    checkNeedsAddToScene(layer, () {
      final Path newPath = Path();
      newPath.addRect(unitRect);
      layer.clipPath = newPath;
    });
    checkNeedsAddToScene(layer, () {
      layer.elevation = 1;
    });
    checkNeedsAddToScene(layer, () {
      layer.color = const Color(1);
    });
    checkNeedsAddToScene(layer, () {
      layer.shadowColor = const Color(1);
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
        color: const Color(0),
        shadowColor: const Color(0),
      );
      final PhysicalModelLayer layerB =PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(10, 10, 20, 20)),
        elevation: 2.0,
        color: const Color(0),
        shadowColor: const Color(0),
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
        color: const Color(0),
        shadowColor: const Color(0),
      );
      final PhysicalModelLayer layerB =PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(10, 10, 20, 20)),
        elevation: 2.0,
        color: const Color(0),
        shadowColor: const Color(0),
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
        color: const Color(0),
        shadowColor: const Color(0),
      );
      final PhysicalModelLayer layerB =PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(20, 20, 20, 20)),
        elevation: 2.0,
        color: const Color(0),
        shadowColor: const Color(0),
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
        color: const Color(0),
        shadowColor: const Color(0),
      );

      layerA.append(PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(2, 2, 10, 10)),
        elevation: 1.0,
        color: const Color(0),
        shadowColor: const Color(0),
      ));

      final PhysicalModelLayer layerB =PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(20, 20, 20, 20)),
        elevation: 2.0,
        color: const Color(0),
        shadowColor: const Color(0),
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
        color: const Color(0),
        shadowColor: const Color(0),
      );

      layerA.append(PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(15, 15, 25, 25)),
        elevation: 2.0,
        color: const Color(0),
        shadowColor: const Color(0),
      ));

      final PhysicalModelLayer layerB =PhysicalModelLayer(
        clipPath: Path()..addRect(const Rect.fromLTWH(20, 20, 20, 20)),
        elevation: 4.0,
        color: const Color(0),
        shadowColor: const Color(0),
      );

      _testConflicts(layerA, layerB, expectedErrorCount: 1);
    });
  });
}
