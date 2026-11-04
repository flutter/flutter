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

      final cases = <(ImageFilter, String)>[
        (unbounded, 'blur(2.5, 3.5, decal)'),
        (bounded1a, 'blur(2.5, 3.5, decal, bounds: Rect.fromLTRB(0.5, 1.5, 10.5, 20.5))'),
        (bounded2, 'blur(2.5, 3.5, decal, bounds: Rect.fromLTRB(0.5, 1.5, 10.5, 30.5))'),
        (
          ImageFilter.blur(sigmaX: 2.5, sigmaY: 3.5, bounds: bounds1),
          'blur(2.5, 3.5, unspecified, bounds: Rect.fromLTRB(0.5, 1.5, 10.5, 20.5))',
        ),
      ];
      for (final (ImageFilter filter, String description) in cases) {
        expect(filter.debugShortDescription, description);
        expect(filter.toString(), 'ImageFilter.$description');
      }
    });

    test('blur bounds compare by value, and null bounds match omitted bounds', () {
      // Built at runtime so that equal rects are distinct instances.
      double runtime(double value) => double.parse('$value');
      Rect boundsOf(double bottom) => Rect.fromLTRB(runtime(0.5), runtime(1.5), 10.5, bottom);
      ImageFilter blur({double sigma = 2.5, Rect? bounds}) =>
          ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, bounds: bounds);

      // ignore: avoid_redundant_argument_values
      final explicitNull = ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5, bounds: null);
      final omitted = ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5);

      final cases = <(String, ImageFilter, ImageFilter)>[
        ('distinct equal rects', blur(bounds: boundsOf(20.5)), blur(bounds: boundsOf(20.5))),
        ('explicit null bounds', explicitNull, omitted),
        ('zero rect', blur(bounds: Rect.zero), blur(bounds: Rect.fromLTRB(0, 0, 0, runtime(0)))),
        (
          'zero sigma',
          blur(sigma: 0, bounds: boundsOf(20.5)),
          blur(sigma: 0, bounds: boundsOf(20.5)),
        ),
      ];
      for (final (String name, ImageFilter a, ImageFilter b) in cases) {
        expect(a, b, reason: name);
        expect(a.hashCode, b.hashCode, reason: name);
        expect(<ImageFilter>{a}.contains(b), isTrue, reason: name);
        expect(<ImageFilter, String>{a: name}[b], name, reason: name);
      }
      expect(explicitNull.debugShortDescription, 'blur(2.5, 2.5, unspecified)');
    });

    test('blur keeps degenerate and zero-sigma bounds', () {
      // Doubles print as '0' on dart2js and '0.0' on dart2wasm.
      final zero = 0.0.toString();
      final cases = <(ImageFilter, ImageFilter, String)>[
        (
          ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5, bounds: Rect.zero),
          ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
          'blur(2.5, 2.5, unspecified, bounds: Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))',
        ),
        (
          ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5, bounds: const Rect.fromLTRB(10, 20, 0, 5)),
          ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
          'blur(2.5, 2.5, unspecified, bounds: Rect.fromLTRB(10.0, 20.0, 0.0, 5.0))',
        ),
        (
          ImageFilter.blur(tileMode: TileMode.mirror, bounds: const Rect.fromLTRB(1, 2, 3, 4)),
          ImageFilter.blur(tileMode: TileMode.mirror),
          'blur($zero, $zero, mirror, bounds: Rect.fromLTRB(1.0, 2.0, 3.0, 4.0))',
        ),
      ];
      for (final (ImageFilter bounded, ImageFilter unbounded, String description) in cases) {
        expect(bounded.debugShortDescription, description);
        expect(bounded, isNot(equals(unbounded)), reason: description);
        expect(unbounded, isNot(equals(bounded)), reason: description);
      }
    });

    test('compose distinguishes and describes a bounded inner blur', () {
      const bounds = Rect.fromLTRB(0.5, 1.5, 10.5, 20.5);
      final outer = ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5, tileMode: TileMode.clamp);
      ImageFilter compose({Rect? bounds}) => ImageFilter.compose(
        outer: outer,
        inner: ImageFilter.blur(sigmaX: 2.5, sigmaY: 3.5, tileMode: TileMode.decal, bounds: bounds),
      );

      expect(compose(bounds: bounds), compose(bounds: bounds));
      expect(compose(bounds: bounds).hashCode, compose(bounds: bounds).hashCode);
      expect(compose(bounds: bounds), isNot(equals(compose())));
      expect(compose(), isNot(equals(compose(bounds: bounds))));
      expect(
        compose(bounds: bounds).debugShortDescription,
        'blur(2.5, 3.5, decal, bounds: Rect.fromLTRB(0.5, 1.5, 10.5, 20.5)) '
        '-> blur(1.5, 1.5, clamp)',
      );
      expect(
        compose(bounds: bounds).toString(),
        'ImageFilter.compose(source -> '
        'blur(2.5, 3.5, decal, bounds: Rect.fromLTRB(0.5, 1.5, 10.5, 20.5)) '
        '-> blur(1.5, 1.5, clamp) -> result)',
      );
    });

    test('bounded blur renders with the same filter bounds as an unbounded blur', () {
      const bounds = Rect.fromLTRB(5, 5, 15, 15);
      const input = Rect.fromLTRB(0, 0, 20, 20);
      final cases = <(double, TileMode?)>[(2.5, TileMode.decal), (2.5, null), (0, TileMode.clamp)];
      for (final (double sigma, TileMode? tileMode) in cases) {
        final bounded = ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: tileMode,
          bounds: bounds,
        ) as EngineImageFilter;
        final unbounded =
            ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: tileMode) as EngineImageFilter;
        final reason = 'sigma: $sigma, tileMode: $tileMode';
        expect(bounded.filterBounds(input), unbounded.filterBounds(input), reason: reason);
        expect(
          bounded.getBackendFilter(defaultBlurTileMode: TileMode.mirror).filterBounds(input),
          unbounded.getBackendFilter(defaultBlurTileMode: TileMode.mirror).filterBounds(input),
          reason: reason,
        );
      }
    });
  });
}
