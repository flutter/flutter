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
    layout(sizer, constraints: new BoxConstraints.tight(new Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
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
        padding: new EdgeInsets.only(left: 20.0),
        child: inner = new RenderSizedBox(const Size(80.0, 100.0)),
      ),
    );
    layout(sizer, constraints: new BoxConstraints.tight(new Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
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
    layout(sizer, constraints: new BoxConstraints.tight(new Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
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
        padding: new EdgeInsets.only(left: 20.0),
        child: inner = new RenderSizedBox(const Size(80.0, 100.0)),
      ),
    );
    layout(sizer, constraints: new BoxConstraints.tight(new Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
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
    layout(sizer, constraints: new BoxConstraints.tight(new Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
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
        padding: new EdgeInsets.only(left: 20.0),
        child: inner = new RenderSizedBox(const Size(80.0, 100.0)),
      ),
    );
    layout(sizer, constraints: new BoxConstraints.tight(new Size(100.0, 100.0)), alignment: FractionalOffset.topLeft);
    expect(round(inner.globalToLocal(const Point(0.0, 0.0))), equals(const Point(80.0, 100.0)));
    expect(round(inner.globalToLocal(const Point(100.0, 100.0))), equals(const Point(-20.0, 0.0)));
    expect(round(inner.globalToLocal(const Point(25.0, 75.0))), equals(const Point(55.0, 25.0)));
    expect(round(inner.globalToLocal(const Point(50.0, 50.0))), equals(const Point(30.0, 50.0)));
    expect(round(inner.localToGlobal(const Point(0.0, 0.0))), equals(const Point(80.0, 100.0)));
    expect(round(inner.localToGlobal(const Point(100.0, 100.0))), equals(const Point(-20.0, 0.0)));
    expect(round(inner.localToGlobal(const Point(25.0, 75.0))), equals(const Point(55.0, 25.0)));
    expect(round(inner.localToGlobal(const Point(50.0, 50.0))), equals(const Point(30.0, 50.0)));
  });
}
