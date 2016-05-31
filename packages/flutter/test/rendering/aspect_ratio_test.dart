// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';
import 'rendering_tester.dart';

void main() {
  test('Intrinsic sizing 2.0', () {
    RenderAspectRatio box = new RenderAspectRatio(aspectRatio: 2.0);

    expect(box.getMinIntrinsicWidth(200.0), 400.0);
    expect(box.getMinIntrinsicWidth(400.0), 800.0);

    expect(box.getMaxIntrinsicWidth(200.0), 400.0);
    expect(box.getMaxIntrinsicWidth(400.0), 800.0);

    expect(box.getMinIntrinsicHeight(200.0), 100.0);
    expect(box.getMinIntrinsicHeight(400.0), 200.0);

    expect(box.getMaxIntrinsicHeight(200.0), 100.0);
    expect(box.getMaxIntrinsicHeight(400.0), 200.0);

    expect(box.getMinIntrinsicWidth(double.INFINITY), 0.0);
    expect(box.getMaxIntrinsicWidth(double.INFINITY), 0.0);
    expect(box.getMinIntrinsicHeight(double.INFINITY), 0.0);
    expect(box.getMaxIntrinsicHeight(double.INFINITY), 0.0);
  });

  test('Intrinsic sizing 0.5', () {
    RenderAspectRatio box = new RenderAspectRatio(aspectRatio: 0.5);

    expect(box.getMinIntrinsicWidth(200.0), 100.0);
    expect(box.getMinIntrinsicWidth(400.0), 200.0);

    expect(box.getMaxIntrinsicWidth(200.0), 100.0);
    expect(box.getMaxIntrinsicWidth(400.0), 200.0);

    expect(box.getMinIntrinsicHeight(200.0), 400.0);
    expect(box.getMinIntrinsicHeight(400.0), 800.0);

    expect(box.getMaxIntrinsicHeight(200.0), 400.0);
    expect(box.getMaxIntrinsicHeight(400.0), 800.0);

    expect(box.getMinIntrinsicWidth(double.INFINITY), 0.0);
    expect(box.getMaxIntrinsicWidth(double.INFINITY), 0.0);
    expect(box.getMinIntrinsicHeight(double.INFINITY), 0.0);
    expect(box.getMaxIntrinsicHeight(double.INFINITY), 0.0);
  });

  test('Intrinsic sizing 2.0', () {
    RenderAspectRatio box = new RenderAspectRatio(
      aspectRatio: 2.0,
      child: new RenderSizedBox(const Size(90.0, 70.0))
    );

    expect(box.getMinIntrinsicWidth(200.0), 400.0);
    expect(box.getMinIntrinsicWidth(400.0), 800.0);

    expect(box.getMaxIntrinsicWidth(200.0), 400.0);
    expect(box.getMaxIntrinsicWidth(400.0), 800.0);

    expect(box.getMinIntrinsicHeight(200.0), 100.0);
    expect(box.getMinIntrinsicHeight(400.0), 200.0);

    expect(box.getMaxIntrinsicHeight(200.0), 100.0);
    expect(box.getMaxIntrinsicHeight(400.0), 200.0);

    expect(box.getMinIntrinsicWidth(double.INFINITY), 90.0);
    expect(box.getMaxIntrinsicWidth(double.INFINITY), 90.0);
    expect(box.getMinIntrinsicHeight(double.INFINITY), 70.0);
    expect(box.getMaxIntrinsicHeight(double.INFINITY), 70.0);
  });

  test('Intrinsic sizing 0.5', () {
    RenderAspectRatio box = new RenderAspectRatio(
      aspectRatio: 0.5,
      child: new RenderSizedBox(const Size(90.0, 70.0))
    );

    expect(box.getMinIntrinsicWidth(200.0), 100.0);
    expect(box.getMinIntrinsicWidth(400.0), 200.0);

    expect(box.getMaxIntrinsicWidth(200.0), 100.0);
    expect(box.getMaxIntrinsicWidth(400.0), 200.0);

    expect(box.getMinIntrinsicHeight(200.0), 400.0);
    expect(box.getMinIntrinsicHeight(400.0), 800.0);

    expect(box.getMaxIntrinsicHeight(200.0), 400.0);
    expect(box.getMaxIntrinsicHeight(400.0), 800.0);

    expect(box.getMinIntrinsicWidth(double.INFINITY), 90.0);
    expect(box.getMaxIntrinsicWidth(double.INFINITY), 90.0);
    expect(box.getMinIntrinsicHeight(double.INFINITY), 70.0);
    expect(box.getMaxIntrinsicHeight(double.INFINITY), 70.0);
  });
}
