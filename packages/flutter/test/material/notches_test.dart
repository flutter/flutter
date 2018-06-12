// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CircularNotch', () {
    test('host and guest must intersect', () {
      const CircularNotch notch = const CircularNotch();
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTWH(50.0, 50.0, 10.0, 10.0);
      const Offset start = const Offset(10.0, 100.0);
      const Offset end = const Offset(60.0, 100.0);
      expect(() {notch.getPath(host, guest, start, end);}, throwsFlutterError);
    });

    test('start/end must be on top edge', () {
      const CircularNotch notch = const CircularNotch();
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 90.0, 210.0, 110.0);

      Offset start = const Offset(180.0, 100.0);
      Offset end = const Offset(220.0, 110.0);
      expect(() {notch.getPath(host, guest, start, end);}, throwsFlutterError);

      start = const Offset(180.0, 110.0);
      end = const Offset(220.0, 100.0);
      expect(() {notch.getPath(host, guest, start, end);}, throwsFlutterError);
    });

    test('notch no margin', () {
      const CircularNotch notch = const CircularNotch(notchMargin: 0.0);
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 90.0, 210.0, 110.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path actualNotch = notch.getPath(host, guest, start, end);
      final Path notchedRectangle =
        createNotchedRectangle(host, start.dx, end.dx, actualNotch);

      expect(pathDoesNotContainCircle(notchedRectangle, guest), isTrue);
    });

    test('notch with margin', () {
      const CircularNotch notch = const CircularNotch(notchMargin: 4.0);
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 90.0, 210.0, 110.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path actualNotch = notch.getPath(host, guest, start, end);
      final Path notchedRectangle =
        createNotchedRectangle(host, start.dx, end.dx, actualNotch);
      expect(pathDoesNotContainCircle(notchedRectangle, guest.inflate(4.0)), isTrue);
    });

    test('notch circle center above BAB', () {
      const CircularNotch notch = const CircularNotch(notchMargin: 4.0);
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 85.0, 210.0, 105.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path actualNotch = notch.getPath(host, guest, start, end);
      final Path notchedRectangle =
        createNotchedRectangle(host, start.dx, end.dx, actualNotch);
      expect(pathDoesNotContainCircle(notchedRectangle, guest.inflate(4.0)), isTrue);
    });

    test('circular notch, notch center below BAB', () {
      const CircularNotch notch = const CircularNotch(notchMargin: 4.0);
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 95.0, 210.0, 115.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path actualNotch = notch.getPath(host, guest, start, end);
      final Path notchedRectangle =
        createNotchedRectangle(host, start.dx, end.dx, actualNotch);
      expect(pathDoesNotContainCircle(notchedRectangle, guest.inflate(4.0)), isTrue);
    });

    test('start/end are swappable', () {
      const CircularNotch notch = const CircularNotch(notchMargin: 4.0);
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 95.0, 210.0, 115.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path notch1 = notch.getPath(host, guest, start, end);
      final Path notchedRectangle1 =
        createNotchedRectangle(host, start.dx, end.dx,notch1);

      final Path notch2 = notch.getPath(host, guest, end, start);
      final Path notchedRectangle2 =
        createNotchedRectangle(host, start.dx, end.dx, notch2);

      expect(notchedRectangle1,
        coversSameAreaAs(
          notchedRectangle2,
          areaToCompare: host.inflate(5.0),
        )
      );
    });

    test('no notch when there is no overlap', () {
      const CircularNotch notch = const CircularNotch(notchMargin: 4.0);
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 40.0, 210.0, 60.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path actualNotch = notch.getPath(host, guest, start, end);
      final Path notchedRectangle =
        createNotchedRectangle(host, start.dx, end.dx, actualNotch);
      expect(pathDoesNotContainCircle(notchedRectangle, guest.inflate(4.0)), isTrue);
    });
  });
}

Path createNotchedRectangle(Rect container, double startX, double endX, Path notch) {
  return new Path()
    ..moveTo(container.left, container.top)
    ..lineTo(startX, container.top)
    ..addPath(notch, Offset.zero)
    ..lineTo(container.right, container.top)
    ..lineTo(container.right, container.bottom)
    ..lineTo(container.left, container.bottom)
    ..close();
}

bool pathDoesNotContainCircle(Path path, Rect circleBounds) {
  assert(circleBounds.width == circleBounds.height);
  final double radius = circleBounds.width / 2.0;

  for (double theta = 0.0; theta <= 2.0 * math.pi; theta += math.pi / 20.0) {
    for (double i = 0.0; i < 1; i += 0.01) {
      final double x = i * radius * math.cos(theta);
      final double y = i * radius * math.sin(theta);
      if (path.contains(new Offset(x,y) + circleBounds.center))
        return false;
    }
  }
  return true;
}
