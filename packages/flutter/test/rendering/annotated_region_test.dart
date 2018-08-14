// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../flutter_test_alternative.dart';

void main() {
  group(AnnotatedRegion, () {
    test('finds the first value in a OffsetLayer when sized', () {
      final ContainerLayer containerLayer = new ContainerLayer();
      final List<OffsetLayer> layers = <OffsetLayer>[
        new OffsetLayer(offset: Offset.zero),
        new OffsetLayer(offset: const Offset(0.0, 100.0)),
        new OffsetLayer(offset: const Offset(0.0, 200.0)),
      ];
      int i = 0;
      for (OffsetLayer layer in layers) {
        layer.append(new AnnotatedRegionLayer<int>(i, size: const Size(200.0, 100.0)));
        containerLayer.append(layer);
        i += 1;
      }

      expect(containerLayer.find<int>(const Offset(0.0, 1.0)), 0);
      expect(containerLayer.find<int>(const Offset(0.0, 101.0)), 1);
      expect(containerLayer.find<int>(const Offset(0.0, 201.0)), 2);
    });

    test('finds a value within the clip in a ClipRectLayer', () {
      final ContainerLayer containerLayer = new ContainerLayer();
      final List<ClipRectLayer> layers = <ClipRectLayer>[
        new ClipRectLayer(clipRect: new Rect.fromLTRB(0.0, 0.0, 100.0, 100.0)),
        new ClipRectLayer(clipRect: new Rect.fromLTRB(0.0, 100.0, 100.0, 200.0)),
        new ClipRectLayer(clipRect: new Rect.fromLTRB(0.0, 200.0, 100.0, 300.0)),
      ];
      int i = 0;
      for (ClipRectLayer layer in layers) {
        layer.append(new AnnotatedRegionLayer<int>(i));
        containerLayer.append(layer);
        i += 1;
      }

      expect(containerLayer.find<int>(const Offset(0.0, 1.0)), 0);
      expect(containerLayer.find<int>(const Offset(0.0, 101.0)), 1);
      expect(containerLayer.find<int>(const Offset(0.0, 201.0)), 2);
    });


    test('finds a value within the clip in a ClipRRectLayer', () {
      final ContainerLayer containerLayer = new ContainerLayer();
      final List<ClipRRectLayer> layers = <ClipRRectLayer>[
        new ClipRRectLayer(clipRRect: new RRect.fromLTRBR(0.0, 0.0, 100.0, 100.0, const Radius.circular(4.0))),
        new ClipRRectLayer(clipRRect: new RRect.fromLTRBR(0.0, 100.0, 100.0, 200.0, const Radius.circular(4.0))),
        new ClipRRectLayer(clipRRect: new RRect.fromLTRBR(0.0, 200.0, 100.0, 300.0, const Radius.circular(4.0))),
      ];
      int i = 0;
      for (ClipRRectLayer layer in layers) {
        layer.append(new AnnotatedRegionLayer<int>(i));
        containerLayer.append(layer);
        i += 1;
      }

      expect(containerLayer.find<int>(const Offset(5.0, 5.0)), 0);
      expect(containerLayer.find<int>(const Offset(5.0, 105.0)), 1);
      expect(containerLayer.find<int>(const Offset(5.0, 205.0)), 2);
    });

    test('finds a value under a TransformLayer', () {
      final Matrix4 transform = new Matrix4(
        2.625, 0.0, 0.0, 0.0,
        0.0, 2.625, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
      );
      final TransformLayer transformLayer = new TransformLayer(transform: transform);
      final List<OffsetLayer> layers = <OffsetLayer>[
        new OffsetLayer(),
        new OffsetLayer(offset: const Offset(0.0, 100.0)),
        new OffsetLayer(offset: const Offset(0.0, 200.0)),
      ];
      int i = 0;
      for (OffsetLayer layer in layers) {
        final AnnotatedRegionLayer<int> annotatedRegionLayer = new AnnotatedRegionLayer<int>(i, size: const Size(100.0, 100.0));
        layer.append(annotatedRegionLayer);
        transformLayer.append(layer);
        i += 1;
      }

      expect(transformLayer.find<int>(const Offset(0.0, 100.0)), 0);
      expect(transformLayer.find<int>(const Offset(0.0, 200.0)), 0);
      expect(transformLayer.find<int>(const Offset(0.0, 270.0)), 1);
      expect(transformLayer.find<int>(const Offset(0.0, 400.0)), 1);
      expect(transformLayer.find<int>(const Offset(0.0, 530.0)), 2);
    });

    test('looks for child AnnotatedRegions before parents', () {
      final AnnotatedRegionLayer<int> parent = new AnnotatedRegionLayer<int>(1);
      final AnnotatedRegionLayer<int> child = new AnnotatedRegionLayer<int>(2);
      final ContainerLayer layer = new ContainerLayer();
      parent.append(child);
      layer.append(parent);

      expect(parent.find<int>(Offset.zero), 2);
    });

    test('looks for correct type', () {
      final AnnotatedRegionLayer<int> child1 = new AnnotatedRegionLayer<int>(1);
      final AnnotatedRegionLayer<String> child2 = new AnnotatedRegionLayer<String>('hello');
      final ContainerLayer layer = new ContainerLayer();
      layer.append(child2);
      layer.append(child1);

      expect(layer.find<String>(Offset.zero), 'hello');
    });

    test('does not clip Layer.find on an AnnotatedRegion with an unrelated type', () {
      final AnnotatedRegionLayer<int> child = new AnnotatedRegionLayer<int>(1);
      final AnnotatedRegionLayer<String> parent = new AnnotatedRegionLayer<String>('hello', size: const Size(10.0, 10.0));
      final ContainerLayer layer = new ContainerLayer();
      parent.append(child);
      layer.append(parent);

      expect(layer.find<int>(const Offset(100.0, 100.0)), 1);
    });

    test('handles non-invertable transforms', () {
      final AnnotatedRegionLayer<int> child = new AnnotatedRegionLayer<int>(1);
      final TransformLayer parent = new TransformLayer(transform: new Matrix4.diagonal3Values(0.0, 1.0, 1.0));
      parent.append(child);

      expect(parent.find<int>(const Offset(0.0, 0.0)), null);

      parent.transform = new Matrix4.diagonal3Values(1.0, 1.0, 1.0);

      expect(parent.find<int>(const Offset(0.0, 0.0)), 1);
    });
  });
}

