// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'mock_canvas.dart';

void main() {
  test('Describe transform control test', () {
    Matrix4 identity = new Matrix4.identity();
    List<String> description = debugDescribeTransform(identity);
    expect(description, equals(<String>[
      '  [0] 1.0,0.0,0.0,0.0',
      '  [1] 0.0,1.0,0.0,0.0',
      '  [2] 0.0,0.0,1.0,0.0',
      '  [3] 0.0,0.0,0.0,1.0',
    ]));
  });

  test('debugPaintPadding', () {
    expect((Canvas canvas) {
      debugPaintPadding(canvas, new Rect.fromLTRB(10.0, 10.0, 20.0, 20.0), null);
    }, paints..rect(color: debugPaintSpacingColor));
    expect((Canvas canvas) {
      debugPaintPadding(canvas, new Rect.fromLTRB(10.0, 10.0, 20.0, 20.0), new Rect.fromLTRB(11.0, 11.0, 19.0, 19.0));
    }, paints..path(color: debugPaintPaddingColor)..path(color: debugPaintPaddingInnerEdgeColor));
    expect((Canvas canvas) {
      debugPaintPadding(canvas, new Rect.fromLTRB(10.0, 10.0, 20.0, 20.0), new Rect.fromLTRB(15.0, 15.0, 15.0, 15.0));
    }, paints..rect(rect: new Rect.fromLTRB(10.0, 10.0, 20.0, 20.0), color: debugPaintSpacingColor));
  });
}
