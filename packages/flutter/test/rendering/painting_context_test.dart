// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('PaintingContext.setIsComplexHint', () {
    final ContainerLayer layer = ContainerLayer();
    final PaintingContext context = PaintingContext(layer, Rect.zero);
    expect(layer.hasChildren, isFalse);
    context.setIsComplexHint();
    expect(layer.hasChildren, isTrue);
    expect(layer.firstChild, isA<PictureLayer>());
    expect((layer.firstChild! as PictureLayer).isComplexHint, isTrue);
  });

  test('PaintingContext.setWillChangeHint', () {
    final ContainerLayer layer = ContainerLayer();
    final PaintingContext context = PaintingContext(layer, Rect.zero);
    expect(layer.hasChildren, isFalse);
    context.setWillChangeHint();
    expect(layer.hasChildren, isTrue);
    expect(layer.firstChild, isA<PictureLayer>());
    expect((layer.firstChild! as PictureLayer).willChangeHint, isTrue);
  });
}
