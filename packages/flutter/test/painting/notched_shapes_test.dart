// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

void main() {
  group('CircularNotchedRectangle', () {
    test('guest and host don\'t overlap', () {
      const CircularNotchedRectangle shape = CircularNotchedRectangle();
      final Rect host = Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = Rect.fromLTWH(50.0, 50.0, 10.0, 10.0);

      final Path actualPath = shape.getOuterPath(host, guest);
      final Path expectedPath = Path()..addRect(host);

      expect(
        actualPath,
        coversSameAreaAs(
          expectedPath,
          areaToCompare: host.inflate(5.0),
          sampleSize: 40,
        )
      );
    });

    test('guest center above host', () {
      const CircularNotchedRectangle shape = CircularNotchedRectangle();
      final Rect host = Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = Rect.fromLTRB(190.0, 85.0, 210.0, 105.0);

      final Path actualPath = shape.getOuterPath(host, guest);

      expect(pathDoesNotContainCircle(actualPath, guest), isTrue);
    });

    test('guest center below host', () {
      const CircularNotchedRectangle shape = CircularNotchedRectangle();
      final Rect host = Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = Rect.fromLTRB(190.0, 95.0, 210.0, 115.0);

      final Path actualPath = shape.getOuterPath(host, guest);

      expect(pathDoesNotContainCircle(actualPath, guest), isTrue);
    });

  });
}

bool pathDoesNotContainCircle(Path path, Rect circleBounds) {
  assert(circleBounds.width == circleBounds.height);
  final double radius = circleBounds.width / 2.0;

  for (double theta = 0.0; theta <= 2.0 * math.pi; theta += math.pi / 20.0) {
    for (double i = 0.0; i < 1; i += 0.01) {
      final double x = i * radius * math.cos(theta);
      final double y = i * radius * math.sin(theta);
      if (path.contains(Offset(x,y) + circleBounds.center))
        return false;
    }
  }
  return true;
}
