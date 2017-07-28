// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    expect(FractionalOffset.lerp(null, b, 0.25), equals(b * 0.25));
    expect(FractionalOffset.lerp(a, null, 0.25), equals(a * 0.75));
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
}
