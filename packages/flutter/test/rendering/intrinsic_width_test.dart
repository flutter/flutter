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
