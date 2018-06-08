// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  group(AnnotatedRegion, () {
    test('finds the first value in a OffsetLayer', () {
      final ContainerLayer containerLayer = new ContainerLayer();
      final List<OffsetLayer> layers = <OffsetLayer>[
        new OffsetLayer(offset: Offset.zero),
        new OffsetLayer(offset: const Offset(0.0, 100.0)),
        new OffsetLayer(offset: const Offset(0.0, 200.0)),
      ];
      int i = 0;
      for (OffsetLayer layer in layers) {
        layer.append(new AnnotatedRegionLayer<int>(i));
        containerLayer.append(layer);
        i += 1;
      }

      expect(containerLayer.findRegion(const Offset(0.0, 1.0), int), 0);
      expect(containerLayer.findRegion(const Offset(0.0, 101.0), int), 1);
      expect(containerLayer.findRegion(const Offset(0.0, 201.0), int), 2);
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

      expect(containerLayer.findRegion(const Offset(0.0, 1.0), int), 0);
      expect(containerLayer.findRegion(const Offset(0.0, 101.0), int), 1);
      expect(containerLayer.findRegion(const Offset(0.0, 201.0), int), 2);
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

      expect(containerLayer.findRegion(const Offset(5.0, 5.0), int), 0);
      expect(containerLayer.findRegion(const Offset(5.0, 105.0), int), 1);
      expect(containerLayer.findRegion(const Offset(5.0, 205.0), int), 2);
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
        final AnnotatedRegionLayer<int> annotatedRegionLayer = new AnnotatedRegionLayer<int>(i);
        layer.append(annotatedRegionLayer);
        transformLayer.append(layer);
        i += 1;
      }

      expect(transformLayer.findRegion(const Offset(0.0, 100.0), int), 0);
      expect(transformLayer.findRegion(const Offset(0.0, 200.0), int), 0);
      expect(transformLayer.findRegion(const Offset(0.0, 270.0), int), 1);
      expect(transformLayer.findRegion(const Offset(0.0, 400.0), int), 1);
      expect(transformLayer.findRegion(const Offset(0.0, 530.0), int), 2);
    });
  });
}

