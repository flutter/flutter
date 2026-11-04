// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
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
  });
}
