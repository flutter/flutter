// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

// before using this, consider using RenderSizedBox from rendering_tester.dart
class RenderTestBox extends RenderBox {
  RenderTestBox(this._intrinsicDimensions);

  final BoxConstraints _intrinsicDimensions;

  @override
  double getMinIntrinsicWidth(double height) {
    return _intrinsicDimensions.minWidth;
  }

  @override
  double getMaxIntrinsicWidth(double height) {
    return _intrinsicDimensions.maxWidth;
  }

  @override
  double getMinIntrinsicHeight(double width) {
    return _intrinsicDimensions.minHeight;
  }

  @override
  double getMaxIntrinsicHeight(double width) {
    return _intrinsicDimensions.maxHeight;
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.constrain(new Size(_intrinsicDimensions.minWidth + (_intrinsicDimensions.maxWidth-_intrinsicDimensions.minWidth) / 2.0,
                                          _intrinsicDimensions.minHeight + (_intrinsicDimensions.maxHeight-_intrinsicDimensions.minHeight) / 2.0));
  }
}

void main() {
  test('Shrink-wrapping width', () {
    RenderBox child = new RenderTestBox(new BoxConstraints(minWidth: 10.0, maxWidth: 100.0, minHeight: 20.0, maxHeight: 200.0));

    RenderBox parent = new RenderIntrinsicWidth(child: child);
    layout(parent,
      constraints: new BoxConstraints(
        minWidth: 5.0,
        minHeight: 8.0,
        maxWidth: 500.0,
        maxHeight: 800.0
      )
    );
    expect(parent.size.width, equals(100.0));
    expect(parent.size.height, equals(110.0));
  });

  test('Shrink-wrapping height', () {
    RenderBox child = new RenderTestBox(new BoxConstraints(minWidth: 10.0, maxWidth: 100.0, minHeight: 20.0, maxHeight: 200.0));

    RenderBox parent = new RenderIntrinsicHeight(child: child);
    layout(parent,
      constraints: new BoxConstraints(
        minWidth: 5.0,
        minHeight: 8.0,
        maxWidth: 500.0,
        maxHeight: 800.0
      )
    );
    expect(parent.size.width, equals(55.0));
    expect(parent.size.height, equals(200.0));
  });

  test('Padding and boring intrinsics', () {
    RenderBox box = new RenderPadding(
      padding: new EdgeInsets.all(15.0),
      child: new RenderSizedBox(const Size(20.0, 20.0))
    );

    expect(box.getMinIntrinsicWidth(0.0), 50.0);
    expect(box.getMaxIntrinsicWidth(0.0), 50.0);
    expect(box.getMinIntrinsicHeight(0.0), 50.0);
    expect(box.getMaxIntrinsicHeight(0.0), 50.0);

    expect(box.getMinIntrinsicWidth(10.0), 50.0);
    expect(box.getMaxIntrinsicWidth(10.0), 50.0);
    expect(box.getMinIntrinsicHeight(10.0), 50.0);
    expect(box.getMaxIntrinsicHeight(10.0), 50.0);

    expect(box.getMinIntrinsicWidth(80.0), 50.0);
    expect(box.getMaxIntrinsicWidth(80.0), 50.0);
    expect(box.getMinIntrinsicHeight(80.0), 50.0);
    expect(box.getMaxIntrinsicHeight(80.0), 50.0);

    expect(box.getMinIntrinsicWidth(double.INFINITY), 50.0);
    expect(box.getMaxIntrinsicWidth(double.INFINITY), 50.0);
    expect(box.getMinIntrinsicHeight(double.INFINITY), 50.0);
    expect(box.getMaxIntrinsicHeight(double.INFINITY), 50.0);

    // also a smoke test:
    layout(
      box,
      constraints: new BoxConstraints(
        minWidth: 10.0,
        minHeight: 10.0,
        maxWidth: 10.0,
        maxHeight: 10.0
      )
    );
  });

  test('Padding and interesting intrinsics', () {
    RenderBox box = new RenderPadding(
      padding: new EdgeInsets.all(15.0),
      child: new RenderAspectRatio(aspectRatio: 1.0)
    );

    expect(box.getMinIntrinsicWidth(0.0), 30.0);
    expect(box.getMaxIntrinsicWidth(0.0), 30.0);
    expect(box.getMinIntrinsicHeight(0.0), 30.0);
    expect(box.getMaxIntrinsicHeight(0.0), 30.0);

    expect(box.getMinIntrinsicWidth(10.0), 30.0);
    expect(box.getMaxIntrinsicWidth(10.0), 30.0);
    expect(box.getMinIntrinsicHeight(10.0), 30.0);
    expect(box.getMaxIntrinsicHeight(10.0), 30.0);

    expect(box.getMinIntrinsicWidth(80.0), 80.0);
    expect(box.getMaxIntrinsicWidth(80.0), 80.0);
    expect(box.getMinIntrinsicHeight(80.0), 80.0);
    expect(box.getMaxIntrinsicHeight(80.0), 80.0);

    expect(box.getMinIntrinsicWidth(double.INFINITY), 30.0);
    expect(box.getMaxIntrinsicWidth(double.INFINITY), 30.0);
    expect(box.getMinIntrinsicHeight(double.INFINITY), 30.0);
    expect(box.getMaxIntrinsicHeight(double.INFINITY), 30.0);

    // also a smoke test:
    layout(
      box,
      constraints: new BoxConstraints(
        minWidth: 10.0,
        minHeight: 10.0,
        maxWidth: 10.0,
        maxHeight: 10.0
      )
    );
  });
}
