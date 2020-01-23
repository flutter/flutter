// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  group('RenderView', () {
    test('accounts for device pixel ratio in paintBounds', () {
      layout(RenderAspectRatio(aspectRatio: 1.0));
      pumpFrame();
      final Size logicalSize = renderer.renderView.configuration.size;
      final double devicePixelRatio = renderer.renderView.configuration.devicePixelRatio;
      final Size physicalSize = logicalSize * devicePixelRatio;
      expect(renderer.renderView.paintBounds, Offset.zero & physicalSize);
    });
  });
}
