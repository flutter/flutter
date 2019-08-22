// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'package:test/test.dart';

void main() {
  group('Surface', () {
    setUp(() {
      SceneBuilder.debugForgetFrameScene();
    });

    test('is created', () {
      final SceneBuilder builder = SceneBuilder();
      final PersistedOpacity opacityLayer = builder.pushOpacity(100);
      builder.pop();

      expect(opacityLayer, isNotNull);
      expect(opacityLayer.rootElement, isNull);
      expect(opacityLayer.isCreated, true);

      builder.build();

      expect(opacityLayer.rootElement.tagName.toLowerCase(), 'flt-opacity');
      expect(opacityLayer.isActive, true);
    });

    test('is released', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer = builder1.pushOpacity(100);
      builder1.pop();
      builder1.build();
      expect(opacityLayer.isActive, true);

      SceneBuilder().build();
      expect(opacityLayer.isReleased, true);
      expect(opacityLayer.rootElement, isNull);
    });

    test('discarding is recursive', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer = builder1.pushOpacity(100);
      final PersistedTransform transformLayer =
          builder1.pushTransform(Matrix4.identity().storage);
      builder1.pop();
      builder1.pop();
      builder1.build();
      expect(opacityLayer.isActive, true);
      expect(transformLayer.isActive, true);

      SceneBuilder().build();
      expect(opacityLayer.isReleased, true);
      expect(transformLayer.isReleased, true);
      expect(opacityLayer.rootElement, isNull);
      expect(transformLayer.rootElement, isNull);
    });

    test('is updated', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer1 = builder1.pushOpacity(100);
      builder1.pop();
      builder1.build();
      expect(opacityLayer1.isActive, true);
      final html.Element element = opacityLayer1.rootElement;

      final SceneBuilder builder2 = SceneBuilder();
      final PersistedOpacity opacityLayer2 =
          builder2.pushOpacity(200, oldLayer: opacityLayer1);
      expect(opacityLayer1.isPendingUpdate, true);
      expect(opacityLayer2.isCreated, true);
      expect(opacityLayer2.oldLayer, same(opacityLayer1));
      builder2.pop();

      builder2.build();
      expect(opacityLayer1.isReleased, true);
      expect(opacityLayer1.rootElement, isNull);
      expect(opacityLayer2.isActive, true);
      expect(
          opacityLayer2.rootElement, element); // adopts old surface's element
      expect(opacityLayer2.oldLayer, isNull);
    });

    test('ignores released surface when updated', () {
      // Build a surface
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer1 = builder1.pushOpacity(100);
      builder1.pop();
      builder1.build();
      expect(opacityLayer1.isActive, true);
      final html.Element element = opacityLayer1.rootElement;

      // Release it
      SceneBuilder().build();
      expect(opacityLayer1.isReleased, true);
      expect(opacityLayer1.rootElement, isNull);

      // Attempt to update it
      final SceneBuilder builder2 = SceneBuilder();
      final PersistedOpacity opacityLayer2 =
          builder2.pushOpacity(200, oldLayer: opacityLayer1);
      builder2.pop();
      expect(opacityLayer1.isReleased, true);
      expect(opacityLayer2.isCreated, true);

      builder2.build();
      expect(opacityLayer1.isReleased, true);
      expect(opacityLayer2.isActive, true);
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
    //   |     │
    //   C ────┘
    test('reparents DOM element when updated', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedTransform a1 =
          builder1.pushTransform(Matrix4.identity().storage);
      final PersistedOpacity b1 = builder1.pushOpacity(100);
      final PersistedTransform c1 =
          builder1.pushTransform(Matrix4.identity().storage);
      builder1.pop();
      builder1.pop();
      builder1.pop();
      builder1.build();

      final html.Element elementA = a1.rootElement;
      final html.Element elementB = b1.rootElement;
      final html.Element elementC = c1.rootElement;

      expect(elementC.parent, elementB);
      expect(elementB.parent, elementA);

      final SceneBuilder builder2 = SceneBuilder();
      final PersistedTransform a2 =
          builder2.pushTransform(Matrix4.identity().storage, oldLayer: a1);
      final PersistedTransform c2 =
          builder2.pushTransform(Matrix4.identity().storage, oldLayer: c1);
      builder2.pop();
      builder2.pop();
      builder2.build();

      expect(a2.rootElement, elementA);
      expect(b1.rootElement, isNull);
      expect(c2.rootElement, elementC);

      expect(elementC.parent, elementA);
      expect(elementB.parent, null);
    });

    test('is retained', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer = builder1.pushOpacity(100);
      builder1.pop();
      builder1.build();
      expect(opacityLayer.isActive, true);
      final html.Element element = opacityLayer.rootElement;

      final SceneBuilder builder2 = SceneBuilder();
      builder2.addRetained(opacityLayer);
      expect(opacityLayer.isPendingRetention, true);

      builder2.build();
      expect(opacityLayer.isActive, true);
      expect(opacityLayer.rootElement, element);
    });

    test('revives released surface when retained', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer = builder1.pushOpacity(100);
      builder1.pop();
      builder1.build();
      expect(opacityLayer.isActive, true);
      final html.Element element = opacityLayer.rootElement;

      SceneBuilder().build();
      expect(opacityLayer.isReleased, true);
      expect(opacityLayer.rootElement, isNull);

      final SceneBuilder builder2 = SceneBuilder();
      builder2.addRetained(opacityLayer);
      expect(opacityLayer.isCreated, true); // revived

      builder2.build();
      expect(opacityLayer.isActive, true);
      expect(opacityLayer.rootElement, isNot(equals(element)));
    });

    test('reviving is recursive', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer = builder1.pushOpacity(100);
      final PersistedTransform transformLayer =
          builder1.pushTransform(Matrix4.identity().storage);
      builder1.pop();
      builder1.pop();
      builder1.build();
      expect(opacityLayer.isActive, true);
      expect(transformLayer.isActive, true);
      final html.Element opacityElement = opacityLayer.rootElement;
      final html.Element transformElement = transformLayer.rootElement;

      SceneBuilder().build();

      final SceneBuilder builder2 = SceneBuilder();
      builder2.addRetained(opacityLayer);
      expect(opacityLayer.isCreated, true); // revived
      expect(transformLayer.isCreated, true); // revived

      builder2.build();
      expect(opacityLayer.isActive, true);
      expect(transformLayer.isActive, true);
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
      final PersistedOpacity a1 = builder1.pushOpacity(10);
      final PersistedOpacity b1 = builder1.pushOpacity(20);
      builder1.pop();
      final PersistedOpacity c1 = builder1.pushOpacity(30);
      final PersistedOpacity d1 = builder1.pushOpacity(40);
      builder1.pop();
      builder1.pop();
      builder1.pop();
      builder1.build();

      final html.Element elementA = a1.rootElement;
      final html.Element elementB = b1.rootElement;
      final html.Element elementC = c1.rootElement;
      final html.Element elementD = d1.rootElement;

      expect(elementB.parent, elementA);
      expect(elementC.parent, elementA);
      expect(elementD.parent, elementC);

      final SceneBuilder builder2 = SceneBuilder();
      final PersistedOpacity a2 = builder2.pushOpacity(10, oldLayer: a1);
      final PersistedOpacity b2 = builder2.pushOpacity(20, oldLayer: b1);
      builder2.addRetained(c1);
      builder2.pop();
      builder2.pop();
      builder2.build();

      expect(a2.rootElement, elementA);
      expect(b2.rootElement, elementB);
      expect(c1.rootElement, elementC);
      expect(d1.rootElement, elementD);

      expect(
        <html.Element>[
          elementD.parent,
          elementC.parent,
          elementB.parent,
        ],
        <html.Element>[elementC, elementB, elementA],
      );
    });

    test('is updated by matching', () {
      final SceneBuilder builder1 = SceneBuilder();
      final PersistedOpacity opacityLayer1 = builder1.pushOpacity(100);
      builder1.pop();
      builder1.build();
      expect(opacityLayer1.isActive, true);
      final html.Element element = opacityLayer1.rootElement;

      final SceneBuilder builder2 = SceneBuilder();
      final PersistedOpacity opacityLayer2 = builder2.pushOpacity(200);
      expect(opacityLayer1.isActive, true);
      expect(opacityLayer2.isCreated, true);
      builder2.pop();

      builder2.build();
      expect(opacityLayer1.isReleased, true);
      expect(opacityLayer1.rootElement, isNull);
      expect(opacityLayer2.isActive, true);
      expect(
          opacityLayer2.rootElement, element); // adopts old surface's element
    });
  });
}
