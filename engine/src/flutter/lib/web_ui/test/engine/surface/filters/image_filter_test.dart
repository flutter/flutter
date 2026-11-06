// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import '../../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpUnitTests();
  group('ImageFilter constructors', () {
    test('matrix is copied', () {
      final matrix = Matrix4.identity();
      final Float64List storage = matrix.toFloat64();
      final filter1 = ImageFilter.matrix(storage);
      storage[0] = 2.0;
      final filter2 = ImageFilter.matrix(storage);
      expect(filter1, filter1);
      expect(filter2, filter2);
      expect(filter1, isNot(equals(filter2)));
      expect(filter2, isNot(equals(filter1)));
    });

    test('matrix tests all values on ==', () {
      final matrix = Matrix4.identity();
      final Float64List storage = matrix.toFloat64();
      final filter1a = ImageFilter.matrix(storage, filterQuality: FilterQuality.none);
      final filter1b = ImageFilter.matrix(storage, filterQuality: FilterQuality.high);

      storage[0] = 2.0;
      final filter2a = ImageFilter.matrix(storage, filterQuality: FilterQuality.none);
      final filter2b = ImageFilter.matrix(storage, filterQuality: FilterQuality.high);

      expect(filter1a, filter1a);
      expect(filter1a, isNot(equals(filter1b)));
      expect(filter1a, isNot(equals(filter2a)));
      expect(filter1a, isNot(equals(filter2b)));

      expect(filter1b, isNot(equals(filter1a)));
      expect(filter1b, filter1b);
      expect(filter1b, isNot(equals(filter2a)));
      expect(filter1b, isNot(equals(filter2b)));

      expect(filter2a, isNot(equals(filter1a)));
      expect(filter2a, isNot(equals(filter1b)));
      expect(filter2a, filter2a);
      expect(filter2a, isNot(equals(filter2b)));

      expect(filter2b, isNot(equals(filter1a)));
      expect(filter2b, isNot(equals(filter1b)));
      expect(filter2b, isNot(equals(filter2a)));
      expect(filter2b, filter2b);
    });

    test('blur tests all values on ==', () {
      final filter1 = ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0, tileMode: TileMode.decal);
      final filter2 = ImageFilter.blur(sigmaX: 2.0, sigmaY: 3.0, tileMode: TileMode.decal);
      final filter3 = ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0, tileMode: TileMode.mirror);

      expect(filter1, filter1);
      expect(filter1, isNot(equals(filter2)));
      expect(filter1, isNot(equals(filter3)));

      expect(filter2, isNot(equals(filter1)));
      expect(filter2, filter2);
      expect(filter2, isNot(equals(filter3)));

      expect(filter3, isNot(equals(filter1)));
      expect(filter3, isNot(equals(filter2)));
      expect(filter3, filter3);
    });

    test('blur bounds participate in ==, hashCode and description', () {
      const bounds1 = Rect.fromLTRB(0.5, 1.5, 10.5, 20.5);
      const bounds2 = Rect.fromLTRB(0.5, 1.5, 10.5, 30.5);
      ImageFilter blur({Rect? bounds}) =>
          ImageFilter.blur(sigmaX: 2.5, sigmaY: 3.5, tileMode: TileMode.decal, bounds: bounds);

      final ImageFilter unbounded = blur();
      final ImageFilter bounded1a = blur(bounds: bounds1);
      final ImageFilter bounded1b = blur(bounds: bounds1);
      final ImageFilter bounded2 = blur(bounds: bounds2);

      expect(bounded1a, bounded1b);
      expect(bounded1a.hashCode, bounded1b.hashCode);
      expect(bounded1a, isNot(equals(bounded2)));
      expect(bounded2, isNot(equals(bounded1a)));
      expect(bounded1a, isNot(equals(unbounded)));
      expect(unbounded, isNot(equals(bounded1a)));

      // Built at runtime, so equal rects are distinct instances.
      Rect runtimeBounds() => Rect.fromLTRB(double.parse('0.5'), 1.5, 10.5, 20.5);
      final equalPairs = <(ImageFilter, ImageFilter)>[
        (blur(bounds: runtimeBounds()), blur(bounds: runtimeBounds())),
        // ignore: avoid_redundant_argument_values
        (ImageFilter.blur(sigmaX: 2.5, bounds: null), ImageFilter.blur(sigmaX: 2.5)),
        (ImageFilter.blur(bounds: runtimeBounds()), ImageFilter.blur(bounds: runtimeBounds())),
      ];
      for (final (ImageFilter a, ImageFilter b) in equalPairs) {
        expect(a, b);
        expect(<ImageFilter>{a}.contains(b), isTrue);
      }

      ImageFilter compose(ImageFilter inner) => ImageFilter.compose(outer: bounded2, inner: inner);
      expect(compose(bounded1a), compose(bounded1b));
      expect(compose(bounded1a).hashCode, compose(bounded1b).hashCode);
      expect(compose(bounded1a), isNot(equals(compose(unbounded))));
      expect(
        compose(bounded1a).debugShortDescription,
        '${bounded1a.debugShortDescription} -> ${bounded2.debugShortDescription}',
      );

      final zero = 0.0.toString(); // '0' on dart2js, '0.0' on dart2wasm.
      final cases = <(ImageFilter, String)>[
        (unbounded, 'blur(2.5, 3.5, decal)'),
        (bounded1a, 'blur(2.5, 3.5, decal, bounds: Rect.fromLTRB(0.5, 1.5, 10.5, 20.5))'),
        (bounded2, 'blur(2.5, 3.5, decal, bounds: Rect.fromLTRB(0.5, 1.5, 10.5, 30.5))'),
        (
          ImageFilter.blur(sigmaX: 2.5, sigmaY: 3.5, bounds: bounds1),
          'blur(2.5, 3.5, unspecified, bounds: Rect.fromLTRB(0.5, 1.5, 10.5, 20.5))',
        ),
        (
          blur(bounds: Rect.zero),
          'blur(2.5, 3.5, decal, bounds: Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))',
        ),
        (
          ImageFilter.blur(tileMode: TileMode.mirror, bounds: bounds1),
          'blur($zero, $zero, mirror, bounds: Rect.fromLTRB(0.5, 1.5, 10.5, 20.5))',
        ),
      ];
      for (final (ImageFilter filter, String description) in cases) {
        expect(filter.debugShortDescription, description);
        expect(filter.toString(), 'ImageFilter.$description');
        final blurFilter = filter as EngineBlurImageFilter;
        final copy = ImageFilter.blur(
          sigmaX: blurFilter.sigmaX,
          sigmaY: blurFilter.sigmaY,
          tileMode: blurFilter.tileMode,
        );
        expect(filter == copy, !description.contains('bounds:'), reason: description);
      }
    });

    test('bounded blur has the same filter bounds as an unbounded blur', () {
      const input = Rect.fromLTRB(0, 0, 20, 20);
      Rect filterBounds(ImageFilter filter) => (filter as EngineImageFilter).filterBounds(input);
      for (final sigma in <double>[2.5, 0]) {
        final bounded = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, bounds: input.deflate(5));
        final unbounded = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
        expect(filterBounds(bounded), filterBounds(unbounded), reason: 'sigma: $sigma');
      }
    });
  });
}
