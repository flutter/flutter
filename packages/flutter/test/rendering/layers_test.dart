// Copyright 2014 The Flutter Authors. All rights reserved.
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
    expect(inner.debugLayer, null);
    expect(boundary.isRepaintBoundary, isTrue);
    expect(boundary.debugLayer, isNotNull);
    expect(boundary.debugLayer!.attached, isTrue); // this time it painted...

    root.opacity = 0.0;
    pumpFrame(phase: EnginePhase.paint);
    expect(inner.isRepaintBoundary, isFalse);
    expect(inner.debugLayer, null);
    expect(boundary.isRepaintBoundary, isTrue);
    expect(boundary.debugLayer, isNotNull);
    expect(boundary.debugLayer!.attached, isFalse); // this time it did not.

    root.opacity = 0.5;
    pumpFrame(phase: EnginePhase.paint);
    expect(inner.isRepaintBoundary, isFalse);
    expect(inner.debugLayer, null);
    expect(boundary.isRepaintBoundary, isTrue);
    expect(boundary.debugLayer, isNotNull);
    expect(boundary.debugLayer!.attached, isTrue); // this time it did again!
  });

  test('updateSubtreeNeedsAddToScene propagates Layer.alwaysNeedsAddToScene up the tree', () {
    final ContainerLayer a = ContainerLayer();
    final ContainerLayer b = ContainerLayer();
    final ContainerLayer c = ContainerLayer();
    final _TestAlwaysNeedsAddToSceneLayer d = _TestAlwaysNeedsAddToSceneLayer();
    final ContainerLayer e = ContainerLayer();
    final ContainerLayer f = ContainerLayer();

    // Tree structure:
    //        a
    //       / \
    //      b   c
    //     / \
    // (x)d   e
    //   /
    //  f
    a.append(b);
    a.append(c);
    b.append(d);
    b.append(e);
    d.append(f);

    a.debugMarkClean();
    b.debugMarkClean();
    c.debugMarkClean();
    d.debugMarkClean();
    e.debugMarkClean();
    f.debugMarkClean();

    expect(a.debugSubtreeNeedsAddToScene, false);
    expect(b.debugSubtreeNeedsAddToScene, false);
    expect(c.debugSubtreeNeedsAddToScene, false);
    expect(d.debugSubtreeNeedsAddToScene, false);
    expect(e.debugSubtreeNeedsAddToScene, false);
    expect(f.debugSubtreeNeedsAddToScene, false);

    a.updateSubtreeNeedsAddToScene();

    expect(a.debugSubtreeNeedsAddToScene, true);
    expect(b.debugSubtreeNeedsAddToScene, true);
    expect(c.debugSubtreeNeedsAddToScene, false);
    expect(d.debugSubtreeNeedsAddToScene, true);
    expect(e.debugSubtreeNeedsAddToScene, false);
    expect(f.debugSubtreeNeedsAddToScene, false);
  });

  test('updateSubtreeNeedsAddToScene propagates Layer._needsAddToScene up the tree', () {
    final ContainerLayer a = ContainerLayer();
    final ContainerLayer b = ContainerLayer();
    final ContainerLayer c = ContainerLayer();
    final ContainerLayer d = ContainerLayer();
    final ContainerLayer e = ContainerLayer();
    final ContainerLayer f = ContainerLayer();
    final ContainerLayer g = ContainerLayer();
    final List<ContainerLayer> allLayers = <ContainerLayer>[a, b, c, d, e, f, g];

    // The tree is like the following where b and j are dirty:
    //        a____
    //       /     \
    //   (x)b___    c
    //     / \  \   |
    //    d   e  f  g(x)
    a.append(b);
    a.append(c);
    b.append(d);
    b.append(e);
    b.append(f);
    c.append(g);

    for (final ContainerLayer layer in allLayers) {
      expect(layer.debugSubtreeNeedsAddToScene, true);
    }

    for (final ContainerLayer layer in allLayers) {
      layer.debugMarkClean();
    }

    for (final ContainerLayer layer in allLayers) {
      expect(layer.debugSubtreeNeedsAddToScene, false);
    }

    b.markNeedsAddToScene();
    a.updateSubtreeNeedsAddToScene();

    expect(a.debugSubtreeNeedsAddToScene, true);
    expect(b.debugSubtreeNeedsAddToScene, true);
    expect(c.debugSubtreeNeedsAddToScene, false);
    expect(d.debugSubtreeNeedsAddToScene, false);
    expect(e.debugSubtreeNeedsAddToScene, false);
    expect(f.debugSubtreeNeedsAddToScene, false);
    expect(g.debugSubtreeNeedsAddToScene, false);

    g.markNeedsAddToScene();
    a.updateSubtreeNeedsAddToScene();

    expect(a.debugSubtreeNeedsAddToScene, true);
    expect(b.debugSubtreeNeedsAddToScene, true);
    expect(c.debugSubtreeNeedsAddToScene, true);
    expect(d.debugSubtreeNeedsAddToScene, false);
    expect(e.debugSubtreeNeedsAddToScene, false);
    expect(f.debugSubtreeNeedsAddToScene, false);
    expect(g.debugSubtreeNeedsAddToScene, true);

    a.buildScene(SceneBuilder());
    for (final ContainerLayer layer in allLayers) {
      expect(layer.debugSubtreeNeedsAddToScene, false);
    }
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

  void checkNeedsAddToScene(Layer layer, void Function() mutateCallback) {
    layer.debugMarkClean();
    layer.updateSubtreeNeedsAddToScene();
    expect(layer.debugSubtreeNeedsAddToScene, false);
    mutateCallback();
    layer.updateSubtreeNeedsAddToScene();
    expect(layer.debugSubtreeNeedsAddToScene, true);
  }

  List<String> _getDebugInfo(Layer layer) {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    layer.debugFillProperties(builder);
    return builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString()).toList();
  }

  test('ClipRectLayer prints clipBehavior in debug info', () {
    expect(_getDebugInfo(ClipRectLayer()), contains('clipBehavior: Clip.hardEdge'));
    expect(
      _getDebugInfo(ClipRectLayer(clipBehavior: Clip.antiAliasWithSaveLayer)),
      contains('clipBehavior: Clip.antiAliasWithSaveLayer'),
    );
  });

  test('ClipRRectLayer prints clipBehavior in debug info', () {
    expect(_getDebugInfo(ClipRRectLayer()), contains('clipBehavior: Clip.antiAlias'));
    expect(
      _getDebugInfo(ClipRRectLayer(clipBehavior: Clip.antiAliasWithSaveLayer)),
      contains('clipBehavior: Clip.antiAliasWithSaveLayer'),
    );
  });

  test('ClipPathLayer prints clipBehavior in debug info', () {
    expect(_getDebugInfo(ClipPathLayer()), contains('clipBehavior: Clip.antiAlias'));
    expect(
      _getDebugInfo(ClipPathLayer(clipBehavior: Clip.antiAliasWithSaveLayer)),
      contains('clipBehavior: Clip.antiAliasWithSaveLayer'),
    );
  });

  test('PictureLayer prints picture, raster cache hints in debug info', () {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawPaint(Paint());
    final Picture picture = recorder.endRecording();
    final PictureLayer layer = PictureLayer(const Rect.fromLTRB(0, 0, 1, 1));
    layer.picture = picture;
    layer.isComplexHint = true;
    layer.willChangeHint = false;
    final List<String> info = _getDebugInfo(layer);
    expect(info, contains('picture: ${describeIdentity(picture)}'));
    expect(info, isNot(contains('engine layer: ${describeIdentity(null)}')));
    expect(info, contains('raster cache hints: isComplex = true, willChange = false'));
  });

  test('Layer prints engineLayer if it is not null in debug info', () {
    final ConcreteLayer layer = ConcreteLayer();
    List<String> info = _getDebugInfo(layer);
    expect(info, isNot(contains('engine layer: ${describeIdentity(null)}')));

    layer.engineLayer = FakeEngineLayer();
    info = _getDebugInfo(layer);
    expect(info, contains('engine layer: ${describeIdentity(layer.engineLayer)}'));
  });

  test('mutating PictureLayer fields triggers needsAddToScene', () {
    final PictureLayer pictureLayer = PictureLayer(Rect.zero);
    checkNeedsAddToScene(pictureLayer, () {
      final PictureRecorder recorder = PictureRecorder();
      Canvas(recorder);
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
      overlayRect: Rect.zero,
      optionsMask: 0,
      rasterizerThreshold: 0,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
    );
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
      layer.clipRRect = RRect.fromRectAndRadius(unitRect, Radius.zero);
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
      clipPath: Path(),
      elevation: 0,
      color: const Color(0x00000000),
      shadowColor: const Color(0x00000000),
    );
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

  test('ContainerLayer.toImage can render interior layer', () {
    final OffsetLayer parent = OffsetLayer();
    final OffsetLayer child = OffsetLayer();
    final OffsetLayer grandChild = OffsetLayer();
    child.append(grandChild);
    parent.append(child);

    // This renders the layers and generates engine layers.
    parent.buildScene(SceneBuilder());

    // Causes grandChild to pass its engine layer as `oldLayer`
    grandChild.toImage(const Rect.fromLTRB(0, 0, 10, 10));

    // Ensure we can render the same scene again after rendering an interior
    // layer.
    parent.buildScene(SceneBuilder());
  }, skip: isBrowser); // TODO(yjbanov): `toImage` doesn't work on the Web: https://github.com/flutter/flutter/issues/49857

  test('PictureLayer does not let you call dispose unless refcount is 0', () {
    PictureLayer layer = PictureLayer(Rect.zero);
    expect(layer.debugHandleCount, 0);
    layer.dispose();
    expect(layer.debugDisposed, true);

    layer = PictureLayer(Rect.zero);
    final LayerHandle<PictureLayer> handle = LayerHandle<PictureLayer>(layer);
    expect(layer.debugHandleCount, 1);
    expect(() => layer.dispose(), throwsAssertionError);
    handle.layer = null;
    expect(layer.debugHandleCount, 0);
    expect(layer.debugDisposed, true);
    expect(() => layer.dispose(), throwsAssertionError); // already disposed.
  });

  test('Layer append/remove increases/decreases handle count', () {
    final PictureLayer layer = PictureLayer(Rect.zero);
    final ContainerLayer parent = ContainerLayer();
    expect(layer.debugHandleCount, 0);
    expect(layer.debugDisposed, false);

    parent.append(layer);
    expect(layer.debugHandleCount, 1);
    expect(layer.debugDisposed, false);

    layer.remove();
    expect(layer.debugHandleCount, 0);
    expect(layer.debugDisposed, true);
  });

  test('Layer.dispose disposes the engineLayer', () {
    final Layer layer = ConcreteLayer();
    final FakeEngineLayer engineLayer = FakeEngineLayer();
    layer.engineLayer = engineLayer;
    expect(engineLayer.disposed, false);
    layer.dispose();
    expect(engineLayer.disposed, true);
    expect(layer.engineLayer, null);
  });

  test('Layer.engineLayer (set) disposes the engineLayer', () {
    final Layer layer = ConcreteLayer();
    final FakeEngineLayer engineLayer = FakeEngineLayer();
    layer.engineLayer = engineLayer;
    expect(engineLayer.disposed, false);
    layer.engineLayer = null;
    expect(engineLayer.disposed, true);
  });

  test('PictureLayer.picture (set) disposes the picture', () {
    final PictureLayer layer = PictureLayer(Rect.zero);
    final FakePicture picture = FakePicture();
    layer.picture = picture;
    expect(picture.disposed, false);
    layer.picture = null;
    expect(picture.disposed, true);
  });

  test('PictureLayer disposes the picture', () {
    final PictureLayer layer = PictureLayer(Rect.zero);
    final FakePicture picture = FakePicture();
    layer.picture = picture;
    expect(picture.disposed, false);
    layer.dispose();
    expect(picture.disposed, true);
  });

  test('LayerHandle disposes the layer', () {
    final ConcreteLayer layer = ConcreteLayer();
    final ConcreteLayer layer2 = ConcreteLayer();

    expect(layer.debugHandleCount, 0);
    expect(layer2.debugHandleCount, 0);

    final LayerHandle<ConcreteLayer> holder = LayerHandle<ConcreteLayer>(layer);
    expect(layer.debugHandleCount, 1);
    expect(layer.debugDisposed, false);
    expect(layer2.debugHandleCount, 0);
    expect(layer2.debugDisposed, false);

    holder.layer = layer;
    expect(layer.debugHandleCount, 1);
    expect(layer.debugDisposed, false);
    expect(layer2.debugHandleCount, 0);
    expect(layer2.debugDisposed, false);

    holder.layer = layer2;
    expect(layer.debugHandleCount, 0);
    expect(layer.debugDisposed, true);
    expect(layer2.debugHandleCount, 1);
    expect(layer2.debugDisposed, false);

    holder.layer = null;
    expect(layer.debugHandleCount, 0);
    expect(layer.debugDisposed, true);
    expect(layer2.debugHandleCount, 0);
    expect(layer2.debugDisposed, true);

    expect(() => holder.layer = layer, throwsAssertionError);
  });
}

class FakeEngineLayer extends Fake implements EngineLayer {
  bool disposed = false;

  @override
  void dispose() {
    assert(!disposed);
    disposed = true;
  }
}

class FakePicture extends Fake implements Picture {
  bool disposed = false;

  @override
  void dispose() {
    assert(!disposed);
    disposed = true;
  }
}

class ConcreteLayer extends Layer {
  @override
  void addToScene(SceneBuilder builder, [ Offset layerOffset = Offset.zero ]) {}
}

class _TestAlwaysNeedsAddToSceneLayer extends ContainerLayer {
  @override
  bool get alwaysNeedsAddToScene => true;
}
