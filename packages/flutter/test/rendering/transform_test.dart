// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

Point round(Point value) {
  return new Point(value.x.roundToDouble(), value.y.roundToDouble());
}

void main() {
  test('RenderTransform - identity', () {
    RenderBox inner;
    RenderBox sizer = new RenderTransform(
      transform: new Matrix4.identity(),
      alignment: FractionalOffset.center,
      child: inner = new RenderSizedBox(const Size(100.0, 100.0)),
    );
    layout(sizer, constraints: new BoxConstraints.tight(const Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
    expect(inner.globalToLocal(const Point(0.0, 0.0)), equals(const Point(0.0, 0.0)));
    expect(inner.globalToLocal(const Point(100.0, 100.0)), equals(const Point(100.0, 100.0)));
    expect(inner.globalToLocal(const Point(25.0, 75.0)), equals(const Point(25.0, 75.0)));
    expect(inner.globalToLocal(const Point(50.0, 50.0)), equals(const Point(50.0, 50.0)));
    expect(inner.localToGlobal(const Point(0.0, 0.0)), equals(const Point(0.0, 0.0)));
    expect(inner.localToGlobal(const Point(100.0, 100.0)), equals(const Point(100.0, 100.0)));
    expect(inner.localToGlobal(const Point(25.0, 75.0)), equals(const Point(25.0, 75.0)));
    expect(inner.localToGlobal(const Point(50.0, 50.0)), equals(const Point(50.0, 50.0)));
  });

  test('RenderTransform - identity with internal offset', () {
    RenderBox inner;
    RenderBox sizer = new RenderTransform(
      transform: new Matrix4.identity(),
      alignment: FractionalOffset.center,
      child: new RenderPadding(
        padding: const EdgeInsets.only(left: 20.0),
        child: inner = new RenderSizedBox(const Size(80.0, 100.0)),
      ),
    );
    layout(sizer, constraints: new BoxConstraints.tight(const Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
    expect(inner.globalToLocal(const Point(0.0, 0.0)), equals(const Point(-20.0, 0.0)));
    expect(inner.globalToLocal(const Point(100.0, 100.0)), equals(const Point(80.0, 100.0)));
    expect(inner.globalToLocal(const Point(25.0, 75.0)), equals(const Point(5.0, 75.0)));
    expect(inner.globalToLocal(const Point(50.0, 50.0)), equals(const Point(30.0, 50.0)));
    expect(inner.localToGlobal(const Point(0.0, 0.0)), equals(const Point(20.0, 0.0)));
    expect(inner.localToGlobal(const Point(100.0, 100.0)), equals(const Point(120.0, 100.0)));
    expect(inner.localToGlobal(const Point(25.0, 75.0)), equals(const Point(45.0, 75.0)));
    expect(inner.localToGlobal(const Point(50.0, 50.0)), equals(const Point(70.0, 50.0)));
  });

  test('RenderTransform - translation', () {
    RenderBox inner;
    RenderBox sizer = new RenderTransform(
      transform: new Matrix4.translationValues(50.0, 200.0, 0.0),
      alignment: FractionalOffset.center,
      child: inner = new RenderSizedBox(const Size(100.0, 100.0)),
    );
    layout(sizer, constraints: new BoxConstraints.tight(const Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
    expect(inner.globalToLocal(const Point(0.0, 0.0)), equals(const Point(-50.0, -200.0)));
    expect(inner.globalToLocal(const Point(100.0, 100.0)), equals(const Point(50.0, -100.0)));
    expect(inner.globalToLocal(const Point(25.0, 75.0)), equals(const Point(-25.0, -125.0)));
    expect(inner.globalToLocal(const Point(50.0, 50.0)), equals(const Point(0.0, -150.0)));
    expect(inner.localToGlobal(const Point(0.0, 0.0)), equals(const Point(50.0, 200.0)));
    expect(inner.localToGlobal(const Point(100.0, 100.0)), equals(const Point(150.0, 300.0)));
    expect(inner.localToGlobal(const Point(25.0, 75.0)), equals(const Point(75.0, 275.0)));
    expect(inner.localToGlobal(const Point(50.0, 50.0)), equals(const Point(100.0, 250.0)));
  });

  test('RenderTransform - translation with internal offset', () {
    RenderBox inner;
    RenderBox sizer = new RenderTransform(
      transform: new Matrix4.translationValues(50.0, 200.0, 0.0),
      alignment: FractionalOffset.center,
      child: new RenderPadding(
        padding: const EdgeInsets.only(left: 20.0),
        child: inner = new RenderSizedBox(const Size(80.0, 100.0)),
      ),
    );
    layout(sizer, constraints: new BoxConstraints.tight(const Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
    expect(inner.globalToLocal(const Point(0.0, 0.0)), equals(const Point(-70.0, -200.0)));
    expect(inner.globalToLocal(const Point(100.0, 100.0)), equals(const Point(30.0, -100.0)));
    expect(inner.globalToLocal(const Point(25.0, 75.0)), equals(const Point(-45.0, -125.0)));
    expect(inner.globalToLocal(const Point(50.0, 50.0)), equals(const Point(-20.0, -150.0)));
    expect(inner.localToGlobal(const Point(0.0, 0.0)), equals(const Point(70.0, 200.0)));
    expect(inner.localToGlobal(const Point(100.0, 100.0)), equals(const Point(170.0, 300.0)));
    expect(inner.localToGlobal(const Point(25.0, 75.0)), equals(const Point(95.0, 275.0)));
    expect(inner.localToGlobal(const Point(50.0, 50.0)), equals(const Point(120.0, 250.0)));
  });

  test('RenderTransform - rotation', () {
    RenderBox inner;
    RenderBox sizer = new RenderTransform(
      transform: new Matrix4.rotationZ(math.PI),
      alignment: FractionalOffset.center,
      child: inner = new RenderSizedBox(const Size(100.0, 100.0)),
    );
    layout(sizer, constraints: new BoxConstraints.tight(const Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
    expect(round(inner.globalToLocal(const Point(0.0, 0.0))), equals(const Point(100.0, 100.0)));
    expect(round(inner.globalToLocal(const Point(100.0, 100.0))), equals(const Point(0.0, 0.0)));
    expect(round(inner.globalToLocal(const Point(25.0, 75.0))), equals(const Point(75.0, 25.0)));
    expect(round(inner.globalToLocal(const Point(50.0, 50.0))), equals(const Point(50.0, 50.0)));
    expect(round(inner.localToGlobal(const Point(0.0, 0.0))), equals(const Point(100.0, 100.0)));
    expect(round(inner.localToGlobal(const Point(100.0, 100.0))), equals(const Point(0.0, 0.0)));
    expect(round(inner.localToGlobal(const Point(25.0, 75.0))), equals(const Point(75.0, 25.0)));
    expect(round(inner.localToGlobal(const Point(50.0, 50.0))), equals(const Point(50.0, 50.0)));
  });

  test('RenderTransform - rotation with internal offset', () {
    RenderBox inner;
    RenderBox sizer = new RenderTransform(
      transform: new Matrix4.rotationZ(math.PI),
      alignment: FractionalOffset.center,
      child: new RenderPadding(
        padding: const EdgeInsets.only(left: 20.0),
        child: inner = new RenderSizedBox(const Size(80.0, 100.0)),
      ),
    );
    layout(sizer, constraints: new BoxConstraints.tight(const Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
    expect(round(inner.globalToLocal(const Point(0.0, 0.0))), equals(const Point(80.0, 100.0)));
    expect(round(inner.globalToLocal(const Point(100.0, 100.0))), equals(const Point(-20.0, 0.0)));
    expect(round(inner.globalToLocal(const Point(25.0, 75.0))), equals(const Point(55.0, 25.0)));
    expect(round(inner.globalToLocal(const Point(50.0, 50.0))), equals(const Point(30.0, 50.0)));
    expect(round(inner.localToGlobal(const Point(0.0, 0.0))), equals(const Point(80.0, 100.0)));
    expect(round(inner.localToGlobal(const Point(100.0, 100.0))), equals(const Point(-20.0, 0.0)));
    expect(round(inner.localToGlobal(const Point(25.0, 75.0))), equals(const Point(55.0, 25.0)));
    expect(round(inner.localToGlobal(const Point(50.0, 50.0))), equals(const Point(30.0, 50.0)));
  });

  test('RenderTransform - perspective - globalToLocal', () {
    RenderBox inner;
    RenderBox sizer = new RenderTransform(
      transform: rotateAroundXAxis(math.PI * 0.25), // at pi/4, we are about 70 pixels high
      alignment: FractionalOffset.center,
      child: inner = new RenderSizedBox(const Size(100.0, 100.0)),
    );
    layout(sizer, constraints: new BoxConstraints.tight(const Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);

    expect(round(inner.globalToLocal(const Point(25.0, 50.0))), equals(const Point(25.0, 50.0)));
    expect(inner.globalToLocal(const Point(25.0, 17.0)).y, greaterThan(0.0));
    expect(inner.globalToLocal(const Point(25.0, 17.0)).y, lessThan(10.0));
    expect(inner.globalToLocal(const Point(25.0, 73.0)).y, greaterThan(90.0));
    expect(inner.globalToLocal(const Point(25.0, 73.0)).y, lessThan(100.0));
    expect(inner.globalToLocal(const Point(25.0, 17.0)).y, equals(-inner.globalToLocal(const Point(25.0, 73.0)).y));
  }, skip: true); // https://github.com/flutter/flutter/issues/6080

  test('RenderTransform - perspective - localToGlobal', () {
    RenderBox inner;
    RenderBox sizer = new RenderTransform(
      transform: rotateAroundXAxis(math.PI * 0.4999), // at pi/2, we're seeing the box on its edge,
      alignment: FractionalOffset.center,
      child: inner = new RenderSizedBox(const Size(100.0, 100.0)),
    );
    layout(sizer, constraints: new BoxConstraints.tight(const Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);

    // the inner widget has a height of about half a pixel at this rotation, so
    // everything should end up around the middle of the outer box.
    expect(inner.localToGlobal(const Point(25.0, 50.0)), equals(const Point(25.0, 50.0)));
    expect(round(inner.localToGlobal(const Point(25.0, 75.0))), equals(const Point(25.0, 50.0)));
    expect(round(inner.localToGlobal(const Point(25.0, 100.0))), equals(const Point(25.0, 50.0)));
  });
}

Matrix4 rotateAroundXAxis(double a) {
  // 3D rotation transform with alpha=a
  double x = 1.0;
  double y = 0.0;
  double z = 0.0;
  double sc = math.sin(a / 2.0) * math.cos(a / 2.0);
  double sq = math.sin(a / 2.0) * math.sin(a / 2.0);
  return new Matrix4.fromList(<double>[
    // col 1
    1.0 - 2.0 * (y * y + z * z) * sq,
    2.0 * (x * y * sq + z * sc),
    2.0 * (x * z * sq - y * sc),
    0.0,
    // col 2
    2.0 * (x * y * sq - z * sc),
    1.0 - 2.0 * (x * x + z * z) * sq,
    2.0 * (y * z * sq + x * sc),
    0.0,
    // col 3
    2.0 * (x * z * sq + y * sc),
    2.0 * (y * z * sq - x * sc),
    1.0 - 2.0 * (x * x + z * z) * sq,
    0.0,
    // col 4
    0.0, 0.0, 0.0, 1.0,
  ]);
}