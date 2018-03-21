// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:test/test.dart';
import 'rendering_tester.dart';

void main() {
  test('RenderAspectRatio: Intrinsic sizing 2.0', () {
    final RenderAspectRatio box = new RenderAspectRatio(aspectRatio: 2.0);

    expect(box.getMinIntrinsicWidth(200.0), 400.0);
    expect(box.getMinIntrinsicWidth(400.0), 800.0);

    expect(box.getMaxIntrinsicWidth(200.0), 400.0);
    expect(box.getMaxIntrinsicWidth(400.0), 800.0);

    expect(box.getMinIntrinsicHeight(200.0), 100.0);
    expect(box.getMinIntrinsicHeight(400.0), 200.0);

    expect(box.getMaxIntrinsicHeight(200.0), 100.0);
    expect(box.getMaxIntrinsicHeight(400.0), 200.0);

    expect(box.getMinIntrinsicWidth(double.infinity), 0.0);
    expect(box.getMaxIntrinsicWidth(double.infinity), 0.0);
    expect(box.getMinIntrinsicHeight(double.infinity), 0.0);
    expect(box.getMaxIntrinsicHeight(double.infinity), 0.0);
  });

  test('RenderAspectRatio: Intrinsic sizing 0.5', () {
    final RenderAspectRatio box = new RenderAspectRatio(aspectRatio: 0.5);

    expect(box.getMinIntrinsicWidth(200.0), 100.0);
    expect(box.getMinIntrinsicWidth(400.0), 200.0);

    expect(box.getMaxIntrinsicWidth(200.0), 100.0);
    expect(box.getMaxIntrinsicWidth(400.0), 200.0);

    expect(box.getMinIntrinsicHeight(200.0), 400.0);
    expect(box.getMinIntrinsicHeight(400.0), 800.0);

    expect(box.getMaxIntrinsicHeight(200.0), 400.0);
    expect(box.getMaxIntrinsicHeight(400.0), 800.0);

    expect(box.getMinIntrinsicWidth(double.infinity), 0.0);
    expect(box.getMaxIntrinsicWidth(double.infinity), 0.0);
    expect(box.getMinIntrinsicHeight(double.infinity), 0.0);
    expect(box.getMaxIntrinsicHeight(double.infinity), 0.0);
  });

  test('RenderAspectRatio: Intrinsic sizing 2.0', () {
    final RenderAspectRatio box = new RenderAspectRatio(
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

    expect(box.getMinIntrinsicWidth(double.infinity), 90.0);
    expect(box.getMaxIntrinsicWidth(double.infinity), 90.0);
    expect(box.getMinIntrinsicHeight(double.infinity), 70.0);
    expect(box.getMaxIntrinsicHeight(double.infinity), 70.0);
  });

  test('RenderAspectRatio: Intrinsic sizing 0.5', () {
    final RenderAspectRatio box = new RenderAspectRatio(
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

    expect(box.getMinIntrinsicWidth(double.infinity), 90.0);
    expect(box.getMaxIntrinsicWidth(double.infinity), 90.0);
    expect(box.getMinIntrinsicHeight(double.infinity), 70.0);
    expect(box.getMaxIntrinsicHeight(double.infinity), 70.0);
  });

  test('RenderAspectRatio: Unbounded', () {
    bool hadError = false;
    final FlutterExceptionHandler oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      hadError = true;
    };
    final RenderBox box = new RenderConstrainedOverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: new RenderAspectRatio(
        aspectRatio: 0.5,
        child: new RenderSizedBox(const Size(90.0, 70.0))
      ),
    );
    expect(hadError, false);
    layout(box);
    expect(hadError, true);
    FlutterError.onError = oldHandler;
  });

  test('RenderAspectRatio: Sizing', () {
    RenderConstrainedOverflowBox outside;
    RenderAspectRatio inside;
    layout(outside = new RenderConstrainedOverflowBox(
      child: inside = new RenderAspectRatio(aspectRatio: 1.0),
    ));
    pumpFrame();
    expect(inside.size, const Size(800.0, 600.0));
    outside.minWidth = 0.0;
    outside.minHeight = 0.0;

    outside.maxWidth = 100.0;
    outside.maxHeight = 90.0;
    pumpFrame();
    expect(inside.size, const Size(90.0, 90.0));

    outside.maxWidth = 90.0;
    outside.maxHeight = 100.0;
    pumpFrame();
    expect(inside.size, const Size(90.0, 90.0));

    outside.maxWidth = double.infinity;
    outside.maxHeight = 90.0;
    pumpFrame();
    expect(inside.size, const Size(90.0, 90.0));

    outside.maxWidth = 90.0;
    outside.maxHeight = double.infinity;
    pumpFrame();
    expect(inside.size, const Size(90.0, 90.0));

    inside.aspectRatio = 2.0;

    outside.maxWidth = 100.0;
    outside.maxHeight = 90.0;
    pumpFrame();
    expect(inside.size, const Size(100.0, 50.0));

    outside.maxWidth = 90.0;
    outside.maxHeight = 100.0;
    pumpFrame();
    expect(inside.size, const Size(90.0, 45.0));

    outside.maxWidth = double.infinity;
    outside.maxHeight = 90.0;
    pumpFrame();
    expect(inside.size, const Size(180.0, 90.0));

    outside.maxWidth = 90.0;
    outside.maxHeight = double.infinity;
    pumpFrame();
    expect(inside.size, const Size(90.0, 45.0));

    outside.minWidth = 80.0;
    outside.minHeight = 80.0;

    outside.maxWidth = 100.0;
    outside.maxHeight = 90.0;
    pumpFrame();
    expect(inside.size, const Size(100.0, 80.0));

    outside.maxWidth = 90.0;
    outside.maxHeight = 100.0;
    pumpFrame();
    expect(inside.size, const Size(90.0, 80.0));

    outside.maxWidth = double.infinity;
    outside.maxHeight = 90.0;
    pumpFrame();
    expect(inside.size, const Size(180.0, 90.0));

    outside.maxWidth = 90.0;
    outside.maxHeight = double.infinity;
    pumpFrame();
    expect(inside.size, const Size(90.0, 80.0));
  });
}
