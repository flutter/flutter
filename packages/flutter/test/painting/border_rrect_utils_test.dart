// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RRectUtils', () {
    test('inflateRRect increases the size while preserving radius proportions', () {
      final RRect original = RRect.fromLTRBAndCorners(
        10.0,
        20.0,
        30.0,
        60.0,
        topLeft: const Radius.circular(5.0),
        topRight: const Radius.circular(6.0),
        bottomRight: const Radius.circular(7.0),
        bottomLeft: const Radius.circular(8.0),
      );

      const EdgeInsets insets = EdgeInsets.fromLTRB(2.0, 3.0, 4.0, 5.0);
      final RRect inflated = RRectUtils.inflateRRect(original, insets);

      expect(inflated.left, equals(original.left - insets.left));
      expect(inflated.top, equals(original.top - insets.top));
      expect(inflated.right, equals(original.right + insets.right));
      expect(inflated.bottom, equals(original.bottom + insets.bottom));

      expect(inflated.tlRadius.x, equals(original.tlRadius.x + insets.left));
      expect(inflated.tlRadius.y, equals(original.tlRadius.y + insets.top));

      expect(inflated.trRadius.x, equals(original.trRadius.x + insets.right));
      expect(inflated.trRadius.y, equals(original.trRadius.y + insets.top));

      expect(inflated.brRadius.x, equals(original.brRadius.x + insets.right));
      expect(inflated.brRadius.y, equals(original.brRadius.y + insets.bottom));

      expect(inflated.blRadius.x, equals(original.blRadius.x + insets.left));
      expect(inflated.blRadius.y, equals(original.blRadius.y + insets.bottom));
    });

    test('deflateRRect decreases the size while preserving radius proportions', () {
      final RRect original = RRect.fromLTRBAndCorners(
        10.0,
        20.0,
        30.0,
        60.0,
        topLeft: const Radius.circular(8.0),
        topRight: const Radius.circular(9.0),
        bottomRight: const Radius.circular(10.0),
        bottomLeft: const Radius.circular(11.0),
      );

      const EdgeInsets insets = EdgeInsets.fromLTRB(2.0, 3.0, 4.0, 5.0);
      final RRect deflated = RRectUtils.deflateRRect(original, insets);

      expect(deflated.left, equals(original.left + insets.left));
      expect(deflated.top, equals(original.top + insets.top));
      expect(deflated.right, equals(original.right - insets.right));
      expect(deflated.bottom, equals(original.bottom - insets.bottom));

      expect(deflated.tlRadius.x, equals(original.tlRadius.x - insets.left));
      expect(deflated.tlRadius.y, equals(original.tlRadius.y - insets.top));

      expect(deflated.trRadius.x, equals(original.trRadius.x - insets.right));
      expect(deflated.trRadius.y, equals(original.trRadius.y - insets.top));

      expect(deflated.brRadius.x, equals(original.brRadius.x - insets.right));
      expect(deflated.brRadius.y, equals(original.brRadius.y - insets.bottom));

      expect(deflated.blRadius.x, equals(original.blRadius.x - insets.left));
      expect(deflated.blRadius.y, equals(original.blRadius.y - insets.bottom));
    });

    test('inflateRRect with zero insets returns the same RRect', () {
      final RRect original = RRect.fromLTRBAndCorners(
        10.0,
        20.0,
        30.0,
        60.0,
        topLeft: const Radius.circular(5.0),
      );

      final RRect inflated = RRectUtils.inflateRRect(original, EdgeInsets.zero);

      expect(inflated, equals(original));
    });

    test('deflateRRect with zero insets returns the same RRect', () {
      final RRect original = RRect.fromLTRBAndCorners(
        10.0,
        20.0,
        30.0,
        60.0,
        topLeft: const Radius.circular(5.0),
      );

      final RRect deflated = RRectUtils.deflateRRect(original, EdgeInsets.zero);

      expect(deflated, equals(original));
    });

    test('deflateRRect clamps radius to zero when insets are larger than radius', () {
      final RRect original = RRect.fromLTRBAndCorners(
        10.0,
        20.0,
        30.0,
        60.0,
        topLeft: const Radius.circular(3.0),
        topRight: const Radius.circular(3.0),
        bottomRight: const Radius.circular(3.0),
        bottomLeft: const Radius.circular(3.0),
      );

      const EdgeInsets largeInsets = EdgeInsets.all(5.0);
      final RRect deflated = RRectUtils.deflateRRect(original, largeInsets);

      expect(deflated.tlRadius.x, equals(0.0));
      expect(deflated.tlRadius.y, equals(0.0));
      expect(deflated.trRadius.x, equals(0.0));
      expect(deflated.trRadius.y, equals(0.0));
      expect(deflated.brRadius.x, equals(0.0));
      expect(deflated.brRadius.y, equals(0.0));
      expect(deflated.blRadius.x, equals(0.0));
      expect(deflated.blRadius.y, equals(0.0));
    });

    test('inflateRRect and deflateRRect are inverse operations', () {
      final RRect original = RRect.fromLTRBAndCorners(
        10.0,
        20.0,
        30.0,
        60.0,
        topLeft: const Radius.circular(5.0),
        topRight: const Radius.circular(6.0),
        bottomRight: const Radius.circular(7.0),
        bottomLeft: const Radius.circular(8.0),
      );

      const EdgeInsets insets = EdgeInsets.fromLTRB(2.0, 3.0, 4.0, 5.0);

      final RRect inflatedThenDeflated = RRectUtils.deflateRRect(
        RRectUtils.inflateRRect(original, insets),
        insets,
      );

      final RRect deflatedThenInflated = RRectUtils.inflateRRect(
        RRectUtils.deflateRRect(original, insets),
        insets,
      );

      expect(inflatedThenDeflated.left, closeTo(original.left, 0.001));
      expect(inflatedThenDeflated.top, closeTo(original.top, 0.001));
      expect(inflatedThenDeflated.right, closeTo(original.right, 0.001));
      expect(inflatedThenDeflated.bottom, closeTo(original.bottom, 0.001));

      expect(deflatedThenInflated.left, closeTo(original.left, 0.001));
      expect(deflatedThenInflated.top, closeTo(original.top, 0.001));
      expect(deflatedThenInflated.right, closeTo(original.right, 0.001));
      expect(deflatedThenInflated.bottom, closeTo(original.bottom, 0.001));
    });
  });
}
