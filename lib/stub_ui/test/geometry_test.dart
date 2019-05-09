// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math show sqrt;
import 'dart:math' show pi;

import 'package:ui/ui.dart';

import 'package:test/test.dart';

void main() {
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
    expect(Offset.fromDirection(pi / 2.0).dx,
        closeTo(0.0, 1e-12)); // aah, floating point math. i love you so.
    expect(Offset.fromDirection(pi / 2.0).dy, 1.0);
    expect(Offset.fromDirection(-pi / 2.0).dx, closeTo(0.0, 1e-12));
    expect(Offset.fromDirection(-pi / 2.0).dy, -1.0);
    expect(Offset.fromDirection(0.0), const Offset(1.0, 0.0));
    expect(Offset.fromDirection(pi / 4.0).dx,
        closeTo(1.0 / math.sqrt(2.0), 1e-12));
    expect(Offset.fromDirection(pi / 4.0).dy,
        closeTo(1.0 / math.sqrt(2.0), 1e-12));
    expect(Offset.fromDirection(-pi / 4.0).dx,
        closeTo(1.0 / math.sqrt(2.0), 1e-12));
    expect(Offset.fromDirection(-pi / 4.0).dy,
        closeTo(-1.0 / math.sqrt(2.0), 1e-12));
    expect(Offset.fromDirection(pi).dx, -1.0);
    expect(Offset.fromDirection(pi).dy, closeTo(0.0, 1e-12));
    expect(Offset.fromDirection(pi * 3.0 / 4.0).dx,
        closeTo(-1.0 / math.sqrt(2.0), 1e-12));
    expect(Offset.fromDirection(pi * 3.0 / 4.0).dy,
        closeTo(1.0 / math.sqrt(2.0), 1e-12));
    expect(Offset.fromDirection(-pi * 3.0 / 4.0).dx,
        closeTo(-1.0 / math.sqrt(2.0), 1e-12));
    expect(Offset.fromDirection(-pi * 3.0 / 4.0).dy,
        closeTo(-1.0 / math.sqrt(2.0), 1e-12));
    expect(Offset.fromDirection(0.0, 2.0), const Offset(2.0, 0.0));
    expect(
        Offset.fromDirection(pi / 6, 2.0).dx, closeTo(math.sqrt(3.0), 1e-12));
    expect(Offset.fromDirection(pi / 6, 2.0).dy, closeTo(1.0, 1e-12));
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
}
