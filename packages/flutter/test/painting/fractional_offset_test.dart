// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FractionalOffset control test', () {
    const FractionalOffset offset = const FractionalOffset(0.5, 0.25);

    expect(offset, hasOneLineDescription);
    expect(offset.hashCode, equals(const FractionalOffset(0.5, 0.25).hashCode));

    expect(offset / 2.0, const FractionalOffset(0.25, 0.125));
    expect(offset ~/ 2.0, const FractionalOffset(0.0, 0.0));
    expect(offset % 5.0, const FractionalOffset(0.5, 0.25));
  });

  test('FractionalOffset.lerp()', () {
    final FractionalOffset a = FractionalOffset.topLeft;
    final FractionalOffset b = FractionalOffset.topCenter;
    expect(FractionalOffset.lerp(a, b, 0.25), equals(const FractionalOffset(0.125, 0.0)));

    expect(FractionalOffset.lerp(null, null, 0.25), isNull);
    expect(FractionalOffset.lerp(null, b, 0.25), equals(new FractionalOffset(0.5, 0.5 - 0.125)));
    expect(FractionalOffset.lerp(a, null, 0.25), equals(new FractionalOffset(0.125, 0.125)));
  });

  test('FractionalOffset.fromOffsetAndSize()', () {
    final FractionalOffset a = new FractionalOffset.fromOffsetAndSize(const Offset(100.0, 100.0), const Size(200.0, 400.0));
    expect(a, const FractionalOffset(0.5, 0.25));
  });

  test('FractionalOffset.fromOffsetAndRect()', () {
    final FractionalOffset a = new FractionalOffset.fromOffsetAndRect(const Offset(150.0, 120.0), new Rect.fromLTWH(50.0, 20.0, 200.0, 400.0));
    expect(a, const FractionalOffset(0.5, 0.25));
  });

  test('FractionalOffsetGeometry.resolve()', () {
    expect(new FractionalOffsetDirectional(0.25, 0.3).resolve(TextDirection.ltr), const FractionalOffset(0.25, 0.3));
    expect(new FractionalOffsetDirectional(0.25, 0.3).resolve(TextDirection.rtl), const FractionalOffset(0.75, 0.3));
    expect(new FractionalOffsetDirectional(-0.25, 0.3).resolve(TextDirection.ltr), const FractionalOffset(-0.25, 0.3));
    expect(new FractionalOffsetDirectional(-0.25, 0.3).resolve(TextDirection.rtl), const FractionalOffset(1.25, 0.3));
    expect(new FractionalOffsetDirectional(1.25, 0.3).resolve(TextDirection.ltr), const FractionalOffset(1.25, 0.3));
    expect(new FractionalOffsetDirectional(1.25, 0.3).resolve(TextDirection.rtl), const FractionalOffset(-0.25, 0.3));
    expect(new FractionalOffsetDirectional(0.5, -0.3).resolve(TextDirection.ltr), const FractionalOffset(0.5, -0.3));
    expect(new FractionalOffsetDirectional(0.5, -0.3).resolve(TextDirection.rtl), const FractionalOffset(0.5, -0.3));
    expect(new FractionalOffsetDirectional(0.0, 0.0).resolve(TextDirection.ltr), const FractionalOffset(0.0, 0.0));
    expect(new FractionalOffsetDirectional(0.0, 0.0).resolve(TextDirection.rtl), const FractionalOffset(1.0, 0.0));
    expect(new FractionalOffsetDirectional(1.0, 1.0).resolve(TextDirection.ltr), const FractionalOffset(1.0, 1.0));
    expect(new FractionalOffsetDirectional(1.0, 1.0).resolve(TextDirection.rtl), const FractionalOffset(0.0, 1.0));
    expect(new FractionalOffsetDirectional(1.0, 2.0), new FractionalOffsetDirectional(1.0, 2.0));
    expect(new FractionalOffsetDirectional(1.0, 2.0).hashCode, isNot(new FractionalOffsetDirectional(2.0, 1.0)));
    expect(new FractionalOffsetDirectional(0.0, 0.0).resolve(TextDirection.ltr),
           new FractionalOffsetDirectional(1.0, 0.0).resolve(TextDirection.rtl));
    expect(new FractionalOffsetDirectional(0.0, 0.0).resolve(TextDirection.ltr),
     isNot(new FractionalOffsetDirectional(1.0, 0.0).resolve(TextDirection.ltr)));
    expect(new FractionalOffsetDirectional(1.0, 0.0).resolve(TextDirection.ltr),
     isNot(new FractionalOffsetDirectional(1.0, 0.0).resolve(TextDirection.rtl)));
  });

  test('FractionalOffsetGeometry.lerp', () {
    final FractionalOffsetGeometry directional1 = const FractionalOffsetDirectional(0.125, 0.625);
    final FractionalOffsetGeometry normal1 = const FractionalOffset(0.25, 0.875);
    final FractionalOffsetGeometry mixed1 = const FractionalOffset(0.0625, 0.5625).add(const FractionalOffsetDirectional(0.1875, 0.6875));
    final FractionalOffsetGeometry directional2 = const FractionalOffsetDirectional(2.0, 3.0);
    final FractionalOffsetGeometry normal2 = const FractionalOffset(2.0, 3.0);
    final FractionalOffsetGeometry mixed2 = const FractionalOffset(2.0, 3.0).add(const FractionalOffsetDirectional(5.0, 3.0));

    expect(FractionalOffsetGeometry.lerp(directional1, directional2, 0.5), const FractionalOffsetDirectional(0.125 + (2.0 - 0.125) / 2.0, 0.625 + (3.0 - 0.625) / 2.0));
    expect(FractionalOffsetGeometry.lerp(directional2, directional2, 0.5), directional2);
    expect(FractionalOffsetGeometry.lerp(directional1, normal2, 0.5).resolve(TextDirection.ltr), const FractionalOffset(1.0 +  1.0 / 16.0, 0.625 + (3.0 - 0.625) / 2.0));
    expect(FractionalOffsetGeometry.lerp(directional1, normal2, 0.5).resolve(TextDirection.rtl), const FractionalOffset(1.0 + 15.0 / 16.0, 0.625 + (3.0 - 0.625) / 2.0));
    expect(FractionalOffsetGeometry.lerp(directional1, mixed1, 0.5).resolve(TextDirection.ltr), new FractionalOffset(1.0 / 32.0 + 2.5 / 16.0, lerpDouble(0.625, 0.5625 + 0.6875, 0.5)));
    expect(FractionalOffsetGeometry.lerp(directional1, mixed1, 0.5).resolve(TextDirection.rtl), new FractionalOffset(1.0 / 32.0 + 1.0 - 2.5 / 16.0, lerpDouble(0.625, 0.5625 + 0.6875, 0.5)));
    expect(FractionalOffsetGeometry.lerp(mixed1, mixed2, 0.5).resolve(TextDirection.ltr), new FractionalOffset(3.0 + 5.0 / 8.0, lerpDouble(0.5625 + 0.6875, 6.0, 0.5)));
    expect(FractionalOffsetGeometry.lerp(mixed1, mixed2, 0.5).resolve(TextDirection.rtl), new FractionalOffset(2.0 - 41.0 / 16.0, lerpDouble(0.5625 + 0.6875, 6.0, 0.5)));
    expect(FractionalOffsetGeometry.lerp(normal1, normal2, 0.5), const FractionalOffset(0.25 + (2.0 - 0.25) / 2.0, 0.875 + (3.0 - 0.875) / 2.0));
    expect(FractionalOffsetGeometry.lerp(normal1, mixed1, 0.5).resolve(TextDirection.ltr), new FractionalOffset(lerpDouble(0.25, 0.0625, 0.5) + lerpDouble(0.0, 0.1875, 0.5), lerpDouble(0.875, 0.5625 + 0.6875, 0.5)));
    expect(FractionalOffsetGeometry.lerp(normal1, mixed1, 0.5).resolve(TextDirection.rtl), new FractionalOffset(lerpDouble(0.25, 0.0625, 0.5) + 1.0 - lerpDouble(0.0, 0.1875, 0.5), lerpDouble(0.875, 0.5625 + 0.6875, 0.5)));
    expect(FractionalOffsetGeometry.lerp(null, mixed1, 0.5).resolve(TextDirection.ltr), FractionalOffsetGeometry.lerp(FractionalOffset.center, mixed1, 0.5).resolve(TextDirection.ltr));
    expect(FractionalOffsetGeometry.lerp(mixed2, null, 0.25).resolve(TextDirection.ltr), FractionalOffsetGeometry.lerp(FractionalOffset.center, mixed2, 0.75).resolve(TextDirection.ltr));
    expect(FractionalOffsetGeometry.lerp(directional1, null, 1.0), FractionalOffsetDirectional.center);
    expect(FractionalOffsetGeometry.lerp(null, null, 0.5), isNull);
  });

  test('FractionalOffsetGeometry.lerp more', () {
    final FractionalOffsetGeometry mixed1 = const FractionalOffset(10.0, 20.0).add(const FractionalOffsetDirectional(30.0, 50.0));
    final FractionalOffsetGeometry mixed2 = const FractionalOffset(70.0, 110.0).add(const FractionalOffsetDirectional(130.0, 170.0));
    final FractionalOffsetGeometry mixed3 = const FractionalOffset(25.0, 42.5).add(const FractionalOffsetDirectional(55.0, 80.0));

    expect(FractionalOffsetGeometry.lerp(mixed1, mixed2, 0.0), mixed1);
    expect(FractionalOffsetGeometry.lerp(mixed1, mixed2, 1.0), mixed2);
    expect(FractionalOffsetGeometry.lerp(mixed1, mixed2, 0.25), mixed3);
  });

  test('FractionalOffsetGeometry add/subtract', () {
    final FractionalOffsetGeometry directional = const FractionalOffsetDirectional(1.0, 2.0);
    final FractionalOffsetGeometry normal = const FractionalOffset(3.0, 5.0);
    expect(directional.add(normal).resolve(TextDirection.ltr), const FractionalOffset(4.0, 7.0));
    expect(directional.add(normal).resolve(TextDirection.rtl), const FractionalOffset(3.0, 7.0));
    expect(directional.subtract(normal).resolve(TextDirection.ltr), const FractionalOffset(-2.0, -3.0));
    expect(directional.subtract(normal).resolve(TextDirection.rtl), const FractionalOffset(-3.0, -3.0));
    expect(normal.add(normal), normal * 2.0);
    expect(normal.subtract(normal), FractionalOffset.topLeft);
    expect(directional.add(directional), directional * 2.0);
    expect(directional.subtract(directional), FractionalOffsetDirectional.topStart);
  });

  test('FractionalOffsetGeometry operators', () {
    expect(new FractionalOffsetDirectional(1.0, 2.0) * 2.0, new FractionalOffsetDirectional(2.0, 4.0));
    expect(new FractionalOffsetDirectional(1.0, 2.0) / 2.0, new FractionalOffsetDirectional(0.5, 1.0));
    expect(new FractionalOffsetDirectional(1.0, 2.0) % 2.0, new FractionalOffsetDirectional(1.0, 0.0));
    expect(new FractionalOffsetDirectional(1.0, 2.0) ~/ 2.0, new FractionalOffsetDirectional(0.0, 1.0));
    expect(FractionalOffset.topLeft.add(new FractionalOffsetDirectional(1.0, 2.0) * 2.0), new FractionalOffsetDirectional(2.0, 4.0));
    expect(FractionalOffset.topLeft.add(new FractionalOffsetDirectional(1.0, 2.0) / 2.0), new FractionalOffsetDirectional(0.5, 1.0));
    expect(FractionalOffset.topLeft.add(new FractionalOffsetDirectional(1.0, 2.0) % 2.0), new FractionalOffsetDirectional(1.0, 0.0));
    expect(FractionalOffset.topLeft.add(new FractionalOffsetDirectional(1.0, 2.0) ~/ 2.0), new FractionalOffsetDirectional(0.0, 1.0));
    expect(new FractionalOffset(1.0, 2.0) * 2.0, new FractionalOffset(2.0, 4.0));
    expect(new FractionalOffset(1.0, 2.0) / 2.0, new FractionalOffset(0.5, 1.0));
    expect(new FractionalOffset(1.0, 2.0) % 2.0, new FractionalOffset(1.0, 0.0));
    expect(new FractionalOffset(1.0, 2.0) ~/ 2.0, new FractionalOffset(0.0, 1.0));
  });

  test('FractionalOffsetGeometry operators', () {
    expect(new FractionalOffset(1.0, 2.0) + new FractionalOffset(3.0, 5.0), new FractionalOffset(4.0, 7.0));
    expect(new FractionalOffset(1.0, 2.0) - new FractionalOffset(3.0, 5.0), new FractionalOffset(-2.0, -3.0));
    expect(new FractionalOffsetDirectional(1.0, 2.0) + new FractionalOffsetDirectional(3.0, 5.0), new FractionalOffsetDirectional(4.0, 7.0));
    expect(new FractionalOffsetDirectional(1.0, 2.0) - new FractionalOffsetDirectional(3.0, 5.0), new FractionalOffsetDirectional(-2.0, -3.0));
  });

  test('FractionalOffsetGeometry toString', () {
    expect(new FractionalOffset(1.0001, 2.0001).toString(), 'FractionalOffset(1.0, 2.0)');
    expect(new FractionalOffset(0.0, 0.0).toString(), 'FractionalOffset.topLeft');
    expect(new FractionalOffset(0.0, 1.0).add(new FractionalOffsetDirectional(1.0, 0.0)).toString(), 'FractionalOffsetDirectional.bottomEnd');
    expect(new FractionalOffset(0.0001, 0.0001).toString(), 'FractionalOffset(0.0, 0.0)');
    expect(new FractionalOffset(0.0, 0.0).toString(), 'FractionalOffset.topLeft');
    expect(new FractionalOffsetDirectional(0.0, 0.0).toString(), 'FractionalOffsetDirectional.topStart');
    expect(new FractionalOffset(1.0, 1.0).add(new FractionalOffsetDirectional(1.0, 1.0)).toString(), 'FractionalOffset(1.0, 2.0) + FractionalOffsetDirectional(1.0, 0.0)');
  });
}
