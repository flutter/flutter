// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import '../flutter_test_alternative.dart';

class RenderTestBox extends RenderBox {
  double value = 0.0;
  double next() { value += 1.0; return value; }
  @override double computeMinIntrinsicWidth(double height) => next();
  @override double computeMaxIntrinsicWidth(double height) => next();
  @override double computeMinIntrinsicHeight(double width) => next();
  @override double computeMaxIntrinsicHeight(double width) => next();
}

void main() {
  test('Intrinsics cache', () {
    final RenderBox test = RenderTestBox();

    expect(test.getMinIntrinsicWidth(0.0), equals(1.0));
    expect(test.getMinIntrinsicWidth(100.0), equals(2.0));
    expect(test.getMinIntrinsicWidth(200.0), equals(3.0));
    expect(test.getMinIntrinsicWidth(0.0), equals(1.0));
    expect(test.getMinIntrinsicWidth(100.0), equals(2.0));
    expect(test.getMinIntrinsicWidth(200.0), equals(3.0));

    expect(test.getMaxIntrinsicWidth(0.0), equals(4.0));
    expect(test.getMaxIntrinsicWidth(100.0), equals(5.0));
    expect(test.getMaxIntrinsicWidth(200.0), equals(6.0));
    expect(test.getMaxIntrinsicWidth(0.0), equals(4.0));
    expect(test.getMaxIntrinsicWidth(100.0), equals(5.0));
    expect(test.getMaxIntrinsicWidth(200.0), equals(6.0));

    expect(test.getMinIntrinsicHeight(0.0), equals(7.0));
    expect(test.getMinIntrinsicHeight(100.0), equals(8.0));
    expect(test.getMinIntrinsicHeight(200.0), equals(9.0));
    expect(test.getMinIntrinsicHeight(0.0), equals(7.0));
    expect(test.getMinIntrinsicHeight(100.0), equals(8.0));
    expect(test.getMinIntrinsicHeight(200.0), equals(9.0));

    expect(test.getMaxIntrinsicHeight(0.0), equals(10.0));
    expect(test.getMaxIntrinsicHeight(100.0), equals(11.0));
    expect(test.getMaxIntrinsicHeight(200.0), equals(12.0));
    expect(test.getMaxIntrinsicHeight(0.0), equals(10.0));
    expect(test.getMaxIntrinsicHeight(100.0), equals(11.0));
    expect(test.getMaxIntrinsicHeight(200.0), equals(12.0));

    // now read them all again backwards
    expect(test.getMaxIntrinsicHeight(200.0), equals(12.0));
    expect(test.getMaxIntrinsicHeight(100.0), equals(11.0));
    expect(test.getMaxIntrinsicHeight(0.0), equals(10.0));
    expect(test.getMinIntrinsicHeight(200.0), equals(9.0));
    expect(test.getMinIntrinsicHeight(100.0), equals(8.0));
    expect(test.getMinIntrinsicHeight(0.0), equals(7.0));
    expect(test.getMaxIntrinsicWidth(200.0), equals(6.0));
    expect(test.getMaxIntrinsicWidth(100.0), equals(5.0));
    expect(test.getMaxIntrinsicWidth(0.0), equals(4.0));
    expect(test.getMinIntrinsicWidth(200.0), equals(3.0));
    expect(test.getMinIntrinsicWidth(100.0), equals(2.0));
    expect(test.getMinIntrinsicWidth(0.0), equals(1.0));

  });
}
