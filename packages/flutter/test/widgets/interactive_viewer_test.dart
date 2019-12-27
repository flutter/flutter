// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

void main() {
  group('closestPointOnLine', () {
    test('does not modify parameters', () {
      final Vector3 point = Vector3(5.0, 5.0, 0.0);
      final Vector3 a = Vector3(0.0, 0.0, 0.0);
      final Vector3 b = Vector3(10.0, 0.0, 0.0);

      final Vector3 closestPoint = closestPointOnLine(point, a , b);

      expect(closestPoint, Vector3(5.0, 0.0, 0.0));
      expect(point, Vector3(5.0, 5.0, 0.0));
      expect(a, Vector3(0.0, 0.0, 0.0));
      expect(b, Vector3(10.0, 0.0, 0.0));
    });

    test('simple example', () {
      final Vector3 point = Vector3(0.0, 5.0, 0.0);
      final Vector3 a = Vector3(0.0, 0.0, 0.0);
      final Vector3 b = Vector3(5.0, 5.0, 0.0);

      expect(closestPointOnLine(point, a, b), Vector3(2.5, 2.5, 0.0));
    });

    test('closest to a', () {
      final Vector3 point = Vector3(-1.0, -1.0, 0.0);
      final Vector3 a = Vector3(0.0, 0.0, 0.0);
      final Vector3 b = Vector3(5.0, 5.0, 0.0);

      expect(closestPointOnLine(point, a, b), a);
    });

    test('closest to b', () {
      final Vector3 point = Vector3(6.0, 6.0, 0.0);
      final Vector3 a = Vector3(0.0, 0.0, 0.0);
      final Vector3 b = Vector3(5.0, 5.0, 0.0);

      expect(closestPointOnLine(point, a, b), b);
    });

    test('real example', () {
      final Vector3 point = Vector3(-436.9, 433.6, 0.0);
      final Vector3 a = Vector3(-1114.0, -60.3, 0.0);
      final Vector3 b = Vector3(288.8, 432.7, 0.0);

      final Vector3 closestPoint = closestPointOnLine(point, a , b);

      expect(closestPoint.x, closeTo(-356.8, 0.1));
      expect(closestPoint.y, closeTo(205.8, 0.1));
    });
  });
}
