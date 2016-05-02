// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

void main() {
  test('Intrinsic sizing', () {
    RenderAspectRatio box = new RenderAspectRatio(aspectRatio: 2.0);

    BoxConstraints constraints = new BoxConstraints.loose(new Size(200.0, 200.0));
    expect(box.getMinIntrinsicWidth(constraints), equals(0.0));
    expect(box.getMaxIntrinsicWidth(constraints), equals(200.0));
    expect(box.getMinIntrinsicHeight(constraints), equals(0.0));
    expect(box.getMaxIntrinsicHeight(constraints), equals(100.0));

    constraints = new BoxConstraints(maxHeight: 400.0);
    expect(box.getMinIntrinsicWidth(constraints), equals(0.0));
    expect(box.getMaxIntrinsicWidth(constraints), equals(800.0));
    expect(box.getMinIntrinsicHeight(constraints), equals(0.0));
    expect(box.getMaxIntrinsicHeight(constraints), equals(400.0));
  });
}
