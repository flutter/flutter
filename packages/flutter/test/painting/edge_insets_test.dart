// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EdgeInsets control test', () {
    const EdgeInsets insets = const EdgeInsets.fromLTRB(5.0, 7.0, 11.0, 13.0);

    expect(insets, hasOneLineDescription);
    expect(insets.hashCode, equals(new EdgeInsets.fromLTRB(5.0, 7.0, 11.0, 13.0).hashCode));

    expect(insets.topLeft, const Offset(5.0, 7.0));
    expect(insets.topRight, const Offset(-11.0, 7.0));
    expect(insets.bottomLeft, const Offset(5.0, -13.0));
    expect(insets.bottomRight, const Offset(-11.0, -13.0));

    expect(insets.collapsedSize, const Size(16.0, 20.0));
    expect(insets.flipped, const EdgeInsets.fromLTRB(11.0, 13.0, 5.0, 7.0));

    expect(insets.along(Axis.horizontal), equals(16.0));
    expect(insets.along(Axis.vertical), equals(20.0));

    expect(insets.inflateRect(new Rect.fromLTRB(23.0, 32.0, 124.0, 143.0)),
           new Rect.fromLTRB(18.0, 25.0, 135.0, 156.0));

    expect(insets.deflateRect(new Rect.fromLTRB(23.0, 32.0, 124.0, 143.0)),
           new Rect.fromLTRB(28.0, 39.0, 113.0, 130.0));

    expect(insets.inflateSize(const Size(100.0, 125.0)), const Size(116.0, 145.0));
    expect(insets.deflateSize(const Size(100.0, 125.0)), const Size(84.0, 105.0));

    expect(insets / 2.0, const EdgeInsets.fromLTRB(2.5, 3.5, 5.5, 6.5));
    expect(insets ~/ 2.0, const EdgeInsets.fromLTRB(2.0, 3.0, 5.0, 6.0));
    expect(insets % 5.0, const EdgeInsets.fromLTRB(0.0, 2.0, 1.0, 3.0));

  });

  test('EdgeInsets.lerp()', () {
    EdgeInsets a = const EdgeInsets.all(10.0);
    EdgeInsets b = const EdgeInsets.all(20.0);
    expect(EdgeInsets.lerp(a, b, 0.25), equals(a * 1.25));
    expect(EdgeInsets.lerp(a, b, 0.25), equals(b * 0.625));
    expect(EdgeInsets.lerp(a, b, 0.25), equals(a + const EdgeInsets.all(2.5)));
    expect(EdgeInsets.lerp(a, b, 0.25), equals(b - const EdgeInsets.all(7.5)));

    expect(EdgeInsets.lerp(null, null, 0.25), isNull);
    expect(EdgeInsets.lerp(null, b, 0.25), equals(b * 0.25));
    expect(EdgeInsets.lerp(a, null, 0.25), equals(a * 0.75));
  });
}
