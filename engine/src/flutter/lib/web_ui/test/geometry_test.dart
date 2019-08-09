// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math show sqrt;
import 'dart:math' show pi;

import 'package:ui/ui.dart';

import 'package:test/test.dart';

void main() {
  group('Offset', () {
    test('Offset.direction', () {
      expect(const Offset(0.0, 0.0).direction, 0.0);
      expect(const Offset(0.0, 1.0).direction, pi / 2.0);
      expect(const Offset(0.0, -1.0).direction, -pi / 2.0);
      expect(const Offset(1.0, 0.0).direction, 0.0);
      expect(const Offset(1.0, 1.0).direction, pi / 4.0);
      expect(const Offset(1.0, -1.0).direction, -pi / 4.0);
      expect(const Offset(-1.0, 0.0).direction, pi);
      expect(const Offset(-1.0, 1.0).direction, pi * 3.0 / 4.0);
      expect(const Offset(-1.0, -1.0).direction, -pi * 3.0 / 4.0);
    });

    test('Offset.fromDirection', () {
      expect(Offset.fromDirection(0.0, 0.0), const Offset(0.0, 0.0));
      expect(Offset.fromDirection(pi / 2.0).dx, closeTo(0.0, 1e-12)); // aah, floating point math. i love you so.
      expect(Offset.fromDirection(pi / 2.0).dy, 1.0);
      expect(Offset.fromDirection(-pi / 2.0).dx, closeTo(0.0, 1e-12));
      expect(Offset.fromDirection(-pi / 2.0).dy, -1.0);
      expect(Offset.fromDirection(0.0), const Offset(1.0, 0.0));
      expect(Offset.fromDirection(pi / 4.0).dx, closeTo(1.0 / math.sqrt(2.0), 1e-12));
      expect(Offset.fromDirection(pi / 4.0).dy, closeTo(1.0 / math.sqrt(2.0), 1e-12));
      expect(Offset.fromDirection(-pi / 4.0).dx, closeTo(1.0 / math.sqrt(2.0), 1e-12));
      expect(Offset.fromDirection(-pi / 4.0).dy, closeTo(-1.0 / math.sqrt(2.0), 1e-12));
      expect(Offset.fromDirection(pi).dx, -1.0);
      expect(Offset.fromDirection(pi).dy, closeTo(0.0, 1e-12));
      expect(Offset.fromDirection(pi * 3.0 / 4.0).dx, closeTo(-1.0 / math.sqrt(2.0), 1e-12));
      expect(Offset.fromDirection(pi * 3.0 / 4.0).dy, closeTo(1.0 / math.sqrt(2.0), 1e-12));
      expect(Offset.fromDirection(-pi * 3.0 / 4.0).dx, closeTo(-1.0 / math.sqrt(2.0), 1e-12));
      expect(Offset.fromDirection(-pi * 3.0 / 4.0).dy, closeTo(-1.0 / math.sqrt(2.0), 1e-12));
      expect(Offset.fromDirection(0.0, 2.0), const Offset(2.0, 0.0));
      expect(Offset.fromDirection(pi / 6, 2.0).dx, closeTo(math.sqrt(3.0), 1e-12));
      expect(Offset.fromDirection(pi / 6, 2.0).dy, closeTo(1.0, 1e-12));
    });
  });

  group('Size', () {
    test('Size created from doubles', () {
      const Size size = Size(5.0, 7.0);
      expect(size.width, equals(5.0));
      expect(size.height, equals(7.0));
      expect(size.shortestSide, equals(5.0));
      expect(size.longestSide, equals(7.0));
    });

    test('Size.aspectRatio', () {
      expect(const Size(0.0, 0.0).aspectRatio, 0.0);
      expect(const Size(-0.0, 0.0).aspectRatio, 0.0);
      expect(const Size(0.0, -0.0).aspectRatio, 0.0);
      expect(const Size(-0.0, -0.0).aspectRatio, 0.0);
      expect(const Size(0.0, 1.0).aspectRatio, 0.0);
      expect(const Size(0.0, -1.0).aspectRatio, -0.0);
      expect(const Size(1.0, 0.0).aspectRatio, double.infinity);
      expect(const Size(1.0, 1.0).aspectRatio, 1.0);
      expect(const Size(1.0, -1.0).aspectRatio, -1.0);
      expect(const Size(-1.0, 0.0).aspectRatio, -double.infinity);
      expect(const Size(-1.0, 1.0).aspectRatio, -1.0);
      expect(const Size(-1.0, -1.0).aspectRatio, 1.0);
      expect(const Size(3.0, 4.0).aspectRatio, 3.0 / 4.0);
    });
  });

  group('Rect', () {
    test('Rect accessors', () {
      final Rect r = Rect.fromLTRB(1.0, 3.0, 5.0, 7.0);
      expect(r.left, equals(1.0));
      expect(r.top, equals(3.0));
      expect(r.right, equals(5.0));
      expect(r.bottom, equals(7.0));
    });

    test('Rect created by width and height', () {
      final Rect r = Rect.fromLTWH(1.0, 3.0, 5.0, 7.0);
      expect(r.left, equals(1.0));
      expect(r.top, equals(3.0));
      expect(r.right, equals(6.0));
      expect(r.bottom, equals(10.0));
      expect(r.shortestSide, equals(5.0));
      expect(r.longestSide, equals(7.0));
    });

    test('Rect intersection', () {
      final Rect r1 = Rect.fromLTRB(0.0, 0.0, 100.0, 100.0);
      final Rect r2 = Rect.fromLTRB(50.0, 50.0, 200.0, 200.0);
      final Rect r3 = r1.intersect(r2);
      expect(r3.left, equals(50.0));
      expect(r3.top, equals(50.0));
      expect(r3.right, equals(100.0));
      expect(r3.bottom, equals(100.0));

      final Rect r4 = r2.intersect(r1);
      expect(r4, equals(r3));
    });

    test('Rect expandToInclude overlapping rects', () {
      final Rect r1 = Rect.fromLTRB(0.0, 0.0, 100.0, 100.0);
      final Rect r2 = Rect.fromLTRB(50.0, 50.0, 200.0, 200.0);
      final Rect r3 = r1.expandToInclude(r2);
      expect(r3.left, equals(0.0));
      expect(r3.top, equals(0.0));
      expect(r3.right, equals(200.0));
      expect(r3.bottom, equals(200.0));

      final Rect r4 = r2.expandToInclude(r1);
      expect(r4, equals(r3));
    });

    test('Rect expandToInclude crossing rects', () {
      final Rect r1 = Rect.fromLTRB(50.0, 0.0, 50.0, 200.0);
      final Rect r2 = Rect.fromLTRB(0.0, 50.0, 200.0, 50.0);
      final Rect r3 = r1.expandToInclude(r2);
      expect(r3.left, equals(0.0));
      expect(r3.top, equals(0.0));
      expect(r3.right, equals(200.0));
      expect(r3.bottom, equals(200.0));

      final Rect r4 = r2.expandToInclude(r1);
      expect(r4, equals(r3));
    });
  });

  group('RRect', () {
    test('RRect.fromRectXY', () {
      final Rect baseRect = Rect.fromLTWH(1.0, 3.0, 5.0, 7.0);
      final RRect r = RRect.fromRectXY(baseRect, 1.0, 1.0);
      expect(r.left, equals(1.0));
      expect(r.top, equals(3.0));
      expect(r.right, equals(6.0));
      expect(r.bottom, equals(10.0));
      expect(r.shortestSide, equals(5.0));
      expect(r.longestSide, equals(7.0));
    });
  });
}
