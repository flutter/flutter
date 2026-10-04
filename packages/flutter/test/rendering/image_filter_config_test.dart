// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageFilterConfig', () {
    test('ImageFilterContext control', () {
      const context = ImageFilterContext(bounds: Rect.zero);
      expect(context.bounds, Rect.zero);
    });

    test('ImageFilterConfig.new == and hashCode', () {
      final imageFilter1 = ui.ImageFilter.blur(sigmaX: 5.1, sigmaY: 5.1);
      final imageFilter2 = ui.ImageFilter.blur(sigmaX: 10.1, sigmaY: 10.1);
      final imageFilter3 = ui.ImageFilter.blur(sigmaX: 10.1, sigmaY: 10.1);

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

    test('ImageFilterConfig.new toString and debugShortDescription', () {
      final imageFilter = ui.ImageFilter.blur(sigmaX: 5.1, sigmaY: 5.1);
      final config = ImageFilterConfig(imageFilter);

      expect(config.debugShortDescription, 'blur(5.1, 5.1, unspecified)');
      expect(config.toString(), 'ImageFilterConfig(blur(5.1, 5.1, unspecified))');
    });

    test('ImageFilterConfig.new get filter', () {
      final imageFilter = ui.ImageFilter.blur(sigmaX: 5.1, sigmaY: 5.1);
      final config = ImageFilterConfig(imageFilter);

      expect(config.filter!.toString(), 'ImageFilter.blur(5.1, 5.1, unspecified)');
    });

    test('ImageFilterConfig.blur == and hashCode', () {
      const config1 = ImageFilterConfig.blur(sigmaX: 5.1, sigmaY: 5.1);
      const config2 = ImageFilterConfig.blur(sigmaX: 5.1, sigmaY: 5.1);
      const config3 = ImageFilterConfig.blur(sigmaX: 10.1, sigmaY: 10.1);
      const config4 = ImageFilterConfig.blur(sigmaX: 5.1, sigmaY: 5.1, bounded: true);

      expect(config1, config2);
      expect(config1.hashCode, config2.hashCode);
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
      expect(config1, isNot(equals(config4)));
      expect(config1.hashCode, isNot(equals(config4.hashCode)));
    });

    test('ImageFilterConfig.blur toString and debugShortDescription', () {
      const config = ImageFilterConfig.blur(sigmaX: 2.5, sigmaY: 3.5, tileMode: ui.TileMode.decal);
      expect(config.debugShortDescription, 'blur(2.5, 3.5, decal, unbounded)');
      expect(config.toString(), 'ImageFilterConfig.blur(2.5, 3.5, decal, unbounded)');

      const config2 = ImageFilterConfig.blur(sigmaX: 2.5, sigmaY: 3.5, bounded: true);
      expect(config2.debugShortDescription, 'blur(2.5, 3.5, clamp, bounded)');
      expect(config2.toString(), 'ImageFilterConfig.blur(2.5, 3.5, clamp, bounded)');
    });

    test('ImageFilterConfig.compose == and hashCode', () {
      const blur1 = ImageFilterConfig.blur(sigmaX: 5.1, sigmaY: 5.1);
      const blur2 = ImageFilterConfig.blur(sigmaX: 10.1, sigmaY: 10.1);

      const config1 = ImageFilterConfig.compose(outer: blur1, inner: blur2);
      const config2 = ImageFilterConfig.compose(outer: blur1, inner: blur2);
      const config3 = ImageFilterConfig.compose(outer: blur2, inner: blur1);

      expect(config1, config2);
      expect(config1.hashCode, config2.hashCode);
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
    });

    test('ImageFilterConfig.compose toString and debugShortDescription', () {
      const blur1 = ImageFilterConfig.blur(sigmaX: 5.1, sigmaY: 5.1);
      const blur2 = ImageFilterConfig.blur(sigmaX: 10.1, sigmaY: 10.1);
      const config = ImageFilterConfig.compose(outer: blur1, inner: blur2);

      final expectedShortDescription =
          '${blur2.debugShortDescription} -> ${blur1.debugShortDescription}';
      expect(config.debugShortDescription, expectedShortDescription);
      expect(
        config.toString(),
        'ImageFilterConfig.compose(source -> $expectedShortDescription -> result)',
      );
    });

    test('ImageFilter resolves correctly', () {
      const bounds = Rect.fromLTWH(0.1, 0.1, 100.1, 100.1);
      const context = ImageFilterContext(bounds: bounds);

      final imageFilter = ui.ImageFilter.blur(sigmaX: 5.1, sigmaY: 5.1);
      final directConfig = ImageFilterConfig(imageFilter);
      expect(directConfig.resolve(context), imageFilter);

      const blurConfig = ImageFilterConfig.blur(sigmaX: 10.1, sigmaY: 10.1);
      final ui.ImageFilter resolvedBlur = blurConfig.resolve(context);
      expect(resolvedBlur, isA<ui.ImageFilter>());
      expect(resolvedBlur.debugShortDescription, 'blur(10.1, 10.1, clamp)');

      const boundedBlurConfig = ImageFilterConfig.blur(sigmaX: 10.1, sigmaY: 10.1, bounded: true);
      final ui.ImageFilter resolvedBoundedBlur = boundedBlurConfig.resolve(context);
      expect(resolvedBoundedBlur, isA<ui.ImageFilter>());
      expect(
        resolvedBoundedBlur.debugShortDescription,
        'blur(10.1, 10.1, clamp, bounds: Rect.fromLTRB(0.1, 0.1, 100.2, 100.2))',
      );

      const composeConfig = ImageFilterConfig.compose(outer: blurConfig, inner: boundedBlurConfig);
      final ui.ImageFilter resolvedCompose = composeConfig.resolve(context);
      expect(resolvedCompose, isA<ui.ImageFilter>());
      expect(
        resolvedCompose.debugShortDescription,
        'blur(10.1, 10.1, clamp, bounds: Rect.fromLTRB(0.1, 0.1, 100.2, 100.2)) '
        '-> blur(10.1, 10.1, clamp)',
      );
    }, skip: kIsWeb); // `bounds` is currently not supported on Web.
    // https://github.com/flutter/flutter/issues/175899
  });
}
