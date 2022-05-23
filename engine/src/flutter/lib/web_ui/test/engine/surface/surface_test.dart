// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('Surface', () {
    setUp(() {
      SurfaceSceneBuilder.debugForgetFrameScene();
    });

    test('debugAssertSurfaceState produces a human-readable message', () {
      final SceneBuilder builder = SceneBuilder();
      final PersistedOpacity opacityLayer = builder.pushOpacity(100) as PersistedOpacity;
      try {
        debugAssertSurfaceState(opacityLayer, PersistedSurfaceState.active, PersistedSurfaceState.pendingRetention);
        fail('Expected $PersistedSurfaceException');
      } on PersistedSurfaceException catch (exception) {
        expect(
          '$exception',
          'PersistedOpacity: is in an unexpected state.\n'
          'Expected one of: PersistedSurfaceState.active, PersistedSurfaceState.pendingRetention\n'
          'But was: PersistedSurfaceState.created',
        );
      }
    });

    test('is created', () {
      final SceneBuilder builder = SceneBuilder();
      final PersistedOpacity opacityLayer = builder.pushOpacity(100) as PersistedOpacity;
      builder.pop();

      expect(opacityLayer, isNotNull);
      expect(opacityLayer.rootElement, isNull);
      expect(opacityLayer.isCreated, isTrue);

      builder.build();

      expect(opacityLayer.rootElement!.tagName.toLowerCase(), 'flt-opacity');
      expect(opacityLayer.isActive, isTrue);
    });

    test('is released', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer = builder1.pushOpacity(100) as PersistedOpacity;
      builder1.pop();
      builder1.build();
      expect(opacityLayer.isActive, isTrue);

      SceneBuilder().build();
      expect(opacityLayer.isReleased, isTrue);
      expect(opacityLayer.rootElement, isNull);
    });

    test('discarding is recursive', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer = builder1.pushOpacity(100) as PersistedOpacity;
      final PersistedTransform transformLayer =
          builder1.pushTransform(Matrix4.identity().toFloat64()) as PersistedTransform;
      builder1.pop();
      builder1.pop();
      builder1.build();
      expect(opacityLayer.isActive, isTrue);
      expect(transformLayer.isActive, isTrue);

      SceneBuilder().build();
      expect(opacityLayer.isReleased, isTrue);
      expect(transformLayer.isReleased, isTrue);
      expect(opacityLayer.rootElement, isNull);
      expect(transformLayer.rootElement, isNull);
    });

    test('is updated', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer1 = builder1.pushOpacity(100) as PersistedOpacity;
      builder1.pop();
      builder1.build();
      expect(opacityLayer1.isActive, isTrue);
      final DomElement element = opacityLayer1.rootElement!;

      final SceneBuilder builder2 = SceneBuilder();
      final PersistedOpacity opacityLayer2 =
          builder2.pushOpacity(200, oldLayer: opacityLayer1) as PersistedOpacity;
      expect(opacityLayer1.isPendingUpdate, isTrue);
      expect(opacityLayer2.isCreated, isTrue);
      expect(opacityLayer2.oldLayer, same(opacityLayer1));
      builder2.pop();

      builder2.build();
      expect(opacityLayer1.isReleased, isTrue);
      expect(opacityLayer1.rootElement, isNull);
      expect(opacityLayer2.isActive, isTrue);
      expect(
          opacityLayer2.rootElement, element); // adopts old surface's element
      expect(opacityLayer2.oldLayer, isNull);
    });

    test('ignores released surface when updated', () {
      // Build a surface
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer1 = builder1.pushOpacity(100) as PersistedOpacity;
      builder1.pop();
      builder1.build();
      expect(opacityLayer1.isActive, isTrue);
      final DomElement element = opacityLayer1.rootElement!;

      // Release it
      SceneBuilder().build();
      expect(opacityLayer1.isReleased, isTrue);
      expect(opacityLayer1.rootElement, isNull);

      // Attempt to update it
      final SceneBuilder builder2 = SceneBuilder();
      final PersistedOpacity opacityLayer2 =
          builder2.pushOpacity(200, oldLayer: opacityLayer1) as PersistedOpacity;
      builder2.pop();
      expect(opacityLayer1.isReleased, isTrue);
      expect(opacityLayer2.isCreated, isTrue);

      builder2.build();
      expect(opacityLayer1.isReleased, isTrue);
      expect(opacityLayer2.isActive, isTrue);
      expect(opacityLayer2.rootElement, isNot(equals(element)));
    });

    // This test creates a situation when an intermediate layer disappears,
    // causing its child to become a direct child of the common ancestor. This
    // often happens with opacity layers. When opacity reaches 1.0, the
    // framework removes that layer (as it is no longer necessary). This test
    // makes sure we reuse the child layer's DOM nodes. Here's the illustration
    // of what's happening:
    //
    // Frame 1   Frame 2
    //
    //   A         A
    //   |         |
    //   B     ┌──>C
    //   |     │   |
    //   C ────┘   L
    //   |
    //   L
    //
    // Layer "L" is a logging layer used to track what would happen to the
    // child of "C" as it's being dragged around the tree. For example, we
    // check that the child doesn't get discarded by mistake.
    test('reparents DOM element when updated', () {
      final _LoggingTestSurface logger = _LoggingTestSurface();
      final SurfaceSceneBuilder builder1 = SurfaceSceneBuilder();
      final PersistedTransform a1 =
          builder1.pushTransform(
              (Matrix4.identity()..scale(domWindow.devicePixelRatio as double)).toFloat64()) as PersistedTransform;
      final PersistedOpacity b1 = builder1.pushOpacity(100) as PersistedOpacity;
      final PersistedTransform c1 =
          builder1.pushTransform(Matrix4.identity().toFloat64()) as PersistedTransform;
      builder1.debugAddSurface(logger);
      builder1.pop();
      builder1.pop();
      builder1.pop();
      builder1.build();
      expect(logger.log, <String>['build', 'createElement', 'apply']);

      final DomElement elementA = a1.rootElement!;
      final DomElement elementB = b1.rootElement!;
      final DomElement elementC = c1.rootElement!;

      expect(elementC.parent, elementB);
      expect(elementB.parent, elementA);

      final SurfaceSceneBuilder builder2 = SurfaceSceneBuilder();
      final PersistedTransform a2 =
          builder2.pushTransform(
              (Matrix4.identity()..scale(domWindow.devicePixelRatio as double)).toFloat64(),
              oldLayer: a1) as PersistedTransform;
      final PersistedTransform c2 =
          builder2.pushTransform(Matrix4.identity().toFloat64(), oldLayer: c1) as PersistedTransform;
      builder2.addRetained(logger);
      builder2.pop();
      builder2.pop();

      expect(c1.isPendingUpdate, isTrue);
      expect(c2.isCreated, isTrue);
      builder2.build();
      expect(logger.log, <String>['build', 'createElement', 'apply', 'retain']);
      expect(c1.isReleased, isTrue);
      expect(c2.isActive, isTrue);

      expect(a2.rootElement, elementA);
      expect(b1.rootElement, isNull);
      expect(c2.rootElement, elementC);

      expect(elementC.parent, elementA);
      expect(elementB.parent, null);
    },
        // This method failed on iOS Safari.
        // TODO(ferhat): https://github.com/flutter/flutter/issues/60036
        skip: browserEngine == BrowserEngine.webkit &&
            operatingSystem == OperatingSystem.iOs);

    test('is retained', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer = builder1.pushOpacity(100) as PersistedOpacity;
      builder1.pop();
      builder1.build();
      expect(opacityLayer.isActive, isTrue);
      final DomElement element = opacityLayer.rootElement!;

      final SceneBuilder builder2 = SceneBuilder();

      expect(opacityLayer.isActive, isTrue);
      builder2.addRetained(opacityLayer);
      expect(opacityLayer.isPendingRetention, isTrue);

      builder2.build();
      expect(opacityLayer.isActive, isTrue);
      expect(opacityLayer.rootElement, element);
    });

    test('revives released surface when retained', () {
      final SurfaceSceneBuilder builder1 = SurfaceSceneBuilder();
      final PersistedOpacity opacityLayer = builder1.pushOpacity(100) as PersistedOpacity;
      final _LoggingTestSurface logger = _LoggingTestSurface();
      builder1.debugAddSurface(logger);
      builder1.pop();
      builder1.build();
      expect(opacityLayer.isActive, isTrue);
      expect(logger.log, <String>['build', 'createElement', 'apply']);
      final DomElement element = opacityLayer.rootElement!;

      SceneBuilder().build();
      expect(opacityLayer.isReleased, isTrue);
      expect(opacityLayer.rootElement, isNull);
      expect(logger.log, <String>['build', 'createElement', 'apply', 'discard']);

      final SceneBuilder builder2 = SceneBuilder();
      builder2.addRetained(opacityLayer);
      expect(opacityLayer.isCreated, isTrue); // revived
      expect(logger.log, <String>['build', 'createElement', 'apply', 'discard', 'revive']);

      builder2.build();
      expect(opacityLayer.isActive, isTrue);
      expect(opacityLayer.rootElement, isNot(equals(element)));
    });

    test('reviving is recursive', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer = builder1.pushOpacity(100) as PersistedOpacity;
      final PersistedTransform transformLayer =
          builder1.pushTransform(Matrix4.identity().toFloat64()) as PersistedTransform;
      builder1.pop();
      builder1.pop();
      builder1.build();
      expect(opacityLayer.isActive, isTrue);
      expect(transformLayer.isActive, isTrue);
      final DomElement opacityElement = opacityLayer.rootElement!;
      final DomElement transformElement = transformLayer.rootElement!;

      SceneBuilder().build();

      final SceneBuilder builder2 = SceneBuilder();
      builder2.addRetained(opacityLayer);
      expect(opacityLayer.isCreated, isTrue); // revived
      expect(transformLayer.isCreated, isTrue); // revived

      builder2.build();
      expect(opacityLayer.isActive, isTrue);
      expect(transformLayer.isActive, isTrue);
      expect(opacityLayer.rootElement, isNot(equals(opacityElement)));
      expect(transformLayer.rootElement, isNot(equals(transformElement)));
    });

    // This test creates a situation when a retained layer is moved to another
    // parent. We want to make sure that we move the retained layer's elements
    // without rebuilding from scratch. No new elements are created in this
    // situation.
    //
    // Here's an illustrated example where layer C is reparented onto B along
    // with D:
    //
    // Frame 1   Frame 2
    //
    //    A         A
    //   ╱ ╲        |
    //  B   C ──┐   B
    //      |   │   |
    //      D   └──>C
    //              |
    //              D
    test('reparents DOM elements when retained', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity a1 = builder1.pushOpacity(10) as PersistedOpacity;
      final PersistedOpacity b1 = builder1.pushOpacity(20) as PersistedOpacity;
      builder1.pop();
      final PersistedOpacity c1 = builder1.pushOpacity(30) as PersistedOpacity;
      final PersistedOpacity d1 = builder1.pushOpacity(40) as PersistedOpacity;
      builder1.pop();
      builder1.pop();
      builder1.pop();
      builder1.build();

      final DomElement elementA = a1.rootElement!;
      final DomElement elementB = b1.rootElement!;
      final DomElement elementC = c1.rootElement!;
      final DomElement elementD = d1.rootElement!;

      expect(elementB.parent, elementA);
      expect(elementC.parent, elementA);
      expect(elementD.parent, elementC);

      final SceneBuilder builder2 = SceneBuilder();
      final PersistedOpacity a2 = builder2.pushOpacity(10, oldLayer: a1) as PersistedOpacity;
      final PersistedOpacity b2 = builder2.pushOpacity(20, oldLayer: b1) as PersistedOpacity;
      builder2.addRetained(c1);
      builder2.pop();
      builder2.pop();
      builder2.build();

      expect(a2.rootElement, elementA);
      expect(b2.rootElement, elementB);
      expect(c1.rootElement, elementC);
      expect(d1.rootElement, elementD);

      expect(
        <DomElement>[
          elementD.parent!,
          elementC.parent!,
          elementB.parent!,
        ],
        <DomElement>[elementC, elementB, elementA],
      );
    });

    test('is updated by matching', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer1 = builder1.pushOpacity(100) as PersistedOpacity;
      builder1.pop();
      builder1.build();
      expect(opacityLayer1.isActive, isTrue);
      final DomElement element = opacityLayer1.rootElement!;

      final SceneBuilder builder2 = SceneBuilder();
      final PersistedOpacity opacityLayer2 = builder2.pushOpacity(200) as PersistedOpacity;
      expect(opacityLayer1.isActive, isTrue);
      expect(opacityLayer2.isCreated, isTrue);
      builder2.pop();

      builder2.build();
      expect(opacityLayer1.isReleased, isTrue);
      expect(opacityLayer1.rootElement, isNull);
      expect(opacityLayer2.isActive, isTrue);
      expect(
          opacityLayer2.rootElement, element); // adopts old surface's element
    });

    // Regression test for https://github.com/flutter/flutter/issues/60461
    //
    // During retained match many to many, build can be called on existing
    // PersistedPhysicalShape multiple times when not matched.
    test('Can call apply multiple times on existing PersistedPhysicalShape'
        'when using arbitrary path',
            () {
      final SceneBuilder builder1 = SceneBuilder();
      final Path path = Path();
      path.addPolygon(const <Offset>[Offset(50, 0), Offset(100, 80), Offset(20, 40)], true);
      final PersistedPhysicalShape shape = builder1.pushPhysicalShape(path: path,
        color: const Color(0xFF00FF00), elevation: 1) as PersistedPhysicalShape;
      builder1.build();
      expect(() => shape.apply(), returnsNormally);
    });
  });
}

class _LoggingTestSurface extends PersistedContainerSurface {
  final List<String> log = <String>[];

  _LoggingTestSurface() : super(null);

  @override
  void build() {
    log.add('build');
    super.build();
  }

  @override
  void apply() {
    log.add('apply');
  }

  @override
  DomElement createElement() {
    log.add('createElement');
    return createDomElement('flt-test-layer');
  }

  @override
  void update(_LoggingTestSurface oldSurface) {
    log.add('update');
    super.update(oldSurface);
  }

  @override
  void adoptElements(covariant PersistedSurface oldSurface) {
    log.add('adoptElements');
    super.adoptElements(oldSurface);
  }

  @override
  void retain() {
    log.add('retain');
    super.retain();
  }

  @override
  void discard() {
    log.add('discard');
    super.discard();
  }

  @override
  void revive() {
    log.add('revive');
    super.revive();
  }

  @override
  double matchForUpdate(PersistedSurface? existingSurface) {
    return 1.0;
  }
}
