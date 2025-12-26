// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageFilterConfig', () {
    test('ImageFilterContext control', () {
      const context = ImageFilterContext(bounds: Rect.zero);
      expect(context.bounds, Rect.zero);
    });

    test('ImageFilterConfig.new == and hashCode', () {
      final imageFilter1 = ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0);
      final imageFilter2 = ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0);
      final imageFilter3 = ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0);

      final config1 = ImageFilterConfig(imageFilter1);
      final config2 = ImageFilterConfig(imageFilter1);
      final config3 = ImageFilterConfig(imageFilter2);
      final config4 = ImageFilterConfig(imageFilter3);

      expect(config1, config2);
      expect(config1.hashCode, config2.hashCode);
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
      expect(config3, config4);
      expect(config3.hashCode, config4.hashCode);
    });

    test('ImageFilterConfig.new toString and shortDescription', () {
      final imageFilter = ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0);
      final config = ImageFilterConfig(imageFilter);

      expect(config.shortDescription, 'blur(5.0, 5.0, unspecified)');
      expect(config.toString(), 'ImageFilterConfig(blur(5.0, 5.0, unspecified))');
    });

    test('ImageFilterConfig.new get filter', () {
      final imageFilter = ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0);
      final config = ImageFilterConfig(imageFilter);

      expect(config.filter!.toString(), 'ImageFilter.blur(5.0, 5.0, unspecified)');
    });

    test('ImageFilterConfig.blur == and hashCode', () {
      const config1 = ImageFilterConfig.blur(sigmaX: 5.0, sigmaY: 5.0);
      const config2 = ImageFilterConfig.blur(sigmaX: 5.0, sigmaY: 5.0);
      const config3 = ImageFilterConfig.blur(sigmaX: 10.0, sigmaY: 10.0);
      const config4 = ImageFilterConfig.blur(sigmaX: 5.0, sigmaY: 5.0, bounded: true);

      expect(config1, config2);
      expect(config1.hashCode, config2.hashCode);
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
      expect(config1, isNot(equals(config4)));
      expect(config1.hashCode, isNot(equals(config4.hashCode)));
    });

    test('ImageFilterConfig.blur toString and shortDescription', () {
      const config = ImageFilterConfig.blur(sigmaX: 2.5, sigmaY: 3.5, tileMode: ui.TileMode.decal);
      expect(config.shortDescription, 'blur(2.5, 3.5, decal, unbounded)');
      expect(config.toString(), 'ImageFilterConfig.blur(2.5, 3.5, decal, unbounded)');

      const config2 = ImageFilterConfig.blur(sigmaX: 2.5, sigmaY: 3.5, bounded: true);
      expect(config2.shortDescription, 'blur(2.5, 3.5, clamp, bounded)');
      expect(config2.toString(), 'ImageFilterConfig.blur(2.5, 3.5, clamp, bounded)');
    });

    test('ImageFilterConfig.compose == and hashCode', () {
      const blur1 = ImageFilterConfig.blur(sigmaX: 5.0, sigmaY: 5.0);
      const blur2 = ImageFilterConfig.blur(sigmaX: 10.0, sigmaY: 10.0);

      const config1 = ImageFilterConfig.compose(outer: blur1, inner: blur2);
      const config2 = ImageFilterConfig.compose(outer: blur1, inner: blur2);
      const config3 = ImageFilterConfig.compose(outer: blur2, inner: blur1);

      expect(config1, config2);
      expect(config1.hashCode, config2.hashCode);
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
    });

    test('ImageFilterConfig.compose toString and shortDescription', () {
      const blur1 = ImageFilterConfig.blur(sigmaX: 5.0, sigmaY: 5.0);
      const blur2 = ImageFilterConfig.blur(sigmaX: 10.0, sigmaY: 10.0);
      const config = ImageFilterConfig.compose(outer: blur1, inner: blur2);

      final expectedShortDescription = '${blur2.shortDescription} -> ${blur1.shortDescription}';
      expect(config.shortDescription, expectedShortDescription);
      expect(
        config.toString(),
        'ImageFilterConfig.compose(source -> $expectedShortDescription -> result)',
      );
    });

    test('ImageFilter resolves correctly', () {
      const bounds = Rect.fromLTWH(0, 0, 100, 100);
      const context = ImageFilterContext(bounds: bounds);

      final imageFilter = ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0);
      final directConfig = ImageFilterConfig(imageFilter);
      expect(directConfig.resolve(context), imageFilter);

      const blurConfig = ImageFilterConfig.blur(sigmaX: 10.0, sigmaY: 10.0);
      final ui.ImageFilter resolvedBlur = blurConfig.resolve(context);
      expect(resolvedBlur, isA<ui.ImageFilter>());
      expect(resolvedBlur.shortDescription, 'blur(10.0, 10.0, clamp)');

      const boundedBlurConfig = ImageFilterConfig.blur(sigmaX: 10.0, sigmaY: 10.0, bounded: true);
      final ui.ImageFilter resolvedBoundedBlur = boundedBlurConfig.resolve(context);
      expect(resolvedBoundedBlur, isA<ui.ImageFilter>());
      expect(
        resolvedBoundedBlur.shortDescription,
        'blur(10.0, 10.0, clamp, bounds: Rect.fromLTRB(0.0, 0.0, 100.0, 100.0))',
      );

      const composeConfig = ImageFilterConfig.compose(outer: blurConfig, inner: boundedBlurConfig);
      final ui.ImageFilter resolvedCompose = composeConfig.resolve(context);
      expect(resolvedCompose, isA<ui.ImageFilter>());
      expect(
        resolvedCompose.shortDescription,
        'blur(10.0, 10.0, clamp, bounds: Rect.fromLTRB(0.0, 0.0, 100.0, 100.0)) '
        '-> blur(10.0, 10.0, clamp)',
      );
    });
  });
}
