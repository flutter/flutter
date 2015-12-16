// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

class RenderTestBox extends RenderBox {
  RenderTestBox(this._intrinsicDimensions);

  final BoxConstraints _intrinsicDimensions;

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(_intrinsicDimensions.minWidth);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(_intrinsicDimensions.maxWidth);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(_intrinsicDimensions.minHeight);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(_intrinsicDimensions.maxHeight);
  }

  bool get sizedByParent => true;
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
              maxHeight: 800.0));
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
              maxHeight: 800.0));
    expect(parent.size.width, equals(55.0));
    expect(parent.size.height, equals(200.0));
  });
}
